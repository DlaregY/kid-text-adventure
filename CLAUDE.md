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

- `scripts/Game.gd` — The entire game controller (~310 lines). Handles story loading, scene rendering, drag-drop input, rule evaluation, inventory/flag state, and scene transitions. This is where nearly all logic lives.
- `scripts/Tile.gd` — Draggable button: sets drag data (`token` + `label`) and creates a drag preview.
- `scripts/CommandSlot.gd` — Drop target: accepts tile drag data, stores the token, updates its label.
- `Game.tscn` — Main UI scene (story text, feedback label, 3 command slots, inventory text, tile tray, GO button, story picker overlay).
- `ui/Tile.tscn` — Reusable tile button component instantiated at runtime.
- `stories/*.json` — Story content files auto-discovered at startup.

**Game loop:** Story picker → select story → load JSON → render scene (text + tiles) → player drags tiles into slots → GO → match command pattern against scene rules → check requirements (inventory/flags) → apply effects → show response → optionally transition scene.

**State:** `inventory` (Dictionary as set: token→true), `flags` (Dictionary: flag→bool), `current_scene_id` (String).

## Story JSON Format

```
meta.title / meta.version
vocab: { token: label }          # label mapping exists but tiles currently render token text
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

- `vocab` labels defined but not yet used for tile rendering (tiles show raw token text).
- Scene `image` fields in JSON are parsed but not rendered.
- No restart/checkpoint UI, no sound/animation feedback, no JSON validation.
