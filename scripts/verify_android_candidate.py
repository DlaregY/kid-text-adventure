"""Inspect a built APK; fail closed rather than infer its properties from source."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import zipfile


def elf_load_alignments(data: bytes) -> list[int]:
    if data[:6] != b'\x7fELF\x02\x01':
        raise ValueError('Expected little-endian ELF64')
    offset = struct.unpack_from('<Q', data, 32)[0]
    size, count = struct.unpack_from('<HH', data, 54)
    aligns = []
    for i in range(count):
        kind, flags, fileoff, vaddr, paddr, filesz, memsz, align = struct.unpack_from('<IIQQQQQQ', data, offset + i * size)
        if kind == 1:
            if align < 16384 or (vaddr - fileoff) % 16384:
                raise ValueError('Native LOAD segment is not 16 KB aligned')
            aligns.append(align)
    if not aligns:
        raise ValueError('ELF has no LOAD segments')
    return aligns


def verify(apk: Path, expected: dict, tools: Path, output: Path, env: dict) -> dict:
    evidence = dict(expected)
    def checked(command: list[str], name: str) -> str:
        result = subprocess.run(command, text=True, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
        (output / name).write_text(result.stdout)
        if result.returncode:
            raise ValueError(f'Artifact validation failed: {name}')
        return result.stdout
    badging = checked([str(tools / 'aapt2'), 'dump', 'badging', str(apk)], 'badging.txt')
    match = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
    if not match or match.groups() != (expected['package'], str(expected['version_code']), expected['version_name']):
        raise ValueError('Packaged identity/version mismatch')
    for prefix, value in [('sdkVersion', 24), ('targetSdkVersion', 36)]:
        if f"{prefix}:'{value}'" not in badging:
            raise ValueError('Packaged SDK mismatch')
    if 'uses-permission:' in badging or 'uses-permission-sdk-' in badging:
        raise ValueError('APK unexpectedly requests permissions')
    permissions = checked([str(tools / 'aapt2'), 'dump', 'permissions', str(apk)], 'permissions.txt')
    if 'uses-permission' in permissions:
        raise ValueError('APK requests a permission')
    manifest = checked([str(tools / 'aapt2'), 'dump', 'xmltree', str(apk), '--file', 'AndroidManifest.xml'], 'manifest.txt')
    if not re.search(r'android:allowBackup[^\n]*=(?:\(type 0x12\))?0x0\b', manifest):
        raise ValueError('Manifest does not explicitly disable backup')
    signing = checked([str(tools / 'apksigner'), 'verify', '--verbose', '--print-certs', str(apk)], 'signing.txt')
    checked([str(tools / 'apksigner'), 'verify', '--min-sdk-version', '33', str(apk)], 'signing-android13.txt')
    fingerprint = re.search(r'Signer #1 certificate SHA-256 digest: ([a-fA-F0-9]+)', signing)
    if not fingerprint:
        raise ValueError('Missing verified signing certificate')
    checked([str(tools / 'zipalign'), '-c', '-P', '16', '-v', '4', str(apk)], 'zipalign.txt')
    libraries = {}
    with zipfile.ZipFile(apk) as z:
        if z.testzip():
            raise ValueError('APK has a bad CRC')
        names = z.namelist()
        if len(set(names)) != len(names):
            raise ValueError('Duplicate APK members')
        (output / 'apk-files.txt').write_text('\n'.join(names) + '\n')
        actual_stories = sorted(n for n in names if n.startswith('assets/stories/') and n.endswith('.json'))
        if actual_stories != sorted('assets/' + n for n in expected['stories']):
            raise ValueError('Packaged story set changed')
        for name, sha in expected['stories'].items():
            if hashlib.sha256(z.read('assets/' + name)).hexdigest() != sha:
                raise ValueError('Packaged story bytes differ: ' + name)
        if z.read('assets/version.txt').decode().strip() != expected['version_name']:
            raise ValueError('Packaged version.txt mismatch')
        if json.loads(z.read('assets/assets/candidate-build.json')) != expected:
            raise ValueError('Build provenance missing or altered')
        if not any('PrivacyDialog' in n for n in names):
            raise ValueError('Privacy dialog missing from APK')
        if any(n.startswith(('assets/tests/', 'assets/docs/', 'assets/tasks/')) or n.endswith(('.keystore', '.jks', '.pyc')) for n in names):
            raise ValueError('APK contains development or signing material')
        if 'assets/icon.png' in names or 'assets/splash.png' in names:
            raise ValueError('Old portrait source exported')
        for name in names:
            if name.startswith('lib/') and name.endswith('.so'):
                if name.split('/')[1] not in expected['abis']:
                    raise ValueError('Unexpected ABI')
                libraries[name] = elf_load_alignments(z.read(name))
        if not libraries:
            raise ValueError('No native libraries packaged')
    evidence.update(apk_name=apk.name, apk_bytes=apk.stat().st_size,
        apk_sha256=hashlib.sha256(apk.read_bytes()).hexdigest(), signer_sha256=fingerprint.group(1).lower(),
        permissions=[], signature_verified=True, android13_signature_verified=True,
        zip_crc_verified=True, zip_alignment_16kb=True, native_load_alignments=libraries,
        packaged_story_bytes_verified=True, privacy_dialog_packaged=True, backup_allowed=False)
    return evidence
