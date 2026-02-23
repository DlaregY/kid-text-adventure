# res://scripts/Game.gd
# Commands now accept 2 or 3 tokens from Slot1/Slot2[/Slot3].
# Rules match only when pattern length equals command length and all tokens align in order.
extends Control

const STORY_PATH := "res://stories/dragon_egg.json"
const TILE_SCENE := preload("res://ui/Tile.tscn")

@onready var story_text: Label = $Layout/StoryText
@onready var feedback_text: Label = $Layout/FeedbackText
@onready var tile_tray: FlowContainer = $Layout/TileTray
@onready var go_button: Button = $Layout/GoButton
@onready var slot1: PanelContainer = $Layout/CommandBar/Slot1
@onready var slot2: PanelContainer = $Layout/CommandBar/Slot2
@onready var slot3: PanelContainer = $Layout/CommandBar/Slot3
@onready var inventory_text: Label = $Layout/InventoryText

var story = {}
var scenes = {}
var current_scene_id = ""
var inventory = {} # token -> true
var flags = {}     # flag -> true/false

func _ready() -> void:
	go_button.pressed.connect(_on_go_pressed)

	_load_story()
	_start_story()

func _load_story() -> void:
	var f = FileAccess.open(STORY_PATH, FileAccess.READ)
	if f == null:
		push_error("Could not open story file: " + STORY_PATH)
		return

	var json_text = f.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if parsed == null:
		push_error("Invalid JSON in story file.")
		return

	story = parsed
	scenes = story.get("scenes", {})
	current_scene_id = story.get("start_scene", "")
	if current_scene_id == "":
		push_error("No start_scene set in story JSON.")
		return

func _start_story() -> void:
	inventory.clear()
	flags.clear()
	_render_scene()

func _render_scene() -> void:
	var scene = scenes.get(current_scene_id, null)
	if scene == null:
		push_error("Scene not found: " + current_scene_id)
		return

	# text
	var lines: Array = scene.get("text", [])
	story_text.text = "\n".join(lines)

	# clear feedback + command slots
	feedback_text.text = ""
	slot1.clear()
	slot2.clear()
	slot3.clear()

	# tiles
	for child in tile_tray.get_children():
		child.queue_free()

	var tiles: Array = scene.get("tiles", [])
	for t in tiles:
		var tile = TILE_SCENE.instantiate()
		tile.token = str(t)
		tile.text = str(t) # label for now; later we can map vocab labels
		tile_tray.add_child(tile)
		
	_update_inventory_ui()

func _update_inventory_ui() -> void:
	var items := inventory.keys()
	items.sort()
	if items.size() == 0:
		inventory_text.text = "Inventory: (empty)"
	else:
		inventory_text.text = "Inventory: " + ", ".join(items)

func _on_go_pressed() -> void:
	var first := slot1.token
	var second := slot2.token
	var third := slot3.token

	if first == "" or second == "":
		feedback_text.text = "Drag at least two words first."
		return

	var cmd: Array[String] = [first, second]
	if third != "":
		cmd.append(third)

	var transitioned := _apply_command(cmd)
	if not transitioned:
		slot2.clear()
		slot3.clear()

func _apply_command(cmd: Array[String]) -> bool:
	var scene = scenes.get(current_scene_id, null)
	var rules: Array = scene.get("commands", [])
	var default_responses: Array = scene.get("default", ["Nothing happens."])

	# Find first matching rule whose requirements pass
	for rule in rules:
		var pattern: Array = rule.get("pattern", [])
		if pattern.size() != cmd.size():
			continue

		var pattern_matches := true
		for i in pattern.size():
			if str(pattern[i]) != cmd[i]:
				pattern_matches = false
				break

		if not pattern_matches:
			continue

		if not _requirements_pass(rule.get("requirements", {})):
			# Requirements not met; treat as not matching (keep searching)
			continue

		# Matched
		var response = str(rule.get("response", "OK."))
		feedback_text.text = response

		_apply_effects(rule.get("effects", {}))
		_update_inventory_ui()

		if rule.has("next"):
			current_scene_id = str(rule["next"])
			_render_scene()
			return true
		else:
			# stay in same scene, keeping Slot1 (verb) for fast retries
			return false

	# No match
	feedback_text.text = str(default_responses[randi() % default_responses.size()])
	return false

func _requirements_pass(req: Dictionary) -> bool:
	# inventory_has: ["key"]
	var inv_has: Array = req.get("inventory_has", [])
	for item in inv_has:
		if not inventory.has(str(item)):
			return false

	# flags_true: ["box_open"]
	var flags_true: Array = req.get("flags_true", [])
	for fl in flags_true:
		if not flags.get(str(fl), false):
			return false

	return true

func _apply_effects(eff: Dictionary) -> void:
	var inv_add: Array = eff.get("inventory_add", [])
	for item in inv_add:
		inventory[str(item)] = true

	var inv_remove: Array = eff.get("inventory_remove", [])
	for item in inv_remove:
		inventory.erase(str(item))

	var flags_set: Dictionary = eff.get("flags_set", {})
	for k in flags_set.keys():
		flags[str(k)] = bool(flags_set[k])
