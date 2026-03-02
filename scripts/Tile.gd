# res://scripts/Tile.gd
extends Button

@export var token: String = ""

func _ready() -> void:
	text = token if token != "" else text

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Show a styled preview matching tile appearance while dragging
	var panel := PanelContainer.new()
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.357, 0.608, 0.835, 1)
	stylebox.set_corner_radius_all(8)
	stylebox.content_margin_left = 12
	stylebox.content_margin_right = 12
	stylebox.content_margin_top = 8
	stylebox.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", stylebox)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(lbl)
	set_drag_preview(panel)
	return {"token": token, "label": text}
