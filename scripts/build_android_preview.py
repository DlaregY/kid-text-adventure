import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

from android_candidate import patch_template


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--diagnostic-target-34", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    output = root / "exports"
    output.mkdir(exist_ok=True)
    (output / ".gdignore").touch()
    toolchain = output / "toolchain"
    godot = toolchain / "Godot_v4.6.1-stable_linux.x86_64"
    sdk = toolchain / "sdk"
    java = Path("/usr/lib/jvm/java-17-openjdk-amd64")
    templates = toolchain / "templates"
    for required in (godot, sdk / "platform-tools/adb", java / "bin/java", templates / "android_source.zip"):
        if not required.exists():
            raise SystemExit(f"Missing build prerequisite: {required}")
    stage = Path(tempfile.mkdtemp(prefix="preview-source-", dir=output))
    for name in ("assets", "scripts", "stories", "ui"):
        shutil.copytree(root / name, stage / name, dirs_exist_ok=True)
    for name in ("Game.tscn", "project.godot", "version.txt", "icon.png", "icon.svg", "splash.png"):
        shutil.copy2(root / name, stage / name)
    preset = (root / "export_presets.cfg").read_text()
    replacements = {
        'package/unique_name="com.ike.textadventure"': 'package/unique_name="com.ike.textadventure.preview"',
        'package/name="Ike Quest"': 'package/name="Ike Quest Preview"',
        'gradle_build/android_source_template=""': f'gradle_build/android_source_template="{templates / "android_source.zip"}"',
        # The production preset emits an App Bundle for Play; sideload previews need an APK.
        'gradle_build/export_format=1': 'gradle_build/export_format=0',
    }
    for old, new in replacements.items():
        if preset.count(old) != 1:
            raise SystemExit(f"Unexpected export configuration: {old}")
        preset = preset.replace(old, new)
    if args.diagnostic_target_34:
        old = 'gradle_build/target_sdk="36"'
        if preset.count(old) != 1:
            raise SystemExit("Unexpected target SDK configuration")
        preset = preset.replace(old, 'gradle_build/target_sdk="34"')
    (stage / "export_presets.cfg").write_text(preset)
    config = output / "config/godot"
    config.mkdir(parents=True, exist_ok=True)
    (config / "editor_settings-4.6.tres").write_text(
        '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
        f'export/android/android_sdk_path = "{sdk}"\n'
        f'export/android/java_sdk_path = "{java}"\n'
    )
    data = output / "data/godot/export_templates/4.6.1.stable"
    data.mkdir(parents=True, exist_ok=True)
    for name in ("android_debug.apk", "android_release.apk", "android_source.zip", "version.txt"):
        target = data / name
        if not target.exists():
            target.symlink_to(templates / name)
    env = dict(os.environ, XDG_CONFIG_HOME=str(output / "config"),
               XDG_DATA_HOME=str(output / "data"), JAVA_HOME=str(java),
               ANDROID_HOME=str(sdk), ANDROID_SDK_ROOT=str(sdk))
    subprocess.run([str(godot), "--headless", "--path", str(stage), "--editor", "--import"], env=env, check=True)
    android = stage / "android"
    android.mkdir()
    with zipfile.ZipFile(templates / "android_source.zip") as archive:
        archive.extractall(android / "build")
    template = templates / "android_source.zip"
    (android / ".build_version").write_text(f"{template} [{hashlib.md5(template.read_bytes()).hexdigest()}]\n")
    (android / ".gdignore").touch()
    (android / "build/gradlew").chmod(0o755)
    if not args.diagnostic_target_34:
        for required in (sdk / "platforms/android-36/android.jar", sdk / "build-tools/36.0.0/aapt2"):
            if not required.exists():
                raise SystemExit(f"Missing Android 36 prerequisite: {required}")
        gradle_config = stage / "android/build/config.gradle"
        gradle_config.write_text(patch_template(gradle_config.read_text()))
    apk = output / ("ike-quest-preview-target34.apk" if args.diagnostic_target_34 else "ike-quest-preview.apk")
    subprocess.run([str(godot), "--headless", "--path", str(stage),
                    "--export-debug",
                    "Ike Quest", str(apk)], env=env, check=True)
    print(apk)


if __name__ == "__main__":
    main()
