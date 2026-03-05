# Ike Quest

A **Godot 4** tap-and-play text adventure aimed at early readers.

Players are shown short story text and categorized trays of word tiles. They tap tiles to fill **two command slots** (action + thing); when both slots are filled, the command auto-executes after a brief delay. The engine evaluates commands against rules defined in JSON. Tiles show emoji icons and are split into Actions, Things, and Inventory sections. Inventory items appear as gold tiles that persist across scenes and can be placed in either slot.

---

## What this repository contains

- `project.godot`: Godot project configuration and the main scene entry point.
- `Game.tscn`: Main UI scene (MenuScreen with logo/title/story picker, story text, feedback label, two command slots, categorized tile trays, continue button, new game button, transition overlay).
- `scripts/Game.gd`: Core game controller (story discovery, scene rendering, click-to-place + drag-drop input, auto-execution, 2-token command evaluation, inventory/flag state, scene transitions with fade, emoji rendering, tile categorization).
- `scripts/Tile.gd`: Draggable/clickable tile with `token`, `tile_color`, and `category` properties.
- `scripts/CommandSlot.gd`: Drop target for command slots (Action, Thing).
- `ui/Tile.tscn`: Reusable tile button component instantiated at runtime.
- `stories/*.json`: Story content files auto-discovered at startup.

---

## How the game works

### 1) Menu and story discovery

At startup, `Game.gd` scans `res://stories/` for all `.json` files and presents them in a story picker dropdown sorted by scene count. Each story shows its title, scene count, and teaser description. The player selects a story and taps PLAY.

### 2) Scene rendering

For the active scene, the controller:

- Displays scene text (`text` array joined by newlines)
- Clears the previous feedback and command slots
- Sorts scene tiles into three categorized trays:
  - **Actions** (blue): verb tiles like "go", "take", "open"
  - **Things** (blue): noun tiles not in inventory
  - **Inventory** (gold/amber): items the player is carrying — includes scene tiles that are in inventory plus items carried from other scenes
- Shows/hides the Inventory section based on whether the player has items

### 3) Input model

- **Click-to-place**: Tapping a tile auto-routes it: action tiles go to Slot 1, thing tiles go to Slot 2, inventory tiles go to the first empty slot (allowing them to act as verbs or objects).
- **Drag-and-drop**: Tiles can also be dragged into slots manually as a fallback.
- Tiles display emoji icons from the `EMOJI` dict (e.g. "🗝️ key", "👉 go").
- Two command slots (Action, Thing) accept tile placement.

### 4) Command resolution

When both slots are filled, the game waits 0.5s (so the kid sees the tile land) then auto-executes.

Rule evaluation is deterministic and simple:

1. Read current scene `commands` in order.
2. Find first command whose `pattern` (2 tokens) matches the player's command.
3. If the rule has `requirements`, verify them:
   - `inventory_has`
   - `flags_true`
4. On success:
   - show `response`
   - apply `effects` (inventory/flag changes)
   - re-render tiles so inventory items move between trays immediately
   - optionally transition to `next` scene with fade effect
5. If no rule matches, show a random scene `default` message.

### 5) Scene transitions

When a rule has `next`, the game shows the response text, pauses briefly, then displays a continue button (▶). When tapped, it fades to black, swaps scene content, and fades back in.

### 6) State tracking

- `inventory`: dictionary acting like a set (`item -> true`)
- `flags`: dictionary for boolean state (`flag -> true/false`)

Supported effects:

- `inventory_add`
- `inventory_remove`
- `flags_set`

---

## Story format (`stories/*.json`)

Top-level keys:

- `meta`: metadata (`title`, `version`, `teaser`)
- `start_scene`: ID of first scene
- `scenes`: map of scene ID to scene object
- `vocab`: token-to-label mapping (not currently used for rendering)

Scene object keys:

- `text`: array of lines shown to player
- `tiles`: list of tokens available as tiles in that scene
- `commands`: list of rules
- `default`: list of fallback responses (one picked at random)

Command rule keys:

- `pattern`: 2-token array (e.g. `["go", "forest"]`, `["key", "gate"]`)
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

## Included stories

### The Lost Dragon Egg (`dragon_egg.json`)

10 scenes. Find a dragon egg in a tree and return it to the mother dragon. Features inventory gating (key, rope, egg), multi-step puzzles, and item consumption.

### Spider-Man and the Ghost Chain (`spider_hero.json`)

13 scenes. Help Spider-Man defeat Ghost Rider by finding his chain's weakness. Features flag-based progression, multiple inventory items (web, potion, hammer, book), and a boss battle.

---

## Running the project

### In Godot Editor

1. Open Godot 4.6 (or compatible 4.x).
2. Import/open this folder.
3. Run project (main scene is already configured).

### From CLI

```bash
godot4 --path .
```

---

## Notes and limitations

- `vocab` labels exist in JSON but tile rendering uses emoji + raw token text via the `EMOJI` dict instead.
- Scene `image` fields exist in story data but are not yet rendered.
- No sound/animation feedback, no JSON validation.
- Emoji rendering depends on OS system fonts (Segoe UI Emoji on Windows, Apple Color Emoji on macOS, Noto Color Emoji on Linux).

---

## Quick contributor guide

If you want to add a new story:

1. Create a new `.json` file in `stories/` following the schema above. Include `meta.teaser` for the menu description.
2. The game auto-discovers all JSON files in that directory and sorts by scene count.

If you want to add a new scene to an existing story:

1. Add scene object under `scenes` with `text`, `tiles`, `commands`, and `default`.
2. Point an existing rule's `next` to your new scene.
3. Run and verify tap/drag command paths.

For code changes, start in `scripts/Game.gd` (runtime logic) and `Game.tscn` (layout).

See `docs/creating-stories.md` for a detailed story authoring guide.
