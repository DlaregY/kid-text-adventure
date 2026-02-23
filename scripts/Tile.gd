# res://scripts/Tile.gd
extends Button

@export var token: String = ""

func _ready() -> void:
	text = token if token != "" else text

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Show a little preview while dragging
	var preview := Label.new()
	preview.text = text
	set_drag_preview(preview)
	return {"token": token, "label": text}
