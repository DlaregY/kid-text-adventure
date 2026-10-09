"""The public build must not initialize or call a device speech service."""
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]

class NoSpeechTests(unittest.TestCase):
    def test_no_speech_entry_points_in_runtime(self):
        sources = [*ROOT.joinpath('scripts').glob('*.gd'), *ROOT.joinpath('ui').glob('*.tscn'), ROOT/'Game.tscn']
        for p in sources:
            with self.subTest(path=p.name):
                text=p.read_text(encoding='utf-8')
                self.assertNotRegex(text, r'DisplayServer\.tts_|FEATURE_TEXT_TO_SPEECH|SpeakButton|ReadAloudToggle|func _speak\(')
        self.assertIn('general/text_to_speech=false', (ROOT/'project.godot').read_text())

    def test_no_speech_daemon_in_ci(self):
        ci=(ROOT/'.github/workflows/godot-checks.yml').read_text()
        self.assertNotIn('speech-dispatcher',ci)
        self.assertNotIn('libspeechd',ci)

    def test_in_app_policy_matches_reviewable_markdown(self):
        md=(ROOT/'docs/privacy-policy.md').read_text(encoding='utf-8')
        plain=re.sub(r'^#{1,2} ', '',md,flags=re.M)
        plain=re.sub(r'^_(Last updated: .*)_$',r'\1',plain,flags=re.M).strip()
        scene=(ROOT/'ui/PrivacyDialog.tscn').read_text(encoding='utf-8')
        body=scene.split('[node name="Policy"',1)[1].split('[node name="Close"',1)[0]
        match=re.search(r'^text = (".*")$',body,re.M)
        self.assertIsNotNone(match)
        self.assertEqual(json.loads(match.group(1)),plain)
        self.assertIn('does not provide read-aloud',plain)
        self.assertIn('hello@norbonics.com',plain)

    def test_production_permissions_remain_disabled(self):
        text=(ROOT/'export_presets.cfg').read_text()
        self.assertIn('package/unique_name="com.ike.textadventure"',text)
        self.assertIsNone(re.search(r'^permissions/[^\n=]+=true$',text,re.M))
        self.assertIn('permissions/custom_permissions=PackedStringArray()',text)

if __name__=='__main__': unittest.main()
