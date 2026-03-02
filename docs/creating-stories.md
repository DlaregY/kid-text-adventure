# Creating Stories

This guide explains how to create new stories for the drag-and-drop text adventure game. No programming required — stories are written as JSON files.

## Quick Start

1. Create a new `.json` file in the `stories/` folder (e.g. `stories/my_story.json`)
2. The game auto-discovers all JSON files in that directory
3. Your story will appear in the story picker when the game runs

## Minimal Example

```json
{
  "meta": { "title": "My First Story", "version": 1 },
  "start_scene": "start",
  "scenes": {
    "start": {
      "text": ["You see a red door."],
      "tiles": ["open", "look", "door"],
      "commands": [
        {
          "pattern": ["open", "door"],
          "response": "The door swings open!",
          "next": "end"
        },
        {
          "pattern": ["look", "door"],
          "response": "A bright red door with a brass handle."
        }
      ],
      "default": ["Hmm, try something else."]
    },
    "end": {
      "text": ["You win! Great job!"],
      "tiles": ["look", "door"],
      "commands": [
        {
          "pattern": ["look", "door"],
          "response": "The door is behind you now."
        }
      ],
      "default": ["You already won!"]
    }
  }
}
```

## File Structure

Every story JSON has these top-level fields:

| Field | Required | Description |
|-------|----------|-------------|
| `meta` | Yes | Story metadata (`title` and `version`) |
| `start_scene` | Yes | ID of the first scene to show |
| `scenes` | Yes | Object containing all scenes, keyed by scene ID |
| `vocab` | No | Token-to-label mapping (not currently used for rendering) |

## Scenes

Each scene is an object inside `scenes` with a unique ID as its key.

```json
"my_scene_id": {
  "text": ["Line one.", "Line two."],
  "tiles": ["go", "look", "door"],
  "commands": [ ... ],
  "default": ["Nothing happens."]
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `text` | Yes | Array of strings displayed as the scene description |
| `tiles` | Yes | Array of token strings available as draggable tiles |
| `commands` | Yes | Array of command rules (evaluated in order) |
| `default` | Yes | Array of fallback responses (one picked at random when no rule matches) |

## Tiles

Tiles are the words players drag into command slots. Each tile is identified by a **token** — a short lowercase string.

### Tile Categories

Tiles are automatically sorted into three trays:

- **Action tray** — Verb tiles. A token goes here if it is one of: `go`, `open`, `take`, `look`, `talk`, `give`, `climb`, `use`
- **Inventory tray** — Items the player is carrying (gold colored). Shown automatically when the player has items in inventory, even if the token isn't in the scene's `tiles` list.
- **Thing tray** — Everything else (nouns, objects, places)

### Emoji

Many tokens automatically display with an emoji icon. These are the built-in mappings:

| Token | Emoji | Token | Emoji |
|-------|-------|-------|-------|
| `go` | 👉 | `key` | 🗝️ |
| `open` | 📖 | `box` | 📦 |
| `take` | ✋ | `door` | 🚪 |
| `look` | 👀 | `rope` | 🪢 |
| `talk` | 💬 | `apple` | 🍎 |
| `give` | 🎁 | `treasure` | 💎 |
| `climb` | 🧗 | `egg` | 🥚 |
| `use` | 🔧 | `forest` | 🌲 |
| `dog` | 🐕 | `gate` | 🏰 |
| `dragon` | 🐉 | `tree` | 🌳 |
| `bridge` | 🌉 | `cave` | 🕳️ |

Tokens not in this list display without an emoji. To add new emoji, the `EMOJI` dictionary in `scripts/Game.gd` must be edited.

## Command Rules

Commands are what happens when the player drags tiles into slots and presses GO. Rules are evaluated **in order** — the first matching rule wins.

```json
{
  "pattern": ["open", "box"],
  "response": "The lid pops open!",
  "requirements": { ... },
  "effects": { ... },
  "next": "another_scene"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `pattern` | Yes | Array of 2 or 3 tokens to match against the player's input |
| `response` | Yes | Text shown to the player when this rule matches |
| `requirements` | No | Conditions that must be true for the rule to match |
| `effects` | No | State changes applied when the rule matches |
| `next` | No | Scene ID to transition to after matching |

### Pattern Matching

Patterns are 2 or 3 tokens that must exactly match what the player dragged into the slots, in order.

```json
"pattern": ["open", "door"]          // 2-word command
"pattern": ["use", "rope", "bridge"] // 3-word command
```

- Matching is **case-sensitive** — always use lowercase
- The third command slot ("Where") only appears if at least one rule in the scene has a 3-token pattern

### Requirements

Optional conditions checked after the pattern matches. If any condition fails, the rule is skipped and the engine tries the next rule.

```json
"requirements": {
  "inventory_has": ["key"],
  "flags_true": ["door_unlocked"]
}
```

| Field | Description |
|-------|-------------|
| `inventory_has` | Array of tokens the player must be carrying. **All** must be present. |
| `flags_true` | Array of flag names that must be set to `true`. **All** must be true. |

### Effects

State changes applied when a rule matches.

```json
"effects": {
  "inventory_add": ["key", "rope"],
  "inventory_remove": ["apple"],
  "flags_set": { "box_open": true, "dog_fed": true }
}
```

| Field | Description |
|-------|-------------|
| `inventory_add` | Array of tokens to add to the player's inventory |
| `inventory_remove` | Array of tokens to remove from the player's inventory |
| `flags_set` | Object of flag names to boolean values |

### Scene Transitions

If a rule has a `next` field, the game transitions to that scene after showing the response and applying effects.

```json
"next": "forest"
```

If `next` is omitted, the player stays in the current scene.

## State: Inventory and Flags

Stories have two kinds of persistent state that carry across scenes:

### Inventory

A set of items the player is carrying. Items are token strings.

- Added via `effects.inventory_add`
- Removed via `effects.inventory_remove`
- Checked via `requirements.inventory_has`
- Inventory items appear as gold tiles in the Inventory tray automatically
- Resets when a new story is started

### Flags

Named boolean values for tracking progress.

- Set via `effects.flags_set`
- Checked via `requirements.flags_true`
- Unset flags default to `false`
- Resets when a new story is started

## Design Patterns

### Gating with Flags (Do X Before Y)

Use duplicate patterns with different requirements. Put the stricter rule first:

```json
{
  "pattern": ["take", "key"],
  "requirements": { "flags_true": ["box_open"] },
  "response": "You grab the shiny key!",
  "effects": { "inventory_add": ["key"] }
},
{
  "pattern": ["take", "key"],
  "response": "You don't see a key. Maybe look in the box?"
}
```

If `box_open` is false, the first rule is skipped and the second one matches instead.

### Gating with Inventory (Must Have Item)

```json
{
  "pattern": ["use", "key"],
  "requirements": { "inventory_has": ["key"] },
  "response": "The key turns and the gate opens!",
  "next": "garden"
},
{
  "pattern": ["use", "key"],
  "response": "You don't have a key!"
}
```

### Multi-Step Puzzles

Combine flags to require completing steps in sequence:

```json
// Step 1: talk to the dog
{
  "pattern": ["talk", "dog"],
  "response": "The dog says: help me find my bone!",
  "effects": { "flags_set": { "dog_talked": true } }
},
// Step 2: give apple (only after talking)
{
  "pattern": ["give", "apple"],
  "requirements": { "flags_true": ["dog_talked"] },
  "response": "The dog wags its tail and gives you a rope!",
  "effects": { "inventory_add": ["rope"], "flags_set": { "dog_helped": true } }
},
// Step 3: proceed (only after both steps)
{
  "pattern": ["go", "forest"],
  "requirements": { "flags_true": ["dog_talked", "dog_helped"] },
  "response": "The dog waves goodbye!",
  "next": "deep_forest"
},
{
  "pattern": ["go", "forest"],
  "response": "The dog blocks the path. Maybe talk to it?"
}
```

### Carrying Items Between Scenes

Items persist in inventory across all scenes. A key taken in scene 1 can be used in scene 5:

```json
// Scene: hall
{ "pattern": ["take", "key"], "response": "Got it!", "effects": { "inventory_add": ["key"] } }

// Scene: gate (later)
{ "pattern": ["use", "key"], "requirements": { "inventory_has": ["key"] }, "response": "It works!", "next": "garden" }
```

### Consuming Items

Remove items from inventory after use:

```json
{
  "pattern": ["give", "egg"],
  "requirements": { "inventory_has": ["egg"] },
  "response": "The dragon takes the egg happily!",
  "effects": { "inventory_remove": ["egg"] }
}
```

### 3-Word Commands

For scenes where direction matters (e.g. "use rope bridge"):

```json
{
  "pattern": ["use", "rope", "bridge"],
  "requirements": { "inventory_has": ["rope"] },
  "response": "You tie the rope to the bridge!",
  "effects": { "flags_set": { "bridge_fixed": true } }
}
```

The third slot ("Where") automatically appears when any rule in the scene has a 3-token pattern.

### Terminal / Ending Scenes

The last scene in a story typically has no `next` transitions. The "Change Story" button appears automatically in scenes where no rule has a `next` field.

```json
"win": {
  "text": ["YOU WIN!", "Great job, hero!"],
  "tiles": ["look", "treasure"],
  "commands": [
    { "pattern": ["look", "treasure"], "response": "So shiny!" }
  ],
  "default": ["You already won!"]
}
```

## Tips for Writing Good Stories

1. **Keep text short.** This game is for early readers. Use simple words and short sentences.
2. **Cover common attempts.** Think about what a child might try and add rules for it, even if the answer is "that doesn't work."
3. **Give helpful hints.** When a command doesn't work, the response should nudge the player toward the solution.
4. **Use funny fallbacks.** The `default` responses are shown when nothing matches — make them entertaining.
5. **Test all paths.** Play through your story and try every tile combination to make sure responses make sense.
6. **Rule order matters.** Put rules with requirements **before** their fallback versions (same pattern, no requirements).
7. **Use existing tokens when possible.** Tokens in the emoji table and action list (`go`, `open`, `take`, `look`, `talk`, `give`, `climb`, `use`) will look best in the UI.

## Complete Reference: dragon_egg.json

The included story `stories/dragon_egg.json` demonstrates all features:

- 9 scenes with a linear progression
- Inventory items: `key`, `rope`, `egg`
- Flags: `box_open`, `dog_talked`, `dog_helped`, `in_tree`, `bridge_fixed`, `egg_returned`
- 3-word command: `use rope bridge`
- Multi-step gating: must talk to dog AND feed dog before proceeding
- Item consumption: egg is removed from inventory when given to dragon
- Terminal scene: "win" has no transitions, shows Change Story button

Read through it as a complete example of story structure and patterns.
