class_name OperationLegend
extends Control

signal operator_info(text: String)

# 5.4: без «unavailable» — серый спутник и так читается (цветной ободок из 1.2).
const LEGEND_OPS := ["add", "subtract", "multiply", "divide"]
const CARD_GAP := 27.0
const CARD_HEIGHT := 147.0

# 5.3: операторы, реально показываемые на текущем уровне (в порядке LEGEND_OPS).
var active_ops: Array = LEGEND_OPS.duplicate()

func _ready() -> void:
	if size.x <= 0:
		size = Vector2(1072, CARD_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	configure_ops()

# Resize to a given width and rebuild the single-row legend.
func set_width(width: float) -> void:
	size = Vector2(width, CARD_HEIGHT)
	rebuild_cards()

# Build chips only for operators present in the current level. An empty list is
# intentional for placeholder levels and therefore renders no operator chips.
func configure_ops(ops: Array = []) -> void:
	active_ops = _ordered_ops(ops)
	rebuild_cards()

func _ordered_ops(ops: Array) -> Array:
	var result: Array = []
	for op in LEGEND_OPS:
		if ops.has(op):
			result.append(op)
	return result

func rebuild_cards() -> void:
	Layout.clear_children_for_rebuild(self)
	for i in range(active_ops.size()):
		add_card(str(active_ops[i]), card_rect(i))

func card_rect(index: int) -> Rect2:
	var count := maxi(active_ops.size(), 1)
	var pill_w := (size.x - CARD_GAP * float(count - 1)) / float(count)
	return Rect2(Vector2(float(index) * (pill_w + CARD_GAP), 0.0), Vector2(pill_w, CARD_HEIGHT))

# Индекс чипа оператора среди показанных (-1, если оператора нет на уровне) — коуч
# спотлайтит конкретный оператор по имени, без фиксированных индексов (5.3/5.4).
func op_index(op: String) -> int:
	return active_ops.find(op)

func short_name(op: String) -> String:
	match op:
		"add": return Locale.t("op.chip.add", "Add")
		"subtract": return Locale.t("op.chip.subtract", "Sub")
		"multiply": return Locale.t("op.chip.multiply", "Mul")
		"divide": return Locale.t("op.chip.divide", "Div")
	return op.capitalize()

func add_card(op: String, rect: Rect2) -> void:
	var button := Button.new()
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	# The colored plate is a separate, static surface. Keeping it out of the
	# Button's state stack prevents the one focused/last button from receiving a
	# theme focus fill while its siblings keep their normal flat fill.
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty.duplicate())
	button.pressed.connect(func() -> void:
		operator_info.emit(short_info(op))
	)
	UIStyles.add_press_animation(button, 67)
	add_child(button)

	var plate := Panel.new()
	plate.name = "Plate"
	plate.position = Vector2.ZERO
	plate.size = rect.size
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", legend_style(op))
	button.add_child(plate)

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
		"subtract": return Locale.t("op.info.subtract", "Red orbit numbers subtract.")
		"multiply": return Locale.t("op.info.multiply", "Blue orbit numbers multiply.")
		"divide": return Locale.t("op.info.divide", "Orange divides — only if exact.")
	return ""
