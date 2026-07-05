class_name LevelCompletePopup
extends Control

signal next_pressed
signal levels_pressed

var panel: Panel
var title_label: Label
var stars_label: Control
var moves_label: Label
var reward_label: Label
var next_button: Button
var levels_button: Button
var badge_circle: TextureRect
var panel_width := 1005.0
var panel_height := 1043.0

func _ready() -> void:
	z_index = 100
	visible = false
	get_viewport().size_changed.connect(_on_viewport_resized)
	build()

func _on_viewport_resized() -> void:
	if visible:
		build()

func build() -> void:
	for child in get_children():
		child.queue_free()

	var vp := Layout.viewport_size(self)
	size = vp

	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = vp
	overlay.color = Color(0.03, 0.02, 0.08, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	panel_width = UIStyles.popup_width(vp.x)
	var pw := panel_width
	var ph := panel_height

	panel = Panel.new()
	panel.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	panel.size = Vector2(pw, ph)
	panel.add_theme_stylebox_override("panel", UIStyles.popup_panel_style())
	add_child(panel)

	badge_circle = UIStyles.popup_badge(panel, pw, Color("#7FE3D2"), Color("#2FB6A8"), UIStyles.ICON_CHECK, 94.0)

	title_label = UIStyles.popup_title(panel, pw, "")

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

	reward_label = Label.new()
	reward_label.position = Vector2(67, 462)
	reward_label.size = Vector2(pw - 134, 64)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(reward_label, UIStyles.FONT_SEMIBOLD, 40, UIStyles.MUTED)
	panel.add_child(reward_label)

	next_button = UIStyles.popup_primary_button("", pw, 560.0)
	next_button.pressed.connect(func(): next_pressed.emit())
	panel.add_child(next_button)

	levels_button = UIStyles.popup_secondary_button(Locale.t("complete.back", "Back to Levels"), pw, 795.0)
	levels_button.pressed.connect(func(): levels_pressed.emit())
	panel.add_child(levels_button)

func show_result(title_text: String, stars: int, moves: int, has_next: bool, reward: int = 0, hint_points: int = 0, show_details: bool = true, tutorial_message: String = "") -> void:
	var pw := panel_width
	var ph := panel_height
	var raw_title: String = Locale.t("complete.title", "%s Complete!") % title_text.capitalize() if show_details else Locale.t("complete.excellent", "Excellent!")
	title_label.text = raw_title.to_upper()
	stars_label.visible = show_details
	moves_label.visible = show_details
	reward_label.visible = true
	if show_details:
		title_label.position = Vector2(0, 154)
		stars_label.position = Vector2(0, 268)
		moves_label.position = Vector2(0, 402)
		reward_label.position = Vector2(67, 462)
		reward_label.size = Vector2(pw - 134, 64)
		draw_star_row(stars)
		moves_label.text = Locale.t("complete.moves", "Moves: %d") % moves
		if reward > 0:
			reward_label.text = Locale.t("complete.reward", "New reward: +%d bulbs  •  Balance: %d") % [reward, hint_points]
		else:
			reward_label.text = Locale.t("complete.reward_claimed", "Best reward already claimed  •  Balance: %d") % hint_points
		next_button.visible = has_next
		levels_button.visible = true
	else:
		title_label.position = Vector2(0, 200)
		draw_star_row(0)
		reward_label.position = Vector2(80, 340)
		reward_label.size = Vector2(pw - 160, 200)
		reward_label.text = tutorial_message if not tutorial_message.is_empty() else Locale.t("complete.continue_idea", "Good. Continue to the next idea.")
		next_button.visible = has_next
		levels_button.visible = false
	next_button.text = Locale.t("complete.next", "Next Level") if show_details else Locale.t("complete.continue", "Continue")
	levels_button.text = Locale.t("complete.back", "Back to Levels")
	visible = true
	animate_open()

func animate_open() -> void:
	panel.scale = Vector2(0.94, 0.94)
	panel.pivot_offset = panel.size * 0.5
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if badge_circle != null:
		badge_circle.scale = Vector2(0.5, 0.5)
		badge_circle.pivot_offset = badge_circle.size * 0.5
		var badge_tween := badge_circle.create_tween()
		badge_tween.tween_property(badge_circle, "scale", Vector2(1.12, 1.12), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		badge_tween.tween_property(badge_circle, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func hide_popup() -> void:
	visible = false

func draw_star_row(count: int) -> void:
	for child in stars_label.get_children():
		child.queue_free()
	var star_size := 112.0
	var gap := 40.0
	var total := star_size * 3.0 + gap * 2.0
	var start_x := (panel_width - total) * 0.5
	for i in range(3):
		var texture: Texture2D = UIStyles.ICON_STAR if i < count else UIStyles.ICON_STAR_EMPTY
		var color: Color = UIStyles.GOLD if i < count else UIStyles.STAR_EMPTY
		var star := UIStyles.icon(texture, stars_label, Vector2(start_x + i * (star_size + gap), 3), Vector2(star_size, star_size), color)
		star.scale = Vector2(0.35, 0.35)
		star.pivot_offset = star.size * 0.5
		var tween := star.create_tween()
		tween.tween_interval(0.05 + float(i) * 0.055)
		tween.tween_property(star, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
