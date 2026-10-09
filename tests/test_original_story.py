"""Original presentation and backward-compatible rule identities for story six."""
import hashlib
import json
from pathlib import Path
import re
import unittest
from story_paths import State, apply, audit

ROOT=Path(__file__).resolve().parents[1]
STORY=ROOT/'stories/spider_hero.json'

# SHA-256 of the mechanical projection of the merged pre-rewrite story.
# Excludes prose/labels/icons/moods/title/version, not any rule, item or flag.
MECHANICS_SHA='28318041e09b2b5982644f38dfa33314b113cc8f18a02fb655fe68a3a604739d'

def mechanics(story):
    return {'start_scene':story['start_scene'], 'scenes':{
        sid:{'tiles':sc['tiles'], 'commands':[{k:v for k,v in c.items() if k!='response'} for c in sc['commands']],
             'ending_id':sc.get('ending',{}).get('id')}
        for sid,sc in story['scenes'].items()}}

def player_text(story):
    chunks=[story['meta']['title'],story['meta']['teaser'],story['meta']['cover']]
    chunks += [entry['label'] for entry in story['vocab'].values()]
    for sc in story['scenes'].values():
        chunks += sc['text']+sc['default']+sc.get('hints',[])
        chunks += [c['response'] for c in sc['commands']]
        chunks.append(sc.get('ending',{}).get('title',''))
    return '\n'.join(chunks)

class OriginalStoryTests(unittest.TestCase):
    def setUp(self): self.story=json.loads(STORY.read_text(encoding='utf-8'))

    def test_mechanics_and_saved_identifiers_are_unchanged(self):
        encoded=json.dumps(mechanics(self.story),sort_keys=True,separators=(',',':')).encode()
        self.assertEqual(hashlib.sha256(encoded).hexdigest(),MECHANICS_SHA)
        self.assertEqual(self.story['meta']['order'],6)

    def test_public_text_has_no_retired_characters_or_signature_equipment(self):
        text=player_text(self.story)
        self.assertNotRegex(text.lower(),r'spider|skull|thwip|web|motorcycle|curse|superhero|fire chain|ghost')
        self.assertEqual(self.story['meta']['title'],'Tess and the Cloud Machine')
        self.assertIn('Puff',text)
        self.assertNotIn('🕷',text)
        self.assertEqual(self.story['scenes']['win']['ending']['id'],'win')

    def test_every_displayed_hint_can_be_resolved_to_available_tokens(self):
        # Validate all direct uppercase pairs, including renamed legacy tokens.
        labels={entry['label'].upper():key for key,entry in self.story['vocab'].items()}
        results=audit(self.story)
        for sid,sc in self.story['scenes'].items():
            if not sc.get('hints'): continue
            state=State(self.story['start_scene'])
            for cmd in results['witnesses'][sid]: state=apply(self.story,state,cmd)
            pairs=re.findall(r'\b([A-Z]+) ([A-Z]+)\b',sc['hints'][-1])
            self.assertTrue(pairs,sid)
            for a,b in pairs:
                self.assertIn(a,labels,sid); self.assertIn(b,labels,sid)
                state=apply(self.story,state,(labels[a],labels[b]))
            self.assertNotEqual(state.scene,sid,sid)

    def test_render_fixtures_are_normal_reachable_checkpoints(self):
        fixtures=json.loads((ROOT/'tests/original_states.json').read_text())
        witnesses=audit(self.story)['witnesses']
        self.assertEqual(set(fixtures),set(self.story['scenes']))
        for sid,path in witnesses.items():
            state=State(self.story['start_scene'])
            for command in path: state=apply(self.story,state,command)
            f=fixtures[sid]
            self.assertEqual(state,State(f['scene'],frozenset(f['inventory']),frozenset(f['flags'])))

    def test_repair_requires_both_observation_and_adult_stop(self):
        for flags in [set(),{'saw_weakness'},{'spidey_ready'}]:
            state=State('battle',frozenset({'hammer','web','book'}),frozenset(flags))
            self.assertEqual(apply(self.story,state,('hammer','chain')),state)
        state=State('battle',frozenset({'hammer','web','book'}),frozenset({'saw_weakness','spidey_ready'}))
        done=apply(self.story,state,('hammer','chain'))
        self.assertEqual(done.scene,'victory')
        self.assertNotIn('hammer',done.inventory)

    def test_renamed_characters_and_objects_have_original_icons(self):
        expected={'spiderdude':('Tess','👩‍🔧'),'web':('tongs','🗜️'),'ghost':('Puff','☁️'),
                  'chain':('gear','⚙️'),'fire':('fluff','☁️'),'bike':('cart','🛒')}
        for token,(label,icon) in expected.items():
            self.assertEqual(self.story['vocab'][token],{'label':label,'icon':icon})
        self.assertEqual(audit(self.story)['states'],54)

if __name__=='__main__':unittest.main()
