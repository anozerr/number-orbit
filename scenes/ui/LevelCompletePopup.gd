class_name LevelCompletePopup
extends Control

const PopupFactoryScript = preload("res://scripts/ui/PopupFactory.gd")

signal next_pressed
signal levels_pressed

var overlay: ColorRect
var panel: Panel
var title_label: Label
var stars_label: Control
var moves_label: Label
var reward_label: Label
var next_button: Button
var levels_button: Button
var badge_circle: TextureRect
var confetti_layer: Control
var panel_width := 1005.0
var panel_height := 1043.0
var confetti_rng := RandomNumberGenerator.new()

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

	badge_circle = PopupFactoryScript.badge(panel, pw, Color("#7FE3D2"), Color("#2FB6A8"), UIStyles.ICON_CHECK, 94.0)

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

	reward_label = Label.new()
	reward_label.position = Vector2(67, 462)
	reward_label.size = Vector2(pw - 134, 64)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(reward_label, UIStyles.FONT_SEMIBOLD, 40, UIStyles.MUTED)
	panel.add_child(reward_label)

	next_button = PopupFactoryScript.primary_button("", pw, 560.0)
	next_button.pressed.connect(func(): next_pressed.emit())
	panel.add_child(next_button)

	levels_button = PopupFactoryScript.secondary_button(Locale.t("complete.back", "Back to Levels"), pw, 795.0)
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
	PopupFactoryScript.show_sheet(self, panel, overlay)
	if show_details:
		start_confetti()

func hide_popup(after_hidden: Callable = Callable()) -> void:
	if panel != null:
		PopupFactoryScript.hide_sheet(self, panel, overlay, func() -> void:
			clear_confetti()
			if after_hidden.is_valid():
				after_hidden.call()
		)
	else:
		visible = false
		if after_hidden.is_valid():
			after_hidden.call()

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
		UIStyles.icon(texture, stars_label, Vector2(start_x + i * (star_size + gap), 3), Vector2(star_size, star_size), color)

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
