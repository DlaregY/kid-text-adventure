# Creating Stories

This guide explains how to create new stories for the tap-and-play text adventure game. No programming required — stories are written as JSON files.

## Quick Start

1. Create a new `.json` file in the `stories/` folder (e.g. `stories/my_story.json`)
2. The game auto-discovers all JSON files in that directory
3. Your story will appear in the story picker when the game runs

## Minimal Example

```json
{
  "meta": { "title": "My First Story", "version": 1, "teaser": "A short adventure!" },
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
| `meta` | Yes | Story metadata (`title`, `version`, and `teaser`) |
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
| `tiles` | Yes | Array of token strings available as tappable/draggable tiles |
| `commands` | Yes | Array of command rules (evaluated in order) |
| `default` | Yes | Array of fallback responses (one picked at random when no rule matches) |
| `hints` | No | Array of 3 progressive hint strings (gentle → specific → direct). Shown after 6 failed commands. |

## Tiles

Tiles are the words players tap to fill command slots. Each tile is identified by a **token** — a short lowercase string.

### Tile Categories

Tiles are automatically sorted into three trays:

- **Action tray** — Verb tiles. A token goes here if it is one of: `go`, `open`, `take`, `look`, `talk`, `give`, `climb`
- **Inventory tray** — Items the player is carrying (gold colored). Shown automatically when the player has items in inventory, even if the token isn't in the scene's `tiles` list.
- **Thing tray** — Everything else (nouns, objects, places)

### Click-to-Place Routing

When a player taps a tile:
- **Action tiles** go to Slot 1 (Action)
- **Thing tiles** go to Slot 2 (Thing)
- **Inventory tiles** go to the first empty slot — this lets them act as verbs (e.g. "hammer chain", "key gate") or objects (e.g. "look hammer")

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
| `dog` | 🐕 | `forest` | 🌲 |
| `dragon` | 🐉 | `gate` | 🏰 |
| `tree` | 🌳 | `bridge` | 🌉 |
| `cave` | 🕳️ | `web` | 🕸️ |
| `spiderdude` | 🕷️ | `ghost` | 👻 |
| `hammer` | 🔨 | `potion` | 🧪 |
| `chain` | ⛓️ | `torch` | 🔦 |
| `phone` | 📱 | `robot` | 🤖 |
| `bug` | 🐛 | `shield` | 🛡️ |
| `chip` | 💾 | `boss` | 👾 |
| `eggs` | 🍳 | `salt` | 🧂 |
| `plate` | 🍽️ | `lake` | 🌊 |
| `cliff` | 🏔️ | `crystal` | 🔮 |
| `rock` | 🪨 | | |

Tokens not in this list display without an emoji. To add new emoji, edit the `EMOJI` dictionary in `scripts/Game.gd`.

## Command Rules

Commands define what happens when the player fills both slots. When both slots are filled, the game auto-executes after a 0.5s delay. Rules are evaluated **in order** — the first matching rule wins.

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
| `pattern` | Yes | Array of 2 tokens to match against the player's command slots |
| `response` | Yes | Text shown to the player when this rule matches |
| `requirements` | No | Conditions that must be true for the rule to match |
| `effects` | No | State changes applied when the rule matches |
| `next` | No | Scene ID to transition to after matching |

### Pattern Matching

Patterns are exactly 2 tokens that must match what the player placed in the slots, in order.

```json
"pattern": ["open", "door"]
"pattern": ["key", "gate"]
"pattern": ["hammer", "chain"]
```

- Matching is **case-sensitive** — always use lowercase
- Inventory items can appear in either position (e.g. `["key", "gate"]` or `["look", "key"]`)

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

If a rule has a `next` field, the game transitions to that scene after showing the response and applying effects. The transition includes a continue button (▶) and a fade-to-black effect.

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
- Inventory items can be placed in either command slot
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
  "pattern": ["key", "gate"],
  "requirements": { "inventory_has": ["key"] },
  "response": "The key turns and the gate opens!",
  "effects": { "inventory_remove": ["key"] },
  "next": "garden"
}
```

### Inventory Items as Verbs

Since inventory items route to the first empty slot, players can use them as the "action" (Slot 1). Design commands that put inventory items first:

```json
{
  "pattern": ["hammer", "chain"],
  "requirements": { "inventory_has": ["hammer"] },
  "response": "You smash the chain! CRASH!"
},
{
  "pattern": ["potion", "door"],
  "requirements": { "inventory_has": ["potion"] },
  "response": "You pour the ice potion on the door! It freezes!",
  "effects": { "inventory_remove": ["potion"] }
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
{ "pattern": ["key", "gate"], "requirements": { "inventory_has": ["key"] }, "response": "It works!", "next": "garden" }
```

### Consuming Items

Remove items from inventory after use to keep the inventory tray clean:

```json
{
  "pattern": ["give", "egg"],
  "requirements": { "inventory_has": ["egg"] },
  "response": "The dragon takes the egg happily!",
  "effects": { "inventory_remove": ["egg"] }
}
```

### Acknowledging Inventory Items

Always add `["look", <item>]` handlers in scenes where the player carries inventory items. Otherwise the player sees a gold tile but gets a useless default response when examining it:

```json
{
  "pattern": ["look", "rope"],
  "response": "A strong rope. It might come in handy!"
}
```

### Preventing Repeated Actions

When a command changes state (opens a box, climbs a tree), add a guarded rule before it to handle re-execution:

```json
{
  "pattern": ["open", "box"],
  "requirements": { "flags_true": ["box_open"] },
  "response": "The box is already open!"
},
{
  "pattern": ["open", "box"],
  "response": "The lid pops open! Inside is a shiny key!",
  "effects": { "flags_set": { "box_open": true } }
}
```

### Terminal / Ending Scenes

The last scene in a story typically has no `next` transitions. A "NEW GAME" button appears automatically in scenes where no rule has a `next` field.

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
3. **Acknowledge inventory.** Add `["look", <item>]` for every inventory item the player carries into a scene. Add handlers for obvious item+target combinations too.
4. **Consume spent items.** Use `inventory_remove` when an item has served its purpose to avoid dead tiles cluttering the inventory.
5. **Prevent re-execution.** Add flag-guarded versions of state-changing commands so repeating them gives sensible responses.
6. **Give helpful hints.** When a command doesn't work, the response should nudge the player toward the solution.
7. **Use funny fallbacks.** The `default` responses are shown when nothing matches — make them entertaining. Aim for 5-8 per scene.
8. **Test all paths.** Play through your story and try every tile combination to make sure responses make sense.
9. **Rule order matters.** Put rules with requirements **before** their fallback versions (same pattern, no requirements).
10. **Use existing tokens when possible.** Tokens in the emoji table and action list (`go`, `open`, `take`, `look`, `talk`, `give`, `climb`) will look best in the UI.

## Complete Reference

The included stories demonstrate all features:

### `dragon_egg.json` (10 scenes)
- Inventory items: `key`, `rope`, `egg` (all consumed after use)
- Flags: `box_open`, `dog_talked`, `dog_helped`, `in_tree`, `bridge_fixed`, `egg_returned`
- Inventory-as-verb: `["key", "gate"]`, `["rope", "bridge"]`, `["egg", "dragon"]`
- Multi-step gating: must talk to dog AND feed dog before proceeding

### `spider_hero.json` (13 scenes)
- Inventory items: `note`, `web`, `key`, `book`, `potion`, `hammer` (key/note/potion/hammer consumed after use)
- Inventory-as-verb: `["potion", "door"]`, `["hammer", "chain"]`, `["web", "torch"]`, `["web", "stairs"]`
- Boss battle with multi-flag gating: must find weakness AND coordinate with Spiderdude
- Extensive inventory acknowledgment: `["look", <item>]` in every scene

### `phone_trap.json` (8 scenes)
- Inventory items: `phone`, `torch`, `key`, `shield`, `chip` (all consumed after use)
- Inventory-as-verb: `["torch", "bug"]`, `["shield", "fire"]`, `["chip", "boss"]`, `["key", "gate"]`
- Multi-step bedroom: take phone then look at it to get sucked in
- Progressive item chain: each item unlocks the next obstacle

### `shake_escape.json` (8 scenes)
- Inventory items: `crystal` (consumed climbing cliffs)
- Flags: `seen_glow`, `floating`, `built_pile`, `heard_mom`
- Multi-step puzzles in 4 scenes: look before act pattern (see glow → get sucked in, step in lake → grab crystal, stack salt → bounce, hear Mom → yell for help)
- Every tile combination has a specific contextual response

Read through them as complete examples of story structure and patterns.
