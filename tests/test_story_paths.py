"""Story-content acceptance checks, including independent state-space coverage."""
from copy import deepcopy
import json
import re
import unittest
from story_paths import STORIES, State, apply, audit


class StoryPathTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.stories = {p.name: json.loads(p.read_text(encoding="utf-8")) for p in STORIES.glob("*.json")}
        cls.results = {name: audit(story) for name, story in cls.stories.items()}

    def test_every_story_scene_and_ending_is_reachable_without_dead_states(self):
        self.assertEqual(len(self.stories), 6)
        self.assertEqual(sum(r["scenes"] for r in self.results.values()), 59)
        self.assertEqual(sum(len(r["endings"]) for r in self.results.values()), 10)
        for name, result in sorted(self.results.items()):
            with self.subTest(story=name):
                self.assertEqual(result["unreachable_scenes"], [])
                self.assertEqual(result["dead_states"], 0)
                print(f"PATH PASS {name}: {result['states']} states, {result['scenes']} scenes, {len(result['endings'])} endings, no dead states")

    def test_library_final_hint_is_executable_from_normal_arrival(self):
        story = self.stories["spider_hero.json"]
        state = State(story["start_scene"])
        for command in self.results["spider_hero.json"]["witnesses"]["library"]:
            state = apply(story, state, command)
        self.assertIn("key", state.inventory)
        self.assertNotIn("read_book", state.flags)
        for door in [("open", "door"), ("key", "door")]:
            self.assertEqual(apply(story, state, door), state)
        final = story["scenes"]["library"]["hints"][-1]
        commands = [(a.lower(), b.lower()) for a,b in re.findall(r"\b(LOOK|TAKE|OPEN) (SHELF|BOOK|DOOR)\b", final)]
        self.assertEqual(commands, [("look","shelf"), ("take","book"), ("open","book"), ("open","door")])
        for command in commands:
            state = apply(story, state, command)
        self.assertEqual(state.scene, "basement")
        self.assertIn("read_book", state.flags)
        self.assertNotIn("key", state.inventory)

    def test_go_bed_and_legacy_open_bed_are_equivalent(self):
        story = self.stories["phone_trap.json"]
        state = State("landing")
        self.assertEqual(apply(story, state, ("go", "bed")), apply(story, state, ("open", "bed")))
        self.assertEqual(apply(story, state, ("go", "bed")).scene, "home")
        self.assertEqual(story["vocab"]["bed"]["label"], "Bed")
        self.assertIn("GO BED", story["scenes"]["landing"]["hints"][-1])

    def test_bigfoot_chat_and_inspection_never_finish_even_after_legacy_hello(self):
        story = self.stories["bigfoot_campout.json"]
        for flags in [frozenset(), frozenset({"said_hello", "looked_bigfoot"})]:
            state = State("bigfoot_meeting", frozenset({"lantern", "snack", "camera", "berries", "pinecone"}), flags)
            for _ in range(6):
                for command in [("look", "bigfoot"), ("talk", "bigfoot"), ("look", "joke")]:
                    state = apply(story, state, command)
                    self.assertEqual(state.scene, "bigfoot_meeting")
            self.assertEqual(len(state.inventory), 5)
        self.assertEqual(apply(story, state, ("tell", "joke")).scene, "ending_goofy")

    def test_bigfoot_endings_remain_available_with_appropriate_equipment(self):
        story = self.stories["bigfoot_campout.json"]
        state = State("bigfoot_meeting", frozenset({"snack", "lantern"}))
        for command, ending in [(('give','snack'),'ending_friend'),(('snack','bigfoot'),'ending_friend'),(('give','bigfoot'),'ending_friend'),(('tell','joke'),'ending_goofy'),(('go','forest'),'ending_quiet'),(('go','camp'),'ending_missed')]:
            with self.subTest(command=command):
                self.assertEqual(apply(story,state,command).scene,ending)
        camera = State(state.scene,state.inventory | {'camera'},state.flags)
        self.assertEqual(apply(story,camera,('camera','bigfoot')).scene,'ending_photo')
        self.assertEqual(apply(story,camera,('go','camp')), camera)
        self.assertIn("Without a CAMERA", story['scenes']['bigfoot_meeting']['hints'][-1])
        self.assertEqual(apply(story,camera,('look','camp')), camera)

    def test_search_detects_a_deliberately_stranded_path(self):
        story = deepcopy(self.stories['dragon_egg.json'])
        for rule in story['scenes']['hall']['commands']:
            if rule.get('next') == 'gate':
                rule.pop('effects', None)  # Arrive without the required key.
        self.assertGreater(audit(story)['dead_states'],0)

    def test_search_rejects_unmodeled_requirements(self):
        story = deepcopy(self.stories['dragon_egg.json'])
        story['scenes']['room']['commands'][0]['requirements']={'flags_false':['unknown']}
        with self.assertRaisesRegex(ValueError,'Unmodeled'):
            audit(story)

if __name__ == '__main__':
    unittest.main()
