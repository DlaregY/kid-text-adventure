"""Build an isolated debug-signed Android candidate; never a Play release.

Requires official Godot 4.6.1 plus its matching Android templates, JDK 17,
Android platform 36, Build Tools 36.0.0 and platform-tools. The caller supplies
these paths. Production/preview IDs, signing material and player data are untouched.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
GODOT_VERSION = '4.6.1'
TEMPLATE_CHANGES = {
    "androidGradlePlugin: '8.6.1'": "androidGradlePlugin: '8.9.2'",
    'compileSdk         : 35': 'compileSdk         : 36',
    "buildTools         : '35.0.1'": "buildTools         : '36.0.0'",
}


def replace_once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise ValueError(f'Unexpected pinned configuration: {old}')
    return text.replace(old, new, 1)


def patch_template(text: str) -> str:
    """The modern-target toolchain used by both preview build entry points."""
    for old, new in TEMPLATE_CHANGES.items():
        text = replace_once(text, old, new)
    return text


def package_for(candidate_id: str) -> str:
    if not re.fullmatch(r'[a-z][a-z0-9]{0,30}', candidate_id):
        raise ValueError('Candidate ID must start with a lowercase letter and use <=31 lowercase letters/digits')
    return 'com.ike.textadventure.candidate.' + candidate_id


def configure_preset(text: str, candidate_id: str, templates: Path) -> str:
    changes = {
        'package/unique_name="com.ike.textadventure"': f'package/unique_name="{package_for(candidate_id)}"',
        'package/name="Ike Quest"': f'package/name="Ike Quest Test {candidate_id}"',
        'gradle_build/export_format=1': 'gradle_build/export_format=0',
        'gradle_build/android_source_template=""': f'gradle_build/android_source_template={json.dumps(str(templates / "android_source.zip"))}',
        'include_filter="stories/*.json,version.txt"': 'include_filter="stories/*.json,version.txt,assets/candidate-build.json"',
    }
    for old, new in changes.items():
        text = replace_once(text, old, new)
    if 'gradle_build/target_sdk="36"' not in text or 'gradle_build/min_sdk="24"' not in text:
        raise ValueError('Expected target 36 / min 24; do not silently change the release target')
    if re.search(r'^permissions/[^\n=]+=true$', text, re.M):
        raise ValueError('Unexpected Android permission enabled')
    if 'permissions/custom_permissions=PackedStringArray()' not in text:
        raise ValueError('Unexpected custom permissions')
    return text


def safe_extract(archive: Path, destination: Path) -> None:
    with zipfile.ZipFile(archive) as z:
        for item in z.infolist():
            path = destination / item.filename
            if not path.resolve().is_relative_to(destination.resolve()) or (item.external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError('Unsafe template archive entry')
        z.extractall(destination)


def run(command: list[str], env: dict[str, str], log: Path, timeout: int = 1200) -> str:
    result = subprocess.run(command, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, timeout=timeout)
    log.write_text(result.stdout, encoding='utf-8')
    print(result.stdout, flush=True)
    if result.returncode or re.search(r'(^|\n)(SCRIPT ERROR:|ERROR:)', result.stdout):
        raise RuntimeError(f'Command failed; see {log.name}')
    return result.stdout


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ['godot', 'sdk', 'templates', 'java']:
        parser.add_argument('--' + name, required=True, type=Path)
    parser.add_argument('--candidate-id', required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'exports/candidate')
    parser.add_argument('--renderer', choices=['mobile', 'gl_compatibility'], default='mobile')
    args = parser.parse_args()
    package = package_for(args.candidate_id)
    godot, sdk, templates, java, output = [p.resolve() for p in
        [args.godot, args.sdk, args.templates, args.java, args.output]]
    if output == ROOT or (ROOT in output.parents and ROOT / 'exports' not in (output, *output.parents)):
        parser.error('Checkout output must be under exports/')
    required = [godot, java / 'bin/java', java / 'bin/keytool', sdk / 'platform-tools/adb',
        sdk / 'platforms/android-36/android.jar', sdk / 'build-tools/36.0.0/aapt2',
        sdk / 'build-tools/36.0.0/apksigner', sdk / 'build-tools/36.0.0/zipalign']
    required += [templates / x for x in ['android_source.zip', 'android_debug.apk', 'android_release.apk', 'version.txt']]
    for path in required:
        if not path.is_file():
            parser.error(f'Missing prerequisite: {path}')
    if subprocess.check_output([str(godot), '--version'], text=True).strip() != '4.6.1.stable.official.14d19694e':
        parser.error('This build is pinned to official Godot 4.6.1')
    if (templates / 'version.txt').read_text().strip() != '4.6.1.stable':
        parser.error('Mismatched export templates')
    if subprocess.check_output(['git', '-C', str(ROOT), 'status', '--porcelain'], text=True).strip():
        parser.error('Commit source changes first; candidate evidence requires a clean checkout')
    sha = subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', 'HEAD'], text=True).strip()
    version = (ROOT / 'version.txt').read_text().strip()
    preset = (ROOT / 'export_presets.cfg').read_text()
    if f'version/name="{version}"' not in preset:
        parser.error('Release version metadata is out of sync')
    code = int(re.search(r'^version/code=(\d+)$', preset, re.M).group(1))
    output.mkdir(parents=True, exist_ok=True)
    apk = output / f'ike-quest-{version}-{args.candidate_id}-target36-{sha[:12]}.apk'
    if apk.exists():
        parser.error('Refusing to overwrite an existing candidate; use a new output/ID')
    source_hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                     for p in sorted((ROOT / 'stories').glob('*.json'))}
    if len(source_hashes) != 6:
        parser.error('Expected exactly six stories')
    metadata = {'source_commit': sha, 'package': package, 'candidate_id': args.candidate_id,
        'version_name': version, 'version_code': code, 'min_sdk': 24, 'target_sdk': 36,
        'compile_sdk': 36, 'build_tools': '36.0.0', 'agp': '8.9.2', 'godot': '4.6.1',
        'renderer_requested': args.renderer, 'renderer_observed_on_device': None,
        'abis': ['arm64-v8a'], 'stories': source_hashes, 'debug_signed': True,
        'device_tested': False, 'play_uploaded': False}
    with tempfile.TemporaryDirectory(prefix='ike-candidate-') as tmp:
        tmp = Path(tmp)
        stage = tmp / 'project'; stage.mkdir()
        for name in ['assets', 'scripts', 'stories', 'ui']:
            shutil.copytree(ROOT / name, stage / name, ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
        for name in ['Game.tscn', 'project.godot', 'version.txt', 'icon.png', 'icon.svg', 'splash.png']:
            shutil.copy2(ROOT / name, stage / name)
        staged_project = (stage / 'project.godot').read_text()
        # Explicitly reproduce the intended mobile default in this test build.
        # This changes only the disposable copy, not production configuration.
        if 'renderer/rendering_method' in staged_project:
            raise ValueError('Renderer is now explicitly configured; reconcile instead of overriding it')
        staged_project = replace_once(staged_project, '[rendering]',
            f'[rendering]\n\nrenderer/rendering_method="{args.renderer}"\nrenderer/rendering_method.mobile="{args.renderer}"')
        (stage / 'project.godot').write_text(staged_project)
        (stage / 'export_presets.cfg').write_text(configure_preset(preset, args.candidate_id, templates))
        (stage / 'assets/candidate-build.json').write_text(json.dumps(metadata, indent=2) + '\n')
        config = tmp / 'config/godot'; config.mkdir(parents=True)
        home = tmp / 'home'; home.mkdir()
        key = tmp / 'candidate-debug.keystore'
        env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(tmp / 'config'),
            XDG_DATA_HOME=str(tmp / 'data'), JAVA_HOME=str(java), ANDROID_HOME=str(sdk),
            ANDROID_SDK_ROOT=str(sdk), GODOT_SILENCE_ROOT_WARNING='1')
        env.pop('GODOT_OVERRIDE', None)
        # Disposable debug key only; never export, cache or publish signing keys.
        run([str(java / 'bin/keytool'), '-genkeypair', '-keystore', str(key), '-storepass', 'android',
            '-keypass', 'android', '-alias', 'androiddebugkey', '-keyalg', 'RSA', '-keysize', '2048',
            '-validity', '3650', '-dname', 'CN=Android Debug,O=Android,C=US'], env, output / 'debug-key.log')
        settings = {'android_sdk_path': str(sdk), 'java_sdk_path': str(java),
            'debug_keystore': str(key), 'debug_keystore_user': 'androiddebugkey', 'debug_keystore_pass': 'android'}
        (config / 'editor_settings-4.6.tres').write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' +
            ''.join(f'export/android/{k} = {json.dumps(v)}\n' for k, v in settings.items()))
        data = tmp / 'data/godot/export_templates/4.6.1.stable'; data.mkdir(parents=True)
        for name in ['android_debug.apk', 'android_release.apk', 'android_source.zip', 'version.txt']:
            (data / name).symlink_to(templates / name)
        run([str(godot), '--headless', '--path', str(stage), '--editor', '--import'], env, output / 'import.log')
        android = stage / 'android'; android.mkdir(exist_ok=True)
        safe_extract(templates / 'android_source.zip', android / 'build')
        (android / '.gdignore').touch()
        template = templates / 'android_source.zip'
        (android / '.build_version').write_text(f'{template} [{hashlib.md5(template.read_bytes()).hexdigest()}]\n')
        (android / 'build/gradlew').chmod(0o755)
        gradle = android / 'build/config.gradle'
        gradle.write_text(patch_template(gradle.read_text()))
        run([str(godot), '--headless', '--path', str(stage), '--export-debug', 'Ike Quest', str(apk)],
            env, output / 'build.log')
        from verify_android_candidate import verify
        evidence = verify(apk, metadata, sdk / 'build-tools/36.0.0', output, env)
    (output / 'candidate-evidence.json').write_text(json.dumps(evidence, indent=2) + '\n')
    (output / 'SHA256SUMS').write_text(f"{evidence['apk_sha256']}  {apk.name}\n")
    print(f'Validated test APK: {apk}\nProduction package and player data were not modified.')
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError, zipfile.BadZipFile) as exc:
        raise SystemExit(str(exc))
