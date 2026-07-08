class_name HintPopup
extends Control

const PopupFactoryScript = preload("res://scripts/ui/PopupFactory.gd")

signal hint_requested
signal hint_ad_requested

var current_hint_points: int = 0
var current_moves: int = 0
var cached_popup_hint_text: String = ""
var cached_popup_move_index: int = -1

var overlay: ColorRect
var panel: Panel
var body_label: Label
var balance_label: Label
var buy_button: Button
var ad_button: Button
var cancel_button: Button
var move_circle: Panel
var move_label: Label

func build(viewport_width: float) -> void:
	for child in get_children():
		child.queue_free()
	z_index = 100
	visible = false

	overlay = PopupFactoryScript.scrim(Vector2.ZERO, func() -> void: hide_popup())
	add_child(overlay)

	var pw := PopupFactoryScript.popup_width(viewport_width)
	panel = Panel.new()
	panel.name = "PopupPanel"
	panel.size = Vector2(pw, 1003)
	PopupFactoryScript.apply_panel_glass(panel)
	PopupFactoryScript.register_sheet_panel(panel)
	add_child(panel)

	PopupFactoryScript.badge(panel, pw, Color("#FFD98F"), Color("#F5A93D"), UIStyles.ICON_BULB, 101.0)
	PopupFactoryScript.title(panel, pw, Locale.t("hint.title", "HINT"))

	body_label = PopupFactoryScript.body(panel, pw, "Spend bulbs to reveal one next move.", 264.0, 130.0)

	move_circle = Panel.new()
	move_circle.position = Vector2(pw * 0.5 - 87, 350)
	move_circle.size = Vector2(174, 174)
	move_circle.visible = false
	panel.add_child(move_circle)

	move_label = Label.new()
	move_label.position = Vector2.ZERO
	move_label.size = move_circle.size
	move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(move_label, UIStyles.FONT_EXTRABOLD, 60, UIStyles.TEXT)
	move_circle.add_child(move_label)

	balance_label = Label.new()
	balance_label.position = Vector2(0, 430)
	balance_label.size = Vector2(pw, 58)
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(balance_label, UIStyles.FONT_SEMIBOLD, 44, UIStyles.MUTED)
	panel.add_child(balance_label)

	buy_button = PopupFactoryScript.primary_button(Locale.t("hint.use", "Use Hint"), pw, 520.0)
	buy_button.pressed.connect(func(): hint_requested.emit())
	panel.add_child(buy_button)

	ad_button = PopupFactoryScript.primary_button(Locale.t("levels.locked.watch_ad", "Watch Ad"), pw, 520.0)
	ad_button.pressed.connect(func(): hint_ad_requested.emit())
	ad_button.visible = false
	panel.add_child(ad_button)

	cancel_button = PopupFactoryScript.secondary_button(Locale.t("common.cancel", "Cancel"), pw, 755.0)
	cancel_button.pressed.connect(func(): hide_popup())
	panel.add_child(cancel_button)

func configure_state(moves: int, hint_points: int) -> void:
	current_moves = moves
	current_hint_points = hint_points
	if cached_popup_move_index != current_moves:
		cached_popup_hint_text = ""
		cached_popup_move_index = -1

func layout_to_viewport(viewport_size: Vector2) -> void:
	size = viewport_size
	if overlay != null:
		overlay.size = viewport_size
	if panel != null:
		panel.position = (viewport_size - panel.size) * 0.5
		PopupFactoryScript.register_sheet_panel(panel)

func show_prompt() -> void:
	reset_layout()
	if cached_popup_move_index == current_moves and not cached_popup_hint_text.is_empty():
		apply_result_text(cached_popup_hint_text)
		balance_label.text = Locale.t("hint.balance", "Balance: %d bulbs") % current_hint_points
		buy_button.visible = false
		ad_button.visible = false
		cancel_button.text = Locale.t("common.back", "Back")
	else:
		body_label.text = Locale.t("hint.body", "Spend %d bulbs to reveal the next winning move.") % GameState.HINT_COST
		hide_move_circle()
		balance_label.text = Locale.t("hint.balance", "Balance: %d bulbs") % current_hint_points
		buy_button.visible = true
		ad_button.visible = false
		cancel_button.text = Locale.t("common.cancel", "Cancel")
	PopupFactoryScript.show_sheet(self, panel, overlay)

func show_result(message: String, balance: int) -> void:
	current_hint_points = balance
	cache_result(message, balance)
	reset_layout()
	apply_result_text(message)
	balance_label.text = Locale.t("hint.balance", "Balance: %d bulbs") % current_hint_points
	buy_button.visible = false
	ad_button.visible = false
	cancel_button.text = Locale.t("common.back", "Back")
	PopupFactoryScript.show_sheet(self, panel, overlay)

func show_insufficient_balance(balance: int) -> void:
	current_hint_points = balance
	cached_popup_hint_text = ""
	cached_popup_move_index = -1
	reset_layout()
	body_label.text = Locale.t("hint.insufficient", "Not enough bulbs for a hint.")
	hide_move_circle()
	balance_label.text = Locale.t("hint.balance_short", "Balance: %d / %d bulbs") % [current_hint_points, GameState.HINT_COST]
	buy_button.visible = false
	ad_button.visible = true
	cancel_button.text = Locale.t("common.cancel", "Cancel")
	PopupFactoryScript.show_sheet(self, panel, overlay)

func cache_result(message: String, balance: int) -> void:
	current_hint_points = balance
	cached_popup_hint_text = message
	cached_popup_move_index = current_moves

func has_cached_result() -> bool:
	return cached_popup_move_index == current_moves and not cached_popup_hint_text.is_empty()

func reset_layout() -> void:
	var pw := panel.size.x
	body_label.position = Vector2(PopupFactoryScript.POPUP_PAD, 264)
	body_label.size = Vector2(pw - PopupFactoryScript.POPUP_PAD * 2.0, 130)
	balance_label.position = Vector2(0, 430)
	balance_label.size = Vector2(pw, 58)
	hide_move_circle()

func apply_result_text(message: String) -> void:
	var parsed := parse_hint_move(message)
	if parsed.is_empty():
		body_label.text = message
		hide_move_circle()
		return
	var moves_left := extract_hint_moves_left(message)
	var tap_next := Locale.t("hint.tap_next", "Tap this orbit number next.")
	body_label.text = "%s\n%s" % [moves_left, tap_next] if not moves_left.is_empty() else tap_next
	var pw := panel.size.x
	body_label.position = Vector2(PopupFactoryScript.POPUP_PAD, 250)
	body_label.size = Vector2(pw - PopupFactoryScript.POPUP_PAD * 2.0, 110)
	balance_label.position = Vector2(0, 600)
	show_move_circle(str(parsed["op"]), int(parsed["value"]))

func extract_hint_moves_left(message: String) -> String:
	for line in message.split("\n", false):
		var trimmed := str(line).strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("Next move:"):
			continue
		return trimmed
	return ""

func parse_hint_move(message: String) -> Dictionary:
	var marker := "Next move:"
	var idx := message.find(marker)
	if idx < 0:
		return {}
	var tail := message.substr(idx + marker.length()).strip_edges()
	var parts := tail.split(" ", false)
	if parts.size() < 2:
		return {}
	var op := op_from_hint_symbol(str(parts[0]))
	if op.is_empty():
		return {}
	return {"op": op, "value": int(parts[1])}

func op_from_hint_symbol(symbol: String) -> String:
	match symbol:
		"+":
			return "add"
		"−", "-":
			return "subtract"
		"×", "x", "*":
			return "multiply"
		"÷", "/":
			return "divide"
	return ""

func show_move_circle(op: String, value: int) -> void:
	if move_circle == null or move_label == null:
		return
	move_circle.visible = true
	move_circle.position = Vector2(panel.size.x * 0.5 - 87, 390)
	var style: StyleBoxFlat = UIStyles.card(UIStyles.operation_bg(op), UIStyles.operation_border(op), 90)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	move_circle.add_theme_stylebox_override("panel", style)
	move_label.text = str(value)
	UIStyles.apply_font(move_label, UIStyles.FONT_BOLD, 50, UIStyles.operation_text(op))

func hide_move_circle() -> void:
	if move_circle != null:
		move_circle.visible = false

func clear_cache() -> void:
	cached_popup_hint_text = ""
	cached_popup_move_index = -1
	hide_popup()

func hide_popup(after_hidden: Callable = Callable()) -> void:
	if panel != null:
		PopupFactoryScript.hide_sheet(self, panel, overlay, after_hidden)
	else:
		visible = false
		if after_hidden.is_valid():
			after_hidden.call()
