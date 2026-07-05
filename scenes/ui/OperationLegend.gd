class_name OperationLegend
extends Control

# Tapping an operator chip writes a short description into the game's info line
# instead of opening a callout popup.
signal operator_info(text: String)

const LEGEND_OPS := ["add", "subtract", "multiply", "divide", "unavailable"]
const CARD_GAP := 27.0
const CARD_HEIGHT := 147.0

var callout: Control
var callout_panel_rect := Rect2()
var callout_version := 0

func _ready() -> void:
	if size.x <= 0:
		size = Vector2(1072, CARD_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	configure_ops(["add", "subtract", "multiply", "divide"])

# Resize to a given width and rebuild the single-row legend.
func set_width(width: float) -> void:
	size = Vector2(width, CARD_HEIGHT)
	configure_ops([])

func configure_ops(_ops: Array) -> void:
	for child in get_children():
		child.queue_free()
	callout = null
	callout_panel_rect = Rect2()
	# Always show all five operators, including "unavailable".
	for i in range(LEGEND_OPS.size()):
		add_card(str(LEGEND_OPS[i]), card_rect(i))

func _gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return
	if callout == null or not is_instance_valid(callout):
		return
	if not callout_panel_rect.has_point(mouse_event.position):
		hide_callout()

func card_rect(index: int) -> Rect2:
	var count := LEGEND_OPS.size()
	var pill_w := (size.x - CARD_GAP * float(count - 1)) / float(count)
	return Rect2(Vector2(float(index) * (pill_w + CARD_GAP), 0.0), Vector2(pill_w, CARD_HEIGHT))

func short_name(op: String) -> String:
	match op:
		"add": return Locale.t("op.chip.add", "Add")
		"subtract": return Locale.t("op.chip.subtract", "Sub")
		"multiply": return Locale.t("op.chip.multiply", "Mul")
		"divide": return Locale.t("op.chip.divide", "Div")
		"unavailable": return Locale.t("op.chip.unavailable", "Una")
	return op.capitalize()

func operation_name(op: String) -> String:
	match op:
		"add": return "Add"
		"subtract": return "Subtract"
		"multiply": return "Multiply"
		"divide": return "Divide"
		"unavailable": return "Unavailable"
	return op.capitalize()

func add_card(op: String, rect: Rect2) -> void:
	var button := Button.new()
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.add_theme_stylebox_override("normal", legend_style(op))
	button.add_theme_stylebox_override("hover", legend_style(op))
	button.add_theme_stylebox_override("pressed", legend_style(op))
	button.pressed.connect(func() -> void: operator_info.emit(short_info(op)))
	UIStyles.add_press_animation(button)
	add_child(button)

	var name_lbl := Label.new()
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.text = short_name(op)
	name_lbl.position = Vector2.ZERO
	name_lbl.size = rect.size
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	UIStyles.apply_font(name_lbl, UIStyles.FONT_BOLD, 42, legend_text_color(op))
	button.add_child(name_lbl)

func legend_style(op: String) -> StyleBoxFlat:
	# Mockup operator chips: soft tinted fill only — NO border, NO shadow (both
	# themes).
	var style := StyleBoxFlat.new()
	style.bg_color = legend_bg_color(op)
	style.corner_radius_top_left = 67
	style.corner_radius_top_right = 67
	style.corner_radius_bottom_left = 67
	style.corner_radius_bottom_right = 67
	return style

func legend_bg_color(op: String) -> Color:
	return UIStyles.operation_plate(op)

func legend_border_color(op: String) -> Color:
	return UIStyles.operation_border(op)

func legend_text_color(op: String) -> Color:
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

	var panel_width := 692.0
	var panel_height := 212.0
	var x: float = clampf(center.x - panel_width * 0.5, 0.0, size.x - panel_width)
	var y: float = center.y - panel_height - 28.0
	callout_panel_rect = Rect2(Vector2(x, y), Vector2(panel_width, center.y - y + 26.0))

	var panel := Panel.new()
	panel.position = Vector2(x, y)
	panel.size = Vector2(panel_width, panel_height)
	panel.z_index = 2
	panel.add_theme_stylebox_override("panel", UIStyles.glass_panel(40, true))
	callout.add_child(panel)

	var pointer := Polygon2D.new()
	pointer.polygon = PackedVector2Array([
		Vector2(center.x - 16, y + panel_height - 3),
		Vector2(center.x + 16, y + panel_height - 3),
		Vector2(center.x, center.y)
	])
	pointer.color = UIStyles.GLASS_POPUP_BG
	pointer.z_index = 4
	callout.add_child(pointer)

	var title := Label.new()
	title.text = operation_name(op)
	title.position = Vector2(22, 18)
	title.size = Vector2(panel_width - 44, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 38, legend_text_color(op))
	panel.add_child(title)

	var body := Label.new()
	body.text = description_for(op)
	body.position = Vector2(48, 68)
	body.size = Vector2(panel_width - 96, 108)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(body, UIStyles.FONT_MEDIUM, 29, UIStyles.MUTED)
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

func short_info(op: String) -> String:
	match op:
		"add": return Locale.t("op.info.add", "Green orbit numbers add.")
		"subtract": return Locale.t("op.info.subtract", "Orange orbit numbers subtract.")
		"multiply": return Locale.t("op.info.multiply", "Red orbit numbers multiply.")
		"divide": return Locale.t("op.info.divide", "Blue divides — only if exact.")
		"unavailable": return Locale.t("op.info.unavailable", "Grey can't be used right now.")
	return ""

func description_for(op: String) -> String:
	match op:
		"add":
			return "Green orbit numbers are added\nto the center number."
		"subtract":
			return "Orange orbit numbers are subtracted\nfrom the center number."
		"multiply":
			return "Red orbit numbers multiply\nthe center number."
		"divide":
			return "Blue orbit numbers divide only\nwhen the result is exact."
		"unavailable":
			return "Grey orbit numbers are unavailable\nwhen a move goes below 1 or divides unevenly."
	return ""
