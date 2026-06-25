class_name SettingsScreen
extends Control

signal back_pressed

func _ready() -> void:
	size = Vector2(1080, 1920)
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

	add_slider_block("MUSIC VOLUME", UIStyles.ICON_MUSIC, 70, 310)
	add_slider_block("SOUND VOLUME", UIStyles.ICON_SPEAKER, 80, 560)

	var back_btn := Button.new()
	back_btn.text = "     Back"
	back_btn.position = Vector2(405, 1740)
	back_btn.size = Vector2(270, 75)
	back_btn.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(back_btn)
	back_btn.pressed.connect(func(): back_pressed.emit())
	add_child(back_btn)
	UIStyles.icon(UIStyles.ICON_BACK, back_btn, Vector2(64, 22), Vector2(30, 30), UIStyles.TEXT)

func add_slider_block(text: String, icon_texture: Texture2D, value: int, y: int) -> void:
	UIStyles.icon(icon_texture, self, Vector2(148, y + 6), Vector2(40, 40), UIStyles.TEXT)

	var label := Label.new()
	label.text = text
	label.position = Vector2(210, y)
	label.size = Vector2(780, 60)
	UIStyles.apply_font(label, UIStyles.FONT_BOLD, 28, UIStyles.TEXT)
	add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = value
	slider.position = Vector2(150, y + 78)
	slider.size = Vector2(720, 72)
	style_slider(slider)
	add_child(slider)

	var value_lbl := Label.new()
	value_lbl.text = "%d%%" % value
	value_lbl.position = Vector2(930, y + 82)
	value_lbl.size = Vector2(95, 60)
	value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(value_lbl, UIStyles.FONT_MEDIUM, 26, UIStyles.TEXT)
	add_child(value_lbl)
	slider.value_changed.connect(_on_slider_value_changed.bind(value_lbl))

func style_slider(slider: HSlider) -> void:
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color("#E6E4E2")
	track.corner_radius_top_left = 10
	track.corner_radius_top_right = 10
	track.corner_radius_bottom_left = 10
	track.corner_radius_bottom_right = 10
	track.content_margin_top = 28
	track.content_margin_bottom = 28
	var active: StyleBoxFlat = track.duplicate() as StyleBoxFlat
	active.bg_color = UIStyles.PURPLE
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", active)
	slider.add_theme_stylebox_override("grabber_area_highlight", active)
	slider.add_theme_icon_override("grabber", make_slider_grabber())
	slider.add_theme_icon_override("grabber_highlight", make_slider_grabber())

func make_slider_grabber() -> ImageTexture:
	var image: Image = Image.create(68, 68, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(68):
		for x in range(68):
			var d: float = Vector2(x - 34, y - 34).length()
			if d <= 25.0:
				image.set_pixel(x, y, UIStyles.PURPLE)
			elif d <= 31.0:
				image.set_pixel(x, y, Color(0.42, 0.22, 0.88, 0.16))
	return ImageTexture.create_from_image(image)

func _on_slider_value_changed(value: float, value_label: Label) -> void:
	value_label.text = "%d%%" % int(round(value))
