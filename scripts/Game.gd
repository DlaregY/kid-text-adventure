# res://scripts/Game.gd
# Commands accept 2 tokens from Slot1/Slot2 (action/item + thing).
# Rules match when pattern length equals command length and all tokens align in order.
# Story flow: discover JSON stories in res://stories/, let player choose from StoryPicker,
# then load the selected path when START is pressed. NewGameButton returns to picker.
extends Control

const STORIES_DIR := "res://stories"
const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const PROGRESS_PATH := "user://progress.json"
const SETTINGS_PATH := "user://settings.json"
const SFX := {
	"tap": preload("res://assets/sfx/tap.wav"),
	"next": preload("res://assets/sfx/next.wav"),
	"success": preload("res://assets/sfx/success.wav"),
	"fail": preload("res://assets/sfx/fail.wav"),
	"whoosh": preload("res://assets/sfx/whoosh.wav"),
	"fanfare": preload("res://assets/sfx/fanfare.wav"),
}
const TOP_BAR_HEIGHT: float = 56.0
const BOTTOM_BAR_HEIGHT: float = 184.0
const CONTINUE_BAR_HEIGHT: float = 104.0
const TILE_BLUE := Color(0.357, 0.608, 0.835)
const TILE_GOLD := Color(0.85, 0.65, 0.13)
# Feedback sits on the dark gray game background, so these are light tints.
const FEEDBACK_NEUTRAL := Color(0.95, 0.92, 0.85)
const FEEDBACK_SUCCESS := Color(0.55, 0.95, 0.55)
const FEEDBACK_FAIL := Color(1.0, 0.6, 0.5)
const TILE_SCENE := preload("res://ui/Tile.tscn")
const ACTION_TOKENS: Array[String] = ["go", "open", "take", "look", "talk", "give", "climb"]
const STORY_FONT_MAX: int = 32
const STORY_FONT_MIN: int = 18
const STORY_FONT_STEP: int = 2
const STORY_MIN_HEIGHT_LINES: int = 3 # reserved story height = font_size * this
const HINT_FAIL_THRESHOLD: int = 4
const IDLE_HINT_SECONDS: float = 40.0
const TYPEWRITER_CHARS_PER_SECOND: float = 60.0
const FONT_REGULAR := preload("res://assets/fonts/Andika-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/Andika-Bold.ttf")
const DEFAULT_BACKGROUND := Color(0.3, 0.3, 0.3)
const MOODS := {
	"night": Color(0.11, 0.13, 0.26), "forest": Color(0.1, 0.21, 0.13), "cave": Color(0.14, 0.11, 0.2),
	"fire": Color(0.32, 0.11, 0.08), "day": Color(0.16, 0.27, 0.38), "digital": Color(0.08, 0.13, 0.22),
	"kitchen": Color(0.3, 0.22, 0.1), "salt": Color(0.3, 0.31, 0.35), "crystal": Color(0.2, 0.11, 0.32),
	"win": Color(0.27, 0.21, 0.06),
}
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
	"lake": "🌊", "cliff": "🏔️", "crystal": "🔮", "rock": "🪨", "river": "🏞️",
	"camp": "⛺", "tent": "⛺", "bushes": "🌿", "snack": "🍪",
	"tracks": "👣", "creek": "🏞️", "bigfoot": "🦶",
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
@onready var story_list: VBoxContainer = $ScrollContainer/Layout/MenuScreen/StoryList
@onready var bottom_bar: VBoxContainer = $BottomBar
@onready var play_button: Button = $BottomBar/PlayButton
@onready var resume_button: Button = $BottomBar/ResumeButton
@onready var about_button: Button = $ScrollContainer/Layout/MenuScreen/AboutButton
@onready var about_dialog: Control = $AboutDialog
@onready var about_close: Button = $AboutDialog/Center/Panel/Box/AboutClose
@onready var about_version: Label = $AboutDialog/Center/Panel/Box/AboutVersion
@onready var top_bar: HBoxContainer = $TopBar
@onready var home_button: Button = $TopBar/HomeButton
@onready var speak_button: Button = $TopBar/SpeakButton
@onready var sfx_player: AudioStreamPlayer = $Sfx
@onready var read_aloud_toggle: CheckButton = $AboutDialog/Center/Panel/Box/ReadAloudToggle
@onready var sound_toggle: CheckButton = $AboutDialog/Center/Panel/Box/SoundToggle
@onready var stop_dialog: Control = $StopDialog
@onready var keep_button: Button = $StopDialog/Center/Panel/Box/KeepButton
@onready var stop_menu_button: Button = $StopDialog/Center/Panel/Box/StopMenuButton
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
@onready var continue_bar: Control = $ContinueBar
@onready var continue_button: Button = $ContinueBar/ContinueButton
@onready var version_label: Label = $ScrollContainer/Layout/MenuScreen/VersionLabel
@onready var hint_button: Button = $ScrollContainer/Layout/HintButton
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var layout: VBoxContainer = $ScrollContainer/Layout
@onready var background: ColorRect = $Background
@onready var timer_bar: ProgressBar = $ScrollContainer/Layout/TimerBar
@onready var ending_badge: PanelContainer = $ScrollContainer/Layout/EndingBadge
@onready var ending_label: Label = $ScrollContainer/Layout/EndingBadge/EndingLabel

var story = {}
var scenes = {}
var current_scene_id = ""
var inventory = {} # token -> true
var flags = {}     # flag -> true/false
var discovered_stories: Array[Dictionary] = []
var selected_story_path := ""
var selected_story_index: int = -1
var story_cards: Array[PanelContainer] = [] # visual card; sizes to its content
var card_buttons: Array[Button] = [] # invisible full-card tap target, parallel to story_cards
var loaded_story_path := "" # path of the story currently in `story`; the save keys off this, not the picker
var has_active_story := false
var is_transitioning := false
var fail_count: int = 0
var hint_index: int = 0
var action_fallback_map := {}
var command_timer := Timer.new()
var is_executing_command := false
var story_generation: int = 0 # bumped whenever a story starts or stops; stale coroutines check it
var continue_pressed := false
var idle_timer := Timer.new()
var reveal_tween: Tween
var settings := {"read_aloud": false, "sound": true}
var last_sfx := "" # name of the most recent effect actually played (for tests)
var tts_voice := "" # chosen system voice id, "" when the device has none
var pending_scene_id := "" # destination of a transition whose Continue tap has not happened yet; saves point here

func _ready() -> void:
	command_timer.one_shot = true
	command_timer.wait_time = 0.5
	command_timer.timeout.connect(_try_execute_command)
	add_child(command_timer)

	action_fallback_map = {
		"look": LOOK_FALLBACKS, "talk": TALK_FALLBACKS, "open": OPEN_FALLBACKS,
		"take": TAKE_FALLBACKS, "go": GO_FALLBACKS, "give": GIVE_FALLBACKS,
		"climb": CLIMB_FALLBACKS,
	}

	_apply_reader_font()

	idle_timer.one_shot = true
	idle_timer.wait_time = IDLE_HINT_SECONDS
	idle_timer.timeout.connect(_on_idle_timeout)
	add_child(idle_timer)
	story_text.gui_input.connect(_on_story_text_input)

	var vf := FileAccess.open("res://version.txt", FileAccess.READ)
	if vf:
		version_label.text = "v" + vf.get_as_text().strip_edges()
		about_version.text = version_label.text

	about_button.pressed.connect(func() -> void: about_dialog.visible = true)
	_load_settings()
	read_aloud_toggle.button_pressed = bool(settings["read_aloud"])
	sound_toggle.button_pressed = bool(settings["sound"])
	read_aloud_toggle.toggled.connect(func(on: bool) -> void: settings["read_aloud"] = on; _save_settings())
	sound_toggle.toggled.connect(func(on: bool) -> void: settings["sound"] = on; _save_settings())
	speak_button.pressed.connect(_on_speak_pressed)
	continue_button.pressed.connect(func() -> void: _play_sfx("next"))
	_pick_tts_voice()
	about_close.pressed.connect(func() -> void: about_dialog.visible = false)
	play_button.pressed.connect(_on_start_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	home_button.pressed.connect(_show_stop_dialog)
	keep_button.pressed.connect(_hide_stop_dialog)
	stop_menu_button.pressed.connect(_on_stop_confirmed)
	new_game_button.pressed.connect(_on_menu_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	continue_button.pressed.connect(func() -> void: continue_pressed = true)
	slot1.tile_dropped.connect(_check_slots_and_execute)
	slot2.tile_dropped.connect(_check_slots_and_execute)
	slot1.tapped.connect(_on_slot_tapped.bind(slot1))
	slot2.tapped.connect(_on_slot_tapped.bind(slot2))
	feedback_text.add_theme_color_override("font_color", FEEDBACK_NEUTRAL)
	_discover_stories()
	_show_menu()

# --- Settings, sound effects, and read-aloud.

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for key in settings.keys():
		if parsed.has(key) and typeof(parsed[key]) == TYPE_BOOL:
			settings[key] = parsed[key]

func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write settings file: " + SETTINGS_PATH)
		return
	f.store_string(JSON.stringify(settings))

func _exit_tree() -> void:
	# Release any in-flight playback so the audio server holds nothing after the game is freed.
	sfx_player.stop()
	if tts_voice != "":
		DisplayServer.tts_stop()

func _play_sfx(name: String) -> void:
	if not bool(settings["sound"]) or not SFX.has(name):
		return
	last_sfx = name
	if AudioServer.get_driver_name() == "Dummy":
		return # headless/no-audio runs: record the trigger without starting a playback that never ends
	sfx_player.stream = SFX[name]
	sfx_player.play()

func _pick_tts_voice() -> void:
	tts_voice = ""
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language("en")
	if voices.is_empty():
		var all_voices: Array = DisplayServer.tts_get_voices()
		if not all_voices.is_empty():
			voices.append(str(all_voices[0].get("id", "")))
	if not voices.is_empty() and voices[0] != "":
		tts_voice = voices[0]

func _speak(text: String) -> bool:
	if tts_voice == "" or text.strip_edges() == "":
		return false
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, tts_voice, 80, 1.0, 0.9)
	return true

func _on_speak_pressed() -> void:
	if not has_active_story:
		return
	if tts_voice != "" and DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
		return
	var parts: Array[String] = []
	if ending_badge.visible:
		parts.append(ending_label.text)
	parts.append(story_text.text)
	if feedback_text.text != "":
		parts.append(feedback_text.text)
	if not _speak(". ".join(parts)):
		_show_feedback("This phone has no reading voice.", "neutral")

func _on_tile_long_pressed(tile: Button) -> void:
	if _input_blocked():
		return
	_bounce_tile(tile)
	_speak(_label_for(tile.token))

func _apply_reader_font() -> void:
	# Andika (SIL OFL) is drawn for beginning readers; emoji fall back to the OS colour font.
	var emoji_font := SystemFont.new()
	emoji_font.font_names = PackedStringArray(["Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji"])
	var regular: FontFile = FONT_REGULAR.duplicate()
	regular.fallbacks = [emoji_font]
	var bold: FontFile = FONT_BOLD.duplicate()
	bold.fallbacks = [emoji_font]
	var app_theme := Theme.new()
	app_theme.default_font = regular
	app_theme.set_font("font", "Button", bold)
	theme = app_theme
	var fb: Font = ThemeDB.fallback_font
	if fb:
		var arr = fb.fallbacks.duplicate()
		arr.append(emoji_font)
		fb.fallbacks = arr

func _set_mood(mood_value: Variant) -> void:
	var target := DEFAULT_BACKGROUND
	var mood := str(mood_value).strip_edges()
	if MOODS.has(mood):
		target = MOODS[mood]
	elif mood.begins_with("#") and Color.html_is_valid(mood):
		target = Color.html(mood)
	if background.color == target:
		return
	var tween := create_tween()
	tween.tween_property(background, "color", target, 0.4)

func _reveal_story_text() -> void:
	if reveal_tween and reveal_tween.is_valid():
		reveal_tween.kill()
	var total: int = story_text.get_total_character_count()
	if total <= 0:
		story_text.visible_characters = -1
		return
	story_text.visible_characters = 0
	reveal_tween = create_tween()
	reveal_tween.tween_property(story_text, "visible_characters", total, total / TYPEWRITER_CHARS_PER_SECOND)
	reveal_tween.tween_callback(func() -> void: story_text.visible_characters = -1)

func _finish_reveal() -> void:
	if reveal_tween and reveal_tween.is_valid():
		reveal_tween.kill()
	story_text.visible_characters = -1

func _on_story_text_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_reveal()

func _restart_idle_timer() -> void:
	idle_timer.stop()
	if has_active_story:
		idle_timer.start()

func _on_idle_timeout() -> void:
	if not has_active_story or is_transitioning or stop_dialog.visible:
		return
	var scene: Dictionary = scenes.get(current_scene_id, {})
	var hints: Array = scene.get("hints", [])
	if not hints.is_empty():
		hint_button.visible = true

func _process(_delta: float) -> void:
	var running: bool = not command_timer.is_stopped()
	timer_bar.visible = running
	if running:
		timer_bar.value = command_timer.time_left / command_timer.wait_time

func _on_slot_tapped(slot: PanelContainer) -> void:
	if _input_blocked() or slot.token == "":
		return
	slot.clear()
	command_timer.stop()

func _discover_stories() -> void:
	discovered_stories.clear()
	for card in story_cards:
		story_list.remove_child(card)
		card.free()
	story_cards.clear()
	card_buttons.clear()

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
		if int(a.get("order", 0)) != int(b.get("order", 0)):
			return int(a.get("order", 0)) < int(b.get("order", 0))
		return int(a.get("scene_count", 0)) < int(b.get("scene_count", 0))
	)

	for i in range(discovered_stories.size()):
		var card := _make_story_card(discovered_stories[i], i)
		story_list.add_child(card)
		story_cards.append(card)
		card_buttons.append(card.get_node("Tap") as Button)

	if discovered_stories.is_empty():
		selected_story_path = ""
		play_button.disabled = true
		feedback_text.text = "No story files found in res://stories/."
		return

	play_button.disabled = false
	_set_selected_story(0)

func _story_info(path: String, file_name: String) -> Dictionary:
	var fallback := file_name.get_basename()
	var info := {"path": path, "display_name": fallback, "teaser": "", "scene_count": 0, "cover": "📖", "order": 999}

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
		var cover := str(meta.get("cover", "")).strip_edges()
		if cover != "":
			info["cover"] = cover
		if meta.has("order"):
			info["order"] = int(meta.get("order"))

	var story_scenes = parsed.get("scenes", {})
	if typeof(story_scenes) == TYPE_DICTIONARY:
		info["scene_count"] = story_scenes.size()
		var ending_ids: Array[String] = []
		for scene in story_scenes.values():
			if typeof(scene) == TYPE_DICTIONARY and typeof(scene.get("ending", null)) == TYPE_DICTIONARY:
				var eid := str(scene["ending"].get("id", "")).strip_edges()
				if eid != "" and eid not in ending_ids:
					ending_ids.append(eid)
		info["ending_ids"] = ending_ids

	return info

# --- Endings collection: which endings each story has reached, kept across sessions.

func _story_key(path: String) -> String:
	return path.get_file().get_basename()

func _read_progress() -> Dictionary:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return {}
	var f := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _found_endings(path: String) -> Array:
	var found = _read_progress().get(_story_key(path), [])
	return found if typeof(found) == TYPE_ARRAY else []

func _record_ending(path: String, ending_id: String) -> void:
	var progress: Dictionary = _read_progress()
	var key := _story_key(path)
	var found: Array = progress.get(key, []) if typeof(progress.get(key, [])) == TYPE_ARRAY else []
	if ending_id in found:
		return
	found.append(ending_id)
	progress[key] = found
	var f := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write progress file: " + PROGRESS_PATH)
		return
	f.store_string(JSON.stringify(progress))

func _clear_progress() -> void:
	if FileAccess.file_exists(PROGRESS_PATH):
		DirAccess.remove_absolute(PROGRESS_PATH)

func _endings_badge_text(entry: Dictionary) -> String:
	var ids: Array = entry.get("ending_ids", [])
	if ids.is_empty():
		return ""
	var found: int = 0
	for eid in _found_endings(str(entry.get("path", ""))):
		if str(eid) in ids:
			found += 1
	if ids.size() == 1:
		return "⭐ Finished" if found == 1 else ""
	return "⭐ %d of %d endings" % [found, ids.size()]

func _refresh_card_badges() -> void:
	for i in range(story_cards.size()):
		var badge: Label = story_cards[i].get_node_or_null("Row/Col/Badge")
		if badge == null:
			continue
		var entry: Dictionary = discovered_stories[i]
		var count: int = int(entry.get("scene_count", 0))
		var text := "%s · %d scenes" % [_length_badge(count), count]
		var endings := _endings_badge_text(entry)
		if endings != "":
			text += "   " + endings
		badge.text = text

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

	var validation: Dictionary = _validate_story(parsed)
	if not bool(validation.get("ok", false)):
		var validation_errors: Array = validation.get("errors", [])
		for err in validation_errors:
			push_error("Story validation failed (%s): %s" % [path, str(err)])
		feedback_text.text = "This story file has setup issues and can't be started. Please choose another story."
		return false

	story = parsed
	scenes = story.get("scenes", {})
	loaded_story_path = path
	current_scene_id = story.get("start_scene", "")
	if current_scene_id == "":
		push_error("No start_scene set in story JSON.")
		feedback_text.text = "Selected story is missing start scene."
		return false

	return true

func _validate_story(story_data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var story_scenes = story_data.get("scenes", null)
	var start_scene = story_data.get("start_scene", null)

	if typeof(story_scenes) != TYPE_DICTIONARY:
		errors.append("`scenes` must be a dictionary.")
		return {"ok": false, "errors": errors}

	if typeof(start_scene) != TYPE_STRING or str(start_scene).strip_edges() == "":
		errors.append("`start_scene` must be a non-empty string.")
	elif not story_scenes.has(start_scene):
		errors.append("`start_scene` references missing scene: `%s`." % str(start_scene))

	for scene_id in story_scenes.keys():
		var scene = story_scenes.get(scene_id, null)
		var scene_name: String = str(scene_id)
		if typeof(scene) != TYPE_DICTIONARY:
			errors.append("Scene `%s` must be a dictionary." % scene_name)
			continue

		if typeof(scene.get("text", null)) != TYPE_ARRAY:
			errors.append("Scene `%s` has invalid `text` (expected array)." % scene_name)
		if typeof(scene.get("tiles", null)) != TYPE_ARRAY:
			errors.append("Scene `%s` has invalid `tiles` (expected array)." % scene_name)
		if typeof(scene.get("commands", null)) != TYPE_ARRAY:
			errors.append("Scene `%s` has invalid `commands` (expected array)." % scene_name)
		if typeof(scene.get("default", null)) != TYPE_ARRAY:
			errors.append("Scene `%s` has invalid `default` (expected array)." % scene_name)

		if scene.has("hints") and typeof(scene.get("hints", null)) != TYPE_ARRAY:
			errors.append("Scene `%s` has invalid `hints` (expected array when present)." % scene_name)
		if scene.has("ending"):
			var ending = scene.get("ending", null)
			if typeof(ending) != TYPE_DICTIONARY or str(ending.get("id", "")).strip_edges() == "":
				errors.append("Scene `%s` has invalid `ending` (expected {id, title})." % scene_name)

		var commands = scene.get("commands", [])
		if typeof(commands) == TYPE_ARRAY:
			for i in range(commands.size()):
				var command = commands[i]
				if typeof(command) != TYPE_DICTIONARY:
					errors.append("Scene `%s` command #%d must be a dictionary." % [scene_name, i])
					continue

				var pattern = command.get("pattern", null)
				if typeof(pattern) != TYPE_ARRAY or pattern.size() != 2:
					errors.append("Scene `%s` command #%d has invalid `pattern` (expected 2 tokens)." % [scene_name, i])
				else:
					for token in pattern:
						if typeof(token) != TYPE_STRING:
							errors.append("Scene `%s` command #%d has non-string token in `pattern`." % [scene_name, i])
							break

				if typeof(command.get("response", null)) != TYPE_STRING:
					errors.append("Scene `%s` command #%d has invalid `response` (expected string)." % [scene_name, i])

				if command.has("next"):
					var next_scene = command.get("next", null)
					if typeof(next_scene) != TYPE_STRING or next_scene.strip_edges() == "":
						errors.append("Scene `%s` command #%d has invalid `next` (expected non-empty string)." % [scene_name, i])
					elif not story_scenes.has(next_scene):
						errors.append("Scene `%s` command #%d points to missing next scene `%s`." % [scene_name, i, next_scene])

				if command.has("requirements"):
					var reqs = command.get("requirements", null)
					if typeof(reqs) != TYPE_DICTIONARY:
						errors.append("Scene `%s` command #%d has invalid `requirements` (expected dictionary when present)." % [scene_name, i])
					else:
						if reqs.has("inventory_has") and typeof(reqs.get("inventory_has", null)) != TYPE_ARRAY:
							errors.append("Scene `%s` command #%d has invalid `requirements.inventory_has` (expected array)." % [scene_name, i])
						if reqs.has("flags_true") and typeof(reqs.get("flags_true", null)) != TYPE_ARRAY:
							errors.append("Scene `%s` command #%d has invalid `requirements.flags_true` (expected array)." % [scene_name, i])

				if command.has("effects"):
					var effects = command.get("effects", null)
					if typeof(effects) != TYPE_DICTIONARY:
						errors.append("Scene `%s` command #%d has invalid `effects` (expected dictionary when present)." % [scene_name, i])
					else:
						if effects.has("inventory_add") and typeof(effects.get("inventory_add", null)) != TYPE_ARRAY:
							errors.append("Scene `%s` command #%d has invalid `effects.inventory_add` (expected array)." % [scene_name, i])
						if effects.has("inventory_remove") and typeof(effects.get("inventory_remove", null)) != TYPE_ARRAY:
							errors.append("Scene `%s` command #%d has invalid `effects.inventory_remove` (expected array)." % [scene_name, i])
						if effects.has("flags_set") and typeof(effects.get("flags_set", null)) != TYPE_DICTIONARY:
							errors.append("Scene `%s` command #%d has invalid `effects.flags_set` (expected dictionary)." % [scene_name, i])

	return {"ok": errors.is_empty(), "errors": errors}

func _start_story(resume: bool = false) -> void:
	if not resume:
		inventory.clear()
		flags.clear()
	story_generation += 1
	has_active_story = true
	pending_scene_id = ""
	menu_screen.visible = false
	about_dialog.visible = false
	bottom_bar.visible = false
	top_bar.visible = true
	scroll_container.offset_top = TOP_BAR_HEIGHT
	scroll_container.offset_bottom = 0.0
	command_bar.visible = true
	tile_section.visible = true
	feedback_text.visible = true
	new_game_button.visible = false
	_save_progress()
	await _render_scene()

func _show_menu() -> void:
	command_timer.stop()
	if tts_voice != "":
		DisplayServer.tts_stop()
	story_generation += 1
	has_active_story = false
	is_transitioning = false
	is_executing_command = false
	stop_dialog.visible = false
	continue_bar.visible = false
	top_bar.visible = false
	bottom_bar.visible = true
	scroll_container.offset_top = 0.0
	scroll_container.offset_bottom = -BOTTOM_BAR_HEIGHT
	pending_scene_id = ""
	menu_screen.visible = true
	_refresh_card_badges()
	command_bar.visible = false
	tile_section.visible = false
	feedback_text.visible = false
	new_game_button.visible = false
	continue_button.visible = false
	_reset_hints()
	story_text.text = ""
	story_text.add_theme_font_size_override("font_size", STORY_FONT_MAX)
	story_text.custom_minimum_size.y = STORY_FONT_MAX * STORY_MIN_HEIGHT_LINES
	idle_timer.stop()
	_finish_reveal()
	_set_mood("")
	for tray in [action_tray, thing_tray, inventory_tray]:
		for child in tray.get_children():
			tray.remove_child(child)
			child.free()
	slot1.clear()
	slot2.clear()
	inventory.clear()
	flags.clear()
	_refresh_resume_button()

func _refresh_resume_button() -> void:
	var save: Dictionary = _read_save()
	var index: int = _story_index_for_path(str(save.get("story_path", "")))
	resume_button.visible = index >= 0
	if index >= 0:
		_set_selected_story(index)

func _story_index_for_path(path: String) -> int:
	if path == "":
		return -1
	for i in range(discovered_stories.size()):
		if str(discovered_stories[i].get("path", "")) == path:
			return i
	return -1

func _save_progress() -> void:
	if not has_active_story or loaded_story_path == "":
		return
	var data := {
		"version": SAVE_VERSION,
		"story_path": loaded_story_path,
		"scene": pending_scene_id if pending_scene_id != "" else current_scene_id,
		"inventory": inventory.keys(),
		"flags": flags.duplicate(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save file: " + SAVE_PATH)
		return
	f.store_string(JSON.stringify(data))

func _clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func _read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	if int(parsed.get("version", 0)) != SAVE_VERSION:
		return {}
	if typeof(parsed.get("scene", null)) != TYPE_STRING or typeof(parsed.get("inventory", null)) != TYPE_ARRAY or typeof(parsed.get("flags", null)) != TYPE_DICTIONARY:
		return {}
	return parsed

func _on_resume_pressed() -> void:
	var save: Dictionary = _read_save()
	var index: int = _story_index_for_path(str(save.get("story_path", "")))
	if index < 0:
		_refresh_resume_button()
		return
	_set_selected_story(index)
	if not _load_story(str(discovered_stories[index].get("path", ""))):
		_clear_save()
		_refresh_resume_button()
		return
	var scene_id := str(save.get("scene", ""))
	if not scenes.has(scene_id):
		_clear_save()
		_refresh_resume_button()
		return
	current_scene_id = scene_id
	inventory.clear()
	for item in save.get("inventory", []):
		inventory[str(item)] = true
	flags.clear()
	var saved_flags: Dictionary = save.get("flags", {})
	for k in saved_flags.keys():
		flags[str(k)] = bool(saved_flags[k])
	_start_story(true)

func _set_continue_visible(shown: bool) -> void:
	continue_bar.visible = shown
	continue_button.visible = shown
	if has_active_story:
		scroll_container.offset_bottom = -CONTINUE_BAR_HEIGHT if shown else 0.0

func _show_stop_dialog() -> void:
	if not has_active_story:
		return
	# Freeze any command that is still in its debounce window; the slots keep their tiles.
	command_timer.stop()
	stop_dialog.visible = true

func _hide_stop_dialog() -> void:
	stop_dialog.visible = false
	# Give a command that was waiting a fresh delay instead of firing instantly.
	_check_slots_and_execute()

func _on_stop_confirmed() -> void:
	_show_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if not is_node_ready():
			return
		if about_dialog.visible:
			about_dialog.visible = false
		elif stop_dialog.visible:
			_hide_stop_dialog()
		elif has_active_story:
			_show_stop_dialog()
		else:
			get_tree().quit()

func _set_selected_story(index: int) -> void:
	if index < 0 or index >= discovered_stories.size():
		selected_story_path = ""
		selected_story_index = -1
		return

	var entry: Dictionary = discovered_stories[index]
	selected_story_path = str(entry.get("path", ""))
	selected_story_index = index
	for i in range(story_cards.size()):
		story_cards[i].add_theme_stylebox_override("panel", _card_style(i == index))

func _card_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(14)
	if selected:
		style.bg_color = Color(1.0, 0.953, 0.878)
		style.border_color = Color(1.0, 0.718, 0.302)
		style.set_border_width_all(4)
		style.set_content_margin_all(10)
	else:
		style.bg_color = Color(1.0, 0.98, 0.94)
		style.border_color = Color(0.85, 0.82, 0.76)
		style.set_border_width_all(2)
		style.set_content_margin_all(12)
	return style

func _length_badge(scene_count: int) -> String:
	if scene_count <= 8:
		return "Short"
	if scene_count <= 11:
		return "Medium"
	return "Long"

func _make_story_card(entry: Dictionary, index: int) -> PanelContainer:
	# A PanelContainer grows with its wrapped text; an invisible Button laid over
	# the whole card is the tap target.
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 88)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cover := Label.new()
	cover.text = str(entry.get("cover", "📖"))
	cover.add_theme_font_size_override("font_size", 44)
	cover.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cover.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cover.custom_minimum_size = Vector2(64, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cover)
	var col := VBoxContainer.new()
	col.name = "Col"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text = str(entry.get("display_name", ""))
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title)
	var teaser := Label.new()
	teaser.text = str(entry.get("teaser", ""))
	teaser.add_theme_font_size_override("font_size", 15)
	teaser.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35))
	teaser.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teaser.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(teaser)
	var badge := Label.new()
	badge.name = "Badge"
	var count: int = int(entry.get("scene_count", 0))
	badge.text = "%s · %d scenes" % [_length_badge(count), count]
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(badge)
	row.add_child(col)
	card.add_child(row)
	var tap := Button.new()
	tap.name = "Tap"
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	var clear := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus"]:
		tap.add_theme_stylebox_override(state, clear)
	tap.pressed.connect(_on_story_card_pressed.bind(index))
	card.add_child(tap)
	return card

func _on_story_card_pressed(index: int) -> void:
	if has_active_story or about_dialog.visible:
		return
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
	command_timer.stop()
	var scene = scenes.get(current_scene_id, null)
	if scene == null:
		push_error("Scene not found: " + current_scene_id)
		return

	_reset_hints()

	# text
	var lines: Array = scene.get("text", [])
	story_text.text = "\n".join(lines)
	_set_mood(scene.get("mood", ""))
	_reveal_story_text()
	_restart_idle_timer()

	# clear feedback + command slots
	_show_feedback("", "neutral")
	slot1.clear()
	slot2.clear()

	_refresh_tiles()

	# Show "New Game" button only on terminal scenes (no outgoing transitions)
	var has_next := false
	for rule in scene.get("commands", []):
		if rule.has("next"):
			has_next = true
			break
	new_game_button.visible = not has_next
	ending_badge.visible = false
	if not has_next:
		_clear_save()
		var ending = scene.get("ending", null)
		if typeof(ending) == TYPE_DICTIONARY:
			var eid := str(ending.get("id", "")).strip_edges()
			var title := str(ending.get("title", eid)).strip_edges()
			if eid != "":
				_record_ending(loaded_story_path, eid)
				var index := _story_index_for_path(loaded_story_path)
				var total: int = discovered_stories[index].get("ending_ids", []).size() if index >= 0 else 1
				var found: int = _found_endings(loaded_story_path).size()
				if total > 1:
					ending_label.text = "🏆 %s ending!  (%d of %d found)" % [title, found, total]
				else:
					ending_label.text = "🏆 %s!" % title
				ending_badge.visible = true
				_play_sfx("fanfare")
	await _auto_fit_story_text()

func _refresh_tiles() -> void:
	# Rebuild only the trays whose contents changed, and free old tiles immediately,
	# so a state change (e.g. picking up an item) does not flash every tile.
	var scene: Dictionary = scenes.get(current_scene_id, {})
	var tiles: Array = scene.get("tiles", [])
	var wanted := {action_tray: [], thing_tray: [], inventory_tray: []}
	for t in tiles:
		var token_str: String = str(t)
		if token_str in ACTION_TOKENS:
			wanted[action_tray].append(token_str)
		elif inventory.has(token_str):
			wanted[inventory_tray].append(token_str)
		else:
			wanted[thing_tray].append(token_str)
	for item in inventory.keys():
		var item_str: String = str(item)
		if item_str not in tiles:
			wanted[inventory_tray].append(item_str)

	for tray in wanted.keys():
		var current: Array = []
		for child in tray.get_children():
			current.append(child.token)
		if current == wanted[tray]:
			continue
		for child in tray.get_children():
			tray.remove_child(child)
			child.free()
		var cat: String = "action" if tray == action_tray else ("inventory" if tray == inventory_tray else "thing")
		var color: Color = TILE_GOLD if tray == inventory_tray else TILE_BLUE
		for token_str in wanted[tray]:
			tray.add_child(_make_tile(token_str, color, cat))

	_update_inventory_ui()

func _show_feedback(text: String, kind: String) -> void:
	feedback_text.text = text
	var color: Color = FEEDBACK_NEUTRAL
	if kind == "success":
		color = FEEDBACK_SUCCESS
	elif kind == "fail":
		color = FEEDBACK_FAIL
	feedback_text.add_theme_color_override("font_color", color)
	if text == "":
		return
	if bool(settings["read_aloud"]):
		_speak(text)
	if kind == "success":
		_play_sfx("success")
	elif kind == "fail":
		_play_sfx("fail")
	if kind == "neutral":
		return
	feedback_text.pivot_offset = feedback_text.size / 2.0
	feedback_text.scale = Vector2.ONE
	feedback_text.rotation_degrees = 0.0
	var tween := create_tween()
	if kind == "success":
		tween.tween_property(feedback_text, "scale", Vector2(1.05, 1.05), 0.08)
		tween.tween_property(feedback_text, "scale", Vector2.ONE, 0.12)
	else:
		for angle in [2.0, -2.0, 1.0, 0.0]:
			tween.tween_property(feedback_text, "rotation_degrees", angle, 0.06)

func _bounce_tile(tile: Control) -> void:
	tile.pivot_offset = tile.size / 2.0
	tile.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(tile, "scale", Vector2(1.12, 1.12), 0.07)
	tween.tween_property(tile, "scale", Vector2.ONE, 0.1)

func _auto_fit_story_text(reset: bool = true) -> void:
	var font_size: int = STORY_FONT_MAX
	if reset:
		story_text.add_theme_font_size_override("font_size", font_size)
		story_text.custom_minimum_size.y = font_size * STORY_MIN_HEIGHT_LINES
	else:
		font_size = story_text.get_theme_font_size("font_size")
	await get_tree().process_frame

	while font_size > STORY_FONT_MIN:
		if layout.size.y <= scroll_container.size.y:
			break
		font_size -= STORY_FONT_STEP
		story_text.add_theme_font_size_override("font_size", font_size)
		story_text.custom_minimum_size.y = font_size * STORY_MIN_HEIGHT_LINES
		await get_tree().process_frame

	scroll_container.scroll_vertical = 0

func _update_inventory_ui() -> void:
	var has_items: bool = not inventory.is_empty()
	inventory_label.visible = has_items
	inventory_tray.visible = has_items

func _label_for(token: String) -> String:
	var vocab = story.get("vocab", {})
	if typeof(vocab) == TYPE_DICTIONARY and vocab.has(token):
		var entry = vocab[token]
		if typeof(entry) == TYPE_DICTIONARY:
			var label := str(entry.get("label", "")).strip_edges()
			if label != "":
				return label
		elif typeof(entry) == TYPE_STRING and str(entry).strip_edges() != "":
			return str(entry).strip_edges()
	return token

func _make_tile(token_str: String, color: Color = TILE_BLUE, cat: String = "thing") -> Button:
	var tile = TILE_SCENE.instantiate()
	tile.token = token_str
	tile.category = cat
	var icon: String = EMOJI.get(token_str, "")
	var label: String = _label_for(token_str)
	tile.text = (icon + " " + label) if icon != "" else label
	if color != TILE_BLUE:
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
	tile.long_pressed.connect(_on_tile_long_pressed.bind(tile))
	return tile

func _input_blocked() -> bool:
	return not has_active_story or is_transitioning or is_executing_command or stop_dialog.visible

func _on_tile_pressed(tile: Button) -> void:
	if _input_blocked():
		return
	if tile.long_press_fired:
		tile.long_press_fired = false
		return

	_bounce_tile(tile)
	_play_sfx("tap")
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
	# A new selection replaces the previous delay, including incomplete input.
	command_timer.stop()
	if _input_blocked():
		return
	# Check if all visible required slots are filled
	if slot1.token == "" or slot2.token == "":
		return
	command_timer.start()

func _try_execute_command() -> void:
	command_timer.stop()
	if _input_blocked():
		return
	var first: String = slot1.token
	var second: String = slot2.token

	if first == "" or second == "":
		return

	var cmd: Array[String] = [first, second]

	is_executing_command = true
	var transitioned := await _apply_command(cmd)
	if not transitioned:
		slot1.clear()
		slot2.clear()
	is_executing_command = false

func _apply_command(cmd: Array[String]) -> bool:
	_restart_idle_timer()
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
		var made_progress := _apply_effects(rule.get("effects", {}))
		_show_feedback(response, "success" if (made_progress or rule.has("next")) else "neutral")

		if rule.has("next"):
			_reset_hints()
			# Effects are already applied; checkpoint the destination now so stopping
			# before the Continue tap resumes past this command, not before it.
			pending_scene_id = str(rule["next"])
			_save_progress()
			_transition_to_scene(pending_scene_id)
			return true
		else:
			if made_progress:
				# Refresh trays and reset hints only when the world changes; keep the
				# story text and feedback in place so nothing flashes.
				var generation: int = story_generation
				_save_progress()
				_reset_hints()
				_refresh_tiles()
				await _auto_fit_story_text(false)
				if generation != story_generation:
					return false
			else:
				_record_no_progress()
			return false

	# No match — try smart fallback, then random default
	_record_no_progress()
	var smart: String = _get_smart_fallback(cmd)
	if smart != "":
		_show_feedback(smart, "fail")
	else:
		_show_feedback(_pick_random_text(default_responses, "Nothing happens."), "fail")
	return false


func _pick_random_text(options: Array, fallback: String = "Nothing happens.") -> String:
	if options.is_empty():
		return fallback
	return str(options[randi() % options.size()])

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
		var msg: String = _pick_random_text(SAME_TOKEN_FALLBACKS, "Nothing happens.")
		return msg.replace("{thing}", _label_for(t1))

	var cat1: String = _classify_token(t1)

	# Action verb in slot1 → action-specific fallback
	if cat1 == "action" and action_fallback_map.has(t1):
		var templates: Array = action_fallback_map[t1]
		var msg: String = _pick_random_text(templates, "Nothing happens.")
		return msg.replace("{action}", _label_for(t1)).replace("{thing}", _label_for(t2))

	# Inventory item used as verb in slot1
	if cat1 == "inventory":
		var msg: String = _pick_random_text(ITEM_AS_VERB_FALLBACKS, "Nothing happens.")
		return msg.replace("{item}", _label_for(t1)).replace("{thing}", _label_for(t2))

	return ""

func _transition_to_scene(scene_id: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	var generation: int = story_generation

	# Brief pause so kid notices the response text (polled so a stopped story releases it)
	var pause_until: int = Time.get_ticks_msec() + 1000
	while Time.get_ticks_msec() < pause_until and generation == story_generation:
		await get_tree().process_frame
	if generation != story_generation:
		return

	# Show continue button and wait for kid to tap it. Poll instead of awaiting the
	# signal so a story stopped from the menu releases this coroutine on its own.
	_set_continue_visible(true)
	continue_pressed = false
	while not continue_pressed and generation == story_generation:
		await get_tree().process_frame
	_set_continue_visible(false)
	if generation != story_generation:
		return

	# Fade to black
	_play_sfx("whoosh")
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 1.0, 0.3)
	await tween.finished
	if generation != story_generation:
		transition_overlay.color.a = 0.0
		return

	# Change scene content
	current_scene_id = scene_id
	pending_scene_id = ""
	_save_progress()
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

func _apply_effects(eff: Dictionary) -> bool:
	var inventory_before: Dictionary = inventory.duplicate()
	var flags_before: Dictionary = flags.duplicate()
	var inv_add: Array = eff.get("inventory_add", [])
	for item in inv_add:
		inventory[str(item)] = true

	var inv_remove: Array = eff.get("inventory_remove", [])
	for item in inv_remove:
		inventory.erase(str(item))

	var flags_set: Dictionary = eff.get("flags_set", {})
	for k in flags_set.keys():
		flags[str(k)] = bool(flags_set[k])
	return inventory != inventory_before or flags != flags_before

func _record_no_progress() -> void:
	fail_count += 1
	var scene: Dictionary = scenes.get(current_scene_id, {})
	var hints: Array = scene.get("hints", [])
	if fail_count >= HINT_FAIL_THRESHOLD and not hints.is_empty():
		hint_button.visible = true

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
	_show_feedback(str(hints[hint_index]), "neutral")
	if hint_index < hints.size() - 1:
		hint_index += 1
