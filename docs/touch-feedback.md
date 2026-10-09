# Phone feedback: scrolling, command roles and Ike branding

October 9, 2026. Based on merged main `ad758b0` (PR #17).

## Device observation

Gerald installed candidate `r37957662835a1` and reached both the story picker and
story pages. This establishes user-reported target-36 installation and launch,
not exhaustive Android acceptance. He reported that swipes over much of the
picker/story content did not scroll; inaccessible controls stranded a story run.
He also found unrestricted action/thing drops confusing. This blocks release.
The model/OS of this pass was not newly reconfirmed, so the older device record
is not silently promoted into a new measurement.

## Corrections

- Let input pass up through story cards, text, word buttons and command slots to
  Godot's native ScrollContainer. Do not loosen the modal input shields.
- Use a 12-logical-pixel scroll threshold. Immediate touch movement scrolls;
  only a stationary 350 ms hold followed by movement may drag a word. Pausing
  an already-started swipe cannot convert it into a late drag. Ordinary taps
  still select; physical mouse dragging remains immediate.
- A slot clears on a genuine release-to-tap, not on finger-down. A scrolling,
  canceled or drag gesture cannot clear it. Native scrolling cancels a card or
  button click and pauses pending command execution; scroll end gives already
  selected commands a fresh full delay.
- Derive slot roles from current scene/inventory, not the supplied drag category.
  First slot: action or collected item. Second: target/collected item, never an
  action. Unknown/stale tokens are refused, rejected drops leave slots intact,
  and displayed text comes from the current story vocabulary. Inventory-first
  puzzles such as CAMERA BIGFOOT, KEY DOOR and MALLET GEAR remain available.
  Ordinary valid action/target experiments can still produce silly responses.
- Restore the original portrait on the menu and launcher; retain the Norbonics
  in-engine splash. See `ike-branding.md`. No new portrait was generated.

All six story JSON files, scene/ending/save identifiers and production package
identity remain unchanged. This is a repair of input and presentation, not new
story content, speech restoration, a Play upload, or a public release.

## Evidence and limits

The pre-fix source reproduced three failures with viewport-routed, touch-derived
mouse events: swipe over a card, over story text, and over a word button. The
same initial checks pass after fixing propagation and touch/drag priority.

`tests/touch_input.gd` extends this with actual ScreenTouch/ScreenDrag input,
repeated card swipes to both ends, real taps and held drags, slot-swiping, invalid
roles/spoofed payloads and a valid item-first ending. It runs under a real desktop
display/Xvfb with touch emulation, not by emitting Button signals or directly
assigning scroll offsets as the act being tested. Fixtures may be positioned
before a gesture. A per-suite timeout fails an incomplete run.

The Python state search now applies the same slot-role constraints. All 59
scenes and ten endings must remain reachable with no dead states. The two old
LOOK LOOK joke responses in story six are no longer reachable via valid slots;
neither is a progression gate and story JSONs are not changed to remove them.

Final commit-specific test, screenshot and APK evidence is recorded in the PR.
None of the desktop gesture tests proves Android hardware behavior. Gerald
should retest the new, separately labeled candidate: scroll starting on cards,
text and tiles, reach lower controls, tap to choose, hold to drag, reject swapped
roles, and verify both the restored portrait and retained loading logo. Keep
existing installations and their separate progress intact.
