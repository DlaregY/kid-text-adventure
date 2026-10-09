# Sixth story: Tess and the Cloud Machine

Date: 2026-10-09. Base main: `7ef951f3783df1426b1d9c0c30d7fe219adc9714`.
This is the separate original-content pass authorized by Gerald after choosing
to defer speech. It is not a release or a rights-clearance determination.

## Original direction

A paper pinwheel invites the player and Mom to Tess's ground-floor workshop.
Tess is a town mender in a yellow pencil-filled apron, not a masked superhero.
Puff is a small cloud trapped in a malfunctioning cloud machine, not an enemy.
With Tess's help, the player borrows a picture guide, collects tools, and reaches
a teapot-shaped weather tower. The climax is observation, stopping and locking
the machine with an adult, and one gentle mallet tap on a bent gear tooth. Puff
floats free and helps with the kite fair; Mom hears about the repair team.

All 218 authored rule responses, all 13 scene introductions, defaults and hints,
the teaser, cover, and ending presentation were reviewed/replaced. The former
spider identity, shooting/swinging webs, flaming rider/motorcycle, supernatural
chain, curse and combat resolution are absent from player-facing content. The
tools are long wooden tongs, an ice pad, and a small mallet; new symbols match
their current roles. No imported character art, third-party story text, or new
font/audio assets were added. The text was composed for this project with AI
assistance. Original composition reduces the previously identified resemblance;
it is not a trademark search, legal opinion, or promise of store acceptance.

## Compatibility rather than destructive migration

`stories/spider_hero.json` and its legacy internal tokens are deliberately retained.
They are identifiers, not player-facing names. `spiderdude` displays Tess, `web`
displays tongs, `ghost` displays Puff, `chain` displays gear, `potion` displays ice,
`hammer` displays mallet, `bike` displays cart, and `rooftop` displays workshop.
Optional `vocab.icon` overrides the global symbol for this story; other stories
keep their existing icons. Invalid icon types safely fall back.

All 13 scene IDs, 218 rule patterns, ordering, requirements, effects, inventory
and flag keys, and the `win` ending ID remain unchanged. The story's editorial
`meta.version` advances to 4, but the save format and app release version do not.
An older in-progress save resumes in the new narrative with the equivalent
objects; collected endings continue to count. There is no silent restart or
loss of progress. The mechanical projection is locked by SHA-256
`28318041e09b2b5982644f38dfa33314b113cc8f18a02fb655fe68a3a604739d`.

## Verification

`test_original_story.py` checks mechanical equivalence, absence of retired
player-facing identities/equipment, original labels/icons, and every direct
final hint from a normally reachable checkpoint. The six-story finite-state
audit still covers 4,499 states (54 for story six), all 59 scenes and ten endings,
with no reachable state lacking a path to an ending.

`tests/original_story.gd`, run through the isolated wrapper, walks the entire
story via displayed tile labels and real debounce/Next transitions. It also
checks both repair prerequisites, a legacy checkpoint, retained ending IDs and
icon fallback. `tests/original_captures.gd` renders all 13 scene fixtures, adding
scrolled views when controls do not fit. Python checks those fixtures against
reachable states rather than inventing their inventory/flags.

Use `python3 -m unittest discover -s tests -p 'test_*.py' -v` and
`python3 tests/run_checks.py --godot /path/to/Godot --suite all`.
The PR records verified commit-specific CI and screenshot results. These are
desktop tests, not a substitute for Gerald's phone pass or final content rating.

## Release boundaries

Other five stories, Gerald's Bigfoot/save-dialog revisions, package ID, Android
permissions/export settings and release metadata are untouched. Speech removal
is a separate PR; merge that first, then this one. No APK/AAB build, signing,
Play Console edit, website publication, main merge or live Hub #1511 update was
performed. Final declarations and store screenshots must describe the combined
speech-free, rewritten build, not the retired story or older recordings.
