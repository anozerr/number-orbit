class_name OperationLegend
extends Control

const LEGEND_OPS := ["add", "subtract", "multiply", "divide", "unavailable"]
const CARD_GAP := 28.0
const TOP_CARD_SIZE := Vector2(290, 90)
const BOTTOM_CARD_SIZE := Vector2(450, 90)
const TOP_Y := 14.0
const BOTTOM_Y := 126.0

var callout: Control
var callout_panel_rect := Rect2()
var callout_version := 0

func _ready() -> void:
	size = Vector2(970, 232)
	mouse_filter = Control.MOUSE_FILTER_PASS
	configure_ops(["add", "subtract", "multiply", "divide"])

func configure_ops(ops: Array) -> void:
	for child in get_children():
		child.queue_free()
	callout = null
	callout_panel_rect = Rect2()
	for i in range(LEGEND_OPS.size()):
		var op: String = str(LEGEND_OPS[i])
		add_card(op, card_rect(i))

func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return
	if callout == null or not is_instance_valid(callout):
		return
	if not callout_panel_rect.has_point(mouse_event.position):
		hide_callout()

func card_position(index: int) -> Vector2:
	return card_rect(index).position

func card_rect(index: int) -> Rect2:
	if index < 3:
		var start_x := (size.x - TOP_CARD_SIZE.x * 3.0 - CARD_GAP * 2.0) * 0.5
		return Rect2(Vector2(start_x + index * (TOP_CARD_SIZE.x + CARD_GAP), TOP_Y), TOP_CARD_SIZE)
	var bottom_start_x := (size.x - BOTTOM_CARD_SIZE.x * 2.0 - CARD_GAP) * 0.5
	return Rect2(Vector2(bottom_start_x + (index - 3) * (BOTTOM_CARD_SIZE.x + CARD_GAP), BOTTOM_Y), BOTTOM_CARD_SIZE)

func operation_name(op: String) -> String:
	match op:
		"add":
			return "Add"
		"subtract":
			return "Subtract"
		"multiply":
			return "Multiply"
		"divide":
			return "Divide"
		"unavailable":
			return "Unavailable"
	return op.capitalize()

func add_card(op: String, rect: Rect2) -> void:
	var button := Button.new()
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.add_theme_stylebox_override("normal", legend_style(op))
	button.add_theme_stylebox_override("hover", legend_style(op))
	button.add_theme_stylebox_override("pressed", legend_style(op))
	button.pressed.connect(show_callout.bind(op, rect.position + rect.size * 0.5))
	UIStyles.add_press_animation(button)
	add_child(button)

	var icon_size := Vector2(34, 34)
	var icon_x := 54.0 if rect.size.x < 330.0 else 118.0
	var icon := TextureRect.new()
	icon.texture = UIStyles.ICON_LOCK if op == "unavailable" else UIStyles.operation_icon(op)
	icon.position = Vector2(icon_x, (rect.size.y - icon_size.y) * 0.5)
	icon.size = icon_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.modulate = legend_text_color(op)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.text = operation_name(op)
	name_lbl.position = Vector2(icon_x + 52.0, 0)
	name_lbl.size = Vector2(rect.size.x - icon_x - 76.0, rect.size.y)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	UIStyles.apply_font(name_lbl, UIStyles.FONT_BOLD, 20, legend_text_color(op))
	button.add_child(name_lbl)

func legend_style(op: String) -> StyleBoxFlat:
	var style: StyleBoxFlat = UIStyles.card(legend_bg_color(op), legend_border_color(op), 18)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0.10, 0.10, 0.18, 0.035)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style

func legend_bg_color(op: String) -> Color:
	if op == "unavailable":
		return Color("#F1F2F4")
	return UIStyles.operation_bg(op)

func legend_border_color(op: String) -> Color:
	if op == "unavailable":
		return Color("#CDD2DA")
	return UIStyles.operation_border(op)

func legend_text_color(op: String) -> Color:
	if op == "unavailable":
		return Color("#7D8491")
	return UIStyles.operation_text(op)

func show_callout(op: String, center: Vector2) -> void:
	callout_version += 1
	var version := callout_version
	if callout != null and is_instance_valid(callout):
		callout.queue_free()

	callout = Control.new()
	callout.mouse_filter = Control.MOUSE_FILTER_STOP
	callout.z_index = 20
	add_child(callout)

	var panel_width := 500.0
	var panel_height := 142.0
	var x: float = clampf(center.x - panel_width * 0.5, 0.0, size.x - panel_width)
	var y: float = center.y - panel_height - 28.0
	callout_panel_rect = Rect2(Vector2(x, y), Vector2(panel_width, center.y - y + 26.0))

	var panel := Panel.new()
	panel.position = Vector2(x, y)
	panel.size = Vector2(panel_width, panel_height)
	panel.z_index = 2
	panel.add_theme_stylebox_override("panel", UIStyles.soft_panel(Color("#FFFEFC"), 24))
	callout.add_child(panel)

	var pointer := Polygon2D.new()
	pointer.polygon = PackedVector2Array([
		Vector2(center.x - 16, y + panel_height - 3),
		Vector2(center.x + 16, y + panel_height - 3),
		Vector2(center.x, center.y)
	])
	pointer.color = Color("#FFFEFC")
	pointer.z_index = 4
	callout.add_child(pointer)

	var title := Label.new()
	title.text = operation_name(op)
	title.position = Vector2(22, 10)
	title.size = Vector2(panel_width - 44, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 23, legend_text_color(op))
	panel.add_child(title)

	var body := Label.new()
	body.text = description_for(op)
	body.position = Vector2(56, 48)
	body.size = Vector2(panel_width - 112, 78)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.clip_text = false
	UIStyles.apply_font(body, UIStyles.FONT_MEDIUM, 17, UIStyles.MUTED)
	panel.add_child(body)

	callout.scale = Vector2.ONE
	callout.modulate.a = 0.0
	callout.pivot_offset = center
	var tween := callout.create_tween()
	tween.tween_property(callout, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(3.0).timeout
	if version == callout_version:
		hide_callout(true)

func hide_callout(animated: bool = false) -> void:
	if callout != null and is_instance_valid(callout):
		if animated:
			var current := callout
			var tween := current.create_tween()
			tween.tween_property(current, "modulate:a", 0.0, 0.16)
			await tween.finished
			if is_instance_valid(current):
				current.queue_free()
		else:
			callout.queue_free()
	callout = null
	callout_panel_rect = Rect2()

func close_callout_if_outside(global_position: Vector2) -> void:
	if callout == null or not is_instance_valid(callout):
		return
	var local_position := get_global_transform().affine_inverse() * global_position
	if not callout_panel_rect.has_point(local_position):
		callout_version += 1
		hide_callout(true)

func description_for(op: String) -> String:
	match op:
		"add":
			return "Green orbit numbers are added\nto the center number."
		"subtract":
			return "Yellow orbit numbers are subtracted\nfrom the center number."
		"multiply":
			return "Red orbit numbers multiply\nthe center number."
		"divide":
			return "Blue orbit numbers divide only\nwhen the result is exact."
		"unavailable":
			return "Grey orbit numbers are unavailable\nwhen a move goes below 1 or divides unevenly."
	return ""
