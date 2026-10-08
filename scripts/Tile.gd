# res://scripts/Tile.gd
extends Button

signal long_pressed

const LONG_PRESS_SECONDS: float = 0.5

@export var token: String = ""
var tile_color: Color = Color(0.357, 0.608, 0.835)
var category: String = ""  # "action", "thing", or "inventory"
var long_press_fired: bool = false # true when the current press became a long press; `pressed` is then ignored
var _hold_timer: Timer

func _ready() -> void:
	# Only set text from token if it wasn't already set by the caller
	if text == "" and token != "":
		text = token
	_hold_timer = Timer.new()
	_hold_timer.one_shot = true
	_hold_timer.wait_time = LONG_PRESS_SECONDS
	_hold_timer.timeout.connect(_on_hold_timeout)
	add_child(_hold_timer)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_button_down() -> void:
	long_press_fired = false
	_hold_timer.start()

func _on_button_up() -> void:
	_hold_timer.stop()

func _on_hold_timeout() -> void:
	long_press_fired = true
	long_pressed.emit()

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Dragging is not a read-aloud hold or a second click on release.
	_hold_timer.stop()
	long_press_fired = true
	# Show a styled preview matching tile appearance while dragging
	var panel := PanelContainer.new()
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = tile_color
	stylebox.set_corner_radius_all(8)
	stylebox.content_margin_left = 14
	stylebox.content_margin_right = 14
	stylebox.content_margin_top = 8
	stylebox.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", stylebox)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(lbl)
	set_drag_preview(panel)
	return {"token": token, "label": text, "category": category}
