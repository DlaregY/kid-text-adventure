# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Godot 4.6 drag-and-drop text adventure for early readers. Players drag 2–3 word tiles into command slots and press GO; the engine evaluates commands against JSON-defined rules.

## Running

Open in Godot 4.6+ editor and press F5, or from CLI:
```bash
godot4 --path .
```

There is no build step, test suite, or linter — verification is manual playtesting in the Godot editor.

## Architecture

**Three scripts, one scene, JSON-driven stories.**

- `scripts/Game.gd` — The entire game controller (~350 lines). Handles story loading, scene rendering, drag-drop input, rule evaluation, inventory/flag state, scene transitions, emoji font loading, and tile categorization. This is where nearly all logic lives.
- `scripts/Tile.gd` — Draggable button: sets drag data (`token` + `label`) and creates a drag preview. Note: `_ready()` only sets text from `token` if `text` is empty — callers that set `text` before `add_child()` won't be overwritten.
- `scripts/CommandSlot.gd` — Drop target: accepts tile drag data, stores the token, updates its label. Has `@export placeholder_text` for labeled slots ("Action", "Thing", "Where"); `clear()` resets to placeholder.
- `Game.tscn` — Main UI scene: story text, feedback label, 3 labeled command slots (Slot3 hidden by default), inventory text, categorized tile tray (TileSection with ActionTray + ThingTray), GO button, story picker overlay.
- `ui/Tile.tscn` — Reusable tile button component instantiated at runtime.
- `stories/*.json` — Story content files auto-discovered at startup.

**Game loop:** Story picker → select story → load JSON → render scene (text + tiles) → player drags tiles into slots → GO → match command pattern against scene rules → check requirements (inventory/flags) → apply effects → show response → optionally transition scene.

**State:** `inventory` (Dictionary as set: token→true), `flags` (Dictionary: flag→bool), `current_scene_id` (String).

**Emoji rendering:** At startup, a `SystemFont` referencing OS emoji fonts (Segoe UI Emoji, Apple Color Emoji, Noto Color Emoji) is appended to `ThemeDB.fallback_font.fallbacks`. The `EMOJI` dict maps tokens to emoji characters; tiles display "emoji + token" text. Note: bundled .ttf emoji fonts (CBDT format) don't render in Godot — SystemFont is required.

**Tile categorization:** `ACTION_TOKENS` const lists verb tokens. `_render_scene()` sorts tiles into `ActionTray` (verbs) and `ThingTray` (nouns) FlowContainers under a `TileSection` VBoxContainer.

**Slot3 visibility:** `_scene_has_3word_commands()` checks if any scene rule has a 3+ token pattern. `_render_scene()` shows/hides Slot3 ("Where") accordingly.

## Story JSON Format

```
meta.title / meta.version
vocab: { token: label }          # label mapping exists but tiles use EMOJI dict + raw token instead
start_scene: scene_id
scenes.{id}.text: [lines]        # displayed to player
scenes.{id}.tiles: [tokens]      # available drag tiles
scenes.{id}.commands: [rules]    # evaluated in order, first match wins
scenes.{id}.default: [strings]   # random fallback if no rule matches
```

Command rules: `pattern` (2–3 token array), `response`, optional `requirements` (inventory_has, flags_true), optional `effects` (inventory_add, inventory_remove, flags_set), optional `next` (scene transition).

## Key Patterns

- **GDScript style:** snake_case for functions/variables, PascalCase for classes. Godot 4 typed syntax (`var x: Type`). Use explicit types over `:=` inference when the source property lacks a type annotation.
- **Adding a story:** Create a new `.json` file in `stories/` following the schema above. The game auto-discovers all JSON files in that directory.
- **Adding a scene:** Add scene object under `scenes` in the story JSON with `text`, `tiles`, `commands`, and `default`. Point an existing rule's `next` to it.
- **Code changes:** Almost everything is in `Game.gd`. UI layout changes go in `Game.tscn`.

## Known Limitations

- `vocab` labels defined but not yet used for tile rendering (tiles show emoji + raw token text via the `EMOJI` dict instead).
- Scene `image` fields in JSON are parsed but not rendered.
- No restart/checkpoint UI, no sound/animation feedback, no JSON validation.
- Emoji rendering depends on OS system fonts (Segoe UI Emoji on Windows, Apple Color Emoji on macOS). Bundled CBDT-format emoji fonts (e.g. NotoColorEmoji.ttf) do not render in Godot.
