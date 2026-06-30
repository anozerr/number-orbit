class_name SettingsScreen
extends Control

signal back_pressed
signal volumes_changed(music_value: int, sound_value: int)
signal reset_progress_requested

var music_volume := 80
var sound_volume := 80
var reset_popup: Control

func _ready() -> void:
	size = Vector2(1080, 1920)
	build()

func configure(music_value: int, sound_value: int) -> void:
	music_volume = int(clamp(music_value, 0, 100))
	sound_volume = int(clamp(sound_value, 0, 100))
	build()

func build() -> void:
	for child in get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "SETTINGS"
	title.position = Vector2(0, 95)
	title.size = Vector2(1080, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 44, UIStyles.TEXT)
	add_child(title)

	var back_btn := Button.new()
	back_btn.text = ""
	back_btn.position = Vector2(70, 70)
	back_btn.size = Vector2(88, 88)
	back_btn.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(back_btn)
	back_btn.pressed.connect(func(): back_pressed.emit())
	add_child(back_btn)
	UIStyles.icon(UIStyles.ICON_BACK, back_btn, Vector2(23, 23), Vector2(42, 42), UIStyles.TEXT)

	add_slider_block("MUSIC VOLUME", UIStyles.ICON_MUSIC, music_volume, 300, "music")
	add_divider(250, 525)
	add_slider_block("SOUND VOLUME", UIStyles.ICON_SPEAKER, sound_volume, 575, "sound")
	add_divider(250, 800)
	add_reset_progress_button()
	build_reset_popup()

func add_reset_progress_button() -> void:
	var reset_btn := Button.new()
	reset_btn.text = "RESET PROGRESS"
	reset_btn.position = Vector2(250, 905)
	reset_btn.size = Vector2(580, 82)
	reset_btn.add_theme_font_size_override("font_size", 26)
	apply_danger_button_style(reset_btn)
	reset_btn.pressed.connect(show_reset_popup)
	add_child(reset_btn)

func apply_danger_button_style(button: Button) -> void:
	var normal := UIStyles.card(Color("#FFF1F1"), Color("#F05A5A"), 30)
	normal.shadow_color = Color(0.35, 0.04, 0.04, 0.065)
	normal.shadow_size = 16
	normal.shadow_offset = Vector2(0, 8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#FFEAEA")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#FFE0E0")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	UIStyles.apply_font(button, UIStyles.FONT_BOLD, int(button.get_theme_font_size("font_size")), Color("#C82424"))
	button.add_theme_color_override("font_hover_color", Color("#C82424"))
	button.add_theme_color_override("font_pressed_color", Color("#C82424"))
	button.add_theme_color_override("font_focus_color", Color("#C82424"))
	UIStyles.add_press_animation(button)

func build_reset_popup() -> void:
	reset_popup = Control.new()
	reset_popup.size = Vector2(1080, 1920)
	reset_popup.visible = false
	reset_popup.z_index = 100
	add_child(reset_popup)

	var overlay := ColorRect.new()
	overlay.size = Vector2(1080, 1920)
	overlay.color = Color(0.05, 0.06, 0.10, 0.45)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	reset_popup.add_child(overlay)

	var panel := Panel.new()
	panel.position = Vector2(110, 610)
	panel.size = Vector2(860, 660)
	panel.add_theme_stylebox_override("panel", UIStyles.soft_panel(Color.WHITE, 38))
	reset_popup.add_child(panel)

	var icon_bg := Panel.new()
	icon_bg.position = Vector2(365, -50)
	icon_bg.size = Vector2(130, 130)
	icon_bg.add_theme_stylebox_override("panel", UIStyles.card(Color("#F05A5A"), Color.WHITE, 65))
	panel.add_child(icon_bg)
	UIStyles.icon(UIStyles.ICON_INFO, icon_bg, Vector2(38, 38), Vector2(54, 54), Color.WHITE)

	var title := Label.new()
	title.text = "RESET PROGRESS"
	title.position = Vector2(0, 105)
	title.size = Vector2(860, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 36, UIStyles.TEXT)
	panel.add_child(title)

	var body := Label.new()
	body.text = "Are you sure?\nThis will erase your progress, stars, bulbs and unlocked levels."
	body.position = Vector2(80, 200)
	body.size = Vector2(700, 130)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(body, UIStyles.FONT_MEDIUM, 24, UIStyles.MUTED)
	panel.add_child(body)

	var confirm_btn := Button.new()
	confirm_btn.text = "Reset progress"
	confirm_btn.position = Vector2(145, 405)
	confirm_btn.size = Vector2(570, 78)
	confirm_btn.add_theme_font_size_override("font_size", 27)
	apply_danger_button_style(confirm_btn)
	confirm_btn.pressed.connect(func():
		reset_popup.visible = false
		reset_progress_requested.emit()
	)
	panel.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.position = Vector2(145, 515)
	cancel_btn.size = Vector2(570, 76)
	cancel_btn.add_theme_font_size_override("font_size", 27)
	UIStyles.menu_button(cancel_btn)
	cancel_btn.pressed.connect(func(): reset_popup.visible = false)
	panel.add_child(cancel_btn)

func show_reset_popup() -> void:
	if reset_popup != null:
		reset_popup.visible = true

func add_slider_block(text: String, icon_texture: Texture2D, value: int, y: int, key: String) -> void:
	var block_x: float = 185.0
	var track_x: float = 115.0
	var track_width: float = 720.0
	UIStyles.icon(icon_texture, self, Vector2(block_x, y + 8), Vector2(42, 42), UIStyles.MUTED)

	var label := Label.new()
	label.text = text
	label.position = Vector2(block_x + 62, y)
	label.size = Vector2(650, 58)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(label, UIStyles.FONT_BOLD, 28, UIStyles.TEXT)
	add_child(label)

	var track_y: float = y + 110.0
	var track_bg := Panel.new()
	track_bg.position = Vector2(track_x, track_y)
	track_bg.size = Vector2(track_width, 8)
	track_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track_bg.add_theme_stylebox_override("panel", slider_track_style(Color("#E6E4E2"), 4))
	add_child(track_bg)

	var track_fill := Panel.new()
	track_fill.position = Vector2(track_x, track_y)
	track_fill.size = Vector2(track_width * float(value) / 100.0, 8)
	track_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track_fill.add_theme_stylebox_override("panel", slider_track_style(UIStyles.PURPLE, 4))
	add_child(track_fill)

	var knob := Panel.new()
	knob.size = Vector2(54, 54)
	knob.position = Vector2(track_x + track_fill.size.x - knob.size.x * 0.5, track_y - 23)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.add_theme_stylebox_override("panel", slider_knob_style())
	add_child(knob)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = value
	slider.position = Vector2(track_x - 8, track_y - 28)
	slider.size = Vector2(track_width + 16, 64)
	slider.modulate = Color(1, 1, 1, 0)
	add_child(slider)

	var value_lbl := Label.new()
	value_lbl.text = "%d%%" % value
	value_lbl.position = Vector2(track_x + track_width + 48, track_y - 27)
	value_lbl.size = Vector2(122, 60)
	value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(value_lbl, UIStyles.FONT_MEDIUM, 26, UIStyles.TEXT)
	add_child(value_lbl)
	slider.value_changed.connect(_on_slider_value_changed.bind(value_lbl, track_fill, knob, track_width, key))

func slider_track_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func slider_knob_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UIStyles.PURPLE
	style.border_color = Color(1, 1, 1, 0)
	style.border_width_left = 0
	style.border_width_right = 0
	style.border_width_top = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = 27
	style.corner_radius_top_right = 27
	style.corner_radius_bottom_left = 27
	style.corner_radius_bottom_right = 27
	style.shadow_color = Color(0.35, 0.18, 0.82, 0.20)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style

func _on_slider_value_changed(value: float, value_label: Label, fill: Panel, knob: Panel, track_width: float, key: String) -> void:
	value_label.text = "%d%%" % int(round(value))
	var fill_width: float = track_width * clamp(value, 0.0, 100.0) / 100.0
	fill.size = Vector2(fill_width, fill.size.y)
	knob.position = Vector2(fill.position.x + fill_width - knob.size.x * 0.5, knob.position.y)
	if key == "music":
		music_volume = int(round(value))
	else:
		sound_volume = int(round(value))
	volumes_changed.emit(music_volume, sound_volume)

func add_divider(x: int, y: int) -> void:
	var line := ColorRect.new()
	line.position = Vector2(x, y)
	line.size = Vector2(580, 2)
	line.color = Color(0.89, 0.88, 0.86, 0.7)
	add_child(line)
