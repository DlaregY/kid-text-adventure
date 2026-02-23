# Kid Text Adventure

A small **Godot 4** drag-and-drop text adventure aimed at early readers.

Players are shown short story text and a tray of word tiles. They drag **two words** (a verb + noun) into command slots, press **GO**, and the game evaluates the command against rules defined in JSON.

---

## What this repository contains

- `project.godot`: Godot project configuration and the main scene entry point.
- `Game.tscn`: Main UI scene (story text, feedback, two command slots, inventory text, tile tray, GO button).
- `scripts/Game.gd`: Core game controller (loads story JSON, renders scenes, evaluates commands, applies effects, tracks inventory/flags, transitions scenes).
- `scripts/Tile.gd`: Draggable tile behavior.
- `scripts/CommandSlot.gd`: Drop target behavior for command slots.
- `stories/dragon_egg.json`: Story content and logic (scenes, available tiles, command patterns, requirements, effects, scene transitions).

---

## How the game works

### 1) Story loading

At startup, `Game.gd` loads `res://stories/dragon_egg.json`, parses it, and reads:

- `start_scene`
- `scenes`

If the file cannot be read, JSON is invalid, or `start_scene` is missing, it reports errors.

### 2) Scene rendering

For the active scene, the controller:

- Displays scene text (`text` array joined by newlines)
- Clears the previous feedback and command slots
- Rebuilds the tile tray from scene `tiles`
- Updates inventory UI

### 3) Input model

- Each tile is a `Button` (`Tile.gd`) that supports drag-and-drop.
- Drag payload is a dictionary containing:
  - `token` (internal command word)
  - `label` (display text)
- Each command slot (`CommandSlot.gd`) accepts that payload, stores the token, and updates its label.

### 4) Command resolution

When GO is pressed, the game checks that both slots are filled and calls `_apply_command(verb, noun)`.

Rule evaluation is deterministic and simple:

1. Read current scene `commands` in order.
2. Find first command whose `pattern` matches `[verb, noun]`.
3. If the rule has `requirements`, verify them:
   - `inventory_has`
   - `flags_true`
4. On success:
   - show `response`
   - apply `effects`
   - optionally move to `next` scene
5. If no rule matches, show a random scene `default` message.

### 5) State tracking

- `inventory`: dictionary acting like a set (`item -> true`)
- `flags`: dictionary for boolean state (`flag -> true/false`)

Supported effects:

- `inventory_add`
- `inventory_remove`
- `flags_set`

---

## Story format (`stories/*.json`)

The current story file (`dragon_egg.json`) demonstrates the content schema used by the game.

Top-level keys:

- `meta`: metadata such as title/version
- `vocab`: token-to-label mapping (currently tiles use token text directly)
- `start_scene`: ID of first scene
- `scenes`: map of scene ID to scene object

Scene object keys used by the runtime:

- `text`: array of lines shown to player
- `tiles`: list of tokens available as drag tiles in that scene
- `commands`: list of rules
- `default`: list of fallback responses

Command rule keys:

- `pattern`: two-token array (verb, noun)
- `response`: text shown on match
- `requirements` (optional):
  - `inventory_has`: required inventory tokens
  - `flags_true`: required true flags
- `effects` (optional):
  - `inventory_add`
  - `inventory_remove`
  - `flags_set`
- `next` (optional): scene ID transition

---

## Current adventure flow

The built-in adventure is **“The Lost Dragon Egg”**, a linear-ish progression with light state gating:

1. Open room door → hall
2. Open box, then take key → gate
3. Use key → forest
4. Talk to dog (path hint) and optionally gain rope by giving apple
5. Climb tree, take egg → bridge
6. Use rope, then cross bridge → cave
7. Enter cave → dragon
8. Give egg → treasure
9. Take treasure → win

The game also includes non-progress commands and fallback responses for experimentation.

---

## Running the project

### In Godot Editor

1. Open Godot 4.6 (or compatible 4.x).
2. Import/open this folder.
3. Run project (main scene is already configured).

### From CLI (if Godot is installed)

```bash
godot4 --path .
```

(Executable name may be `godot`, `godot4`, or platform-specific.)

---

## Notes and limitations

- Command input is currently fixed to exactly **two tokens**.
- `vocab` labels exist in JSON, but tile rendering currently uses token text directly.
- Scene `image` fields exist in story data but are not yet rendered by UI.
- Some story branches imply inventory items (e.g., giving apple) that are not fully sourced by earlier gameplay; this is fine for prototype content but can be tightened during story pass.

---

## Ideas for next improvements

- Render scene art (`image`) with optional transitions.
- Use `vocab` labels for kid-friendly display text while keeping stable internal tokens.
- Add restart/checkpoint UI.
- Add sound and simple animation feedback for correct/incorrect commands.
- Add lightweight JSON validation for authoring errors.
- Expand command system to support single-word and 3-word patterns.

---

## Quick contributor guide

If you want to add a new story scene quickly:

1. Add scene object under `scenes`.
2. Add `text`, `tiles`, at least one `commands` rule, and `default`.
3. Point an existing rule’s `next` to your new scene.
4. Run and verify drag/drop command paths.

For code changes, start in `scripts/Game.gd` (runtime logic) and `Game.tscn` (layout).
