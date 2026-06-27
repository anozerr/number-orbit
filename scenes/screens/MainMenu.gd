class_name MainMenuScreen
extends Control

signal play_pressed
signal levels_pressed
signal settings_pressed

var play_button: Button
var logo_orbit_rect: TextureRect
var logo_orbit_base_position := Vector2.ZERO
var logo_time := 0.0

func _ready() -> void:
	size = Vector2(1080, 1920)
	build()

func build() -> void:
	for child in get_children():
		child.queue_free()

	var orbit_bg: TextureRect = TextureRect.new()
	orbit_bg.texture = preload("res://assets/images/backgrounds/background.png")
	orbit_bg.position = Vector2.ZERO
	orbit_bg.size = Vector2(1080, 1920)
	orbit_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	orbit_bg.stretch_mode = TextureRect.STRETCH_SCALE
	orbit_bg.modulate = Color.WHITE
	orbit_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(orbit_bg)

	logo_orbit_rect = TextureRect.new()
	logo_orbit_rect.texture = preload("res://assets/images/logo/home-orbit.png")
	logo_orbit_base_position = Vector2(16, -205)
	logo_orbit_rect.position = logo_orbit_base_position
	logo_orbit_rect.size = Vector2(1080, 1620)
	logo_orbit_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_orbit_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_orbit_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_orbit_rect.pivot_offset = logo_orbit_rect.size * 0.5
	add_child(logo_orbit_rect)

	var logo_name := TextureRect.new()
	logo_name.texture = preload("res://assets/images/logo/name.png")
	logo_name.position = logo_orbit_base_position + Vector2(-16, 62)
	logo_name.size = logo_orbit_rect.size
	logo_name.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_name.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo_name)

	play_button = Button.new()
	play_button.position = Vector2(170, 1040)
	play_button.size = Vector2(740, 120)
	play_button.add_theme_font_size_override("font_size", 42)
	UIStyles.primary_button(play_button)
	play_button.pressed.connect(func(): play_pressed.emit())
	add_child(play_button)
	UIStyles.icon(UIStyles.ICON_PLAY_WHITE, play_button, Vector2(240, 39), Vector2(42, 42), Color.WHITE)

	var levels_btn := Button.new()
	levels_btn.text = "        Levels"
	levels_btn.position = Vector2(170, 1200)
	levels_btn.size = Vector2(740, 110)
	levels_btn.add_theme_font_size_override("font_size", 38)
	UIStyles.menu_button(levels_btn)
	levels_btn.pressed.connect(func(): levels_pressed.emit())
	add_child(levels_btn)
	UIStyles.icon(UIStyles.ICON_LEVELS, levels_btn, Vector2(240, 36), Vector2(38, 38), UIStyles.TEXT)

	var settings_btn := Button.new()
	settings_btn.text = "        Settings"
	settings_btn.position = Vector2(170, 1340)
	settings_btn.size = Vector2(740, 110)
	settings_btn.add_theme_font_size_override("font_size", 38)
	UIStyles.menu_button(settings_btn)
	settings_btn.pressed.connect(func(): settings_pressed.emit())
	add_child(settings_btn)
	UIStyles.icon(UIStyles.ICON_GEAR, settings_btn, Vector2(240, 36), Vector2(38, 38), UIStyles.TEXT)

func set_continue_mode(has_played: bool, current_level: int) -> void:
	if play_button == null:
		return
	play_button.text = "        Continue" if has_played and current_level > 1 else "        Play"

func _process(delta: float) -> void:
	if logo_orbit_rect == null:
		return
	logo_time += delta
	var offset := Vector2(
		sin(logo_time * 1.05) * 6.0 + sin(logo_time * 0.54) * 2.5,
		cos(logo_time * 0.92) * 6.0
	)
	logo_orbit_rect.position = logo_orbit_base_position + offset
	logo_orbit_rect.rotation_degrees = sin(logo_time * 0.82) * 1.25
