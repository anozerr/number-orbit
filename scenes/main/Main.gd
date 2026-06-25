extends Node2D

const MainMenuScene = preload("res://scenes/screens/MainMenu.tscn")
const LevelSelectScene = preload("res://scenes/screens/LevelSelect.tscn")
const SettingsScene = preload("res://scenes/screens/SettingsScreen.tscn")
const GameScreenScene = preload("res://scenes/screens/GameScreen.tscn")
const CompletePopupScene = preload("res://scenes/ui/LevelCompletePopup.tscn")

var state: GameState = GameState.new()
var orbit_items: Array = []
var return_to_game_after_settings: bool = false

var bg: ColorRect
var main_menu: MainMenuScreen
var level_select: LevelSelectScreen
var settings_screen: SettingsScreen
var game_screen: GameScreen
var complete_popup: LevelCompletePopup

func _ready() -> void:
	randomize()
	state.setup(LevelData.get_levels())
	build()
	load_level(1)
	show_main_menu()

func build() -> void:
	bg = ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1080, 1920)
	bg.color = UIStyles.BG
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	main_menu = get_or_create_screen("MainMenu", MainMenuScene) as MainMenuScreen
	main_menu.play_pressed.connect(_on_play_pressed)
	main_menu.levels_pressed.connect(show_level_select)
	main_menu.settings_pressed.connect(_on_main_settings_pressed)

	level_select = get_or_create_screen("LevelSelect", LevelSelectScene) as LevelSelectScreen
	level_select.back_pressed.connect(show_main_menu)
	level_select.level_selected.connect(_on_level_selected)

	settings_screen = get_or_create_screen("SettingsScreen", SettingsScene) as SettingsScreen
	settings_screen.back_pressed.connect(_on_settings_back_pressed)

	game_screen = get_or_create_screen("GameScreen", GameScreenScene) as GameScreen
	game_screen.back_pressed.connect(show_level_select)
	game_screen.settings_pressed.connect(_on_game_settings_pressed)
	game_screen.restart_pressed.connect(restart_level)
	game_screen.orbit_pressed.connect(_on_orbit_pressed)

	complete_popup = get_or_create_screen("LevelCompletePopup", CompletePopupScene) as LevelCompletePopup
	complete_popup.next_pressed.connect(_on_popup_next_pressed)
	complete_popup.levels_pressed.connect(_on_popup_levels_pressed)

func get_or_create_screen(node_name: String, scene: PackedScene) -> Node:
	var existing: Node = get_node_or_null(node_name)
	if existing != null:
		return existing
	var instance: Node = scene.instantiate()
	instance.name = node_name
	add_child(instance)
	return instance

func hide_all() -> void:
	main_menu.visible = false
	level_select.visible = false
	settings_screen.visible = false
	game_screen.visible = false
	complete_popup.hide_popup()

func show_main_menu() -> void:
	hide_all()
	main_menu.visible = true
	main_menu.set_continue_mode(state.has_played, state.current_level)

func show_level_select() -> void:
	hide_all()
	level_select.visible = true
	level_select.rebuild(state.star_ratings, state.max_unlocked_level)

func show_settings() -> void:
	hide_all()
	settings_screen.visible = true

func show_game() -> void:
	hide_all()
	game_screen.visible = true
	refresh_game_screen()

func _on_main_settings_pressed() -> void:
	return_to_game_after_settings = false
	show_settings()

func _on_game_settings_pressed() -> void:
	return_to_game_after_settings = true
	show_settings()

func _on_settings_back_pressed() -> void:
	if return_to_game_after_settings:
		return_to_game_after_settings = false
		show_game()
	else:
		show_main_menu()

func _on_play_pressed() -> void:
	if not state.has_played:
		load_level(1)
	else:
		load_level(state.current_level)
	state.has_played = true
	show_game()

func _on_level_selected(level_number: int) -> void:
	load_level(level_number)
	state.has_played = true
	show_game()

func load_level(level_number: int) -> void:
	var data: Dictionary = state.load_level(level_number)
	orbit_items = OrbitGenerator.initial_items(data, state.current_number)

func restart_level() -> void:
	load_level(state.current_level)
	show_game()

func refresh_game_screen() -> void:
	var thresholds: Array = StarCalculator.sorted_thresholds(state.current_level_data())
	game_screen.configure(state.current_level, state.current_number, state.target_number, state.moves_used, thresholds, orbit_items)

func _on_orbit_pressed(value: int, op: String) -> void:
	if complete_popup.visible:
		return
	if not OperationLogic.can_apply(state.current_number, value, op):
		orbit_items = OrbitGenerator.generate_items(state.current_level_data(), state.current_number)
		refresh_game_screen()
		return

	state.current_number = OperationLogic.apply(state.current_number, value, op)
	state.moves_used += 1
	if state.current_number == state.target_number:
		complete_level()
	else:
		orbit_items = OrbitGenerator.generate_items(state.current_level_data(), state.current_number)
		refresh_game_screen()

func complete_level() -> void:
	var stars: int = StarCalculator.calculate(state.moves_used, state.current_level_data())
	state.set_stars(stars)
	state.unlock_next_level()
	refresh_game_screen()
	complete_popup.show_result(state.current_level, stars, state.moves_used, state.current_level < LevelData.LEVEL_COUNT)

func _on_popup_next_pressed() -> void:
	complete_popup.hide_popup()
	if state.current_level < LevelData.LEVEL_COUNT:
		load_level(state.current_level + 1)
		show_game()
	else:
		show_level_select()

func _on_popup_levels_pressed() -> void:
	complete_popup.hide_popup()
	show_level_select()
