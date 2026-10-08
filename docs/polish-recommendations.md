# Ike Quest Polish Recommendations (pre-Play review, 2026-10-08)

Review of `scripts/Game.gd`, `Game.tscn`, `ui/Tile.tscn`, all six `stories/*.json`,
`export_presets.cfg`, `project.godot` and the planning docs. Grouped by priority.
Items marked **(verify on device)** are deduced from code, not observed on a phone.

## A. Fix before submitting to Play

1. **Android Back button quits the app.** Nothing handles
   `NOTIFICATION_WM_GO_BACK_REQUEST`, and Godot's default `quit_on_go_back` is on,
   so one accidental Back press kills the story. Set
   `application/config/quit_on_go_back=false` and route Back to "return to menu"
   with a confirm, or ignore it mid-story.
2. **No way out of a story except finishing it.** NewGameButton only appears on
   terminal scenes. A kid who picks the wrong story, or a parent who wants to stop,
   has no menu button. Add a small persistent ⌂ / "Menu" button (hold-to-confirm or a
   simple "Stop playing?" dialog so toddler taps don't nuke progress).
3. **Progress is lost on process death.** Persist `current_scene_id`, `inventory`,
   `flags` and the story path to `user://save.json` after every state change, and
   show a "CONTINUE" button on the menu when a save exists. Android kills background
   apps aggressively; this will be the #1 complaint otherwise.
4. **Bigfoot: the meeting scene ends the story on the two "safe" verbs.** In
   `bigfoot_meeting`, `look bigfoot` and `talk bigfoot` are instant endings. Every
   other scene in every story trains kids to LOOK first, so the most natural first
   tap ends the game. This is the root cause of "the friend ending arrives too fast".
5. **Bigfoot: `snack` + `bigfoot` has no rule.** Tapping the gold snack tile first
   routes it to Slot 1; tapping Bigfoot gives `["snack","bigfoot"]`, which falls to
   the generic "You wave the snack at the bigfoot. Nothing happens!" Add that pattern
   (and treat it the same as `give snack`). The hint text also says GIVE SNACK, but
   tapping `give` then `snack` requires the kid to know the target is implied.
6. **Bigfoot: the snack is optional and never hinted at camp.** Camp hints only say
   LOOK BUSHES / GO FOREST, so a kid following hints leaves without the snack and
   the best ending becomes unreachable with no way back.
7. **Spiderdude `win` scene has a single tile (`look`) and nothing to pair it
   with** unless inventory is carried. Add 2–3 things (`city`, `spiderdude`, `home`).
8. **Export preset produces an APK (`gradle_build/export_format=0`).** Play requires
   an AAB; set format to 1 for the production preset and keep APK for sideload
   previews. Also the preset is named "Ike's Adventures" while the app is "Ike Quest".
9. **Stray `Game.tscn4721128948.tmp` is tracked in git.** Delete it and add
   `*.tmp` to `.gitignore`.
10. **Content/IP risk: Spiderdude + Skull Rider.** Google's impersonation policy
    looks at names *and* likeness. Already flagged in PROJECT_PLAN; decide before
    submission (rename to something original, e.g. "Webster and the Ember Chain").
11. **Privacy policy draft is stale** (names Norbonics Industries, old contact). Needs
    a public URL; consider an in-app "About" screen that shows the same text.
12. **Feedback text overflow (verify on device).** `_auto_fit_story_text()` only runs
    at render time and only shrinks StoryText. A long response (Byte's intro in Phone
    Trap is ~190 chars at 22px ≈ 6 lines) pushes the tile trays below the fold
    mid-command, and the HINT button lives at the very bottom of the scroll, so the
    kid who needs it most may never see it. Options: cap response length in the QA
    checklist (~120 chars), auto-fit feedback too, or move HINT next to the slots.

## B. Jank / feel improvements in the engine

13. **No undo for a mis-tap.** Both slots fill, 0.5 s later it fires. Let a tap on a
    filled slot clear it, and show a small shrinking bar or ring on the command bar
    during the 0.5 s so the auto-fire is legible rather than surprising.
14. **Success and failure look identical.** Same label, same color. Tint the feedback
    green/bold when a rule matched, gray when it was a fallback, and shake the
    command bar on a fallback. Kids currently can't tell "that worked" from "nope".
15. **Full tile rebuild on every state change flickers.** `_render_scene()` frees and
    recreates every tile after `take snack`; only add/remove the tiles that changed.
16. **Reserved story height is one-size-fits-all.** `custom_minimum_size.y = font*5`
    leaves 160 px of air under Bigfoot's two-line scenes while Phone Trap's 16-line
    `home` scene shrinks to 18 px, which is too small for early readers. Normalize
    scene text to 3–5 short lines (see story section) and drop the min height to
    `font*3`.
17. **Hint threshold.** Six failed commands is a lot for a five-year-old. Try four,
    and additionally surface the hint after ~45 s of no progress.
18. **Dropdown story picker is the least kid-friendly control in the app.** Replace
    the OptionButton with big tappable cards: cover emoji, title, teaser, and a
    length badge ("Short / Medium / Long" or ⭐⭐⭐) instead of "(8 scenes)". Sort by
    a `meta.order` or difficulty, not scene count.
19. **Use the `vocab` labels.** They exist in every file and would fix "bigfoot" →
    "Bigfoot", "spiderdude" → "Spiderdude", and allow two-word labels later.
20. **Emoji choices to revisit:** `open` = 📖 (reads as "book"), `gate` = 🏰,
    `bigfoot` = 🦶. Consider ✋➡️ / 🔓 for open, 🚧 for gate, and 🦧 or a bundled SVG
    for Bigfoot. Bundling a small SVG icon set (Twemoji is CC-BY) would also remove
    the dependence on the phone's emoji font.
21. **Tile tap feedback.** A 0.1 s scale-bounce on tap, a "pop" when it lands in the
    slot, and a brief glow on the slot. Pure tween work, no assets.
22. **Typewriter reveal for story text** (and a tap to finish instantly). Cheap and
    makes each scene feel like an event.
23. **Transition is a flat fade to black.** Add a per-scene `mood` color in JSON
    (night blue for camp, red for the boss room) used as a subtle background tint;
    it gives the illusion of scene art for zero art budget.

## C. Bigger features that raise the app's quality bar

24. **Read-aloud with on-device TTS.** `DisplayServer.tts_speak()` works on Android
    with no network and no permissions. A 🔊 button on the story text, feedback, and
    long-press on a tile to hear the word is the single biggest win for the target
    audience and keeps the app Families-policy clean.
25. **Ending collection / sticker book.** Persist which endings each story has
    reached. Show "⭐ 2 of 4 endings found" on the story card and a badge on the
    terminal scene. This turns Bigfoot's short branches into a feature (replay) and
    solves Gerald's complaint about the ending title: render it as a small gold
    badge above the text instead of shouting it as line one. Requires an `ending`
    field on terminal scenes (`{"id": "friend", "title": "Bigfoot Friend"}`).
26. **Sound.** Six tiny OGGs: tile tap, slot land, success chime, fallback bonk, scene
    whoosh, ending fanfare. Plus a mute toggle on the menu (persisted).
27. **Early-reader typography.** Bundle an OFL font designed for beginning readers
    (Andika or Lexend) with 1.3× line spacing. Godot's default font has a two-story
    "a" and tight leading.
28. **Scene art, cheaply.** The JSON `image` field is already parsed. Even a large
    emoji "scene banner" per scene (⛺🌙🌲) rendered at 64 px above the text gives
    visual rhythm until real art exists.
29. **Parent corner / About screen** reachable from the menu: version, privacy
    policy text, "no ads, no accounts, no internet", and the Games URL. Play
    reviewers like to find this.
30. **Idle nudge.** After ~20 s with no tap, gently pulse one relevant tile. Keeps
    very young players moving without spoiling the puzzle.

## D. Story content

### Bigfoot Campout (too short, flattest text)

Shape of the problem: four real scenes of two short lines each, a three-command
critical path, then a meeting scene where four of seven commands are instant
endings. Other stories average 5–9 lines per scene with NPC dialogue and an
inventory chain. Suggested rebuild (10–12 scenes, 3–4 beats each):

- **camp**: Dad is mentioned but has no tile. Add `dad` (talk dad → he hands you the
  lantern and says to pack a snack), `fire`, `lantern`, `marshmallow`. Make `take
  lantern` required to enter the dark forest (first inventory gate), and have Dad
  push the snack so it's never skipped.
- **forest_edge**: keep the tracks beat, add the fur-on-the-tree clue as a flag that
  unlocks the next hint.
- **hollow_log / creek crossing**: a mini-puzzle (rope? stepping stones you must
  LOOK at first) so there's a second gate before the reveal.
- **berry_patch**: Bigfoot is first glimpsed eating berries; `talk` and `look` here
  are safe and build the relationship (he flinches, then relaxes).
- **bigfoot_meeting** (rewritten): LOOK and TALK must be safe. Endings come only
  from deliberate verbs: `give snack` / `snack bigfoot` (friend), `go camp`
  (missed), `take photo` if you add a `camera` (a new "proof" ending), and a quiet
  `wave`/`bye` choice for the secret ending.
- Give each ending a short **second scene** ("next morning at camp") so endings feel
  earned rather than abrupt, and tag them with the `ending` field for the sticker
  book.
- Voice: Bigfoot reads calm and literary; the other five stories are loud and
  exclamatory. Pick one house voice. The others' voice tests better with kids, but
  trim their CAPS a little rather than flattening Bigfoot entirely.

### Other stories

- **Phone Trap** `home`: 16 lines forces the 18 px fallback. Split into two scenes
  (land on bed → morning).
- **Spiderdude** `win`: add things to pair with `look` (see A7). Also decide the IP
  question (A10).
- **Shake Escape** `home`: no hints array (fine for a terminal scene, but the other
  stories' endings have them for consistency).
- All stories: adopt a response-length budget (~120 chars) in
  `docs/story-qa-checklist.md`, and a scene text budget (3–6 lines).

## Suggested order

1. A1–A3 (Back button, menu button, save/resume) — these are the "janky app" feel.
2. A4–A6 Bigfoot meeting fixes, then the Bigfoot rebuild (D).
3. B13–B14 (slot clear, success/fail feedback) and B18 (story cards).
4. C24 TTS and C25 ending collection — the two features that make the store listing
   stand out.
5. A8–A11 release hygiene right before upload.
