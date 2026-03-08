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

## Export, Install & Release

**Export APK** (debug-signed):
```bash
"/c/Users/geral/Downloads/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64_console.exe" --headless --export-debug "Ike's Adventures" exports/ike-adventure.apk
```

**Install on phone** (device must be connected via USB with ADB debugging enabled):
```bash
/c/Android/Sdk/platform-tools/adb.exe install -r exports/ike-adventure.apk
```

**Create a GitHub release** (attach APK for easy download):
```bash
gh release create v<VERSION> exports/ike-adventure.apk --title "v<VERSION> — <Title>" --notes "<markdown notes>"
```

The goodnight shutdown sequence should include: export APK, install on phone (if connected), and create a GitHub release with the APK attached. Version comes from `version.txt`.

## Architecture

**Three scripts, one scene, JSON-driven stories.**

- `scripts/Game.gd` — The entire game controller. Handles story discovery, scene rendering, click-to-place + drag-drop input, auto-execution, rule evaluation, smart fallback responses, inventory/flag state, scene transitions with fade effect, emoji font loading, tile categorization, and auto-fit text sizing. Inventory items can be placed in either slot (first-empty routing). This is where nearly all logic lives.
- `scripts/Tile.gd` — Draggable/clickable button: has `token`, `tile_color`, and `category` ("action"/"thing"/"inventory") properties. `_get_drag_data()` creates a styled preview and returns token + label + category. `pressed` signal connected to Game.gd for click-to-place.
- `scripts/CommandSlot.gd` — Drop target: accepts tile drag data, stores the token, updates its label. Has `set_tile(token, text)` method and `tile_dropped` signal for auto-execution. `clear()` resets to placeholder.
- `Game.tscn` — Main UI scene: MenuScreen (VBoxContainer with logo, title, story picker, PLAY button), story text, feedback label, 2 command slots (Action + Thing), categorized tile tray (TileSection with InventoryTray + ActionTray + ThingTray), HintButton (hidden until 6 failed commands, shows progressive hints), ContinueButton (▶ arrow, shown during scene transitions), NewGameButton (inline, shown on terminal scenes), TransitionOverlay (full-screen ColorRect for fade transitions).
- `ui/Tile.tscn` — Reusable tile button component (72px min height, 32px font). Instantiated at runtime.
- `stories/*.json` — Story content files auto-discovered at startup.

**Story selection:** MenuScreen is a centered VBoxContainer with Ike's logo (220x220 icon.png), "Ike Quest" title (40px), "A Text Adventure" subtitle (20px gray), story picker dropdown (24px), teaser label (18px gray), green PLAY button (80px tall, 36px font, rounded corners), and version label (14px gray, pushed to bottom via flex spacer). The picker shows `"Title (N scenes)"` and stories are sorted by ascending scene count. Selecting a story displays its `meta.teaser` from the JSON. Version is read from `version.txt` at startup. It hides game UI (CommandBar, TileSection, FeedbackText, StoryText). On start, game UI is shown and MenuScreen is hidden. On terminal scenes (no outgoing transitions), a "NEW GAME" button appears inline at the bottom, returning to the menu.

**Game loop:** Story picker → select story → load JSON → render scene (text + tiles) → player taps tiles (auto-placed into correct slot by category) → when all visible slots filled, 0.5s delay then auto-execute → match command pattern against scene rules → check requirements (inventory/flags) → apply effects → show response → optionally transition scene with fade.

**Smart fallbacks:** When no rule matches a command, `_get_smart_fallback()` generates a contextual response before falling back to random scene defaults. It checks: (1) same token in both slots → silly "that's the same word" responses, (2) action verb + wrong thing → verb-specific funny responses (e.g., "You say hello to the tree. It does not answer. Rude!"), (3) inventory item as verb → "You wave the {item} at the {thing}" responses. Each category has 5 kid-friendly templates with `{thing}`/`{item}` placeholders. `_classify_token()` mirrors tile categorization to determine token types at evaluation time. `action_fallback_map` dict maps each verb to its response array.

**Click-to-place:** Tapping a tile auto-routes it: action tiles → Slot1, thing tiles → Slot2, inventory tiles → first empty slot (Slot1 if empty, else Slot2). This lets inventory items act as verbs (e.g., "hammer chain", "key gate") or objects (e.g., "look hammer"). Drag-and-drop still works as fallback.

**Auto-execution:** `_check_slots_and_execute()` fires after any tile placement (click or drag). When all visible slots are filled, waits 0.5s (so kid sees the tile land), then calls `_try_execute_command()`. Guards against stale execution with scene ID check across the await.

**Scene transitions:** `_transition_to_scene()` shows response text, pauses 1.0s, then displays a ▶ continue button. When the kid taps the button, it fades to black over 0.3s via `TransitionOverlay` ColorRect tween, swaps scene content, fades back in over 0.3s. `is_transitioning` flag prevents input during transitions (including while the continue button is visible).

**Hint system:** After 6 consecutive failed commands (no rule match), a HINT button appears below the tile section. Each scene has an optional `"hints"` array in the JSON with 3 progressive hints (gentle nudge, more specific, nearly direct). `_on_hint_pressed()` shows the next hint in FeedbackText, advancing `hint_index` and clamping at the last entry. `_reset_hints()` zeroes `fail_count` and `hint_index`, hides the button. Called by `_render_scene()` (scene change), `_apply_command()` (successful match), and `_show_menu()` (return to menu).

**Auto-fit text:** `_auto_fit_story_text()` runs at the end of every `_render_scene()` call. It iteratively shrinks StoryText font size from `STORY_FONT_MAX` (32px) down to `STORY_FONT_MIN` (18px) in `STORY_FONT_STEP` (2px) increments until the layout fits the viewport without scrolling. Also scales `custom_minimum_size.y` proportionally (`font_size * 5`). Resets scroll position to top after fitting. `_render_scene()` is async due to the frame-wait loop. Font size resets to max in `_show_menu()`.

**State:** `inventory` (Dictionary as set: token→true), `flags` (Dictionary: flag→bool), `current_scene_id` (String), `is_transitioning` (bool), `fail_count` (int: consecutive failed commands), `hint_index` (int: current hint position).

**Emoji rendering:** At startup, a `SystemFont` referencing OS emoji fonts (Segoe UI Emoji, Apple Color Emoji, Noto Color Emoji) is appended to `ThemeDB.fallback_font.fallbacks`. The `EMOJI` dict maps tokens to emoji characters; tiles display "emoji + token" text.

**Tile categorization:** `ACTION_TOKENS` const lists verb tokens. `_render_scene()` sorts tiles into `ActionTray` (verbs), `ThingTray` (nouns), and `InventoryTray` (items in inventory) FlowContainers under a `TileSection` VBoxContainer. Inventory tiles are gold/amber colored and include items carried from other scenes. `_make_tile()` helper creates tiles with color styling and category, connects `pressed` signal.

## Stories

- **`dragon_egg.json`** — Fantasy adventure with 2-word commands. Player finds a dragon egg and returns it.
- **`spider_hero.json`** — "Spiderdude and the Ghost Chain." 13 scenes, 2-word commands. Player helps Spiderdude defeat Skull Rider.
- **`phone_trap.json`** — "Phone Trap." 8 scenes, 2-word commands. Player gets sucked into Dad's phone and must defeat the Phone Boss to escape.
- **`salt_trap.json`** — "Salt Trap." 7 scenes, 2-word commands. Player gets sucked into a saltshaker, explores a salt crystal world (Dead Sea lake, salt cliffs), and escapes when Mom shakes the shaker.

## Story JSON Format

```
meta.title / meta.version / meta.teaser
vocab: { token: label }          # label mapping exists but tiles use EMOJI dict + raw token instead
start_scene: scene_id
scenes.{id}.text: [lines]        # displayed to player
scenes.{id}.tiles: [tokens]      # available drag tiles
scenes.{id}.commands: [rules]    # evaluated in order, first match wins
scenes.{id}.default: [strings]   # random fallback if no rule matches (5-8 funny responses per scene)
scenes.{id}.hints: [strings]    # progressive hints shown after 6 failed commands (optional, 3 strings: gentle → specific → direct)
```

Command rules: `pattern` (2 token array), `response`, optional `requirements` (inventory_has, flags_true), optional `effects` (inventory_add, inventory_remove, flags_set), optional `next` (scene transition).

## Key Patterns

- **GDScript style:** snake_case for functions/variables, PascalCase for classes. Godot 4 typed syntax (`var x: Type`). Use explicit types over `:=` inference when the source property lacks a type annotation.
- **Adding a story:** Create a new `.json` file in `stories/` following the schema above. Include `meta.teaser` for the menu description. The game auto-discovers all JSON files in that directory and sorts by scene count.
- **Adding a scene:** Add scene object under `scenes` in the story JSON with `text`, `tiles`, `commands`, `default`, and optionally `hints` (3 progressive strings: gentle, specific, direct). Point an existing rule's `next` to it.
- **Code changes:** Almost everything is in `Game.gd`. UI layout changes go in `Game.tscn`.
- **Consumable items:** Use `inventory_remove` in effects when items should be used up (e.g., rope after tying bridge, potion after pouring).

## Known Limitations

- `vocab` labels defined but not yet used for tile rendering (tiles show emoji + raw token text via the `EMOJI` dict instead).
- Scene `image` fields in JSON are parsed but not rendered.
- No sound/animation feedback, no JSON validation.
- Emoji rendering depends on OS system fonts (Segoe UI Emoji on Windows, Apple Color Emoji on macOS). Bundled CBDT-format emoji fonts (e.g. NotoColorEmoji.ttf) do not render in Godot.

## Deferred Features

See `tasks/todo.md` for planned features: scene images, story creation tool, sound/animation, restart UI, JSON validation.
