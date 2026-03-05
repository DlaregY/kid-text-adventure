# Deferred Features

## Scene Images
- [ ] Each scene could have an illustration displayed above the story text
- [ ] JSON schema already has `image` fields that are parsed but not rendered
- [ ] Implementation: add `TextureRect` to scene layout, load images from `res://images/{story}/{scene}.png`
- [ ] Need to generate/create art for each scene (AI image generation or manual)

## Story Creation Tool
- [ ] GUI or web-based tool for authoring story JSONs without editing raw JSON
- [ ] Could be a Godot editor plugin, a separate web app, or even an in-game editor
- [ ] `docs/creating-stories.md` guide exists but a visual tool would lower the barrier

## Sound & Animation Feedback
- [ ] Add sound effects for tile placement, command success/failure, scene transitions
- [ ] Add simple animations (tile bounce on placement, text appear effects)

## Restart / Checkpoint UI
- [ ] Allow restarting a story from the beginning
- [ ] Optionally save progress between sessions

## JSON Validation
- [ ] Validate story JSON on load (check required fields, valid scene references, pattern consistency)
- [ ] Show helpful error messages for malformed stories
