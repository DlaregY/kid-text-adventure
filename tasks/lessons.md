# Lessons Learned

## Keep docs in sync with game changes
When making gameplay changes (removing features, changing mechanics), update ALL docs — not just CLAUDE.md. Check README.md and docs/*.md too. The goodnight sequence should include a docs audit for any stale references.

## Consume inventory items after use
Items that have served their purpose (key after unlocking, note after delivering) should be removed via `inventory_remove`. Dead inventory tiles confuse players and require handlers in every subsequent scene.

## Acknowledge inventory items in every scene
Every scene should have `["look", <item>]` handlers for items the player is carrying. Also handle obvious item+target combinations (hammer+door, web+ghost). Getting a generic default response when examining your own inventory is a bad experience.

## Guard repeatable state-changing actions
Commands like "open box" or "climb tree" that set flags need a guarded version that checks if the flag is already set. Otherwise the player sees "The lid pops open!" repeatedly.
