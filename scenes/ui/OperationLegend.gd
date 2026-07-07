class_name OperationLegend
extends Control

signal operator_info(text: String)

const LEGEND_OPS := ["add", "subtract", "multiply", "divide", "unavailable"]
const CARD_GAP := 27.0
const CARD_HEIGHT := 147.0

func _ready() -> void:
	if size.x <= 0:
		size = Vector2(1072, CARD_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	configure_ops()

# Resize to a given width and rebuild the single-row legend.
func set_width(width: float) -> void:
	size = Vector2(width, CARD_HEIGHT)
	configure_ops()

func configure_ops(_ops: Array = []) -> void:
	for child in get_children():
		child.queue_free()
	# Always show all five operators, including "unavailable".
	for i in range(LEGEND_OPS.size()):
		add_card(str(LEGEND_OPS[i]), card_rect(i))

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
	# Mockup operator chips: soft tinted fill only, no border.
	var style := StyleBoxFlat.new()
	style.bg_color = legend_bg_color(op)
	UIStyles._set_radius(style, 67)
	return style

func legend_bg_color(op: String) -> Color:
	return UIStyles.operation_plate(op)

func legend_text_color(op: String) -> Color:
	return UIStyles.operation_text(op)

func short_info(op: String) -> String:
	match op:
		"add": return Locale.t("op.info.add", "Green orbit numbers add.")
		"subtract": return Locale.t("op.info.subtract", "Orange orbit numbers subtract.")
		"multiply": return Locale.t("op.info.multiply", "Red orbit numbers multiply.")
		"divide": return Locale.t("op.info.divide", "Blue divides — only if exact.")
		"unavailable": return Locale.t("op.info.unavailable", "Grey can't be used right now.")
	return ""
