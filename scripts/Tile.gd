# res://scripts/Tile.gd
extends Button

@export var token: String = ""
var tile_color: Color = Color(0.357, 0.608, 0.835)
var category: String = ""  # "action", "thing", or "inventory"
var drag_started: bool = false # Suppress a Button.pressed event after dragging.
var drag_allowed: Callable
const TOUCH_HOLD_MSEC := 350
var touch_press := false
var pressed_at := 0
var scroll_gesture := false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		touch_press = event.device == InputEvent.DEVICE_ID_EMULATION
		pressed_at = Time.get_ticks_msec()
		scroll_gesture = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCROLL_BEGIN:
		# Never convert a swipe into a drag, even after the finger slows or pauses.
		scroll_gesture = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Only set text from token if it wasn't already set by the caller
	if text == "" and token != "":
		text = token
	button_down.connect(func() -> void: drag_started = false)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if drag_allowed.is_valid() and not bool(drag_allowed.call()):
		return null
	# Touch: immediate movement scrolls; a stationary hold then movement drags.
	# A physical mouse keeps the usual immediate drag behavior.
	if touch_press and (scroll_gesture or Time.get_ticks_msec() - pressed_at < TOUCH_HOLD_MSEC):
		return null
	# Dragging must not also select a tile on release.
	drag_started = true
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
