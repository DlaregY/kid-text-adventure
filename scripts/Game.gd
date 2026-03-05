# res://scripts/Game.gd
# Commands now accept 2 or 3 tokens from Slot1/Slot2[/Slot3].
# Rules match only when pattern length equals command length and all tokens align in order.
# Story flow: discover JSON stories in res://stories/, let player choose from StoryPicker,
# then load the selected path when START is pressed. MenuButton returns to picker.
extends Control

const STORIES_DIR := "res://stories"
const TILE_SCENE := preload("res://ui/Tile.tscn")
const ACTION_TOKENS: Array[String] = ["go", "open", "take", "look", "talk", "give", "climb", "use"]
const EMOJI := {
	"key": "🗝️", "box": "📦", "door": "🚪", "rope": "🪢",
	"apple": "🍎", "treasure": "💎", "egg": "🥚",
	"forest": "🌲", "gate": "🏰", "tree": "🌳",
	"bridge": "🌉", "cave": "🕳️",
	"dog": "🐕", "dragon": "🐉",
	"go": "👉", "open": "📖", "take": "✋", "look": "👀",
	"talk": "💬", "give": "🎁", "climb": "🧗", "use": "🔧",
	"window": "🪟", "comic": "📕", "note": "📝", "fire": "🔥",
	"cat": "🐱", "rooftop": "🏢", "spiderman": "🕷️", "web": "🕸️",
	"city": "🏙️", "lady": "👵", "bench": "🪑", "sign": "🪧",
	"book": "📗", "shelf": "📚", "potion": "🧪", "hammer": "🔨",
	"chain": "⛓️", "tunnel": "🚇", "torch": "🔦", "wall": "🧱",
	"tower": "🗼", "bike": "🏍️", "stairs": "🪜", "ghost": "👻",
	"home": "🏠", "library": "🏛️",
}

@onready var menu_bar: HBoxContainer = $ScrollContainer/Layout/MenuBar
@onready var story_picker: OptionButton = $ScrollContainer/Layout/MenuBar/StoryPicker
@onready var start_button: Button = $ScrollContainer/Layout/MenuBar/StartButton
@onready var story_title: Label = $ScrollContainer/Layout/MenuBar/StoryTitle
@onready var menu_button: Button = $MenuButton
@onready var story_text: Label = $ScrollContainer/Layout/StoryText
@onready var feedback_text: Label = $ScrollContainer/Layout/FeedbackText
@onready var action_tray: FlowContainer = $ScrollContainer/Layout/TileSection/ActionTray
@onready var thing_tray: FlowContainer = $ScrollContainer/Layout/TileSection/ThingTray
@onready var slot1: PanelContainer = $ScrollContainer/Layout/CommandBar/Slot1
@onready var slot2: PanelContainer = $ScrollContainer/Layout/CommandBar/Slot2
@onready var slot3: PanelContainer = $ScrollContainer/Layout/CommandBar/Slot3
@onready var inventory_label: Label = $ScrollContainer/Layout/TileSection/InventoryLabel
@onready var inventory_tray: FlowContainer = $ScrollContainer/Layout/TileSection/InventoryTray
@onready var transition_overlay: ColorRect = $TransitionOverlay

var story = {}
var scenes = {}
var current_scene_id = ""
var inventory = {} # token -> true
var flags = {}     # flag -> true/false
var discovered_stories: Array[Dictionary] = []
var selected_story_path := ""
var has_active_story := false
var is_transitioning := false

func _ready() -> void:
	var emoji_font := SystemFont.new()
	emoji_font.font_names = PackedStringArray(["Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji"])
	var fb: Font = ThemeDB.fallback_font
	if fb:
		var arr = fb.fallbacks.duplicate()
		arr.append(emoji_font)
		fb.fallbacks = arr

	story_picker.item_selected.connect(_on_story_selected)
	start_button.pressed.connect(_on_start_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	slot1.tile_dropped.connect(_check_slots_and_execute)
	slot2.tile_dropped.connect(_check_slots_and_execute)
	slot3.tile_dropped.connect(_check_slots_and_execute)
	menu_button.visible = false

	_discover_stories()
	_show_menu()

func _discover_stories() -> void:
	discovered_stories.clear()
	story_picker.clear()

	var dir := DirAccess.open(STORIES_DIR)
	if dir == null:
		feedback_text.text = "Story folder not found."
		start_button.disabled = true
		story_title.text = "No stories found"
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".json"):
			continue
		if file_name == "index.json":
			continue

		var path := "%s/%s" % [STORIES_DIR, file_name]
		var display_name := _story_display_name(path, file_name)
		discovered_stories.append({
			"path": path,
			"display_name": display_name,
		})
	dir.list_dir_end()

	discovered_stories.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", "")).nocasecmp_to(str(b.get("display_name", ""))) < 0
	)

	for entry in discovered_stories:
		story_picker.add_item(str(entry["display_name"]))

	if discovered_stories.is_empty():
		selected_story_path = ""
		start_button.disabled = true
		story_title.text = "No stories found"
		feedback_text.text = "No story files found in res://stories/."
		return

	start_button.disabled = false
	story_picker.select(0)
	_set_selected_story(0)

func _story_display_name(path: String, file_name: String) -> String:
	var fallback := file_name.get_basename()
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return fallback

	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return fallback

	var meta = parsed.get("meta", {})
	if typeof(meta) == TYPE_DICTIONARY:
		var title = str(meta.get("title", "")).strip_edges()
		if title != "":
			return title

	return fallback

func _load_story(path: String) -> bool:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Could not open story file: " + path)
		feedback_text.text = "Couldn't open selected story."
		return false

	var json_text = f.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON in story file.")
		feedback_text.text = "Selected story has invalid JSON."
		return false

	story = parsed
	scenes = story.get("scenes", {})
	current_scene_id = story.get("start_scene", "")
	if current_scene_id == "":
		push_error("No start_scene set in story JSON.")
		feedback_text.text = "Selected story is missing start scene."
		return false

	return true

func _start_story() -> void:
	inventory.clear()
	flags.clear()
	has_active_story = true
	_render_scene()
	menu_bar.visible = false
	menu_button.visible = false

func _show_menu() -> void:
	has_active_story = false
	menu_bar.visible = true
	menu_button.visible = false
	story_text.text = "Choose a story, then press START."
	feedback_text.text = ""
	for tray in [action_tray, thing_tray, inventory_tray]:
		for child in tray.get_children():
			child.queue_free()
	slot1.clear()
	slot2.clear()
	slot3.clear()
	slot3.visible = false
	inventory.clear()
	flags.clear()
	_update_inventory_ui()

func _set_selected_story(index: int) -> void:
	if index < 0 or index >= discovered_stories.size():
		selected_story_path = ""
		story_title.text = "No stories found"
		return

	var entry: Dictionary = discovered_stories[index]
	selected_story_path = str(entry.get("path", ""))
	story_title.text = str(entry.get("display_name", ""))

func _on_story_selected(index: int) -> void:
	_set_selected_story(index)

func _on_start_pressed() -> void:
	if selected_story_path == "":
		feedback_text.text = "Please choose a story first."
		return

	if not _load_story(selected_story_path):
		return

	_start_story()

func _on_menu_pressed() -> void:
	_show_menu()

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
	slot3.visible = _scene_has_3word_commands(scene)

	# tiles — split into actions, things, and inventory
	for tray in [action_tray, thing_tray, inventory_tray]:
		for child in tray.get_children():
			child.queue_free()

	var tiles: Array = scene.get("tiles", [])
	for t in tiles:
		var token_str: String = str(t)
		if token_str in ACTION_TOKENS:
			action_tray.add_child(_make_tile(token_str, Color(0.357, 0.608, 0.835), "action"))
		elif inventory.has(token_str):
			inventory_tray.add_child(_make_tile(token_str, Color(0.85, 0.65, 0.13), "inventory"))
		else:
			thing_tray.add_child(_make_tile(token_str, Color(0.357, 0.608, 0.835), "thing"))

	# Add inventory items not in this scene's tile list
	for item in inventory.keys():
		var item_str: String = str(item)
		if item_str not in tiles:
			inventory_tray.add_child(_make_tile(item_str, Color(0.85, 0.65, 0.13), "inventory"))

	_update_inventory_ui()

	# Show "Change Story" button only on terminal scenes (no outgoing transitions)
	var has_next := false
	for rule in scene.get("commands", []):
		if rule.has("next"):
			has_next = true
			break
	menu_button.visible = not has_next

func _update_inventory_ui() -> void:
	var has_items: bool = inventory_tray.get_child_count() > 0
	inventory_label.visible = has_items
	inventory_tray.visible = has_items

func _make_tile(token_str: String, color: Color = Color(0.357, 0.608, 0.835), cat: String = "thing") -> Button:
	var tile = TILE_SCENE.instantiate()
	tile.token = token_str
	tile.category = cat
	var icon: String = EMOJI.get(token_str, "")
	tile.text = (icon + " " + token_str) if icon != "" else token_str
	if color != Color(0.357, 0.608, 0.835):
		tile.tile_color = color
		var normal := StyleBoxFlat.new()
		normal.bg_color = color
		normal.set_corner_radius_all(8)
		normal.content_margin_left = 16
		normal.content_margin_right = 16
		normal.content_margin_top = 12
		normal.content_margin_bottom = 12
		var hover := normal.duplicate()
		hover.bg_color = Color(0.92, 0.75, 0.25)
		var pressed := normal.duplicate()
		pressed.bg_color = Color(0.70, 0.53, 0.10)
		tile.add_theme_stylebox_override("normal", normal)
		tile.add_theme_stylebox_override("hover", hover)
		tile.add_theme_stylebox_override("pressed", pressed)
	tile.pressed.connect(_on_tile_pressed.bind(tile))
	return tile

func _on_tile_pressed(tile: Button) -> void:
	if not has_active_story or is_transitioning:
		return

	var cat: String = tile.category
	if cat == "action":
		slot1.set_tile(tile.token, tile.text)
	elif cat == "thing" or cat == "inventory":
		if slot2.token == "":
			slot2.set_tile(tile.token, tile.text)
		elif slot3.visible and slot3.token == "":
			slot3.set_tile(tile.token, tile.text)
		else:
			slot2.set_tile(tile.token, tile.text)

	_check_slots_and_execute()

func _check_slots_and_execute() -> void:
	if not has_active_story or is_transitioning:
		return
	# Check if all visible required slots are filled
	if slot1.token == "" or slot2.token == "":
		return
	if slot3.visible and slot3.token == "":
		return
	# All slots filled — brief delay then execute
	var scene_before := current_scene_id
	await get_tree().create_timer(0.5).timeout
	if current_scene_id != scene_before:
		return
	if not has_active_story or is_transitioning:
		return
	_try_execute_command()

func _try_execute_command() -> void:
	var first: String = slot1.token
	var second: String = slot2.token
	var third: String = slot3.token

	if first == "" or second == "":
		return

	var cmd: Array[String] = [first, second]
	if third != "":
		cmd.append(third)

	var transitioned := _apply_command(cmd)
	if not transitioned:
		slot1.clear()
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

		if rule.has("next"):
			_transition_to_scene(str(rule["next"]))
			return true
		else:
			# stay in same scene — re-render tiles so inventory moves between trays
			_render_scene()
			feedback_text.text = response
			return false

	# No match
	feedback_text.text = str(default_responses[randi() % default_responses.size()])
	return false

func _transition_to_scene(scene_id: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	# Response text is already visible — wait for kid to read it
	await get_tree().create_timer(2.5).timeout

	# Fade to black
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 1.0, 0.3)
	await tween.finished

	# Change scene content
	current_scene_id = scene_id
	_render_scene()

	# Fade back in
	var tween2 := create_tween()
	tween2.tween_property(transition_overlay, "color:a", 0.0, 0.3)
	await tween2.finished

	is_transitioning = false

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

func _scene_has_3word_commands(scene: Dictionary) -> bool:
	var commands: Array = scene.get("commands", [])
	for rule in commands:
		var pattern: Array = rule.get("pattern", [])
		if pattern.size() >= 3:
			return true
	return false

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
