# res://scripts/CommandSlot.gd
extends PanelContainer

signal tile_dropped
signal tapped

@export var slot_index: int = 0
@export var placeholder_text: String = "(drop here)"
@onready var label: Label = get_child(0)

var token: String = ""
# The controller supplies the same input gate used by tapping and execution.
var input_allowed: Callable
var token_allowed: Callable
var token_display: Callable
var tap_pending := false

func _notification(what: int) -> void:
	if what in [NOTIFICATION_SCROLL_BEGIN, NOTIFICATION_DRAG_BEGIN, NOTIFICATION_VISIBILITY_CHANGED]:
		tap_pending = false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if input_allowed.is_valid() and not bool(input_allowed.call()):
		return false
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("token")) != TYPE_STRING or str(data["token"]).is_empty():
		return false
	return token_allowed.is_valid() and bool(token_allowed.call(str(data["token"])))

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Recheck here: a dialog/transition can start after the drag was accepted.
	if not _can_drop_data(_at_position, data):
		return
	token = str(data["token"])
	label.text = str(token_display.call(token)) if token_display.is_valid() else token
	tile_dropped.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			tap_pending = true # Let the press/motion propagate so a swipe can begin here.
		else:
			var was_tap: bool = tap_pending and not event.canceled and Rect2(Vector2.ZERO, size).has_point(event.position)
			tap_pending = false
			if was_tap:
				tapped.emit()
			# Release must also reach the scroll container, including after a swipe.

func set_tile(new_token: String, display_text: String) -> void:
	token = new_token
	label.text = display_text

func clear() -> void:
	token = ""
	label.text = placeholder_text
