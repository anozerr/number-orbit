class_name HintPopup
extends Control

const PopupFactoryScript = preload("res://scripts/ui/PopupFactory.gd")
const HintSolverScript = preload("res://scripts/game/HintSolver.gd")

class HintMoveOutline:
	extends Control

	var outline_color: Color = Color.WHITE
	var outline_width := 4.0

	func _draw() -> void:
		var radius := minf(size.x, size.y) * 0.5 - outline_width * 0.5
		if radius <= 0.0:
			return
		draw_arc(size * 0.5, radius, 0.0, TAU, 192, outline_color, outline_width, true)

signal hint_requested
signal hint_ad_requested(reward_amount: int)

var current_lumens: int = 0
var current_moves: int = 0
var current_hint_cost: int = 0
var current_ad_reward: int = 0
var cached_popup_hint_text: String = ""
var cached_popup_target: Dictionary = {}
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
var move_outline: HintMoveOutline

const DEFAULT_PANEL_HEIGHT := 1003.0
const COMPACT_RESULT_PANEL_HEIGHT := 740.0

func build(viewport_width: float) -> void:
	Layout.clear_children_for_rebuild(self)
	z_index = 100
	visible = false

	overlay = PopupFactoryScript.scrim(Vector2.ZERO, func() -> void: hide_popup())
	add_child(overlay)

	var pw := PopupFactoryScript.popup_width(viewport_width)
	panel = Panel.new()
	panel.name = "PopupPanel"
	panel.size = Vector2(pw, DEFAULT_PANEL_HEIGHT)
	PopupFactoryScript.apply_panel_glass(panel)
	PopupFactoryScript.register_sheet_panel(panel)
	add_child(panel)

	PopupFactoryScript.badge(panel, pw, Color("#FFD98F"), Color("#F5A93D"), UIStyles.ICON_BULB, 101.0)
	PopupFactoryScript.title(panel, pw, Locale.t("hint.title", "HINT"))

	body_label = PopupFactoryScript.body(panel, pw, "Spend Lumens to reveal one next move.", 264.0, 130.0)

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

	move_outline = HintMoveOutline.new()
	move_outline.size = move_circle.size
	move_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_outline.z_index = 10
	move_circle.add_child(move_outline)

	balance_label = Label.new()
	balance_label.position = Vector2(0, 430)
	balance_label.size = Vector2(pw, 58)
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(balance_label, UIStyles.FONT_SEMIBOLD, 40, UIStyles.MUTED)
	panel.add_child(balance_label)

	buy_button = PopupFactoryScript.primary_button(Locale.t("hint.use", "Use Hint"), pw, 520.0)
	buy_button.pressed.connect(func(): hint_requested.emit())
	panel.add_child(buy_button)

	ad_button = PopupFactoryScript.primary_button(Locale.t("levels.locked.watch_ad", "Watch Ad"), pw, 520.0)
	ad_button.pressed.connect(func(): hint_ad_requested.emit(current_ad_reward))
	ad_button.visible = false
	panel.add_child(ad_button)

	cancel_button = PopupFactoryScript.secondary_button(Locale.t("common.cancel", "Cancel"), pw, 755.0)
	cancel_button.pressed.connect(func(): hide_popup())
	panel.add_child(cancel_button)

func configure_state(moves: int, lumens: int, hint_cost: int, ad_reward: int) -> void:
	current_moves = moves
	current_lumens = lumens
	current_hint_cost = hint_cost
	current_ad_reward = ad_reward
	if cached_popup_move_index != current_moves:
		cached_popup_hint_text = ""
		cached_popup_target.clear()
		cached_popup_move_index = -1

func layout_to_viewport(viewport_size: Vector2) -> void:
	size = viewport_size
	if overlay != null:
		overlay.size = viewport_size
	if panel != null:
		panel.position = (viewport_size - panel.size) * 0.5
		PopupFactoryScript.register_sheet_panel(panel)

func show_prompt() -> void:
	var was_visible := visible
	set_panel_height(DEFAULT_PANEL_HEIGHT)
	reset_layout()
	if cached_popup_move_index == current_moves and not cached_popup_hint_text.is_empty():
		apply_result_text(cached_popup_hint_text, cached_popup_target)
		balance_label.text = Locale.t("hint.balance", "Balance: %d Lumens") % current_lumens
		buy_button.visible = false
		ad_button.visible = false
		cancel_button.text = Locale.t("common.back", "Back")
	else:
		body_label.position.y = 314.0
		body_label.text = Locale.t("hint.body", "Spend %d Lumens to analyze this position.") % current_hint_cost
		hide_move_circle()
		balance_label.text = Locale.t("hint.balance", "Balance: %d Lumens") % current_lumens
		balance_label.visible = false
		buy_button.visible = true
		ad_button.visible = false
		cancel_button.text = Locale.t("common.cancel", "Cancel")
	show_popup_if_hidden(was_visible)

func show_result(message: String, balance: int, target: Dictionary = {}) -> void:
	var was_visible := visible
	current_lumens = balance
	cache_result(message, balance, target)
	var has_winning_move := not target.is_empty()
	set_panel_height(DEFAULT_PANEL_HEIGHT if has_winning_move else COMPACT_RESULT_PANEL_HEIGHT)
	reset_layout()
	apply_result_text(message, target)
	balance_label.text = Locale.t("hint.balance", "Balance: %d Lumens") % current_lumens
	balance_label.visible = true
	buy_button.visible = false
	ad_button.visible = false
	cancel_button.text = Locale.t("common.back", "Back")
	if not has_winning_move:
		body_label.position = Vector2(PopupFactoryScript.POPUP_PAD, 264.0)
		body_label.size = Vector2(panel.size.x - PopupFactoryScript.POPUP_PAD * 2.0, 126.0)
		balance_label.position = Vector2(0, 410.0)
		cancel_button.position.y = 498.0
	show_popup_if_hidden(was_visible)

func show_insufficient_balance(balance: int) -> void:
	var was_visible := visible
	current_lumens = balance
	cached_popup_hint_text = ""
	cached_popup_target.clear()
	cached_popup_move_index = -1
	set_panel_height(DEFAULT_PANEL_HEIGHT)
	reset_layout()
	body_label.position = Vector2(PopupFactoryScript.POPUP_PAD, 246.0)
	body_label.size = Vector2(panel.size.x - PopupFactoryScript.POPUP_PAD * 2.0, 164.0)
	UIStyles.apply_font(body_label, UIStyles.FONT_SEMIBOLD, 38, UIStyles.MUTED)
	body_label.text = Locale.t(
		"hint.insufficient",
		"Not enough Lumens for a hint. Watch an ad to get %d Lumens."
	) % current_ad_reward
	hide_move_circle()
	balance_label.position.y = 420.0
	balance_label.text = Locale.t("hint.balance_short", "Balance: %d / %d Lumens") % [current_lumens, current_hint_cost]
	balance_label.visible = true
	buy_button.visible = false
	ad_button.text = Locale.t("levels.locked.watch_ad", "Watch Ad")
	ad_button.visible = true
	cancel_button.text = Locale.t("common.cancel", "Cancel")
	show_popup_if_hidden(was_visible)

func show_popup_if_hidden(was_visible: bool) -> void:
	if not was_visible:
		PopupFactoryScript.show_pop(self, panel, overlay)

func cache_result(message: String, balance: int, target: Dictionary = {}) -> void:
	current_lumens = balance
	cached_popup_hint_text = message
	cached_popup_target = target.duplicate(true)
	cached_popup_move_index = current_moves

func has_cached_result() -> bool:
	return cached_popup_move_index == current_moves and not cached_popup_hint_text.is_empty()

func reset_layout() -> void:
	var pw := panel.size.x
	body_label.position = Vector2(PopupFactoryScript.POPUP_PAD, 264)
	body_label.size = Vector2(pw - PopupFactoryScript.POPUP_PAD * 2.0, 130)
	UIStyles.apply_font(body_label, UIStyles.FONT_SEMIBOLD, 45, UIStyles.MUTED)
	balance_label.position = Vector2(0, 430)
	balance_label.size = Vector2(pw, 58)
	balance_label.visible = true
	buy_button.position.y = 520.0
	ad_button.position.y = 520.0
	cancel_button.position.y = 755.0
	hide_move_circle()

func set_panel_height(height: float) -> void:
	if panel == null:
		return
	panel.size.y = height
	panel.position = (size - panel.size) * 0.5
	PopupFactoryScript.register_sheet_panel(panel)

func apply_result_text(message: String, target: Dictionary) -> void:
	if target.is_empty():
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
	show_move_circle(str(target.get("op", "")), int(target.get("value", 0)))

func extract_hint_moves_left(message: String) -> String:
	for line in message.split("\n", false):
		var trimmed := str(line).strip_edges()
		if trimmed.is_empty() or trimmed.begins_with(HintSolverScript.NEXT_MOVE_MARKER):
			continue
		return trimmed
	return ""

func show_move_circle(op: String, value: int) -> void:
	if move_circle == null or move_label == null:
		return
	move_circle.visible = true
	move_circle.position = Vector2(panel.size.x * 0.5 - 87, 390)
	var style := StyleBoxFlat.new()
	style.bg_color = UIStyles.operation_bg(op)
	UIStyles._set_radius(style, 85)
	move_circle.add_theme_stylebox_override("panel", style)
	if move_outline != null:
		move_outline.outline_color = UIStyles.operation_border(op)
		move_outline.outline_width = 4.0
		move_outline.queue_redraw()
	move_label.text = str(value)
	UIStyles.apply_font(move_label, UIStyles.FONT_BOLD, 50, UIStyles.operation_text(op))

func hide_move_circle() -> void:
	if move_circle != null:
		move_circle.visible = false

func clear_cache() -> void:
	cached_popup_hint_text = ""
	cached_popup_target.clear()
	cached_popup_move_index = -1
	hide_popup()

func hide_popup(after_hidden: Callable = Callable()) -> void:
	if panel != null:
		PopupFactoryScript.hide_sheet(self, panel, overlay, after_hidden)
	else:
		visible = false
		if after_hidden.is_valid():
			after_hidden.call()
