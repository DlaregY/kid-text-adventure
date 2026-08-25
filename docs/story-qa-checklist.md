# Story QA Checklist

Use this checklist before merging or releasing any story in `stories/*.json`.
It is intended for mission authors, reviewers, and coding agents. For details on
the story format, see [Creating Stories](creating-stories.md).

## How to Use This Checklist

1. Complete the automated and structural checks first.
2. Make a list of every intended route and ending.
3. Play every route from a fresh game, recording the commands used.
4. Test state changes, repeated actions, likely mistakes, and optional choices.
5. Do not mark the story ready while any required item below is unchecked.

## 1. File and Schema

- [ ] The file is valid JSON and has a unique lowercase `snake_case.json` name.
- [ ] Top-level `meta`, `start_scene`, and `scenes` fields are present.
- [ ] `meta.title`, `meta.version`, and `meta.teaser` are present and accurate.
- [ ] `start_scene` is a non-empty ID that exists in `scenes`.
- [ ] Every scene has `text`, `tiles`, `commands`, and `default` arrays.
- [ ] Every optional `hints` value is an array.
- [ ] Every command has a two-string `pattern` and a string `response`.
- [ ] Required strings are non-empty; arrays contain values of the expected type,
      and every `flags_set` value is boolean.
- [ ] Continuing scenes have at least one command, and player-facing `text` and
      `default` arrays are not empty.
- [ ] Every `next` value is a non-empty ID for an existing scene.
- [ ] Every `requirements` value uses only supported fields: `inventory_has` and
      `flags_true`.
- [ ] Every `effects` value uses only supported fields: `inventory_add`,
      `inventory_remove`, and `flags_set`.
- [ ] Tokens, scene IDs, item names, and flag names use consistent spelling and
      capitalization. Command matching is case-sensitive; tokens should be
      lowercase.
- [ ] The story appears in the game picker with the expected title, scene count,
      and teaser.
- [ ] The story starts without validation errors in Godot's output.

## 2. Scene Graph and Endings

- [ ] Every scene is reachable from `start_scene`, or is intentionally retained
      and documented as unused.
- [ ] Every intended branch can be reached through commands available to the
      player at that point.
- [ ] Every transition rule has been exercised, including multiple commands that
      lead to the same destination scene.
- [ ] No transition creates an unintended loop or traps the player in a scene.
- [ ] A scene that should continue has at least one reachable command with
      `next`.
- [ ] A terminal scene has no command with `next`; this is what makes the engine
      show the NEW GAME button.
- [ ] Every intended ending has its own terminal scene and clearly tells the
      player that the story has ended.
- [ ] Every ending has been reached in a fresh playthrough, not only by editing
      `start_scene` during testing.
- [ ] Optional branches eventually rejoin or end intentionally; none simply stop
      because a transition was forgotten.

For a story with multiple endings, record the tested paths:

| Path | Key commands or choices | Expected ending | Result |
| --- | --- | --- | --- |
| Main route | | | [ ] Pass |
| Alternate route | | | [ ] Pass |
| Additional ending | | | [ ] Pass |

Add rows until every ending and materially different route is covered.

## 3. Tiles and Command Reachability

- [ ] Every action token is one of the built-in actions: `go`, `open`, `take`,
      `look`, `talk`, `give`, or `climb`.
- [ ] Both tokens needed for every command are available in that scene, either
      through `tiles` or the player's inventory.
- [ ] A required inventory item can actually be acquired before the command that
      requires it.
- [ ] An item is not consumed before the last route that needs it.
- [ ] Inventory-as-action commands use the item first, such as `key gate` or
      `rope bridge`, and have an `inventory_has` requirement.
- [ ] Inventory items still work when automatically added to a scene's Inventory
      tray even if they are absent from that scene's `tiles` array.
- [ ] Obvious commands suggested by the scene text have specific responses.
- [ ] Important nouns mentioned in the scene text have tiles when the player is
      expected to interact with them.
- [ ] A regular Thing tile represents something present or intentionally
      referenceable. If a state change removes it while the scene remains active,
      relevant commands acknowledge that it is gone. Inventory-only items are
      omitted from `tiles` because carried items appear automatically in the
      Inventory tray.
- [ ] New tokens either have an appropriate emoji mapping in `scripts/Game.gd`
      or have been intentionally accepted without an icon.
- [ ] No tile is present without at least one sensible use or response, unless it
      is intentionally included as a harmless distraction.

## 4. Rule Order and Requirements

Commands are evaluated from top to bottom. The first matching pattern whose
requirements pass wins.

- [ ] Rules sharing the same pattern are ordered from most specific to least
      specific.
- [ ] A guarded rule is never placed below an unguarded rule with the same
      pattern; the unguarded rule would make it unreachable.
- [ ] When a requirement fails, a later rule handles the same command with a
      useful explanation whenever the player is likely to try it.
- [ ] Every flag in `flags_true` is set to `true` on at least one reachable path.
- [ ] Every flag written by `flags_set` is read by a reachable rule later, or its
      intentional future purpose is documented.
- [ ] Every required inventory item is added on at least one reachable path.
- [ ] Requirements do not assume support for negative conditions. The engine can
      require only items that are present and flags that are true.
- [ ] Commands with both `effects` and `next` leave state correct for the next
      scene.
- [ ] Duplicate command patterns are intentional and differ by requirements or
      outcome.

## 5. State-Aware Behavior

- [ ] Every action that changes the world sets a flag or changes inventory when
      later behavior depends on that change.
- [ ] Repeating a state-changing command gives a state-aware response instead of
      repeating the reward or event.
- [ ] An item cannot be collected repeatedly. If the player remains in the same
      scene, put an already-collected flag rule before the collection rule.
- [ ] An opened, moved, repaired, defeated, or completed object is described as
      such on later attempts.
- [ ] A spent or given item is removed with `inventory_remove`.
- [ ] A reusable item remains in inventory intentionally.
- [ ] Every carried item has a useful `look <item>` response in scenes where the
      player may reasonably inspect it.
- [ ] Obvious item-target combinations have contextual responses, even when they
      do not solve the puzzle.
- [ ] Optional items are handled both when present and when absent.
- [ ] Branch-specific flags do not accidentally unlock content on another branch.
- [ ] Starting a new game clears all inventory and flags; no state leaks from the
      previous playthrough.

For every state-changing command, test this sequence:

- [ ] Try it before its prerequisites are met.
- [ ] Perform it when its prerequisites are met.
- [ ] Try it again immediately.
- [ ] Inspect the affected object or item afterward.
- [ ] Continue to the next scene and confirm inventory and flags have the expected
      effect.

## 6. Puzzle Fairness and Recovery

- [ ] The scene text gives enough information to begin without guessing blindly.
- [ ] Required actions can be inferred from the available words and responses.
- [ ] Failed prerequisite responses point toward the missing step without giving
      false information.
- [ ] The player cannot permanently lose a required item and become unable to
      finish the story.
- [ ] Optional choices do not accidentally block all endings.
- [ ] A player who skips optional inspection commands can still progress unless
      looking first is an intentional puzzle.
- [ ] If looking first is required, the response clearly explains why progression
      is blocked.
- [ ] All three progressive hints are present for puzzle scenes: gentle, specific,
      and direct.
- [ ] The final hint names the exact two-token command needed to progress.
- [ ] Hints remain correct in every state in which they can appear.

## 7. Responses and Early-Reader UX

- [ ] Scene text uses short sentences, familiar words, and manageable line lengths.
- [ ] Each scene clearly establishes where the player is, what changed, and what
      deserves attention.
- [ ] Command responses are concise enough to read before the next action.
- [ ] Success responses clearly describe the result before a transition.
- [ ] Failure responses are encouraging, specific, and never blame the player.
- [ ] `default` contains several varied, story-appropriate responses rather than
      one repetitive message.
- [ ] Character names, pronouns, tense, and point of view stay consistent.
- [ ] Spelling, punctuation, and grammar have been reviewed.
- [ ] Humor and suspense are age-appropriate; frightening outcomes are gentle.
- [ ] Safety review distinguishes fantasy adventure from realistic risk. Normal
      cartoon, movie, and video-game action such as climbing, chases, caves,
      monsters, and magical danger is acceptable. Flag realistic, readily
      imitated behavior likely to cause serious harm, especially when the story
      gives actionable detail or presents it as safe without context or
      consequences.
- [ ] Endings feel distinct and acknowledge the choice or state that caused them.
- [ ] Text fits on the target desktop and mobile layouts without becoming
      uncomfortably small or requiring awkward scrolling.

## 8. Manual Playtest Matrix

Run each test from the story picker with a fresh game unless the row says
otherwise.

- [ ] Complete the shortest successful route.
- [ ] Complete the longest or most stateful route.
- [ ] Complete every alternate route and ending.
- [ ] Complete routes both with and without each optional item.
- [ ] Enter each scene with every materially different inventory and flag state
      that can change its available commands, hints, or outcomes.
- [ ] Repeat every pickup and state-changing command before leaving its scene.
- [ ] Try progression commands before meeting their requirements.
- [ ] Inspect every inventory item in every scene where it can be carried.
- [ ] Try every action tile with the scene's main noun or target.
- [ ] Try inventory items in both command slots where relevant.
- [ ] Trigger hints through repeated failed commands and read all hint levels.
- [ ] Reach each terminal scene and confirm the NEW GAME button appears.
- [ ] Start a new game after an ending and confirm the story starts cleanly.
- [ ] Switch to another story and back; confirm no state or UI leaks across stories.
- [ ] Test both tapping and drag-and-drop for representative commands.
- [ ] Test at the smallest supported window or mobile size.

## 9. Regression and Repository Checks

- [ ] Only intended files changed.
- [ ] Existing stories still load and appear in the story picker.
- [ ] Any `scripts/Game.gd` change made for new actions, emoji, or behavior is
      tested against existing stories.
- [ ] The story file contains no comments; standard JSON does not allow them.
- [ ] No temporary notes, test scenes, debug text, or placeholder copy remain.
- [ ] `meta.version` was incremented when updating a previously released story.
- [ ] The final diff was reviewed for accidental deletions, renamed tokens, and
      broken scene IDs.
- [ ] The repository's available validation or test commands pass.

## Release Gate

A story is ready only when all of the following are true:

- [ ] JSON parsing and the engine's built-in story validation pass.
- [ ] Every scene and transition is reachable or intentionally documented.
- [ ] Every ending has a recorded, passing, fresh-game playthrough.
- [ ] Every inventory item and flag has a verified acquisition, use, repeat, and
      cleanup lifecycle.
- [ ] No command is shadowed by incorrect rule order.
- [ ] No player choice can create an unintended dead end.
- [ ] Hints, fallbacks, and child-facing text have been manually reviewed.
- [ ] The story has been played in the actual Godot UI, not only inspected as JSON.

When an agent reports completion, it should include:

1. The number of scenes and terminal endings found.
2. The tested command path for every ending.
3. The inventory items and flags exercised during testing.
4. The validation and playtest results.
5. Any checks that could not be run and the remaining risk.

