# Kid Text Adventure

A small **Godot 4** drag-and-drop text adventure aimed at early readers.

Players are shown short story text and categorized trays of word tiles. They drag **two or three words** (a verb + noun, optionally a location) into command slots, press **GO**, and the game evaluates the command against rules defined in JSON. Tiles show emoji icons and are split into Actions, Things, and Inventory sections. Inventory items appear as gold draggable tiles that persist across scenes.

---

## What this repository contains

- `project.godot`: Godot project configuration and the main scene entry point.
- `Game.tscn`: Main UI scene (story text, feedback, three labeled command slots, categorized tile trays, GO button, story picker).
- `scripts/Game.gd`: Core game controller (story discovery, scene rendering, drag-drop input, 2–3 token command evaluation, inventory/flag state, emoji rendering, tile categorization).
- `scripts/Tile.gd`: Draggable tile behavior with `tile_color` property for styled drag previews.
- `scripts/CommandSlot.gd`: Drop target behavior for labeled command slots (Action, Thing, Where).
- `ui/Tile.tscn`: Reusable tile button component instantiated at runtime.
- `stories/*.json`: Story content files auto-discovered at startup.

---

## How the game works

### 1) Story discovery and loading

At startup, `Game.gd` scans `res://stories/` for all `.json` files and presents them in a story picker dropdown. The player selects a story and presses START. Each story file is parsed for:

- `meta.title` (used as display name in the picker)
- `start_scene`
- `scenes`

If a file cannot be read, JSON is invalid, or `start_scene` is missing, it reports errors.

### 2) Scene rendering

For the active scene, the controller:

- Displays scene text (`text` array joined by newlines)
- Clears the previous feedback and command slots
- Sorts scene tiles into three categorized trays:
  - **Actions** (blue): verb tiles like "go", "take", "open"
  - **Things** (blue): noun tiles not in inventory
  - **Inventory** (gold/amber): items the player is carrying — includes scene tiles that are in inventory plus items carried from other scenes
- Shows/hides the third command slot ("Where") based on whether the scene has 3-token rules
- Shows/hides the Inventory section based on whether the player has items

### 3) Input model

- Each tile is a `Button` (`Tile.gd`) that supports drag-and-drop with a styled preview matching its tray color.
- Tiles display emoji icons from the `EMOJI` dict (e.g. "🗝️ key", "👉 go").
- Drag payload is a dictionary containing:
  - `token` (internal command word)
  - `label` (display text)
- Three labeled command slots (Action, Thing, Where) accept tile drops. Slot3 ("Where") is only visible when the scene has 3-token command rules.

### 4) Command resolution

When GO is pressed, the game checks that at least two slots are filled and builds a 2–3 token command array.

Rule evaluation is deterministic and simple:

1. Read current scene `commands` in order.
2. Find first command whose `pattern` length and tokens match the player's command.
3. If the rule has `requirements`, verify them:
   - `inventory_has`
   - `flags_true`
4. On success:
   - show `response`
   - apply `effects` (inventory/flag changes)
   - re-render tiles so inventory items move between trays immediately
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

- `pattern`: 2–3 token array (e.g. `["go", "forest"]` or `["give", "egg", "dragon"]`)
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

- `vocab` labels exist in JSON, but tile rendering uses emoji + raw token text via the `EMOJI` dict instead.
- Scene `image` fields exist in story data but are not yet rendered by UI.
- No restart/checkpoint UI, no sound/animation feedback, no JSON validation.
- Emoji rendering depends on OS system fonts (Segoe UI Emoji on Windows, Apple Color Emoji on macOS, Noto Color Emoji on Linux). Bundled CBDT-format emoji fonts do not render in Godot.

---

## Ideas for next improvements

- Render scene art (`image`) with optional transitions.
- Use `vocab` labels for kid-friendly display text while keeping stable internal tokens.
- Add restart/checkpoint UI.
- Add sound and simple animation feedback for correct/incorrect commands.
- Add lightweight JSON validation for authoring errors.

---

## Quick contributor guide

If you want to add a new story scene quickly:

1. Add scene object under `scenes`.
2. Add `text`, `tiles`, at least one `commands` rule, and `default`.
3. Point an existing rule’s `next` to your new scene.
4. Run and verify drag/drop command paths.

For code changes, start in `scripts/Game.gd` (runtime logic) and `Game.tscn` (layout).
