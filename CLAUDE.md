# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Godot 4.6 text adventure for early readers. Players tap word tiles to fill 2 command slots (action + thing); commands auto-execute when both slots are filled. The engine evaluates commands against JSON-defined rules.

## Running

Open in Godot 4.6+ editor and press F5, or from CLI:
```bash
godot4 --path .
```

There is no build step, test suite, or linter — verification is manual playtesting in the Godot editor.

## Architecture

**Three scripts, one scene, JSON-driven stories.**

- `scripts/Game.gd` — The entire game controller. Handles story discovery, scene rendering, click-to-place + drag-drop input, auto-execution, rule evaluation, inventory/flag state, scene transitions with fade effect, emoji font loading, and tile categorization. Inventory items can be placed in either slot (first-empty routing). This is where nearly all logic lives.
- `scripts/Tile.gd` — Draggable/clickable button: has `token`, `tile_color`, and `category` ("action"/"thing"/"inventory") properties. `_get_drag_data()` creates a styled preview and returns token + label + category. `pressed` signal connected to Game.gd for click-to-place.
- `scripts/CommandSlot.gd` — Drop target: accepts tile drag data, stores the token, updates its label. Has `set_tile(token, text)` method and `tile_dropped` signal for auto-execution. `clear()` resets to placeholder.
- `Game.tscn` — Main UI scene: MenuScreen (VBoxContainer with logo, title, story picker, PLAY button), story text, feedback label, 2 command slots (Action + Thing), categorized tile tray (TileSection with InventoryTray + ActionTray + ThingTray), ContinueButton (▶ arrow, shown during scene transitions), NewGameButton (inline, shown on terminal scenes), TransitionOverlay (full-screen ColorRect for fade transitions).
- `ui/Tile.tscn` — Reusable tile button component (72px min height, 32px font). Instantiated at runtime.
- `stories/*.json` — Story content files auto-discovered at startup.

**Story selection:** MenuScreen is a centered VBoxContainer with Ike's logo (220x220 icon.png), "Ike Quest" title (40px), "A Text Adventure" subtitle (20px gray), story picker dropdown (24px), teaser label (18px gray), green PLAY button (80px tall, 36px font, rounded corners), and version label (14px gray, pushed to bottom via flex spacer). The picker shows `"Title (N scenes)"` and stories are sorted by ascending scene count. Selecting a story displays its `meta.teaser` from the JSON. Version is read from `version.txt` at startup. It hides game UI (CommandBar, TileSection, FeedbackText, StoryText). On start, game UI is shown and MenuScreen is hidden. On terminal scenes (no outgoing transitions), a "NEW GAME" button appears inline at the bottom, returning to the menu.

**Game loop:** Story picker → select story → load JSON → render scene (text + tiles) → player taps tiles (auto-placed into correct slot by category) → when all visible slots filled, 0.5s delay then auto-execute → match command pattern against scene rules → check requirements (inventory/flags) → apply effects → show response → optionally transition scene with fade.

**Click-to-place:** Tapping a tile auto-routes it: action tiles → Slot1, thing tiles → Slot2, inventory tiles → first empty slot (Slot1 if empty, else Slot2). This lets inventory items act as verbs (e.g., "hammer chain", "key gate") or objects (e.g., "look hammer"). Drag-and-drop still works as fallback.

**Auto-execution:** `_check_slots_and_execute()` fires after any tile placement (click or drag). When all visible slots are filled, waits 0.5s (so kid sees the tile land), then calls `_try_execute_command()`. Guards against stale execution with scene ID check across the await.

**Scene transitions:** `_transition_to_scene()` shows response text, pauses 1.0s, then displays a ▶ continue button. When the kid taps the button, it fades to black over 0.3s via `TransitionOverlay` ColorRect tween, swaps scene content, fades back in over 0.3s. `is_transitioning` flag prevents input during transitions (including while the continue button is visible).

**State:** `inventory` (Dictionary as set: token→true), `flags` (Dictionary: flag→bool), `current_scene_id` (String), `is_transitioning` (bool).

**Emoji rendering:** At startup, a `SystemFont` referencing OS emoji fonts (Segoe UI Emoji, Apple Color Emoji, Noto Color Emoji) is appended to `ThemeDB.fallback_font.fallbacks`. The `EMOJI` dict maps tokens to emoji characters; tiles display "emoji + token" text.

**Tile categorization:** `ACTION_TOKENS` const lists verb tokens. `_render_scene()` sorts tiles into `ActionTray` (verbs), `ThingTray` (nouns), and `InventoryTray` (items in inventory) FlowContainers under a `TileSection` VBoxContainer. Inventory tiles are gold/amber colored and include items carried from other scenes. `_make_tile()` helper creates tiles with color styling and category, connects `pressed` signal.

## Stories

- **`dragon_egg.json`** — Fantasy adventure with 2-word commands. Player finds a dragon egg and returns it.
- **`spider_hero.json`** — "Spider-Man and the Ghost Chain." 13 scenes, 2-word commands. Player helps Spider-Man defeat Ghost Rider.

## Story JSON Format

```
meta.title / meta.version / meta.teaser
vocab: { token: label }          # label mapping exists but tiles use EMOJI dict + raw token instead
start_scene: scene_id
scenes.{id}.text: [lines]        # displayed to player
scenes.{id}.tiles: [tokens]      # available drag tiles
scenes.{id}.commands: [rules]    # evaluated in order, first match wins
scenes.{id}.default: [strings]   # random fallback if no rule matches (5-8 funny responses per scene)
```

Command rules: `pattern` (2 token array), `response`, optional `requirements` (inventory_has, flags_true), optional `effects` (inventory_add, inventory_remove, flags_set), optional `next` (scene transition).

## Key Patterns

- **GDScript style:** snake_case for functions/variables, PascalCase for classes. Godot 4 typed syntax (`var x: Type`). Use explicit types over `:=` inference when the source property lacks a type annotation.
- **Adding a story:** Create a new `.json` file in `stories/` following the schema above. Include `meta.teaser` for the menu description. The game auto-discovers all JSON files in that directory and sorts by scene count.
- **Adding a scene:** Add scene object under `scenes` in the story JSON with `text`, `tiles`, `commands`, and `default`. Point an existing rule's `next` to it.
- **Code changes:** Almost everything is in `Game.gd`. UI layout changes go in `Game.tscn`.
- **Consumable items:** Use `inventory_remove` in effects when items should be used up (e.g., rope after tying bridge, potion after pouring).

## Known Limitations

- `vocab` labels defined but not yet used for tile rendering (tiles show emoji + raw token text via the `EMOJI` dict instead).
- Scene `image` fields in JSON are parsed but not rendered.
- No sound/animation feedback, no JSON validation.
- Emoji rendering depends on OS system fonts (Segoe UI Emoji on Windows, Apple Color Emoji on macOS). Bundled CBDT-format emoji fonts (e.g. NotoColorEmoji.ttf) do not render in Godot.

## Deferred Features

See `tasks/todo.md` for planned features: scene images, story creation tool, sound/animation, restart UI, JSON validation.
