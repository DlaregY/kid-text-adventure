# Safe Godot checks

Run from the project root with Python 3 and Godot 4.6.1:

```bash
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tests/run_checks.py --godot /path/to/Godot --suite all
```

`--suite smoke`, `regressions`, or `screenshots` selects a single suite. The default executable is `$GODOT_BIN`, otherwise `godot4`. Screenshots need a desktop display or Linux `xvfb-run` and OpenGL/Mesa. Logs and PNGs default to ignored `exports/qa/`; `--output` can select another output directory outside the tracked source directories.

## Player-data protection

The wrapper copies the project into a temporary staging directory, excluding `.git`, `.godot`, exports, existing overrides, and release/key artifacts. A staged `override.cfg` assigns a random custom Godot user-data directory **before startup**. The source project and its player data are not changed. Test scripts check that actual Godot settings and user directory match the wrapper's random identity before instantiating the game or manipulating saves. Cleanup requires that identity and a matching marker; a different path or symlink is refused.

**Do not use the older direct `godot --script res://tests/...` commands.** They now stop with an explanation rather than modify normal `user://` files. Use the wrapper, including in CI. The wrapper treats script/parse/resource errors as failures even when Godot exits with code zero. The only exceptions are the exact JSON diagnostics from the two intentional corrupt-save/progress recovery tests, matched to both their engine-reader and test-function backtraces and capped at the expected counts (one save, six card reads). The complete diagnostics remain in the log. A zero-failure summary is insufficient unless the focused safety suite also reaches its completion marker. Desktop checks use the Dummy audio driver; physical sound/speech testing is separate.

## Coverage and limits

The smoke suite renders all six stories / 59 scenes. The regression suite covers the existing engine behavior plus cancellation/confirmation of saved-run replacement, named resume, all ten ending-to-menu resets, blocked drop mutation, drag/long-press interaction, and idle-help recovery. Screenshot capture asserts that its failed-command example really executes a fallback and fails if an input tile is missing.

The GitHub workflow downloads the official desktop Godot 4.6.1 binary and checks its SHA-256 against the release asset digest. It runs tests and uploads only logs/desktop PNG captures. It does **not** export APKs or AABs, sign anything, release anything, or access Play Console.

Desktop captures are not phone/store screenshots and do not prove physical touch, Android Back integration, process-death resume, target-36 installation, or safe-area behavior. Gerald's phone pass remains required.

## Original sixth-story acceptance

The optional `original_story` suite is included by `--suite all`. It plays every
scene using current displayed words (Tess, tongs, Puff, gear, ice, workshop),
including the supervised repair gates and a legacy-token save. Python tests lock
all mechanical identifiers and verify final hints/fixtures. The screenshot suite
includes every rewritten scene plus scrolled controls where needed. Desktop
screenshots remain QA evidence, not Play assets or Android-device approval.

## Story polish acceptance (batch 2)

`tests/test_story_paths.py` is included by the Python unittest command above. It
walks the six story graphs with first-eligible-rule semantics, available tiles,
inventory, and true flags (false and missing flags are equivalent in this schema).
It checks all 59 scenes / ten endings and backward reachability from every state
to an ending. Unknown condition/effect types fail rather than being ignored.
This is a finite-state audit, not every possible repeated command sequence or a
physical gesture test. `python3 tests/story_paths.py` prints counts and shortest
witnesses; it never opens player data.

`tests/polish_stories.gd` also exercises the real tile routing/debounce for the
library hint (including both door aliases), GO BED / legacy OPEN BED, and repeated
Bigfoot chat after resuming a checkpoint with the older `said_hello` flag. TELL JOKE
is the deliberate goofy ending. The wrapper requires this suite's completion
marker as well as the earlier safety marker; a partial pass cannot hide an abort.
`tests/story_captures.gd` adds focused library, bed, and full-inventory Bigfoot
captures to the existing screenshot run. Full-inventory scenes scroll by design.
