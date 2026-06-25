class_name MainMenuScreen
extends Control

signal play_pressed
signal levels_pressed
signal settings_pressed

var play_button: Button

func _ready() -> void:
	size = Vector2(1080, 1920)
	build()

func build() -> void:
	for child in get_children():
		child.queue_free()

	var orbit_bg: TextureRect = TextureRect.new()
	orbit_bg.texture = preload("res://assets/images/backgrounds/home-orbit2.png")
	orbit_bg.position = Vector2.ZERO
	orbit_bg.size = Vector2(1080, 1920)
	orbit_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	orbit_bg.stretch_mode = TextureRect.STRETCH_SCALE
	orbit_bg.modulate = Color.WHITE
	orbit_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(orbit_bg)

	play_button = Button.new()
	play_button.position = Vector2(170, 1110)
	play_button.size = Vector2(740, 120)
	play_button.add_theme_font_size_override("font_size", 42)
	UIStyles.primary_button(play_button)
	play_button.pressed.connect(func(): play_pressed.emit())
	add_child(play_button)
	UIStyles.icon(UIStyles.ICON_PLAY_WHITE, play_button, Vector2(240, 39), Vector2(42, 42), Color.WHITE)

	var levels_btn := Button.new()
	levels_btn.text = "        Levels"
	levels_btn.position = Vector2(170, 1270)
	levels_btn.size = Vector2(740, 110)
	levels_btn.add_theme_font_size_override("font_size", 38)
	UIStyles.menu_button(levels_btn)
	levels_btn.pressed.connect(func(): levels_pressed.emit())
	add_child(levels_btn)
	UIStyles.icon(UIStyles.ICON_LEVELS, levels_btn, Vector2(240, 36), Vector2(38, 38), UIStyles.TEXT)

	var settings_btn := Button.new()
	settings_btn.text = "        Settings"
	settings_btn.position = Vector2(170, 1410)
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
