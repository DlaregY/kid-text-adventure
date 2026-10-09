"""Guard the phone-input role model and reuse of the approved portrait/splash."""
import hashlib
from pathlib import Path
import re
import struct
import unittest
from story_paths import ACTIONS, State, fits_slots

ROOT = Path(__file__).resolve().parents[1]

class TouchRolesAndBrandingTests(unittest.TestCase):
    def test_audit_actions_match_the_runtime(self):
        code = (ROOT/'scripts/Game.gd').read_text()
        match = re.search(r'const ACTION_TOKENS: Array\[String\] = \[(.*?)\]', code)
        self.assertIsNotNone(match)
        self.assertEqual(set(re.findall(r'"(.*?)"', match[1])), set(ACTIONS))

    def test_actions_and_things_cannot_swap_slots(self):
        state = State('bigfoot_meeting')
        self.assertTrue(fits_slots(state, ('look','bigfoot')))
        self.assertFalse(fits_slots(state, ('bigfoot','look')))
        self.assertFalse(fits_slots(state, ('look','look')))
        self.assertFalse(fits_slots(state, ('camera','bigfoot')))

    def test_collected_items_retain_both_roles(self):
        state = State('bigfoot_meeting', frozenset({'camera', 'snack'}))
        for command in [('camera','bigfoot'), ('snack','bigfoot'), ('look','camera'), ('give','snack')]:
            self.assertTrue(fits_slots(state, command), command)
        self.assertFalse(fits_slots(state, ('camera','give')))

    def test_portrait_is_the_original_asset_and_splash_is_unchanged(self):
        portrait = (ROOT/'assets/branding/ike-portrait.png').read_bytes()
        self.assertEqual(portrait, (ROOT/'icon.png').read_bytes())
        self.assertEqual(hashlib.sha256(portrait).hexdigest(), '8c0dfb11a73a742f5ef2f4ad3e3c36987c59d7fd3b2e5653b889afead7f3a5a1')
        self.assertEqual(hashlib.sha256((ROOT/'assets/branding/norbonics-games.png').read_bytes()).hexdigest(), '295a811a23c81f541fe14fced20bfa00a7bb5502bb0005e40b9f89b05835ad2d')
        self.assertIn('boot_splash/image="res://assets/branding/norbonics-games.png"', (ROOT/'project.godot').read_text())
        self.assertIn('path="res://assets/branding/ike-portrait.png" id="icon_tex"', (ROOT/'Game.tscn').read_text())

    def test_launcher_uses_portrait_not_the_old_k(self):
        preset = (ROOT/'export_presets.cfg').read_text()
        self.assertIn('launcher_icons/main_192x192="res://assets/branding/ike-portrait.png"', preset)
        self.assertIn('launcher_icons/adaptive_foreground_432x432="res://assets/icons/android/ike_adaptive_foreground_432.png"', preset)
        self.assertIn('launcher_icons/adaptive_monochrome_432x432=""', preset)
        png = (ROOT/'assets/icons/android/ike_adaptive_foreground_432.png').read_bytes()
        self.assertEqual(struct.unpack('>II', png[16:24]), (432,432))
        self.assertEqual(hashlib.sha256(png).hexdigest(), 'cb6219980b3aec5b60b48a7891d7f11e8f459ea445eb42aa7696ae1291a5e842')

if __name__ == '__main__':
    unittest.main()
