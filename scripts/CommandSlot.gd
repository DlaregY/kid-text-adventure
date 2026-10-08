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

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if input_allowed.is_valid() and not bool(input_allowed.call()):
		return false
	return typeof(data) == TYPE_DICTIONARY and typeof(data.get("token")) == TYPE_STRING and not str(data["token"]).is_empty()

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Recheck here: a dialog/transition can start after the drag was accepted.
	if not _can_drop_data(_at_position, data):
		return
	token = str(data["token"])
	label.text = str(data.get("label", token))
	tile_dropped.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tapped.emit()
		accept_event()

func set_tile(new_token: String, display_text: String) -> void:
	token = new_token
	label.text = display_text

func clear() -> void:
	token = ""
	label.text = placeholder_text
