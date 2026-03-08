# res://scripts/Game.gd
# Commands accept 2 tokens from Slot1/Slot2 (action/item + thing).
# Rules match when pattern length equals command length and all tokens align in order.
# Story flow: discover JSON stories in res://stories/, let player choose from StoryPicker,
# then load the selected path when START is pressed. NewGameButton returns to picker.
extends Control

const STORIES_DIR := "res://stories"
const TILE_SCENE := preload("res://ui/Tile.tscn")
const ACTION_TOKENS: Array[String] = ["go", "open", "take", "look", "talk", "give", "climb"]
const STORY_FONT_MAX: int = 32
const STORY_FONT_MIN: int = 18
const STORY_FONT_STEP: int = 2
const EMOJI := {
	"key": "🗝️", "box": "📦", "door": "🚪", "rope": "🪢",
	"apple": "🍎", "treasure": "💎", "egg": "🥚",
	"forest": "🌲", "gate": "🏰", "tree": "🌳",
	"bridge": "🌉", "cave": "🕳️",
	"dog": "🐕", "dragon": "🐉",
	"go": "👉", "open": "📖", "take": "✋", "look": "👀",
	"talk": "💬", "give": "🎁", "climb": "🧗",
	"window": "🪟", "comic": "📕", "note": "📝", "fire": "🔥",
	"cat": "🐱", "rooftop": "🏢", "spiderdude": "🕷️", "web": "🕸️",
	"city": "🏙️", "lady": "👵", "bench": "🪑", "sign": "🪧",
	"book": "📗", "shelf": "📚", "potion": "🧪", "hammer": "🔨",
	"chain": "⛓️", "tunnel": "🚇", "torch": "🔦", "wall": "🧱",
	"tower": "🗼", "bike": "🏍️", "stairs": "🪜", "ghost": "👻",
	"home": "🏠", "library": "🏛️",
	"phone": "📱", "robot": "🤖", "bug": "🐛",
	"shield": "🛡️", "chip": "💾", "boss": "👾",
	"eggs": "🍳", "salt": "🧂", "plate": "🍽️",
	"lake": "🌊", "cliff": "🏔️", "crystal": "🔮",
}

const LOOK_FALLBACKS: Array[String] = [
	"You look at the {thing} really hard. Yep, still a {thing}!",
	"You stare at the {thing}. It does not do anything special.",
	"You squint at the {thing}. Hmm, looks pretty normal!",
	"You look at the {thing} from every angle. Nope, nothing new!",
	"The {thing} looks back at you. Wait, no it doesn't!",
]
const TALK_FALLBACKS: Array[String] = [
	"You say hello to the {thing}. It does not answer. Rude!",
	"You talk to the {thing}. It is very quiet. Not a great chat!",
	"Hey {thing}! ...Nothing. Not a good listener.",
	"You whisper to the {thing}. Shhhh. Still nothing!",
	"The {thing} has nothing to say. Maybe it is shy!",
]
const OPEN_FALLBACKS: Array[String] = [
	"You try to open the {thing}. It does not open!",
	"How do you open a {thing}? You can't! Nice try though!",
	"You pull and push the {thing}. Nope, it won't open!",
	"The {thing} is not something you can open, silly!",
	"You tug on the {thing}. Nope! It stays shut!",
]
const TAKE_FALLBACKS: Array[String] = [
	"You try to grab the {thing}. Nope, you can't take that!",
	"The {thing} is way too stuck! It won't budge!",
	"You reach for the {thing}. Your hands just slide right off!",
	"Take the {thing}? Where would you even put it?!",
	"You pull on the {thing} really hard. HNNNNG! Nope!",
]
const GO_FALLBACKS: Array[String] = [
	"You can't go to the {thing}! That's not a place!",
	"The {thing} is not somewhere you can go, silly!",
	"Go to a {thing}? Your feet say no!",
	"You walk toward the {thing}. Bonk! That didn't work!",
	"You can't go there right now!",
]
const GIVE_FALLBACKS: Array[String] = [
	"You hold out the {thing}. Nobody wants it right now!",
	"Give the {thing}? To who? Nobody is asking for it!",
	"You offer the {thing}. Nope! Not the right gift!",
	"The {thing} is not something anyone needs right now!",
	"You try to give away the {thing}. No takers! Sorry!",
]
const CLIMB_FALLBACKS: Array[String] = [
	"You try to climb the {thing}. It is not climbable!",
	"Climb the {thing}?! That would be really silly!",
	"You put your foot on the {thing}. Nope! Can't climb that!",
	"The {thing} is not for climbing!",
	"You hug the {thing} and try to shimmy up. Whoops! You slide off!",
]
const ITEM_AS_VERB_FALLBACKS: Array[String] = [
	"You wave the {item} at the {thing}. Nothing happens!",
	"You bonk the {thing} with the {item}. Nope! Not useful!",
	"You hold the {item} up to the {thing}. Hmm, nothing!",
	"The {item} and the {thing} don't go together!",
	"You poke the {thing} with the {item}. Boop! Nothing!",
]
const SAME_TOKEN_FALLBACKS: Array[String] = [
	"{thing} the {thing}? That makes no sense! Silly!",
	"{thing} {thing}? Nah, that's just being goofy!",
	"That's the same word twice! Try a new combo!",
	"Two {thing}s don't make a right! Mix it up!",
	"You can't {thing} a {thing}! Try something different!",
]

@onready var menu_screen: VBoxContainer = $ScrollContainer/Layout/MenuScreen
@onready var story_picker: OptionButton = $ScrollContainer/Layout/MenuScreen/StoryPicker
@onready var play_button: Button = $ScrollContainer/Layout/MenuScreen/PlayButton
@onready var new_game_button: Button = $ScrollContainer/Layout/NewGameButton
@onready var command_bar: HBoxContainer = $ScrollContainer/Layout/CommandBar
@onready var tile_section: VBoxContainer = $ScrollContainer/Layout/TileSection
@onready var story_text: Label = $ScrollContainer/Layout/StoryText
@onready var feedback_text: Label = $ScrollContainer/Layout/FeedbackText
@onready var action_tray: FlowContainer = $ScrollContainer/Layout/TileSection/ActionTray
@onready var thing_tray: FlowContainer = $ScrollContainer/Layout/TileSection/ThingTray
@onready var slot1: PanelContainer = $ScrollContainer/Layout/CommandBar/Slot1
@onready var slot2: PanelContainer = $ScrollContainer/Layout/CommandBar/Slot2
@onready var inventory_label: Label = $ScrollContainer/Layout/TileSection/InventoryLabel
@onready var inventory_tray: FlowContainer = $ScrollContainer/Layout/TileSection/InventoryTray
@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var continue_button: Button = $ScrollContainer/Layout/ContinueButton
@onready var version_label: Label = $ScrollContainer/Layout/MenuScreen/VersionLabel
@onready var teaser_label: Label = $ScrollContainer/Layout/MenuScreen/TeaserLabel
@onready var hint_button: Button = $ScrollContainer/Layout/HintButton
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var layout: VBoxContainer = $ScrollContainer/Layout

var story = {}
var scenes = {}
var current_scene_id = ""
var inventory = {} # token -> true
var flags = {}     # flag -> true/false
var discovered_stories: Array[Dictionary] = []
var selected_story_path := ""
var has_active_story := false
var is_transitioning := false
var fail_count: int = 0
var hint_index: int = 0
var action_fallback_map := {}

func _ready() -> void:
	action_fallback_map = {
		"look": LOOK_FALLBACKS, "talk": TALK_FALLBACKS, "open": OPEN_FALLBACKS,
		"take": TAKE_FALLBACKS, "go": GO_FALLBACKS, "give": GIVE_FALLBACKS,
		"climb": CLIMB_FALLBACKS,
	}

	var emoji_font := SystemFont.new()
	emoji_font.font_names = PackedStringArray(["Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji"])
	var fb: Font = ThemeDB.fallback_font
	if fb:
		var arr = fb.fallbacks.duplicate()
		arr.append(emoji_font)
		fb.fallbacks = arr

	var vf := FileAccess.open("res://version.txt", FileAccess.READ)
	if vf:
		version_label.text = "v" + vf.get_as_text().strip_edges()

	story_picker.item_selected.connect(_on_story_selected)
	play_button.pressed.connect(_on_start_pressed)
	new_game_button.pressed.connect(_on_menu_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	slot1.tile_dropped.connect(_check_slots_and_execute)
	slot2.tile_dropped.connect(_check_slots_and_execute)
	_discover_stories()
	_show_menu()

func _discover_stories() -> void:
	discovered_stories.clear()
	story_picker.clear()

	var dir := DirAccess.open(STORIES_DIR)
	if dir == null:
		feedback_text.text = "Story folder not found."
		play_button.disabled = true
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
		var info := _story_info(path, file_name)
		discovered_stories.append(info)
	dir.list_dir_end()

	discovered_stories.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("scene_count", 0)) < int(b.get("scene_count", 0))
	)

	for entry in discovered_stories:
		var label := "%s (%d scenes)" % [entry["display_name"], entry["scene_count"]]
		story_picker.add_item(label)

	if discovered_stories.is_empty():
		selected_story_path = ""
		play_button.disabled = true
		feedback_text.text = "No story files found in res://stories/."
		return

	play_button.disabled = false
	story_picker.select(0)
	_set_selected_story(0)

func _story_info(path: String, file_name: String) -> Dictionary:
	var fallback := file_name.get_basename()
	var info := {"path": path, "display_name": fallback, "teaser": "", "scene_count": 0}

	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return info

	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return info

	var meta = parsed.get("meta", {})
	if typeof(meta) == TYPE_DICTIONARY:
		var title = str(meta.get("title", "")).strip_edges()
		if title != "":
			info["display_name"] = title
		info["teaser"] = str(meta.get("teaser", ""))

	var story_scenes = parsed.get("scenes", {})
	if typeof(story_scenes) == TYPE_DICTIONARY:
		info["scene_count"] = story_scenes.size()

	return info

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
	menu_screen.visible = false
	command_bar.visible = true
	tile_section.visible = true
	feedback_text.visible = true
	new_game_button.visible = false
	await _render_scene()

func _show_menu() -> void:
	has_active_story = false
	menu_screen.visible = true
	command_bar.visible = false
	tile_section.visible = false
	feedback_text.visible = false
	new_game_button.visible = false
	continue_button.visible = false
	_reset_hints()
	story_text.text = ""
	story_text.add_theme_font_size_override("font_size", STORY_FONT_MAX)
	story_text.custom_minimum_size.y = STORY_FONT_MAX * 5
	for tray in [action_tray, thing_tray, inventory_tray]:
		for child in tray.get_children():
			child.queue_free()
	slot1.clear()
	slot2.clear()
	inventory.clear()
	flags.clear()

func _set_selected_story(index: int) -> void:
	if index < 0 or index >= discovered_stories.size():
		selected_story_path = ""
		teaser_label.text = ""
		return

	var entry: Dictionary = discovered_stories[index]
	selected_story_path = str(entry.get("path", ""))
	teaser_label.text = str(entry.get("teaser", ""))

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

	_reset_hints()

	# text
	var lines: Array = scene.get("text", [])
	story_text.text = "\n".join(lines)

	# clear feedback + command slots
	feedback_text.text = ""
	slot1.clear()
	slot2.clear()

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

	# Show "New Game" button only on terminal scenes (no outgoing transitions)
	var has_next := false
	for rule in scene.get("commands", []):
		if rule.has("next"):
			has_next = true
			break
	new_game_button.visible = not has_next
	await _auto_fit_story_text()

func _auto_fit_story_text() -> void:
	var font_size: int = STORY_FONT_MAX
	story_text.add_theme_font_size_override("font_size", font_size)
	story_text.custom_minimum_size.y = font_size * 5
	await get_tree().process_frame

	while font_size > STORY_FONT_MIN:
		if layout.size.y <= scroll_container.size.y:
			break
		font_size -= STORY_FONT_STEP
		story_text.add_theme_font_size_override("font_size", font_size)
		story_text.custom_minimum_size.y = font_size * 5
		await get_tree().process_frame

	scroll_container.scroll_vertical = 0

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
	elif cat == "thing":
		slot2.set_tile(tile.token, tile.text)
	elif cat == "inventory":
		if slot1.token == "":
			slot1.set_tile(tile.token, tile.text)
		else:
			slot2.set_tile(tile.token, tile.text)

	_check_slots_and_execute()

func _check_slots_and_execute() -> void:
	if not has_active_story or is_transitioning:
		return
	# Check if all visible required slots are filled
	if slot1.token == "" or slot2.token == "":
		return
	# All slots filled — brief delay then execute
	var scene_before: String = current_scene_id
	await get_tree().create_timer(0.5).timeout
	if current_scene_id != scene_before:
		return
	if not has_active_story or is_transitioning:
		return
	await _try_execute_command()

func _try_execute_command() -> void:
	var first: String = slot1.token
	var second: String = slot2.token

	if first == "" or second == "":
		return

	var cmd: Array[String] = [first, second]

	var transitioned := await _apply_command(cmd)
	if not transitioned:
		slot1.clear()
		slot2.clear()

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
		_reset_hints()
		var response = str(rule.get("response", "OK."))
		feedback_text.text = response

		_apply_effects(rule.get("effects", {}))

		if rule.has("next"):
			_transition_to_scene(str(rule["next"]))
			return true
		else:
			# stay in same scene — re-render tiles so inventory moves between trays
			await _render_scene()
			feedback_text.text = response
			return false

	# No match — try smart fallback, then random default
	fail_count += 1
	if fail_count >= 6:
		var scene_hints: Array = scene.get("hints", [])
		if not scene_hints.is_empty():
			hint_button.visible = true
	var smart: String = _get_smart_fallback(cmd)
	if smart != "":
		feedback_text.text = smart
	else:
		feedback_text.text = str(default_responses[randi() % default_responses.size()])
	return false

func _classify_token(token: String) -> String:
	if token in ACTION_TOKENS:
		return "action"
	if inventory.has(token):
		return "inventory"
	return "thing"

func _get_smart_fallback(cmd: Array[String]) -> String:
	var t1: String = cmd[0]
	var t2: String = cmd[1]

	# Same token in both slots
	if t1 == t2:
		var msg: String = SAME_TOKEN_FALLBACKS[randi() % SAME_TOKEN_FALLBACKS.size()]
		return msg.replace("{thing}", t1)

	var cat1: String = _classify_token(t1)

	# Action verb in slot1 → action-specific fallback
	if cat1 == "action" and action_fallback_map.has(t1):
		var templates: Array = action_fallback_map[t1]
		var msg: String = templates[randi() % templates.size()]
		return msg.replace("{action}", t1).replace("{thing}", t2)

	# Inventory item used as verb in slot1
	if cat1 == "inventory":
		var msg: String = ITEM_AS_VERB_FALLBACKS[randi() % ITEM_AS_VERB_FALLBACKS.size()]
		return msg.replace("{item}", t1).replace("{thing}", t2)

	return ""

func _transition_to_scene(scene_id: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	# Brief pause so kid notices the response text
	await get_tree().create_timer(1.0).timeout

	# Show continue button and wait for kid to tap it
	continue_button.visible = true
	await continue_button.pressed
	continue_button.visible = false

	# Fade to black
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 1.0, 0.3)
	await tween.finished

	# Change scene content
	current_scene_id = scene_id
	await _render_scene()

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

func _reset_hints() -> void:
	fail_count = 0
	hint_index = 0
	hint_button.visible = false

func _on_hint_pressed() -> void:
	if not has_active_story or is_transitioning:
		return
	var scene = scenes.get(current_scene_id, null)
	if scene == null:
		return
	var hints: Array = scene.get("hints", [])
	if hints.is_empty():
		return
	feedback_text.text = str(hints[hint_index])
	if hint_index < hints.size() - 1:
		hint_index += 1
