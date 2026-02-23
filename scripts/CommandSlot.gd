# res://scripts/CommandSlot.gd
extends PanelContainer

@export var slot_index: int = 0
@onready var label: Label = get_child(0)

var token: String = ""

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("token")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	token = str(data["token"])
	label.text = str(data.get("label", token))

func clear() -> void:
	token = ""
	label.text = "(drop here)"
