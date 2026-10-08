# Ike Quest Polish Plan (pre-Play)

Source of the items: `docs/polish-recommendations.md` (numbers in brackets refer to it).
Work happens on branch `claude/awesome-mendel-fwz978`, one commit per phase.
Every phase ends with the verification block run green:

```
godot4 --headless --path . --editor --import
godot4 --headless --path . --script res://tests/story_smoke.gd
godot4 --headless --path . --script res://tests/game_regressions.gd
```

Real-phone checks are listed per phase and are Gerald's to run; the headless suite
cannot see touch, safe areas, or TTS.

## Phase 1 — Stop the app feeling fragile [A1, A2, A3, A9]
- [x] `quit_on_go_back=false`; Android Back opens the Stop dialog in a story, quits on the menu.
- [x] Persistent ⌂ button during a story opens the same Stop dialog (KEEP PLAYING / GO TO MENU).
- [x] Save `user://save.json` (story path, scene, inventory, flags) after every state change and transition; clear it on terminal scenes.
- [x] Menu shows CONTINUE when a save exists and preselects that story; PLAY always starts fresh.
- [x] Remove tracked `Game.tscn4721128948.tmp`; ignore `*.tmp`.
- [x] Tests: save/resume round-trip, terminal clears save, Back → dialog → keep/menu, ⌂ hidden on menu, stale transition cancelled (61 checks green).
- [ ] Phone: Back mid-story shows dialog; force-stop then relaunch shows CONTINUE and lands on the same scene.

## Phase 2 — Bigfoot meeting fixes (quick wins before the rebuild) [A4, A5, A6]
- [x] `look bigfoot` / `talk bigfoot` become safe, non-ending responses (goofy ending needs a second TALK after an explicit prompt; quiet ending moved to GO FOREST).
- [x] Add `["snack","bigfoot"]` and `["give","bigfoot"]` (with snack) rules mirroring `give snack`.
- [x] Camp text, hints, and a Dad nag gate leaving camp on packing the snack so the friend ending is always reachable.
- [x] Spiderdude `win` scene gets talk/go and spiderdude/city/home tiles [A7].
- [x] Tests: smoke renders 55 scenes; regression covers safe LOOK/TALK, snack→Bigfoot tap routing, all four endings, and the camp gate.

## Phase 3 — Command bar feel [B13, B14, B15, B21]
- [x] Tap a filled slot to clear it.
- [x] Visible countdown bar on the command bar during the 0.5 s delay.
- [x] Feedback label tinted/animated differently for matched rules vs fallbacks; shake on fallback.
- [x] Incremental tile updates instead of a full rebuild on state change (story text/font no longer reset on progress).
- [x] Tile tap bounce tween.
- [x] Tests: slot clear cancels timer; timer bar visibility; progress vs fallback feedback color; unchanged trays keep nodes (110 checks).
- [ ] Phone: slot tap-to-clear works with touch; bar/pop/shake feel right; no flicker on TAKE SNACK.

## Phase 4 — Menu as story cards [B18, B19, B20, C29]
- [ ] Replace OptionButton with a scrollable list of cards (cover emoji, title, teaser, length badge).
- [ ] Use `vocab` labels for tile text; add `meta.cover` and `meta.order` to story JSON.
- [ ] Parent corner / About screen (version, privacy text, no-ads statement, Games URL).
- [ ] Tests: cards fit 540 px; selecting a card updates the selected path; labels render.

## Phase 5 — Endings collection and ending presentation [C25]
- [ ] `ending` field on terminal scenes (`{"id","title"}`); render title as a small gold badge, not line one.
- [ ] Persist found endings per story in `user://progress.json`; show "N of M endings" on cards and at the ending.
- [ ] Tests: reaching an ending records it; menu counts match.

## Phase 6 — Read-aloud and sound [C24, C26]
- [ ] 🔊 button reads story text; tap feedback reads it; long-press a tile reads the word (DisplayServer TTS).
- [ ] Six short OGG effects + mute toggle persisted in settings.
- [ ] Phone: TTS voice available on Gerald's moto g; mute persists across launches.

## Phase 7 — Text and typography [B16, B17, B22, B23, C27]
- [ ] Early-reader font bundled with looser line spacing; story min height reduced.
- [ ] Typewriter reveal with tap-to-finish; per-scene `mood` tint.
- [ ] Hint threshold to 4 and idle timer.
- [ ] Feedback length budget documented in `docs/story-qa-checklist.md`.

## Phase 8 — Bigfoot rebuild and story pass [D]
- [ ] Rebuild Bigfoot to 10–12 scenes per the sketch in the recommendations doc.
- [ ] Split Phone Trap `home` into two scenes; add hints to Shake Escape `home`.
- [ ] Decide Spiderdude naming [A10].
- [ ] Run `docs/story-qa-checklist.md` on every touched story.

## Phase 9 — Release hygiene [A8, A11, A12]
- [ ] Production preset exports AAB; preset renamed to match the app.
- [ ] Privacy policy reconciled and published; About screen shows the same text.
- [ ] Bump `version.txt`, `version/name`, `version/code`.
- [ ] Update CLAUDE.md, README and `docs/creating-stories.md` for new JSON fields and UI.
