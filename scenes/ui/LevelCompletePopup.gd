class_name LevelCompletePopup
extends Control

const PopupFactoryScript = preload("res://scripts/ui/PopupFactory.gd")

signal next_pressed
signal levels_pressed
signal double_reward_requested

class RewardPlayIcon:
	extends Control

	var icon_color := Color("#4A2C00")

	func _draw() -> void:
		var inset := 1.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(inset, inset),
			Vector2(size.x - inset, size.y * 0.5),
			Vector2(inset, size.y - inset),
		]), icon_color)

var overlay: ColorRect
var panel: Panel
var title_label: Label
var stars_label: Control
var moves_label: Label
var reward_glow: Panel
var reward_pill: Button
var reward_sign_label: Label
var reward_number_label: Label
var reward_unit_label: Label
var reward_tab_gradient: TextureRect
var reward_tab_cover: ColorRect
var reward_play_icon: RewardPlayIcon
var reward_multiplier_sign_label: Label
var reward_multiplier_label: Label
var reward_hint_label: Label
var reward_label: Label
var next_button: Button
var levels_button: Button
var confetti_layer: Control
var panel_width := 1005.0
var panel_height := 1043.0
var confetti_rng := RandomNumberGenerator.new()
var reward_pulse_tween: Tween
var reward_glow_style: StyleBoxFlat

# 5.1: кэш аргументов последнего show_result — чтобы переприменить после build() на
# ресайзе (иначе заголовок/звёзды/ходы/награда обнулялись).
var _result_shown := false
var _r_title := ""
var _r_stars := 0
var _r_moves := 0
var _r_has_next := false
var _r_reward := 0
var _r_lumens := 0
var _r_show_details := true
var _r_tutorial_message := ""
var _reward_doubled := false

const DEFAULT_PANEL_HEIGHT := 1123.0
const TUTORIAL_PANEL_HEIGHT := 710.0
const REWARD_PILL_HEIGHT := 74.0
const REWARD_PILL_RADIUS := 37
const REWARD_ROW_Y := 448.0
const REWARD_HINT_Y := 548.0
const REWARD_HINT_HEIGHT := 44.0
const REWARD_ROW_GAP := 60.0
const REWARD_TAB_WIDTH := 132.0
const DETAILS_NEXT_Y := 630.0
const DETAILS_LEVELS_Y := 855.0
const REWARD_GOLD_TOP := Color("#FFD25E")
const REWARD_GOLD := Color("#F5A623")
const REWARD_PURPLE := Color("#5B32C4")
const REWARD_BROWN := Color("#4A2C00")
const REWARD_HINT_TEXT := Color("#9A7B1E")
const REWARD_DONE_HINT := Color("#2FB6A8")
const MODAL_Z_INDEX := 300
const SIGN_VERTICAL_NUDGE := -3.0

func _ready() -> void:
	# The tutorial coach can raise the persistent header to z=200. Completion is
	# a hard modal and must remain above every game/header control.
	z_index = MODAL_Z_INDEX
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	get_viewport().size_changed.connect(_on_viewport_resized)
	build()

func _on_viewport_resized() -> void:
	# Main marks a hidden popup dirty and rebuilds it immediately before its next
	# show. Recreating the whole hidden tree here only made the next build duplicate
	# that work.
	if not visible:
		return
	var was_visible := visible
	build()
	# 5.1: после ребилда переприменяем последний результат (без повторной анимации входа
	# и конфетти) — иначе контент попапа обнулялся.
	if was_visible and _result_shown:
		show_result(_r_title, _r_stars, _r_moves, _r_has_next, _r_reward, _r_lumens, _r_show_details, _r_tutorial_message, false)

func build() -> void:
	Layout.clear_children_for_rebuild(self)
	reward_pulse_tween = null
	reward_glow_style = null

	var vp := Layout.viewport_size(self)
	size = vp

	overlay = PopupFactoryScript.scrim(vp)
	add_child(overlay)
	panel_width = PopupFactoryScript.popup_width(vp.x)
	var pw := panel_width
	var ph := panel_height

	panel = Panel.new()
	panel.name = "PopupPanel"
	panel.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	panel.size = Vector2(pw, ph)
	PopupFactoryScript.apply_panel_glass(panel)
	PopupFactoryScript.register_sheet_panel(panel)
	add_child(panel)

	confetti_layer = Control.new()
	confetti_layer.position = Vector2.ZERO
	confetti_layer.size = panel.size
	confetti_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(confetti_layer)

	PopupFactoryScript.badge(panel, pw, Color("#7FE3D2"), Color("#2FB6A8"), UIStyles.ICON_CHECK, 94.0)

	title_label = PopupFactoryScript.title(panel, pw, "")

	stars_label = Control.new()
	stars_label.position = Vector2(0, 268)
	stars_label.size = Vector2(pw, 122)
	panel.add_child(stars_label)

	moves_label = Label.new()
	moves_label.position = Vector2(0, 402)
	moves_label.size = Vector2(pw, 58)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(moves_label, UIStyles.FONT_SEMIBOLD, 44, UIStyles.MUTED)
	panel.add_child(moves_label)

	reward_glow = Panel.new()
	reward_glow.position = Vector2(pw * 0.5 - 215.0, REWARD_ROW_Y)
	reward_glow.size = Vector2(430.0, REWARD_PILL_HEIGHT)
	reward_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_glow.visible = false
	panel.add_child(reward_glow)

	reward_pill = Button.new()
	reward_pill.text = ""
	reward_pill.position = reward_glow.position
	reward_pill.size = reward_glow.size
	reward_pill.focus_mode = Control.FOCUS_NONE
	reward_pill.clip_contents = true
	reward_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_pill.pressed.connect(func(): double_reward_requested.emit())
	UIStyles.add_press_animation(reward_pill, REWARD_PILL_RADIUS)
	panel.add_child(reward_pill)

	reward_tab_gradient = TextureRect.new()
	reward_tab_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_tab_gradient.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reward_tab_gradient.stretch_mode = TextureRect.STRETCH_SCALE
	reward_pill.add_child(reward_tab_gradient)

	# The gradient is baked as a full capsule, then its left rounded cap is
	# covered with white up to the section seam. This produces one straight
	# internal edge while retaining a perfectly rounded outer-right edge.
	reward_tab_cover = ColorRect.new()
	reward_tab_cover.color = Color.WHITE
	reward_tab_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_pill.add_child(reward_tab_cover)

	reward_sign_label = Label.new()
	reward_sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	reward_sign_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_sign_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_pill.add_child(reward_sign_label)

	reward_number_label = Label.new()
	reward_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	reward_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_pill.add_child(reward_number_label)

	reward_unit_label = Label.new()
	reward_unit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	reward_unit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_unit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_pill.add_child(reward_unit_label)

	reward_play_icon = RewardPlayIcon.new()
	reward_play_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_pill.add_child(reward_play_icon)

	reward_multiplier_sign_label = Label.new()
	reward_multiplier_sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	reward_multiplier_sign_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_multiplier_sign_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_pill.add_child(reward_multiplier_sign_label)

	reward_multiplier_label = Label.new()
	reward_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	reward_multiplier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_multiplier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_pill.add_child(reward_multiplier_label)

	reward_hint_label = Label.new()
	reward_hint_label.position = Vector2(PopupFactoryScript.POPUP_PAD, REWARD_HINT_Y)
	reward_hint_label.size = Vector2(pw - PopupFactoryScript.POPUP_PAD * 2.0, REWARD_HINT_HEIGHT)
	reward_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	reward_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_hint_label.visible = false
	UIStyles.apply_font(reward_hint_label, UIStyles.FONT_SEMIBOLD, 30, REWARD_HINT_TEXT)
	panel.add_child(reward_hint_label)

	reward_label = Label.new()
	reward_label.position = Vector2(67, 462)
	reward_label.size = Vector2(pw - 134, 64)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(reward_label, UIStyles.FONT_SEMIBOLD, 40, UIStyles.MUTED)
	panel.add_child(reward_label)

	next_button = PopupFactoryScript.primary_button("", pw, DETAILS_NEXT_Y)
	next_button.pressed.connect(func(): next_pressed.emit())
	panel.add_child(next_button)

	levels_button = PopupFactoryScript.secondary_button(Locale.t("complete.back", "Back to Levels"), pw, DETAILS_LEVELS_Y)
	levels_button.pressed.connect(func(): levels_pressed.emit())
	panel.add_child(levels_button)

func show_result(title_text: String, stars: int, moves: int, has_next: bool, reward: int = 0, lumens: int = 0, show_details: bool = true, tutorial_message: String = "", animate: bool = true) -> void:
	_result_shown = true
	_r_title = title_text
	_r_stars = stars
	_r_moves = moves
	_r_has_next = has_next
	_r_reward = reward
	_r_lumens = lumens
	_r_show_details = show_details
	_r_tutorial_message = tutorial_message
	# A fresh completion (animate) resets the one-shot; resize re-applies keep it.
	if animate:
		_reward_doubled = false
	set_panel_height(TUTORIAL_PANEL_HEIGHT if not show_details else DEFAULT_PANEL_HEIGHT)
	var pw := panel_width
	var raw_title: String = Locale.t("complete.title", "%s Complete!") % title_text.capitalize() if show_details else Locale.t("complete.excellent", "Excellent!")
	title_label.text = raw_title.to_upper()
	stars_label.visible = show_details
	moves_label.visible = show_details
	reward_pill.visible = show_details
	reward_glow.visible = false
	reward_hint_label.visible = false
	reward_label.visible = not show_details
	if show_details:
		title_label.position = Vector2(0, 154)
		stars_label.position = Vector2(0, 292)
		next_button.position = Vector2(PopupFactoryScript.POPUP_PAD, DETAILS_NEXT_Y)
		levels_button.position = Vector2(PopupFactoryScript.POPUP_PAD, DETAILS_LEVELS_Y)
		draw_star_row(stars, animate)
		moves_label.text = Locale.t("complete.moves", "Moves: %d") % moves
		update_reward_pill(reward * 2 if _reward_doubled else reward)
		next_button.visible = has_next
		levels_button.visible = true
	else:
		stop_reward_pulse()
		title_label.position = Vector2(0, 150.0)
		next_button.position = Vector2(PopupFactoryScript.POPUP_PAD, 470.0)
		levels_button.position = Vector2(PopupFactoryScript.POPUP_PAD, 795.0)
		draw_star_row(0, animate)
		reward_glow.visible = false
		reward_pill.visible = false
		reward_hint_label.visible = false
		reward_label.visible = true
		reward_label.position = Vector2(80, 280.0)
		reward_label.size = Vector2(pw - 160, 140.0)
		reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_label.text = tutorial_message if not tutorial_message.is_empty() else Locale.t("complete.continue_idea", "Good. Continue to the next idea.")
		next_button.visible = has_next
		levels_button.visible = false
	next_button.text = Locale.t("complete.next", "Next Level") if show_details else Locale.t("complete.continue", "Continue")
	levels_button.text = Locale.t("complete.back", "Back to Levels")
	PopupFactoryScript.show_sheet(self, panel, overlay)
	if animate and show_details:
		start_confetti()

# Player watched an ad to double the reward. The action stays in the reward row:
# buttons and panel geometry never move, and the pill becomes a static receipt.
func apply_reward_doubled() -> void:
	_reward_doubled = true
	update_reward_pill(_r_reward * 2)

func set_panel_height(height: float) -> void:
	if panel == null:
		return
	panel_height = height
	panel.size.y = height
	panel.position = (size - panel.size) * 0.5
	if confetti_layer != null:
		confetti_layer.size = panel.size
	PopupFactoryScript.register_sheet_panel(panel)

func update_reward_pill(reward: int) -> void:
	if reward_pill == null or reward_number_label == null:
		return
	reward_pill.visible = true
	reward_label.visible = false
	var amount: int = max(0, reward)
	var interactive := amount > 0 and not _reward_doubled
	var doubled := amount > 0 and _reward_doubled
	# Keep the signs in their own labels. Poppins positions + and × slightly low
	# on the text baseline, so they receive a small optical lift without moving
	# the adjacent digits.
	var sign_text := "+" if amount > 0 else ""
	var number_text := (Locale.t("complete.reward", "%d Lumens") % amount if doubled else str(amount)) if amount > 0 else Locale.t("complete.reward_claimed", "Reward claimed")
	var unit_text := localized_reward_unit(amount) if interactive else ""
	var amount_font_size := 38 if amount > 0 else 32
	var unit_font_size := 24
	var sign_width := UIStyles.FONT_BOLD.get_string_size(sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, amount_font_size).x
	var number_width := UIStyles.FONT_BOLD.get_string_size(number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, amount_font_size).x
	var unit_width := UIStyles.FONT_BOLD.get_string_size(unit_text, HORIZONTAL_ALIGNMENT_LEFT, -1, unit_font_size).x
	var sign_number_gap := 1.0
	var number_unit_gap := 10.0
	var tab_width := REWARD_TAB_WIDTH if interactive else 0.0
	var left_content_width := number_width
	if amount > 0:
		left_content_width += sign_width + sign_number_gap
	if interactive and not unit_text.is_empty():
		left_content_width += number_unit_gap + unit_width
	var left_width := maxf(228.0, left_content_width + 52.0)
	var reward_width := clampf(left_width + tab_width, 360.0, 470.0) if interactive else clampf(left_content_width + 64.0, 300.0, 400.0)
	if amount <= 0:
		reward_width = clampf(number_width + 72.0, 300.0, 410.0)
		left_width = reward_width
	var moves_width := UIStyles.FONT_SEMIBOLD.get_string_size(moves_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
	var row_width := moves_width + REWARD_ROW_GAP + reward_width
	var row_x := (panel_width - row_width) * 0.5
	moves_label.position = Vector2(row_x, REWARD_ROW_Y + 8.0)
	moves_label.size = Vector2(moves_width, 58.0)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_pill.position = Vector2(row_x + moves_width + REWARD_ROW_GAP, REWARD_ROW_Y)
	reward_pill.size = Vector2(reward_width, REWARD_PILL_HEIGHT)
	reward_pill.pivot_offset = reward_pill.size * 0.5
	reward_glow.position = reward_pill.position
	reward_glow.size = reward_pill.size
	reward_pill.disabled = not interactive
	reward_pill.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE

	reward_tab_gradient.visible = interactive
	reward_tab_cover.visible = interactive
	reward_play_icon.visible = interactive
	reward_multiplier_sign_label.visible = interactive
	reward_multiplier_label.visible = interactive
	reward_sign_label.visible = amount > 0
	reward_unit_label.visible = interactive and not unit_text.is_empty()

	if amount <= 0:
		stop_reward_pulse()
		reward_hint_label.visible = false
		# Claimed rewards use the same soft-purple treatment as Back to Levels:
		# tinted fill, purple text, and no glass outline.
		var claimed_bg := Color(1, 1, 1, 0.08) if UIStyles.is_dark() else Color(UIStyles.PURPLE.r, UIStyles.PURPLE.g, UIStyles.PURPLE.b, 0.10)
		var claimed_text := Color("#C4B5FD") if UIStyles.is_dark() else UIStyles.PURPLE_DARK
		set_reward_pill_style(claimed_bg, Color.TRANSPARENT, 0)
		reward_sign_label.text = ""
		reward_number_label.text = number_text
		reward_number_label.position = Vector2.ZERO
		reward_number_label.size = reward_pill.size
		reward_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_unit_label.text = ""
		UIStyles.apply_font(reward_number_label, UIStyles.FONT_BOLD, amount_font_size, claimed_text)
		return

	left_width = reward_width - tab_width
	var group_x := (left_width - left_content_width) * 0.5
	reward_sign_label.text = sign_text
	reward_sign_label.position = Vector2(group_x, SIGN_VERTICAL_NUDGE)
	reward_sign_label.size = Vector2(sign_width + 2.0, REWARD_PILL_HEIGHT)
	reward_number_label.text = number_text
	reward_number_label.position = Vector2(group_x + sign_width + sign_number_gap, 0.0)
	reward_number_label.size = Vector2(number_width + 4.0, REWARD_PILL_HEIGHT)
	reward_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	reward_unit_label.text = unit_text
	reward_unit_label.position = Vector2(group_x + sign_width + sign_number_gap + number_width + number_unit_gap, 1.0)
	reward_unit_label.size = Vector2(unit_width + 4.0, REWARD_PILL_HEIGHT)

	var seam_x := reward_width - tab_width
	if interactive:
		set_reward_pill_style(Color.WHITE, REWARD_GOLD)
		UIStyles.apply_font(reward_sign_label, UIStyles.FONT_BOLD, amount_font_size, REWARD_PURPLE)
		UIStyles.apply_font(reward_number_label, UIStyles.FONT_BOLD, amount_font_size, REWARD_PURPLE)
		UIStyles.apply_font(reward_unit_label, UIStyles.FONT_BOLD, unit_font_size, UIStyles.MUTED)
		configure_reward_tab(seam_x, tab_width)
		var multiplier_sign_width := UIStyles.FONT_EXTRABOLD.get_string_size("×", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
		var multiplier_number_width := UIStyles.FONT_EXTRABOLD.get_string_size("2", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
		var icon_width := 20.0
		var icon_gap := 13.0
		var multiplier_gap := 1.0
		var tab_content_width := icon_width + icon_gap + multiplier_sign_width + multiplier_gap + multiplier_number_width
		var tab_content_x := seam_x + (tab_width - tab_content_width) * 0.5
		reward_play_icon.position = Vector2(tab_content_x, 25.0)
		reward_play_icon.size = Vector2(20.0, 24.0)
		reward_play_icon.icon_color = REWARD_BROWN
		reward_play_icon.queue_redraw()
		reward_multiplier_sign_label.text = "×"
		reward_multiplier_sign_label.position = Vector2(tab_content_x + icon_width + icon_gap, SIGN_VERTICAL_NUDGE)
		reward_multiplier_sign_label.size = Vector2(multiplier_sign_width + 2.0, REWARD_PILL_HEIGHT)
		reward_multiplier_label.text = "2"
		reward_multiplier_label.position = Vector2(tab_content_x + icon_width + icon_gap + multiplier_sign_width + multiplier_gap, 0.0)
		reward_multiplier_label.size = Vector2(multiplier_number_width + 2.0, REWARD_PILL_HEIGHT)
		UIStyles.apply_font(reward_multiplier_sign_label, UIStyles.FONT_EXTRABOLD, 32, REWARD_BROWN)
		UIStyles.apply_font(reward_multiplier_label, UIStyles.FONT_EXTRABOLD, 32, REWARD_BROWN)
		reward_hint_label.text = Locale.t("complete.double_hint", "Tap ×2 to double — watch a short ad")
		UIStyles.apply_font(reward_hint_label, UIStyles.FONT_SEMIBOLD, 30, REWARD_HINT_TEXT)
		reward_hint_label.visible = true
		start_reward_pulse()
	elif doubled:
		stop_reward_pulse()
		var receipt_bg := Color(167.0 / 255.0, 139.0 / 255.0, 250.0 / 255.0, 0.16) if UIStyles.is_dark() else Color(139.0 / 255.0, 92.0 / 255.0, 246.0 / 255.0, 0.10)
		var receipt_text := Color("#C4B5FD") if UIStyles.is_dark() else REWARD_PURPLE
		set_reward_pill_style(receipt_bg, Color.TRANSPARENT, 0)
		UIStyles.apply_font(reward_sign_label, UIStyles.FONT_BOLD, amount_font_size, receipt_text)
		UIStyles.apply_font(reward_number_label, UIStyles.FONT_BOLD, amount_font_size, receipt_text)
		reward_hint_label.text = Locale.t("complete.double_done", "Reward doubled!")
		UIStyles.apply_font(reward_hint_label, UIStyles.FONT_SEMIBOLD, 30, REWARD_DONE_HINT)
		reward_hint_label.visible = true

func localized_reward_unit(amount: int) -> String:
	var localized := Locale.t("complete.reward", "%d Lumens") % amount
	var amount_text := str(amount)
	var amount_index := localized.find(amount_text)
	if amount_index < 0:
		return localized.strip_edges()
	var before := localized.substr(0, amount_index).strip_edges()
	var after := localized.substr(amount_index + amount_text.length()).strip_edges()
	return ("%s %s" % [before, after]).strip_edges()

func set_reward_pill_style(background: Color, border: Color, border_width: int = 2) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = background
	normal.border_color = border
	UIStyles._set_border(normal, border_width)
	UIStyles._set_radius(normal, REWARD_PILL_RADIUS)
	reward_pill.add_theme_stylebox_override("normal", normal)
	reward_pill.add_theme_stylebox_override("hover", normal.duplicate())
	reward_pill.add_theme_stylebox_override("pressed", normal.duplicate())
	reward_pill.add_theme_stylebox_override("disabled", normal.duplicate())

func configure_reward_tab(seam_x: float, tab_width: float) -> void:
	var inset := 2.0
	var inner_height := REWARD_PILL_HEIGHT - inset * 2.0
	var inner_radius := int(inner_height * 0.5)
	var gradient_x := seam_x - float(inner_radius)
	var gradient_width := reward_pill.size.x - inset - gradient_x
	reward_tab_gradient.position = Vector2(gradient_x, inset)
	reward_tab_gradient.size = Vector2(gradient_width, inner_height)
	reward_tab_gradient.texture = UIStyles.rounded_gradient_texture(
		REWARD_GOLD_TOP,
		REWARD_GOLD,
		inner_radius,
		Vector2i(maxi(1, roundi(gradient_width)), maxi(1, roundi(inner_height)))
	)
	reward_tab_cover.position = Vector2(gradient_x, inset)
	reward_tab_cover.size = Vector2(reward_pill.size.x - tab_width - gradient_x, inner_height)
	reward_tab_cover.color = Color.WHITE

func start_reward_pulse() -> void:
	stop_reward_pulse()
	reward_glow_style = StyleBoxFlat.new()
	reward_glow_style.bg_color = Color.TRANSPARENT
	reward_glow_style.shadow_color = Color(REWARD_GOLD.r, REWARD_GOLD.g, REWARD_GOLD.b, 0.42)
	reward_glow_style.shadow_offset = Vector2.ZERO
	UIStyles._set_radius(reward_glow_style, REWARD_PILL_RADIUS)
	reward_glow.add_theme_stylebox_override("panel", reward_glow_style)
	reward_glow.visible = true
	set_reward_pulse(0.0)
	reward_pulse_tween = reward_glow.create_tween().set_loops()
	reward_pulse_tween.tween_method(set_reward_pulse, 0.0, 1.0, UIStyles.ATTENTION_PULSE_HALF_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	reward_pulse_tween.tween_method(set_reward_pulse, 1.0, 0.0, UIStyles.ATTENTION_PULSE_HALF_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func set_reward_pulse(level: float) -> void:
	if reward_glow == null or reward_glow_style == null:
		return
	reward_glow_style.shadow_size = roundi(UIStyles.attention_glow_extent(level))
	reward_glow.modulate.a = UIStyles.attention_glow_alpha(level)

func stop_reward_pulse() -> void:
	if reward_pulse_tween != null and reward_pulse_tween.is_valid():
		reward_pulse_tween.kill()
	reward_pulse_tween = null
	if reward_glow != null:
		reward_glow.visible = false
		reward_glow.modulate.a = 0.0
	reward_glow_style = null

func hide_popup(after_hidden: Callable = Callable()) -> void:
	if panel != null:
		PopupFactoryScript.hide_sheet(self, panel, overlay, func() -> void:
			stop_reward_pulse()
			clear_confetti()
			if after_hidden.is_valid():
				after_hidden.call()
		)
	else:
		stop_reward_pulse()
		visible = false
		if after_hidden.is_valid():
			after_hidden.call()

func draw_star_row(count: int, animate: bool = true) -> void:
	for child in stars_label.get_children():
		child.queue_free()
	var star_size := 112.0
	var gap := 40.0
	var total := star_size * 3.0 + gap * 2.0
	var start_x := (panel_width - total) * 0.5
	for i in range(3):
		var texture: Texture2D = UIStyles.ICON_STAR if i < count else UIStyles.ICON_STAR_EMPTY
		var color: Color = UIStyles.GOLD if i < count else UIStyles.STAR_EMPTY
		var position := Vector2(start_x + i * (star_size + gap), 3)
		var star := UIStyles.icon(texture, stars_label, position, Vector2(star_size, star_size), color)
		star.pivot_offset = star.size * 0.5
		if not animate:
			star.scale = Vector2.ONE
			star.modulate.a = 1.0
			continue
		star.scale = Vector2(0.62, 0.62) if i < count else Vector2(0.82, 0.82)
		star.modulate.a = 0.0
		var tween := star.create_tween()
		tween.tween_interval(float(i) * 0.08)
		if count == 3:
			tween.tween_property(star, "scale", Vector2(1.3, 1.3), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(star, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		else:
			tween.tween_property(star, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(star, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func start_confetti() -> void:
	if confetti_layer == null:
		return
	clear_confetti()
	confetti_rng.randomize()
	var colors := [
		Color("#FBBF24"),
		Color("#7FE3D2"),
		Color("#A78BFA"),
		Color("#F87171"),
		Color("#60A5FA"),
		Color("#FFFFFF")
	]
	var count := confetti_rng.randi_range(22, 28)
	for _i in range(count):
		var size := confetti_rng.randf_range(12.0, 25.0)
		var color: Color = colors[confetti_rng.randi_range(0, colors.size() - 1)]
		var particle := make_confetti_particle(size, color, confetti_rng.randf() > 0.5)
		particle.position = Vector2(confetti_rng.randf_range(60.0, panel_width - 60.0), -40.0 - confetti_rng.randf_range(0.0, 80.0))
		particle.rotation = confetti_rng.randf_range(-0.7, 0.7)
		particle.pivot_offset = particle.size * 0.5
		particle.modulate.a = 1.0
		confetti_layer.add_child(particle)

		var duration := confetti_rng.randf_range(2.2, 3.9)
		var delay := confetti_rng.randf_range(0.0, 0.6)
		var drift := confetti_rng.randf_range(-95.0, 95.0)
		var rotation_dir := -1.0 if confetti_rng.randf() < 0.5 else 1.0
		var tween := particle.create_tween()
		tween.tween_interval(delay)
		tween.tween_property(particle, "position", Vector2(particle.position.x + drift, 900.0), duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(particle, "rotation", particle.rotation + deg_to_rad(540.0) * rotation_dir, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween.finished.connect(func() -> void:
			if is_instance_valid(particle):
				particle.queue_free()
		)

func make_confetti_particle(size: float, color: Color, circle: bool) -> Control:
	if circle:
		var dot := Panel.new()
		dot.size = Vector2(size, size)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = color
		UIStyles._set_radius(style, int(size * 0.5))
		dot.add_theme_stylebox_override("panel", style)
		return dot
	var square := ColorRect.new()
	square.size = Vector2(size, size)
	square.color = color
	square.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return square

func clear_confetti() -> void:
	if confetti_layer == null:
		return
	for child in confetti_layer.get_children():
		child.queue_free()
