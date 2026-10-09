"""Safety checks for candidate staging and APK evidence helpers; no Android builds."""
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zipfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import android_candidate as candidate
from verify_android_candidate import elf_load_alignments

class AndroidCandidateTests(unittest.TestCase):
    def test_separate_identity_and_bad_ids(self):
        self.assertEqual(candidate.package_for('r123a1'), 'com.ike.textadventure.candidate.r123a1')
        for value in ['', '123', '../preview', 'r1.foo', 'a'*32, 'R1', 'r1\n']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                candidate.package_for(value)

    def test_preset_changes_are_staged_and_keep_release_fields(self):
        source = (candidate.ROOT / 'export_presets.cfg').read_text()
        updated = candidate.configure_preset(source, 'r123a1', Path('/tmp/templates'))
        self.assertIn('package/unique_name="com.ike.textadventure.candidate.r123a1"',updated)
        self.assertIn('gradle_build/export_format=0',updated)
        for setting in ['version/code=700', 'version/name="0.7.0"','target_sdk="36"','user_data_backup/allow=false']:
            self.assertIn(setting,updated)
        self.assertEqual((candidate.ROOT/'export_presets.cfg').read_text(),source)
        for bad in [source.replace('permissions/internet=false','permissions/internet=true'),
                    source.replace('gradle_build/target_sdk="36"','gradle_build/target_sdk="34"'),
                    source.replace('gradle_build/export_format=1','gradle_build/export_format=0')]:
            with self.assertRaises(ValueError):candidate.configure_preset(bad,'r1',Path('/tmp'))

    def test_exact_template_patch_fails_on_drift(self):
        source='\n'.join(candidate.TEMPLATE_CHANGES)
        self.assertEqual(candidate.patch_template(source),'\n'.join(candidate.TEMPLATE_CHANGES.values()))
        for bad in [source+source, source.replace("8.6.1", "9.0.0")]:
            with self.assertRaises(ValueError):candidate.patch_template(bad)

    def test_template_path_traversal_rejected(self):
        with tempfile.TemporaryDirectory() as t:
            root=Path(t); archive=root/'test.zip'
            with zipfile.ZipFile(archive,'w') as z:z.writestr('../escape','not allowed')
            with self.assertRaises(ValueError):candidate.safe_extract(archive,root/'stage')
            self.assertFalse((root/'escape').exists())

    def test_native_alignment_accepts_16k_not_4k(self):
        data=bytearray(120);data[:6]=b'\x7fELF\x02\x01'
        struct.pack_into('<Q',data,32,64);struct.pack_into('<HH',data,54,56,1)
        struct.pack_into('<IIQQQQQQ',data,64,1,5,0,0,0,0,0,16384)
        self.assertEqual(elf_load_alignments(bytes(data)),[16384])
        struct.pack_into('<Q',data,112,4096)
        with self.assertRaises(ValueError):elf_load_alignments(bytes(data))

if __name__=='__main__':unittest.main()
