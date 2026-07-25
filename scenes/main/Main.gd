extends Node2D

const MainMenuScene = preload("res://scenes/screens/MainMenu.tscn")
const LevelSelectScene = preload("res://scenes/screens/LevelSelect.tscn")
const SettingsScene = preload("res://scenes/screens/SettingsScreen.tscn")
const GameScreenScene = preload("res://scenes/screens/GameScreen.tscn")
const CompletePopupScene = preload("res://scenes/ui/LevelCompletePopup.tscn")
const AudioManagerScript = preload("res://scripts/audio/AudioManager.gd")
const OrbitSlotsScript = preload("res://scripts/game/OrbitSlots.gd")
const HintSolverScript = preload("res://scripts/game/HintSolver.gd")
const GameViewStateScript = preload("res://scripts/game/GameViewState.gd")

const SCREEN_FADE_OUT_DURATION := 0.20
const SCREEN_FADE_IN_DURATION := 0.24
# Lead-in before the orbit chips pop after a screen crossfade. Kept below the
# fade-in so the ripple starts as the screen settles (light handoff), not during
# it and not after a dead gap.
const ORBIT_ENTRANCE_AFTER_TRANSITION := 0.16
const SCREEN_TRANSITION_ROLE_META := &"screen_transition_role"
const PERSISTENT_HEADER_Z_INDEX := 10
const SCREEN_TRANSITION_INPUT_Z_INDEX := 299
const HEADER_TWEEN_META := &"persistent_header_tween"
const VOLUME_SAVE_DEBOUNCE_SECONDS := 0.30
# Кросс-фейд скрывает синхронный rebuild, но не должен ощущаться отдельной паузой.
# 0.20с совпадает по темпу с обычными переходами между экранами.
const THEME_CROSSFADE_SECONDS := 0.20

var state: GameState = GameState.new()
var orbit_items: Array = []
var tutorial_levels: Array = []
var tutorial_mode: bool = false
var tutorial_index: int = 0
var settings_return_screen: String = "menu"
var settings_game_coach_snapshot: Dictionary = {}
var orbit_input_locked: bool = false
var shown_tutorial_coaches: Dictionary = {}

var bg: ThemeBackground
var theme_crossfade: TextureRect
var theme_transitioning := false
var screen_transition_tween: Tween
var screen_transition_from: CanvasItem
var screen_transition_to: CanvasItem
var screen_transition_input_blocker: Control
var current_screen: String = "menu"
var persistent_header_root: Control
var persistent_back_button: Button
var persistent_settings_button: Button
var audio: AudioManager
var volume_save_timer: Timer
var main_menu: MainMenuScreen
var level_select: LevelSelectScreen
var settings_screen: SettingsScreen
var game_screen: GameScreen
var complete_popup: LevelCompletePopup
var game_screen_visuals_dirty := false
var complete_popup_visuals_dirty := false
var last_reward_delta := 0

func _ready() -> void:
	randomize()
	get_viewport().size_changed.connect(_on_viewport_resized)
	state.setup(LevelData.get_levels())
	tutorial_levels = LevelData.get_tutorial_levels()
	UIStyles.set_theme(state.theme)
	Locale.set_language(state.language)
	audio = AudioManagerScript.new()
	audio.name = "AudioManager"
	add_child(audio)
	audio.configure(state.music_volume, state.sound_volume, state.haptics_enabled)
	build()
	show_main_menu()

func _on_viewport_resized() -> void:
	_layout_persistent_header()
	if is_instance_valid(complete_popup) and not complete_popup.visible:
		complete_popup_visuals_dirty = true
	if is_instance_valid(screen_transition_input_blocker):
		screen_transition_input_blocker.size = Layout.viewport_size(self)
	# A theme/language snapshot may outlive several resize events during its
	# 0.32s fade. Keep it covering the newly exposed canvas instead of leaving a
	# vertical strip with the old background geometry.
	if is_instance_valid(theme_crossfade):
		theme_crossfade.position = Vector2.ZERO
		theme_crossfade.size = Layout.viewport_size(self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_progress_now()

func build() -> void:
	if bg == null:
		bg = ThemeBackground.new()
		add_child(bg)

	main_menu = get_or_create_screen("MainMenu", MainMenuScene) as MainMenuScreen
	main_menu.play_pressed.connect(_on_play_pressed)
	main_menu.levels_pressed.connect(show_level_select)
	main_menu.settings_pressed.connect(_on_main_settings_pressed)

	level_select = get_or_create_screen("LevelSelect", LevelSelectScene) as LevelSelectScreen
	level_select.back_pressed.connect(_on_level_select_back_pressed)
	level_select.level_selected.connect(_on_level_selected)
	level_select.skip_level_requested.connect(_on_skip_level_requested)
	level_select.ad_reward_requested.connect(_on_ad_reward_requested)
	level_select.settings_pressed.connect(_on_levels_settings_pressed)

	settings_screen = get_or_create_screen("SettingsScreen", SettingsScene) as SettingsScreen
	settings_screen.back_pressed.connect(_on_settings_back_pressed)
	settings_screen.volumes_changed.connect(_on_settings_volumes_changed)
	settings_screen.haptics_changed.connect(_on_settings_haptics_changed)
	settings_screen.reset_progress_requested.connect(_on_reset_progress_pressed)
	settings_screen.theme_selected.connect(_on_theme_changed)
	settings_screen.language_changed.connect(_on_language_changed)
	settings_screen.configure(state.music_volume, state.sound_volume, state.theme, state.language, state.haptics_enabled)

	game_screen = get_or_create_screen("GameScreen", GameScreenScene) as GameScreen
	game_screen.back_pressed.connect(_on_game_back_pressed)
	game_screen.settings_pressed.connect(_on_game_settings_pressed)
	game_screen.restart_pressed.connect(restart_level)
	game_screen.orbit_pressed.connect(_on_orbit_pressed)
	game_screen.hint_requested.connect(_on_hint_requested)
	game_screen.hint_ad_requested.connect(_on_hint_ad_requested)
	game_screen.coach_header_mode_changed.connect(_on_game_coach_header_mode_changed)

	complete_popup = get_or_create_screen("LevelCompletePopup", CompletePopupScene) as LevelCompletePopup
	complete_popup.next_pressed.connect(_on_popup_next_pressed)
	complete_popup.levels_pressed.connect(_on_popup_levels_pressed)
	complete_popup.double_reward_requested.connect(_on_double_reward_requested)

	_build_persistent_header()
	_build_screen_transition_input_blocker()
	_hide_all_local_headers()

func get_or_create_screen(node_name: String, scene: PackedScene) -> Node:
	var existing: Node = get_node_or_null(node_name)
	if existing != null:
		return existing
	var instance: Node = scene.instantiate()
	instance.name = node_name
	if instance is CanvasItem:
		(instance as CanvasItem).visible = false
	add_child(instance)
	return instance

func _show_screen(screen: CanvasItem, animate: bool) -> void:
	_settle_screen_transition()
	var was_visible := screen.visible
	var outgoing_screen: CanvasItem
	for candidate in [main_menu, level_select, settings_screen, game_screen]:
		if candidate != screen and candidate.visible:
			outgoing_screen = candidate
			break
	var should_animate := animate and not was_visible
	_transition_persistent_header(outgoing_screen, screen, should_animate)
	for candidate in [main_menu, level_select, settings_screen, game_screen]:
		if candidate != screen and candidate != outgoing_screen:
			_set_screen_visible_immediate(candidate, false)
	if complete_popup.visible:
		complete_popup.hide_popup()
	if should_animate:
		_crossfade_screens(outgoing_screen, screen)
	else:
		if is_instance_valid(outgoing_screen):
			_set_screen_visible_immediate(outgoing_screen, false)
		_set_screen_visible_immediate(screen, true)
		_reset_persistent_header_z()

func _crossfade_screens(outgoing_screen: CanvasItem, incoming_screen: CanvasItem) -> void:
	incoming_screen.position = _screen_home(incoming_screen)
	incoming_screen.z_index = 0
	incoming_screen.modulate.a = 0.0
	incoming_screen.visible = true
	if is_instance_valid(outgoing_screen):
		outgoing_screen.position = _screen_home(outgoing_screen)
		outgoing_screen.modulate.a = 1.0
		outgoing_screen.visible = true
		# Descendants use their own relative z-indices (some reach 110), so a
		# literal 0/1 split would let parts of the incoming screen leak above the
		# outgoing one. Shift the outgoing root just far enough to keep its whole
		# visible tree above the incoming tree without flattening local UI layers.
		var incoming_bounds := _screen_relative_z_bounds(incoming_screen)
		var outgoing_bounds := _screen_relative_z_bounds(outgoing_screen)
		outgoing_screen.z_index = maxi(1, incoming_bounds.y - outgoing_bounds.x + 1)
		_raise_persistent_header_for_transition(outgoing_screen, incoming_screen, outgoing_bounds, incoming_bounds)
	else:
		_reset_persistent_header_z()
	_set_screen_transition_input_blocked(true)
	screen_transition_from = outgoing_screen
	screen_transition_to = incoming_screen
	var tween := create_tween().set_parallel(true)
	screen_transition_tween = tween
	tween.tween_property(incoming_screen, "modulate:a", 1.0, SCREEN_FADE_IN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_instance_valid(outgoing_screen):
		tween.tween_property(outgoing_screen, "modulate:a", 0.0, SCREEN_FADE_OUT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.finished.connect(_on_screen_transition_finished.bind(tween, outgoing_screen, incoming_screen))

func _on_screen_transition_finished(tween: Tween, outgoing_screen: CanvasItem, incoming_screen: CanvasItem) -> void:
	if screen_transition_tween != tween:
		return
	_finalize_screen_transition(outgoing_screen, incoming_screen)

func _finalize_screen_transition(outgoing_screen: CanvasItem, incoming_screen: CanvasItem) -> void:
	screen_transition_tween = null
	screen_transition_from = null
	screen_transition_to = null
	if is_instance_valid(outgoing_screen):
		_set_screen_visible_immediate(outgoing_screen, false)
	if is_instance_valid(incoming_screen):
		_set_screen_visible_immediate(incoming_screen, true)
	_set_screen_transition_input_blocked(false)
	_reset_persistent_header_z()

func _settle_screen_transition() -> void:
	if screen_transition_tween == null:
		return
	if screen_transition_tween.is_valid():
		screen_transition_tween.kill()
	var outgoing_screen := screen_transition_from
	var incoming_screen := screen_transition_to
	_finalize_screen_transition(outgoing_screen, incoming_screen)

func _set_screen_visible_immediate(screen: CanvasItem, shown: bool) -> void:
	if not is_instance_valid(screen):
		return
	screen.position = _screen_home(screen)
	screen.z_index = 0
	screen.modulate.a = 1.0
	screen.visible = shown

func _screen_home(screen: CanvasItem) -> Vector2:
	if not screen.has_meta("screen_transition_home"):
		screen.set_meta("screen_transition_home", screen.position)
	return screen.get_meta("screen_transition_home") as Vector2

func _screen_relative_z_bounds(root: CanvasItem, relative_z: int = 0) -> Vector2i:
	var bounds := Vector2i(relative_z, relative_z)
	for child_node in root.get_children():
		var child := child_node as CanvasItem
		if child == null or not child.visible:
			continue
		var child_z := relative_z + child.z_index if child.z_as_relative else child.z_index
		var child_bounds := _screen_relative_z_bounds(child, child_z)
		bounds.x = mini(bounds.x, child_bounds.x)
		bounds.y = maxi(bounds.y, child_bounds.y)
	return bounds

func _build_screen_transition_input_blocker() -> void:
	if not is_instance_valid(screen_transition_input_blocker):
		screen_transition_input_blocker = Control.new()
		screen_transition_input_blocker.name = "ScreenTransitionInputBlocker"
		screen_transition_input_blocker.position = Vector2.ZERO
		screen_transition_input_blocker.z_index = SCREEN_TRANSITION_INPUT_Z_INDEX
		screen_transition_input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(screen_transition_input_blocker)
	screen_transition_input_blocker.size = Layout.viewport_size(self)
	screen_transition_input_blocker.visible = false

func _set_screen_transition_input_blocked(blocked: bool) -> void:
	if is_instance_valid(screen_transition_input_blocker):
		screen_transition_input_blocker.visible = blocked

func _transition_uses_coach_overlay(outgoing_screen: CanvasItem, incoming_screen: CanvasItem) -> bool:
	return (
		(outgoing_screen == game_screen or incoming_screen == game_screen)
		and is_instance_valid(game_screen)
		and is_instance_valid(game_screen.coach_overlay)
		and game_screen.coach_overlay.visible
	)

func _raise_persistent_header_for_transition(outgoing_screen: CanvasItem, incoming_screen: CanvasItem, outgoing_bounds: Vector2i, incoming_bounds: Vector2i) -> void:
	if not is_instance_valid(persistent_header_root):
		return
	# While the tutorial shader is present, its existing z=90 relationship must
	# remain intact so the shared buttons stay behind it and non-clickable.
	if _transition_uses_coach_overlay(outgoing_screen, incoming_screen):
		persistent_header_root.z_index = PERSISTENT_HEADER_Z_INDEX
		return
	var outgoing_top := outgoing_screen.z_index + outgoing_bounds.y
	persistent_header_root.z_index = maxi(PERSISTENT_HEADER_Z_INDEX, maxi(outgoing_top, incoming_bounds.y) + 1)

func _reset_persistent_header_z() -> void:
	if is_instance_valid(persistent_header_root):
		persistent_header_root.z_index = PERSISTENT_HEADER_Z_INDEX

func _screen_header_controls(screen: CanvasItem) -> Dictionary:
	var controls: Dictionary = {}
	if not is_instance_valid(screen):
		return controls
	for child in screen.get_children():
		var control := child as Control
		if control == null or not control.has_meta(SCREEN_TRANSITION_ROLE_META):
			continue
		controls[StringName(control.get_meta(SCREEN_TRANSITION_ROLE_META))] = control
	return controls

func _build_persistent_header() -> void:
	if not is_instance_valid(persistent_header_root):
		persistent_header_root = Control.new()
		persistent_header_root.name = "PersistentHeader"
		persistent_header_root.position = Vector2.ZERO
		persistent_header_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		persistent_header_root.z_index = PERSISTENT_HEADER_Z_INDEX
		add_child(persistent_header_root)
	else:
		Layout.clear_children_for_rebuild(persistent_header_root)

	persistent_back_button = UIStyles.back_button(persistent_header_root, Vector2.ZERO)
	persistent_back_button.pressed.connect(_on_persistent_back_pressed)
	persistent_settings_button = UIStyles.circle_button(persistent_header_root, Vector2.ZERO, 127.0)
	persistent_settings_button.pressed.connect(_on_persistent_settings_pressed)
	UIStyles.icon(UIStyles.ICON_GEAR, persistent_settings_button, Vector2(33, 33), Vector2(60, 60), UIStyles.TEXT)
	_layout_persistent_header()
	_apply_persistent_header_immediate(_current_screen_node())
	_set_persistent_header_coach_blocked(_game_coach_active())

func _layout_persistent_header() -> void:
	if not is_instance_valid(persistent_header_root):
		return
	var column := Layout.content_column(self)
	var top := Layout.content_top(self)
	persistent_header_root.size = Layout.viewport_size(self)
	if is_instance_valid(persistent_back_button):
		persistent_back_button.position = Vector2(maxf(Layout.SIDE_MARGIN, column.position.x), top + 74.0)
	if is_instance_valid(persistent_settings_button):
		persistent_settings_button.position = Vector2(column.position.x + column.size.x - 127.0, top + 74.0)

func _hide_all_local_headers() -> void:
	for screen in [level_select, settings_screen, game_screen]:
		for control in _screen_header_controls(screen).values():
			if is_instance_valid(control):
				(control as Control).visible = false

func _screen_has_header_role(screen: CanvasItem, role: StringName) -> bool:
	if role == &"back":
		return screen == level_select or screen == settings_screen or screen == game_screen
	if role == &"settings":
		return screen == level_select or screen == game_screen
	return false

func _current_screen_node() -> CanvasItem:
	match current_screen:
		"levels": return level_select
		"settings": return settings_screen
		"game": return game_screen
		_: return main_menu

func _persistent_button_for_role(role: StringName) -> Button:
	return persistent_back_button if role == &"back" else persistent_settings_button

func _kill_persistent_header_tween(button: Button) -> void:
	if not is_instance_valid(button) or not button.has_meta(HEADER_TWEEN_META):
		return
	var tween := button.get_meta(HEADER_TWEEN_META) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	button.remove_meta(HEADER_TWEEN_META)

func _apply_persistent_header_immediate(screen: CanvasItem) -> void:
	for role in [&"back", &"settings"]:
		var button := _persistent_button_for_role(role)
		if not is_instance_valid(button):
			continue
		_kill_persistent_header_tween(button)
		var shown := _screen_has_header_role(screen, role)
		button.visible = shown
		button.modulate.a = 1.0
		button.mouse_filter = Control.MOUSE_FILTER_STOP if shown else Control.MOUSE_FILTER_IGNORE

func _game_coach_active() -> bool:
	return (
		current_screen == "game"
		and is_instance_valid(game_screen)
		and is_instance_valid(game_screen.coach_overlay)
		and game_screen.coach_overlay.visible
	)

func _set_persistent_header_coach_blocked(blocked: bool) -> void:
	for button in [persistent_back_button, persistent_settings_button]:
		if not is_instance_valid(button):
			continue
		if blocked:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif button.visible:
			button.mouse_filter = Control.MOUSE_FILTER_STOP

func _transition_persistent_header(from_screen: CanvasItem, to_screen: CanvasItem, animate: bool) -> void:
	_hide_all_local_headers()
	var coach_active := to_screen == game_screen and is_instance_valid(game_screen.coach_overlay) and game_screen.coach_overlay.visible
	if is_instance_valid(persistent_header_root):
		persistent_header_root.z_index = PERSISTENT_HEADER_Z_INDEX
	if coach_active:
		_apply_persistent_header_immediate(game_screen)
		_set_persistent_header_coach_blocked(true)
		return
	if not animate:
		_apply_persistent_header_immediate(to_screen)
		return
	for role in [&"back", &"settings"]:
		var button := _persistent_button_for_role(role)
		if not is_instance_valid(button):
			continue
		_kill_persistent_header_tween(button)
		var shown_before := _screen_has_header_role(from_screen, role)
		var shown_after := _screen_has_header_role(to_screen, role)
		if shown_before and shown_after:
			# This is one persistent button shared by both screens: keep it fully
			# visible and never attach it to either side of the crossfade.
			button.visible = true
			button.modulate.a = 1.0
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			continue
		if not shown_before and not shown_after:
			button.visible = false
			button.modulate.a = 1.0
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			continue
		button.visible = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween := button.create_tween()
		button.set_meta(HEADER_TWEEN_META, tween)
		if shown_after:
			button.modulate.a = 0.0
			tween.tween_property(button, "modulate:a", 1.0, SCREEN_FADE_IN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		else:
			button.modulate.a = 1.0
			tween.tween_property(button, "modulate:a", 0.0, SCREEN_FADE_OUT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.finished.connect(_on_persistent_header_transition_finished.bind(button, tween, to_screen, role))

func _on_persistent_header_transition_finished(button: Button, tween: Tween, target_screen: CanvasItem, role: StringName) -> void:
	if not is_instance_valid(button) or not button.has_meta(HEADER_TWEEN_META) or button.get_meta(HEADER_TWEEN_META) != tween:
		return
	button.remove_meta(HEADER_TWEEN_META)
	var shown := _current_screen_node() == target_screen and _screen_has_header_role(target_screen, role)
	button.visible = shown
	button.modulate.a = 1.0
	button.mouse_filter = Control.MOUSE_FILTER_STOP if shown else Control.MOUSE_FILTER_IGNORE

func _on_persistent_back_pressed() -> void:
	if is_level_complete_modal_active():
		return
	match current_screen:
		"levels": _on_level_select_back_pressed()
		"settings": _on_settings_back_pressed()
		"game": _on_game_back_pressed()

func _on_persistent_settings_pressed() -> void:
	if is_level_complete_modal_active():
		return
	match current_screen:
		"levels": _on_levels_settings_pressed()
		"game": _on_game_settings_pressed()

func show_main_menu(animate: bool = true) -> void:
	current_screen = "menu"
	main_menu.set_continue_mode(state.has_played, state.current_level, state.are_all_tutorials_completed())
	main_menu.build()
	_show_screen(main_menu, animate)

func show_level_select(animate: bool = true) -> void:
	current_screen = "levels"
	tutorial_mode = false
	level_select.rebuild_level_difficulties(state.star_ratings, state.max_unlocked_level, state.tutorial_completed, state.lumens)
	_show_screen(level_select, animate)

func show_settings(animate: bool = true) -> void:
	current_screen = "settings"
	settings_screen.configure(state.music_volume, state.sound_volume, state.theme, state.language, state.haptics_enabled)
	_show_screen(settings_screen, animate)

func show_game(animate: bool = true) -> void:
	var preserve_current_board := current_screen == "game" or (current_screen == "settings" and settings_return_screen == "game")
	# A real crossfade only happens when arriving from another screen. In that case
	# hold the orbit's pop-in until the screen has (almost) materialised so the two
	# animations read as a sequence, not an overlap.
	var crossfade_in := animate and not game_screen.visible
	current_screen = "game"
	_ensure_game_screen_visuals(preserve_current_board)
	game_screen.orbit_entrance_delay = ORBIT_ENTRANCE_AFTER_TRANSITION if crossfade_in else 0.0
	var coach_snapshot := settings_game_coach_snapshot.duplicate(true)
	if not coach_snapshot.is_empty():
		game_screen.prepare_coach_snapshot_restore(coach_snapshot)
	refresh_game_screen()
	if not coach_snapshot.is_empty():
		settings_game_coach_snapshot.clear()
	restore_cached_hint_highlight()
	_show_screen(game_screen, animate)

func restore_cached_hint_highlight() -> void:
	if not state.has_cached_hint_for_current_move():
		return
	var target := state.cached_hint_target.duplicate(true)
	if not target.is_empty():
		game_screen.restore_hint_highlight(target)

func _on_theme_changed(theme_name: String) -> void:
	if state.theme == theme_name or theme_transitioning:
		return
	theme_transitioning = true
	await crossfade_rebuild(func() -> void:
		state.theme = theme_name
		UIStyles.set_theme(theme_name)
	)
	_save_progress_now()
	theme_transitioning = false

func capture_theme_snapshot() -> TextureRect:
	if is_instance_valid(theme_crossfade):
		theme_crossfade.queue_free()
	var snapshot := TextureRect.new()
	snapshot.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	snapshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	snapshot.stretch_mode = TextureRect.STRETCH_SCALE
	snapshot.position = Vector2.ZERO
	snapshot.size = Layout.viewport_size(self)
	snapshot.z_index = 1000
	snapshot.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(snapshot)
	theme_crossfade = snapshot
	return snapshot

func _on_language_changed(language_code: String) -> void:
	if state.language == language_code or theme_transitioning:
		return
	theme_transitioning = true
	await crossfade_rebuild(func() -> void:
		state.language = language_code
		Locale.set_language(language_code)
	)
	_save_progress_now()
	theme_transitioning = false

# Общий снапшот-кросс-фейд для смены темы/языка (4.1): захватываем текущий экран,
# мгновенно применяем изменение + rebuild под снапшотом, затем растворяем снапшот —
# единый плавный переход и для темы, и для языка.
func crossfade_rebuild(apply_change: Callable) -> void:
	var snapshot := capture_theme_snapshot()
	apply_change.call()
	rebuild_all(false)
	var reveal := snapshot.create_tween()
	reveal.tween_property(snapshot, "modulate:a", 0.0, THEME_CROSSFADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await reveal.finished
	if is_instance_valid(snapshot):
		snapshot.queue_free()
	if theme_crossfade == snapshot:
		theme_crossfade = null

# Rebuild only what is visible. Menu, Levels, and Settings already rebuild from
# their show methods; Game and the completion popup are marked dirty because
# their show paths otherwise update content without recreating themed controls.
func rebuild_all(animate_screen: bool = true) -> void:
	if bg != null:
		bg.refresh()
	game_screen_visuals_dirty = true
	complete_popup_visuals_dirty = true
	_build_persistent_header()
	show_current_screen(animate_screen)

func _ensure_game_screen_visuals(preserve_current_board: bool) -> void:
	if not game_screen_visuals_dirty:
		return
	if preserve_current_board:
		game_screen.restore_orbit_without_entrance_animation()
	game_screen.build()
	game_screen_visuals_dirty = false

func _ensure_complete_popup_visuals() -> void:
	if not complete_popup_visuals_dirty:
		return
	complete_popup.build()
	complete_popup_visuals_dirty = false

func show_current_screen(animate: bool = true) -> void:
	match current_screen:
		"levels":
			show_level_select(animate)
		"settings":
			show_settings(animate)
		"game":
			show_game(animate)
		_:
			show_main_menu(animate)

func _on_main_settings_pressed() -> void:
	settings_return_screen = "menu"
	show_settings()

func _on_levels_settings_pressed() -> void:
	settings_return_screen = "levels"
	show_settings()

func _on_reset_progress_pressed() -> void:
	state.reset_progress_preserving_preferences()
	settings_game_coach_snapshot.clear()
	shown_tutorial_coaches.clear()
	tutorial_levels = LevelData.get_tutorial_levels()
	_save_progress_now()
	show_main_menu()

func _on_game_settings_pressed() -> void:
	if is_level_complete_modal_active():
		return
	settings_return_screen = "game"
	settings_game_coach_snapshot = game_screen.active_coach_snapshot()
	game_screen.prepare_coach_for_screen_navigation()
	show_settings()

func _on_game_coach_header_mode_changed(active: bool) -> void:
	if current_screen != "game":
		return
	if is_instance_valid(persistent_header_root):
		persistent_header_root.z_index = PERSISTENT_HEADER_Z_INDEX
	_apply_persistent_header_immediate(game_screen)
	_set_persistent_header_coach_blocked(active)
	game_screen._set_local_header_over_coach(false)

func _on_settings_back_pressed() -> void:
	_save_progress_now()
	match settings_return_screen:
		"game":
			show_game()
		"levels":
			show_level_select()
		_:
			show_main_menu()

func _on_settings_volumes_changed(music_value: int, sound_value: int) -> void:
	state.music_volume = music_value
	state.sound_volume = sound_value
	if audio != null:
		audio.set_volumes(music_value, sound_value)
	_schedule_volume_save()

func _on_settings_haptics_changed(enabled: bool) -> void:
	state.haptics_enabled = enabled
	if audio != null:
		audio.set_haptics_enabled(enabled)
	_save_progress_now()

func _schedule_volume_save() -> void:
	if not is_instance_valid(volume_save_timer):
		volume_save_timer = Timer.new()
		volume_save_timer.name = "VolumeSaveTimer"
		volume_save_timer.one_shot = true
		volume_save_timer.wait_time = VOLUME_SAVE_DEBOUNCE_SECONDS
		volume_save_timer.timeout.connect(func() -> void: state.save_progress())
		add_child(volume_save_timer)
	volume_save_timer.start()

func _save_progress_now() -> void:
	if is_instance_valid(volume_save_timer):
		volume_save_timer.stop()
	state.save_progress()

func _on_play_pressed() -> void:
	if not state.are_all_tutorials_completed():
		state.has_played = true
		load_tutorial_level(first_unfinished_tutorial_index(), true)
		state.save_progress()
	else:
		load_level(state.current_level)
	show_game()

func _on_level_selected(level_number: int) -> void:
	if level_number < 0:
		load_tutorial_level(first_unfinished_tutorial_index(), true)
		state.has_played = true
		state.save_progress()
		show_game()
		return
	load_level(level_number)
	state.has_played = true
	state.save_progress()
	show_game()

func _on_skip_level_requested(level_number: int) -> void:
	# Authoritative gate + spend live in GameState; the UI only offers this when
	# affordable, but re-checking here keeps skips honest against any stale view.
	if not state.try_skip_level(level_number):
		return
	state.save_progress()
	level_select.hide_locked_level_popup()
	load_level(level_number)
	show_game()

func _on_ad_reward_requested(level_number: int) -> void:
	state.grant_ad_reward()
	state.save_progress()
	level_select.set_lumens(state.lumens)
	# Re-evaluate the popup after the reward: keep the balance/Watch Ad state while
	# funds are short, or switch to the balance-free Unlock state once affordable.
	level_select.show_locked_level_popup(level_number, state.can_skip_level(level_number), true)

func _on_level_select_back_pressed() -> void:
	show_main_menu()

func _on_game_back_pressed() -> void:
	if is_level_complete_modal_active():
		return
	game_screen.prepare_coach_for_screen_navigation()
	if tutorial_mode:
		if state.are_all_tutorials_completed():
			show_level_select()
		else:
			show_main_menu()
	else:
		show_level_select()

func is_level_complete_modal_active() -> bool:
	return is_instance_valid(complete_popup) and complete_popup.visible

func load_level(level_number: int) -> void:
	tutorial_mode = false
	var data: Dictionary = state.load_level(level_number)
	orbit_items = OrbitSlotsScript.assign(OrbitGenerator.initial_items(data, state.current_number))
	if game_screen != null:
		game_screen.clear_hint_cache()
		game_screen.clear_orbit_buttons()

func load_tutorial_level(index: int, reset_coach_memory: bool = true) -> void:
	tutorial_mode = true
	tutorial_index = int(clamp(index, 0, tutorial_levels.size() - 1))
	var data: Dictionary = tutorial_levels[tutorial_index]
	if reset_coach_memory:
		clear_tutorial_coach_memory(str(data.get("id", "tutorial")))
	state.current_number = int(data["start"])
	state.target_number = int(data["target"])
	state.moves_used = 0
	state.is_level_failed = false
	state.clear_cached_hint()
	orbit_items = OrbitSlotsScript.assign(OrbitGenerator.initial_items(data, state.current_number))
	if game_screen != null:
		game_screen.clear_hint_cache()
		game_screen.clear_orbit_buttons()

func first_unfinished_tutorial_index() -> int:
	for i in range(tutorial_levels.size()):
		if not state.is_tutorial_completed(i):
			return i
	return 0

func clear_tutorial_coach_memory(tutorial_id: String) -> void:
	var prefix := "%s:" % tutorial_id
	for key in shown_tutorial_coaches.keys():
		if str(key).begins_with(prefix):
			shown_tutorial_coaches.erase(key)

func restart_level() -> void:
	if tutorial_mode:
		# Restart the board and replay this tutorial's explanation from its first step.
		load_tutorial_level(tutorial_index, true)
	else:
		load_level(state.current_level)
	show_game()

func refresh_game_screen() -> void:
	var data: Dictionary = active_level_data()
	var view := GameViewStateScript.new()
	view.title_text = active_level_title()
	view.current_number = state.current_number
	view.target_number = state.target_number
	view.moves = state.moves_used
	view.star_mode = str(data.get("star_mode", ""))
	view.star_bands = StarCalculator.star_bands(data)
	view.orbit_items = visible_orbit_items()
	view.allowed_ops = data.get("allowed_ops", []) as Array
	view.failed = state.is_level_failed
	view.lumens = state.lumens
	view.hint_cost = state.current_hint_cost()
	view.tutorial = tutorial_mode
	view.tutorial_help = tutorial_help_text(data)
	view.coach_hint = tutorial_coach_data(data)
	view.placeholder = bool(data.get("placeholder", false))
	game_screen.configure(view)
	if state.has_cached_hint_for_current_move():
		game_screen.restore_hint_result_cache(state.cached_hint_text, state.lumens, state.cached_hint_target)

func visible_orbit_items() -> Array:
	var result: Array = []
	for raw_item in orbit_items:
		var item: Dictionary = (raw_item as Dictionary).duplicate()
		result.append(item)
	for i in range(result.size()):
		var item: Dictionary = (result[i] as Dictionary).duplicate()
		item["slot"] = int(item.get("slot", i))
		item["slot_count"] = int(item.get("slot_count", result.size()))
		result[i] = item
	return result

func _on_orbit_pressed(value: int, op: String, item_id: String) -> void:
	if orbit_input_locked or complete_popup.visible:
		return
	if tutorial_mode and not tutorial_move_keeps_winning_path(value, op, item_id):
		AudioManagerScript.play_invalid()
		game_screen.reject_tutorial_orbit(item_id)
		return
	orbit_input_locked = true
	_apply_orbit_press_after_frame(value, op, item_id)

func tutorial_move_keeps_winning_path(value: int, op: String, item_id: String) -> bool:
	if not orbit_item_exists(item_id) or not OperationLogic.can_apply(state.current_number, value, op):
		return false
	var next_number := OperationLogic.apply(state.current_number, value, op)
	if next_number == state.target_number:
		return true
	var remaining: Array = []
	for raw_item in orbit_items:
		var item: Dictionary = raw_item as Dictionary
		if str(item.get("id", "")) != item_id:
			remaining.append(item.duplicate(true))
	var visited: Dictionary = {}
	var path: Array = HintSolverScript.search_path(next_number, state.target_number, remaining, remaining.size(), visited)
	return not path.is_empty()

func _apply_orbit_press_after_frame(value: int, op: String, item_id: String) -> void:
	await get_tree().process_frame
	if complete_popup.visible:
		unlock_orbit_input()
		return
	perform_orbit_move(value, op, item_id)
	await unlock_orbit_input_after_animation()

# Применение хода по спутнику — общий путь для обычных тапов и для коуч-проводника.
# Возвращает false, если ход невозможен / спутник исчез (экран всё равно обновляется).
func perform_orbit_move(value: int, op: String, item_id: String) -> bool:
	if not orbit_item_exists(item_id):
		refresh_game_screen()
		return false
	if not OperationLogic.can_apply(state.current_number, value, op):
		AudioManagerScript.play_invalid()
		state.is_level_failed = has_no_available_moves()
		refresh_game_screen()
		return false
	AudioManagerScript.play_orbit_select()
	state.current_number = OperationLogic.apply(state.current_number, value, op)
	game_screen.flash_center(op)
	state.moves_used += 1
	remove_orbit_item(value, op, item_id)
	if state.current_number == state.target_number:
		complete_level()
	else:
		var failed_now := has_no_available_moves()
		# Поражение показываем только в наблюдаемом тупике: среди оставшихся
		# спутников нет ни одного применимого хода. Скрытую нерешаемость позиции
		# здесь не раскрываем — цветные ходы остаются доступны игроку.
		if failed_now and not state.is_level_failed:
			AudioManagerScript.play_invalid()
			AudioManagerScript.play_no_valid_moves_haptic()
		state.is_level_failed = failed_now
		refresh_game_screen()
	return true

func unlock_orbit_input() -> void:
	orbit_input_locked = false

func unlock_orbit_input_after_animation() -> void:
	# 4.3: длительность = реальному времени исчезновения спутника (не «магическая» 0.22).
	# Убранный спутник `disabled` сразу, оставшиеся уже перетекают — доска готова к тапу.
	await get_tree().create_timer(game_screen.orbit_move_settle_time()).timeout
	orbit_input_locked = false

func complete_level() -> void:
	AudioManagerScript.play_level_complete()
	var stars := 0
	var reward := -1
	var teaser := ""
	var show_details := not tutorial_mode
	if tutorial_mode:
		var was_tutorial_completed := state.is_tutorial_completed(tutorial_index)
		state.set_tutorial_completed(tutorial_index)
		state.save_progress()
		var base := str(active_level_data().get("id", "tutorial")).trim_prefix("tutorial_")
		teaser = Locale.t("tut.%s.teaser" % base, str(active_level_data().get("complete_teaser", "Excellent. Continue when ready.")))
		# Тизер повторного прохождения — для ЛЮБОГО уже пройденного туториала (3.3),
		# не только «order»; EN — инлайн-фолбэк, RU — ключ tut.<base>.teaser_replay.
		if was_tutorial_completed:
			teaser = Locale.t("tut.%s.teaser_replay" % base, "Great practice. Return to levels anytime.")
	else:
		stars = StarCalculator.calculate(state.moves_used, active_level_data())
		reward = state.claim_level_reward(stars)
		state.set_stars(stars)
		state.unlock_next_level()
		state.save_progress()
	last_reward_delta = max(0, reward)
	refresh_game_screen()
	_ensure_complete_popup_visuals()
	if tutorial_mode:
		complete_popup.show_result(active_level_title(), 0, state.moves_used, true, reward, state.lumens, show_details, teaser)
	else:
		complete_popup.show_result(active_level_title(), stars, state.moves_used, state.current_level < LevelData.PLAYABLE_LEVEL_COUNT, reward, state.lumens)

func has_no_available_moves() -> bool:
	# Обычный интерфейс опирается только на видимое состояние доски. Полный решатель
	# намеренно не вызывается: иначе моментальная реакция после хода выдаёт игроку,
	# сохранил ли он победную последовательность.
	if state.current_number == state.target_number:
		return false
	for raw_item in orbit_items:
		var item: Dictionary = raw_item as Dictionary
		if OperationLogic.can_apply(state.current_number, int(item["value"]), str(item["op"])):
			return false
	return true

func remove_orbit_item(value: int, op: String, item_id: String) -> void:
	for i in range(orbit_items.size()):
		var item: Dictionary = orbit_items[i] as Dictionary
		if str(item.get("id", "")) == item_id or (int(item["value"]) == value and str(item["op"]) == op):
			var removed_slot: int = int(item.get("slot", i))
			var old_slot_count: int = int(item.get("slot_count", orbit_items.size()))
			var removed_angle: float = float(item.get("orbit_target_angle", OrbitSlotsScript.angle_for_slot(removed_slot, old_slot_count)))
			orbit_items.remove_at(i)
			orbit_items = OrbitSlotsScript.reflow(orbit_items, removed_slot, old_slot_count, removed_angle)
			return

func orbit_item_exists(item_id: String) -> bool:
	for raw_item in orbit_items:
		var item: Dictionary = raw_item as Dictionary
		if str(item.get("id", "")) == item_id:
			return true
	return false

func _on_hint_requested() -> void:
	if tutorial_mode:
		show_free_tutorial_hint()
		return
	if state.has_cached_hint_for_current_move():
		var cached_target := state.cached_hint_target.duplicate(true)
		if cached_target.is_empty():
			game_screen.show_hint_result(state.cached_hint_text, state.lumens)
		else:
			game_screen.reveal_hint_result(state.cached_hint_text, state.lumens, cached_target)
		return

	if not state.can_afford_hint():
		AudioManagerScript.play_invalid()
		game_screen.show_insufficient_hint_balance(state.lumens)
		return

	# Анализ нерешаемой позиции — тоже подсказка: без оплаты этот ответ становится
	# бесплатным оракулом для перебора ходов через Restart. Сначала подтверждаем
	# баланс, затем одинаково оплачиваем и следующий ход, и диагноз тупика.
	var hint_result: Dictionary = HintSolverScript.next_hint(state.current_number, state.target_number, state.moves_used, orbit_items, active_level_data())
	var hint_text := str(hint_result.get("text", ""))
	var hint_target: Dictionary = (hint_result.get("target", {}) as Dictionary).duplicate(true)
	if state.spend_hint():
		AudioManagerScript.play_hint_reveal()
		state.cache_hint(hint_text, hint_target)
		state.save_progress()
		if hint_target.is_empty():
			game_screen.show_hint_result(hint_text, state.lumens)
		else:
			game_screen.reveal_hint_result(hint_text, state.lumens, hint_target)
		refresh_game_screen()

func show_free_tutorial_hint() -> void:
	# Tutorials never spend Lumens or open the purchase prompt. Pick the first
	# currently available move that still leaves a complete path to the target.
	var target: Dictionary = {}
	for raw_item in orbit_items:
		var item: Dictionary = raw_item as Dictionary
		var value := int(item.get("value", 0))
		var op := str(item.get("op", ""))
		var item_id := str(item.get("id", ""))
		if tutorial_move_keeps_winning_path(value, op, item_id):
			target = {
				"id": item_id,
				"op": op,
				"value": value
			}
			break
	if target.is_empty():
		AudioManagerScript.play_invalid()
		game_screen.show_temporary_help(
			Locale.t("tutorial.hint.none", "No winning move is available. Restart the explanation."),
			false
		)
		return
	AudioManagerScript.play_hint_reveal()
	game_screen.highlight_hint_target(target)
	game_screen.show_temporary_help(
		Locale.t("tutorial.hint.next", "The next winning move is highlighted."),
		false
	)

func _on_hint_ad_requested() -> void:
	if tutorial_mode:
		return
	state.grant_ad_reward()
	state.save_progress()
	# Advertising only replenishes the balance. Return to the matching confirmation
	# state instead of automatically buying/revealing the hint.
	refresh_game_screen()
	if state.can_afford_hint():
		game_screen.show_hint_prompt_after_ad(state.lumens)
	else:
		game_screen.show_insufficient_hint_balance(state.lumens)

func active_level_data() -> Dictionary:
	return tutorial_levels[tutorial_index] if tutorial_mode else state.current_level_data()

func active_level_title() -> String:
	if tutorial_mode:
		return Locale.t("game.tutorial", "TUTORIAL")
	return Locale.t("game.level", "LEVEL %d") % state.current_level

func _on_popup_next_pressed() -> void:
	# When the next step stays on the game screen, dismiss the old orbit in parallel
	# with the popup sliding away, then swap in the next level — so the boards flow
	# into each other instead of the old chips vanishing in a single frame. Going to
	# level select keeps the plain popup-hide (the screen crossfade covers it).
	if _completion_advances_in_place():
		complete_popup.hide_popup()
		game_screen.dismiss_orbit(_continue_after_complete_popup)
	else:
		complete_popup.hide_popup(_continue_after_complete_popup)

func _completion_advances_in_place() -> bool:
	if tutorial_mode:
		return tutorial_index < tutorial_levels.size() - 1
	return state.current_level < LevelData.PLAYABLE_LEVEL_COUNT

func _continue_after_complete_popup() -> void:
	if tutorial_mode:
		if tutorial_index < tutorial_levels.size() - 1:
			load_tutorial_level(tutorial_index + 1, true)
			state.save_progress()
			show_game()
		else:
			show_level_select()
		return
	if state.current_level < LevelData.PLAYABLE_LEVEL_COUNT:
		load_level(state.current_level + 1)
		state.save_progress()
		show_game()
	else:
		show_level_select()

func _on_popup_levels_pressed() -> void:
	complete_popup.hide_popup(show_level_select)

func _on_double_reward_requested() -> void:
	# Double just the delta this win paid; base rewards stay delta-based (no farm).
	if last_reward_delta <= 0:
		return
	state.lumens += last_reward_delta
	state.save_progress()
	complete_popup.apply_reward_doubled()
	last_reward_delta = 0

func tutorial_help_text(data: Dictionary) -> String:
	if not tutorial_mode:
		return ""
	var base := str(data.get("id", "tutorial")).trim_prefix("tutorial_")
	if state.moves_used == 0:
		return Locale.t("tut.%s.start" % base, str(data.get("help_start", "Tap orbit numbers to change the center.")))
	return Locale.t("tut.%s.after" % base, str(data.get("help_after", "Keep going to the target.")))

func tutorial_coach_data(data: Dictionary) -> Dictionary:
	if not tutorial_mode:
		return {}
	var id := str(data.get("id", "tutorial"))
	var total_steps := tutorial_explanation_step_count(data)
	if state.moves_used == 0:
		var start_key := "%s:start" % id
		if shown_tutorial_coaches.has(start_key):
			return {}
		var intro := (data.get("coach", {}) as Dictionary).duplicate(true)
		if (intro.get("steps", []) as Array).is_empty():
			return {}
		shown_tutorial_coaches[start_key] = true
		intro["progress_start"] = 0
		intro["progress_total"] = total_steps
		return intro
	var note := tutorial_note_after_move(data, state.moves_used)
	if note.is_empty():
		return {}
	var note_key := "%s:after:%d" % [id, state.moves_used]
	if shown_tutorial_coaches.has(note_key):
		return {}
	shown_tutorial_coaches[note_key] = true
	var progress_before := ((data.get("coach", {}) as Dictionary).get("steps", []) as Array).size()
	for move_count in range(1, state.moves_used):
		progress_before += (tutorial_note_after_move(data, move_count).get("steps", []) as Array).size()
	note["progress_start"] = progress_before
	note["progress_total"] = total_steps
	return note

func tutorial_note_after_move(data: Dictionary, move_count: int) -> Dictionary:
	var notes_raw = data.get("coach_after_moves", {})
	if typeof(notes_raw) != TYPE_DICTIONARY:
		return {}
	var notes := notes_raw as Dictionary
	var raw_note: Variant = null
	if notes.has(move_count):
		raw_note = notes[move_count]
	elif notes.has(str(move_count)):
		raw_note = notes[str(move_count)]
	if raw_note == null or typeof(raw_note) != TYPE_DICTIONARY:
		return {}
	return (raw_note as Dictionary).duplicate(true)

func tutorial_explanation_step_count(data: Dictionary) -> int:
	var total := ((data.get("coach", {}) as Dictionary).get("steps", []) as Array).size()
	var notes_raw = data.get("coach_after_moves", {})
	if typeof(notes_raw) == TYPE_DICTIONARY:
		for raw_note in (notes_raw as Dictionary).values():
			if typeof(raw_note) == TYPE_DICTIONARY:
				total += ((raw_note as Dictionary).get("steps", []) as Array).size()
	return maxi(total, 1)
