# Polish batch 2 — executable hints and deliberate endings

Date: 2026-10-08. Base: merged PR #13, `82edf7655c4908b86fc2f758e829c2b65e6fe8e9`.
Gerald's `f22b320` safe-button styling adjustment is preserved unchanged in
`ui/NewStoryDialog.tscn`: green hover/press for KEEP MY SAVE, smaller START NEW.

## Changes

| Review item | Implementation |
|---|---|
| M05 — library help | Both the intermediate and final hints include OPEN BOOK. The final hint executes LOOK SHELF → TAKE BOOK → OPEN BOOK → OPEN DOOR with normal incoming inventory. KEY DOOR remains an equivalent exit after reading. No requirements are removed. |
| M05 — Phone Trap | GO BED reaches the existing `home` ending; OPEN BED remains a forgiving alias. The landing exposes GO, the vocabulary supplies Bed, the engine supplies the bed symbol, and the hint matches GO BED. |
| M06 — Bigfoot choice | Repeated LOOK/TALK BIGFOOT stays in the meeting, including a resumed older checkpoint with `said_hello=true`. TELL JOKE is the explicit goofy goodbye; LOOK JOKE explains that it finishes the visit without choosing it. The scene and hints distinguish staying from finish actions. Camera advice distinguishes carrying/not carrying it. |
| M06 / small editorial cleanup | Camp's final hint puts gear collection before leaving. The goofy epilogue keeps Bigfoot present during its optional conversations. The quiet ending now concerns respecting his home, not a general lesson about keeping friends secret. |
| M07 — evidence | New real-engine tile/debounce tests, full-state story audit, negative controls for the audit, and targeted desktop captures. The test wrapper requires the new suite's completion marker. |

## Compatibility and scope

All six stories, 59 scene IDs, ten ending IDs and existing inventory/flag tokens
are preserved. `tell` and `joke` are additive vocabulary; `bed` already existed as a story token.
No save version or release version change is required by these compatible edits.
Existing collected endings still count. The gameplay engine changes are limited
to TELL action routing/fallbacks and the new vocabulary symbols. Save-replacement
behavior and Gerald's dialog styling are unchanged.

No Android export, signing, release, Play Console edit, policy publication, main
merge, or live Hub update is part of this batch. Speech configuration, privacy
policy and production package identity are unchanged. Spiderdude/Skull Rider
originalization/rights and speech/privacy remain separate unresolved decisions.

## Verification

Reproduce with the safe wrapper documented in `testing.md`:

```bash
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tests/story_paths.py
python3 tests/run_checks.py --godot /path/to/Godot --suite all
```

The Python audit models available tiles, first eligible rules, inventory and
positive flags, and reverse reachability from terminal states. It covers 4,499
reachable states: Bigfoot 4,392; Crystal 12; Dragon 16; Phone 13; Shake 12; Spider
54. All 59 scenes and ten endings are reachable; zero reachable states lack an
ending path. Repeated identical states are deduplicated; this is not a physical
playtest or enumeration of infinitely many repeated commands.

The final TELL JOKE code passed [branch validation run 37857221326](https://github.com/DlaregY/kid-text-adventure/actions/runs/37857221326):
17 Python tests, 324 Godot regression assertions, six stories / 59 scene renders,
and 23 desktop screenshot checks, all with zero test failures. The downloaded
artifact's SHA-256 was verified and all 23 captures were visually inspected.
The library hint and bed controls are readable; full-inventory Bigfoot scenes
scroll, with the joke tile accessible. These are 540×960 desktop captures, not
Android store screenshots or a full visual audit of every reachable state.
The PR's checks remain the authoritative result for its final commit.

Direct GitHub cloning still fails on DNS in the implementation runtime. A
branch-only GitHub Actions checkout supplied a checksum-verified source archive
and official desktop Godot 4.6.1 binary for local work. Local headless regression
checks passed; local desktop captures exposed a missing Linux speech library.
The successful branch run used CI's speech dependencies; no such errors were
waived. Temporary transport files/workflow are excluded from the review commit.
Only source, tests, and documentation changes belong in the final PR diff.

Remaining device checks are Gerald's: actual taps/drags, both bed phrases,
repeatable chat after force-stop/resume, joke choice and other endings, readable
scrolling, and Android Back/safe areas. Desktop capture success is not Android
release approval and does not close the larger store/signing/testing gates.
