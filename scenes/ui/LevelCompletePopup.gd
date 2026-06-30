class_name LevelCompletePopup
extends Control

signal next_pressed
signal levels_pressed

var panel: Panel
var title_label: Label
var stars_label: Label
var moves_label: Label
var reward_label: Label
var next_button: Button
var levels_button: Button
var badge_panel: Panel

func _ready() -> void:
	size = Vector2(1080, 1920)
	z_index = 100
	visible = false
	build()

func build() -> void:
	for child in get_children():
		child.queue_free()

	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1080, 1920)
	overlay.color = Color(0.05, 0.06, 0.10, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	panel = Panel.new()
	panel.position = Vector2(110, 610)
	panel.size = Vector2(860, 660)
	panel.add_theme_stylebox_override("panel", UIStyles.soft_panel(Color.WHITE, 36))
	add_child(panel)

	badge_panel = Panel.new()
	badge_panel.position = Vector2(375, -45)
	badge_panel.size = Vector2(110, 110)
	badge_panel.add_theme_stylebox_override("panel", UIStyles.card(Color("#51C46B"), Color.WHITE, 55))
	panel.add_child(badge_panel)
	UIStyles.icon(UIStyles.ICON_CHECK, badge_panel, Vector2(28, 28), Vector2(54, 54), Color.WHITE)

	title_label = Label.new()
	title_label.position = Vector2(0, 95)
	title_label.size = Vector2(860, 100)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title_label, UIStyles.FONT_BOLD, 42, UIStyles.TEXT)
	panel.add_child(title_label)

	stars_label = Label.new()
	stars_label.position = Vector2(0, 198)
	stars_label.size = Vector2(860, 84)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(stars_label)

	moves_label = Label.new()
	moves_label.position = Vector2(0, 292)
	moves_label.size = Vector2(860, 54)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(moves_label, UIStyles.FONT_MEDIUM, 28, UIStyles.TEXT)
	panel.add_child(moves_label)

	reward_label = Label.new()
	reward_label.position = Vector2(70, 342)
	reward_label.size = Vector2(700, 62)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(reward_label, UIStyles.FONT_SEMIBOLD, 24, UIStyles.MUTED)
	panel.add_child(reward_label)

	next_button = Button.new()
	next_button.position = Vector2(145, 405)
	next_button.size = Vector2(570, 78)
	next_button.add_theme_font_size_override("font_size", 28)
	UIStyles.primary_button(next_button)
	next_button.pressed.connect(func(): next_pressed.emit())
	panel.add_child(next_button)

	levels_button = Button.new()
	levels_button.text = "Back to Levels"
	levels_button.position = Vector2(145, 515)
	levels_button.size = Vector2(570, 76)
	levels_button.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(levels_button)
	levels_button.pressed.connect(func(): levels_pressed.emit())
	panel.add_child(levels_button)

func show_result(title_text: String, stars: int, moves: int, has_next: bool, reward: int = 0, hint_points: int = 0, show_details: bool = true, tutorial_message: String = "") -> void:
	title_label.text = "%s COMPLETE!" % title_text if show_details else "Excellent!"
	stars_label.visible = show_details
	moves_label.visible = show_details
	reward_label.visible = true
	if show_details:
		title_label.position = Vector2(0, 112)
		title_label.size = Vector2(860, 62)
		UIStyles.apply_font(title_label, UIStyles.FONT_BOLD, 40, UIStyles.TEXT)
		stars_label.position = Vector2(0, 184)
		moves_label.position = Vector2(0, 274)
		reward_label.position = Vector2(60, 330)
		reward_label.size = Vector2(740, 58)
		next_button.position = Vector2(145, 405)
		next_button.size = Vector2(570, 78)
		levels_button.position = Vector2(145, 515)
		levels_button.size = Vector2(570, 76)
		draw_star_row(stars)
		moves_label.text = "Moves: %d" % moves
		if reward > 0:
			reward_label.text = "New reward: +%d bulbs  •  Balance: %d" % [reward, hint_points]
		else:
			reward_label.text = "Best reward already claimed  •  Balance: %d" % hint_points
	else:
		title_label.position = Vector2(0, 125)
		title_label.size = Vector2(860, 80)
		UIStyles.apply_font(title_label, UIStyles.FONT_BOLD, 42, UIStyles.TEXT)
		draw_star_row(0)
		reward_label.position = Vector2(90, 250)
		reward_label.size = Vector2(680, 145)
		reward_label.text = tutorial_message if not tutorial_message.is_empty() else "Good. Continue to the next idea."
		next_button.position = Vector2(145, 455)
		next_button.size = Vector2(570, 78)
		levels_button.visible = false
	next_button.text = "Next Level" if show_details else "Continue"
	levels_button.text = "Back to Levels" if show_details else "Back to All Levels"
	next_button.visible = has_next
	if show_details:
		levels_button.visible = true
	visible = true
	animate_open()

func animate_open() -> void:
	panel.scale = Vector2(0.94, 0.94)
	panel.pivot_offset = panel.size * 0.5
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if badge_panel != null:
		badge_panel.scale = Vector2(0.5, 0.5)
		badge_panel.pivot_offset = badge_panel.size * 0.5
		var badge_tween := badge_panel.create_tween()
		badge_tween.tween_property(badge_panel, "scale", Vector2(1.12, 1.12), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		badge_tween.tween_property(badge_panel, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func hide_popup() -> void:
	visible = false

func draw_star_row(count: int) -> void:
	stars_label.text = ""
	for child in stars_label.get_children():
		child.queue_free()
	for i in range(3):
		var texture: Texture2D = UIStyles.ICON_STAR if i < count else UIStyles.ICON_STAR_EMPTY
		var color: Color = UIStyles.GOLD if i < count else Color("#DADDE4")
		var star := UIStyles.icon(texture, stars_label, Vector2(255 + i * 116, 3), Vector2(78, 78), color)
		star.scale = Vector2(0.35, 0.35)
		star.pivot_offset = star.size * 0.5
		var tween := star.create_tween()
		tween.tween_interval(0.05 + float(i) * 0.055)
		tween.tween_property(star, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
