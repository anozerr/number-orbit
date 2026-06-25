class_name OperationLegend
extends Control

func _ready() -> void:
	size = Vector2(970, 170)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	build()

func build() -> void:
	for child in get_children():
		child.queue_free()
	var cards := [
		{"name": "Add", "op": "add", "pos": Vector2(0, 0)},
		{"name": "Subtract", "op": "subtract", "pos": Vector2(505, 0)},
		{"name": "Multiply", "op": "multiply", "pos": Vector2(0, 86)},
		{"name": "Divide", "op": "divide", "pos": Vector2(505, 86)}
	]
	for data in cards:
		add_card(data)

func add_card(data: Dictionary) -> void:
	var op: String = str(data["op"])
	var pos: Vector2 = data["pos"] as Vector2

	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = pos
	panel.size = Vector2(465, 76)
	panel.add_theme_stylebox_override("panel", UIStyles.card(UIStyles.operation_bg(op), UIStyles.operation_border(op), 18))
	add_child(panel)

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.position = Vector2(0, 0)
	content.size = panel.size
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)

	var name: String = str(data["name"])
	var label_width: float = 120.0 if name.length() <= 6 else 180.0

	var icon := TextureRect.new()
	icon.texture = UIStyles.operation_icon(op)
	icon.custom_minimum_size = Vector2(38, 38)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = UIStyles.operation_text(op)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.text = name
	name_lbl.custom_minimum_size = Vector2(label_width, panel.size.y)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(name_lbl, UIStyles.FONT_BOLD, 26, UIStyles.operation_text(op))
	content.add_child(name_lbl)
