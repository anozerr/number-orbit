extends Node2D

const MainMenuScene = preload("res://scenes/screens/MainMenu.tscn")
const LevelSelectScene = preload("res://scenes/screens/LevelSelect.tscn")
const SettingsScene = preload("res://scenes/screens/SettingsScreen.tscn")
const GameScreenScene = preload("res://scenes/screens/GameScreen.tscn")
const CompletePopupScene = preload("res://scenes/ui/LevelCompletePopup.tscn")

var state: GameState = GameState.new()
var orbit_items: Array = []
var tutorial_levels: Array = []
var tutorial_mode: bool = false
var tutorial_select_mode: bool = false
var tutorial_select_page: String = ""
var selected_tutorial_op: int = 0
var level_select_page: String = ""
var selected_level_difficulty: int = 0
var tutorial_index: int = 0
var return_to_game_after_settings: bool = false
var orbit_input_locked: bool = false

var bg: TextureRect
var main_menu: MainMenuScreen
var level_select: LevelSelectScreen
var settings_screen: SettingsScreen
var game_screen: GameScreen
var complete_popup: LevelCompletePopup

func _ready() -> void:
	randomize()
	state.setup(LevelData.get_levels())
	tutorial_levels = LevelData.get_tutorial_levels()
	build()
	load_level(state.current_level)
	show_main_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		state.save_progress()

func build() -> void:
	bg = TextureRect.new()
	bg.texture = preload("res://assets/images/backgrounds/background.png")
	bg.position = Vector2.ZERO
	bg.size = Vector2(1080, 1920)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	main_menu = get_or_create_screen("MainMenu", MainMenuScene) as MainMenuScreen
	main_menu.play_pressed.connect(_on_play_pressed)
	main_menu.levels_pressed.connect(show_level_select)
	main_menu.settings_pressed.connect(_on_main_settings_pressed)
	main_menu.reset_progress_pressed.connect(_on_reset_progress_pressed)
	main_menu.add_bulbs_pressed.connect(_on_add_bulbs_pressed)

	level_select = get_or_create_screen("LevelSelect", LevelSelectScene) as LevelSelectScreen
	level_select.back_pressed.connect(_on_level_select_back_pressed)
	level_select.level_selected.connect(_on_level_selected)

	settings_screen = get_or_create_screen("SettingsScreen", SettingsScene) as SettingsScreen
	settings_screen.back_pressed.connect(_on_settings_back_pressed)
	settings_screen.volumes_changed.connect(_on_settings_volumes_changed)
	settings_screen.configure(state.music_volume, state.sound_volume)

	game_screen = get_or_create_screen("GameScreen", GameScreenScene) as GameScreen
	game_screen.back_pressed.connect(_on_game_back_pressed)
	game_screen.settings_pressed.connect(_on_game_settings_pressed)
	game_screen.restart_pressed.connect(restart_level)
	game_screen.orbit_pressed.connect(_on_orbit_pressed)
	game_screen.hint_requested.connect(_on_hint_requested)

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
	tutorial_mode = false
	tutorial_select_mode = false
	tutorial_select_page = ""
	level_select_page = "all"
	hide_all()
	level_select.visible = true
	level_select.rebuild_level_difficulties(state.star_ratings, state.max_unlocked_level, state.tutorial_completed)

func show_level_grid(difficulty_index: int = selected_level_difficulty) -> void:
	tutorial_mode = false
	tutorial_select_mode = false
	tutorial_select_page = ""
	level_select_page = "grid"
	selected_level_difficulty = int(clamp(difficulty_index, 0, LevelData.DIFFICULTIES.size() - 1))
	hide_all()
	level_select.visible = true
	level_select.rebuild_levels_for_difficulty(selected_level_difficulty, state.star_ratings, state.max_unlocked_level)

func show_tutorial_difficulty_select(op_index: int = selected_tutorial_op) -> void:
	tutorial_mode = false
	tutorial_select_mode = true
	tutorial_select_page = "difficulty"
	selected_tutorial_op = int(clamp(op_index, 0, 3))
	hide_all()
	level_select.visible = true
	level_select.rebuild_tutorial_difficulty(selected_tutorial_op, state.tutorial_completed)

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

func _on_reset_progress_pressed() -> void:
	state.setup(LevelData.get_levels(), false)
	tutorial_levels = LevelData.get_tutorial_levels()
	settings_screen.configure(state.music_volume, state.sound_volume)
	load_level(1)
	state.save_progress()
	show_main_menu()

func _on_add_bulbs_pressed() -> void:
	state.hint_points += 500
	state.save_progress()
	if main_menu != null:
		main_menu.pulse_play_button()

func _on_game_settings_pressed() -> void:
	return_to_game_after_settings = true
	show_settings()

func _on_settings_back_pressed() -> void:
	state.save_progress()
	if return_to_game_after_settings:
		return_to_game_after_settings = false
		show_game()
	else:
		show_main_menu()

func _on_settings_volumes_changed(music_value: int, sound_value: int) -> void:
	state.music_volume = music_value
	state.sound_volume = sound_value
	state.save_progress()

func _on_play_pressed() -> void:
	if not state.has_played:
		state.has_played = true
		load_tutorial_level(0)
		state.save_progress()
	else:
		load_level(state.current_level)
	show_game()

func _on_level_selected(level_number: int) -> void:
	if tutorial_select_mode:
		if tutorial_select_page == "ops":
			show_tutorial_difficulty_select(level_number - 1)
		else:
			load_tutorial_level(selected_tutorial_op * 3 + level_number - 1)
			show_game()
		return
	if level_number < 0:
		show_tutorial_difficulty_select(-level_number - 1)
		return
	load_level(level_number)
	state.has_played = true
	state.save_progress()
	show_game()

func _on_level_select_back_pressed() -> void:
	if tutorial_select_mode and tutorial_select_page == "difficulty":
		show_level_select()
	else:
		show_main_menu()

func _on_game_back_pressed() -> void:
	if tutorial_mode:
		show_level_select()
	else:
		show_level_select()

func load_level(level_number: int) -> void:
	tutorial_mode = false
	var data: Dictionary = state.load_level(level_number)
	selected_level_difficulty = LevelData.difficulty_index_for_level(state.current_level)
	orbit_items = assign_orbit_slots(OrbitGenerator.initial_items(data, state.current_number))
	if game_screen != null:
		game_screen.clear_hint_cache()
		game_screen.clear_orbit_buttons()

func load_tutorial_level(index: int) -> void:
	tutorial_mode = true
	tutorial_index = int(clamp(index, 0, tutorial_levels.size() - 1))
	selected_tutorial_op = int(float(tutorial_index) / 3.0)
	var data: Dictionary = tutorial_levels[tutorial_index]
	state.current_number = int(data["start"])
	state.target_number = int(data["target"])
	state.moves_used = 0
	state.is_level_failed = false
	state.clear_cached_hint()
	orbit_items = assign_orbit_slots(OrbitGenerator.initial_items(data, state.current_number))
	if game_screen != null:
		game_screen.clear_hint_cache()
		game_screen.clear_orbit_buttons()

func assign_orbit_slots(items: Array) -> Array:
	var result: Array = []
	var slots: Array = spread_slot_order(items.size())
	for i in range(items.size()):
		var item: Dictionary = (items[i] as Dictionary).duplicate()
		item["id"] = "orbit_%d" % i
		item["slot"] = int(slots[i])
		item["slot_count"] = items.size()
		result.append(item)
	return result

func spread_slot_order(count: int) -> Array:
	match count:
		1:
			return [0]
		2:
			return [0, 1]
		3:
			return [0, 2, 1]
		4:
			return [0, 2, 1, 3]
		5:
			return [0, 2, 4, 1, 3]
		6:
			return [0, 3, 1, 4, 2, 5]
		7:
			return [0, 3, 6, 2, 5, 1, 4]
		8:
			return [0, 4, 1, 5, 2, 6, 3, 7]
		9:
			return [0, 4, 8, 3, 7, 2, 6, 1, 5]
		10:
			return [0, 5, 1, 6, 2, 7, 3, 8, 4, 9]
	var result: Array = []
	var step: int = int(max(1, floor(float(count) * 0.5)))
	var used: Dictionary = {}
	var slot := 0
	while result.size() < count:
		if not used.has(slot):
			result.append(slot)
			used[slot] = true
		slot = (slot + step) % count
		if used.has(slot):
			for candidate in range(count):
				if not used.has(candidate):
					slot = candidate
					break
	return result

func reflow_orbit_slots(removed_slot: int = -1, old_slot_count: int = 0, removed_angle_override: float = INF) -> void:
	if orbit_items.is_empty():
		return
	var new_count: int = orbit_items.size()
	if old_slot_count <= 0:
		old_slot_count = new_count + 1
	if removed_slot < 0:
		var slots: Array = spread_slot_order(new_count)
		for i in range(new_count):
			var item: Dictionary = (orbit_items[i] as Dictionary).duplicate()
			item["slot"] = int(slots[i])
			item["slot_count"] = new_count
			item.erase("orbit_target_angle")
			item.erase("orbit_snap_to_target")
			item.erase("orbit_force_clockwise")
			orbit_items[i] = item
		return

	var removed_angle: float = removed_angle_override
	if is_inf(removed_angle):
		removed_angle = orbit_angle_for_slot(removed_slot, old_slot_count)
	var anchor_index := 0
	var best_distance := INF
	for i in range(new_count):
		var candidate: Dictionary = orbit_items[i] as Dictionary
		var candidate_slot: int = int(candidate.get("slot", i))
		var candidate_angle: float = float(candidate.get("orbit_target_angle", orbit_angle_for_slot(candidate_slot, old_slot_count)))
		var distance: float = fposmod(candidate_angle - removed_angle, TAU)
		if distance < 0.001:
			distance = TAU
		if distance < best_distance:
			best_distance = distance
			anchor_index = i

	var anchor: Dictionary = orbit_items[anchor_index] as Dictionary
	var anchor_old_slot: int = int(anchor.get("slot", 0))
	var anchor_angle: float = float(anchor.get("orbit_target_angle", orbit_angle_for_slot(anchor_old_slot, old_slot_count)))
	var order: Array = []
	for i in range(new_count):
		var item: Dictionary = orbit_items[i] as Dictionary
		var old_slot: int = int(item.get("slot", i))
		var old_angle: float = float(item.get("orbit_target_angle", orbit_angle_for_slot(old_slot, old_slot_count)))
		var clockwise_distance: float = fposmod(old_angle - anchor_angle, TAU)
		order.append({"index": i, "distance": clockwise_distance, "old_slot": old_slot, "old_angle": old_angle})
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distance"]) < float(b["distance"])
	)

	for rank in range(order.size()):
		var info: Dictionary = order[rank] as Dictionary
		var i: int = int(info["index"])
		var old_angle: float = float(info["old_angle"])
		var target_angle: float = anchor_angle + (TAU * float(rank) / float(new_count))
		while target_angle < old_angle - 0.001:
			target_angle += TAU
		if target_angle - old_angle > PI:
			target_angle -= TAU
		var item: Dictionary = (orbit_items[i] as Dictionary).duplicate()
		item["slot"] = rank
		item["slot_count"] = new_count
		item["orbit_target_angle"] = target_angle
		item["orbit_force_clockwise"] = true
		item["orbit_snap_to_target"] = rank == 0
		orbit_items[i] = item

func orbit_angle_for_slot(slot: int, slot_count: int) -> float:
	return TAU * float(slot) / float(max(1, slot_count)) - PI / 2.0

func restart_level() -> void:
	if tutorial_mode:
		load_tutorial_level(tutorial_index)
	else:
		load_level(state.current_level)
	show_game()

func refresh_game_screen() -> void:
	var data: Dictionary = active_level_data()
	var thresholds: Array = StarCalculator.sorted_thresholds(data)
	game_screen.configure(active_level_title(), state.current_number, state.target_number, state.moves_used, thresholds, visible_orbit_items(), data["allowed_ops"] as Array, state.is_level_failed, state.hint_points, tutorial_mode, tutorial_help_text(data))

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
	orbit_input_locked = true
	_apply_orbit_press_after_frame(value, op, item_id)

func _apply_orbit_press_after_frame(value: int, op: String, item_id: String) -> void:
	await get_tree().process_frame
	if complete_popup.visible:
		unlock_orbit_input()
		return
	if not orbit_item_exists(item_id):
		refresh_game_screen()
		unlock_orbit_input()
		return
	if not OperationLogic.can_apply(state.current_number, value, op):
		state.is_level_failed = is_current_level_failed()
		refresh_game_screen()
		await unlock_orbit_input_after_animation()
		return

	state.current_number = OperationLogic.apply(state.current_number, value, op)
	state.moves_used += 1
	remove_orbit_item(value, op, item_id)
	if state.current_number == state.target_number:
		complete_level()
	else:
		state.is_level_failed = is_current_level_failed()
		refresh_game_screen()
	await unlock_orbit_input_after_animation()

func unlock_orbit_input() -> void:
	orbit_input_locked = false

func unlock_orbit_input_after_animation() -> void:
	await get_tree().create_timer(0.22).timeout
	orbit_input_locked = false

func complete_level() -> void:
	var stars: int = StarCalculator.calculate(state.moves_used, active_level_data())
	if tutorial_mode:
		state.set_tutorial_completed(tutorial_index)
		state.save_progress()
		refresh_game_screen()
		complete_popup.show_result(active_level_title(), 0, state.moves_used, tutorial_index < tutorial_levels.size() - 1, -1, state.hint_points, false)
		return
	var reward: int = state.claim_level_reward(stars)
	state.set_stars(stars)
	state.unlock_next_level()
	state.save_progress()
	refresh_game_screen()
	complete_popup.show_result(active_level_title(), stars, state.moves_used, state.current_level < LevelData.LEVEL_COUNT, reward, state.hint_points)

func is_current_level_failed() -> bool:
	var data: Dictionary = active_level_data()
	var allowed_ops: Array = data["allowed_ops"] as Array
	var can_decrease: bool = allowed_ops.has("subtract") or allowed_ops.has("divide")
	var can_increase: bool = allowed_ops.has("add") or allowed_ops.has("multiply")
	if state.current_number > state.target_number and not can_decrease:
		return true
	if state.current_number < state.target_number and not can_increase:
		return true
	if not has_any_valid_orbit_item():
		return true
	return false

func remove_orbit_item(value: int, op: String, item_id: String) -> void:
	for i in range(orbit_items.size()):
		var item: Dictionary = orbit_items[i] as Dictionary
		if str(item.get("id", "")) == item_id or (int(item["value"]) == value and str(item["op"]) == op):
			var removed_slot: int = int(item.get("slot", i))
			var old_slot_count: int = int(item.get("slot_count", orbit_items.size()))
			var removed_angle: float = float(item.get("orbit_target_angle", orbit_angle_for_slot(removed_slot, old_slot_count)))
			orbit_items.remove_at(i)
			reflow_orbit_slots(removed_slot, old_slot_count, removed_angle)
			return

func orbit_item_exists(item_id: String) -> bool:
	for raw_item in orbit_items:
		var item: Dictionary = raw_item as Dictionary
		if str(item.get("id", "")) == item_id:
			return true
	return false

func has_any_valid_orbit_item() -> bool:
	for raw_item in orbit_items:
		var item: Dictionary = raw_item as Dictionary
		if OperationLogic.can_apply(state.current_number, int(item["value"]), str(item["op"])):
			return true
	return false

func _on_hint_requested() -> void:
	if tutorial_mode:
		return
	if state.has_cached_hint_for_current_move():
		game_screen.show_hint_result(state.cached_hint_text, state.hint_points)
		return

	var hint_text: String = next_hint_text()
	if hint_text.begins_with("No "):
		game_screen.show_hint_result(hint_text, state.hint_points)
		return

	if not state.can_afford_hint():
		game_screen.show_insufficient_hint_balance(state.hint_points)
		return
	if state.spend_hint():
		state.cache_hint(hint_text)
		state.save_progress()
		game_screen.show_hint_result(hint_text, state.hint_points)
		refresh_game_screen()

func next_hint_text() -> String:
	var data: Dictionary = active_level_data()
	var thresholds: Array = StarCalculator.sorted_thresholds(data)
	var max_depth: int = int(min(orbit_items.size(), max(1, int(thresholds[thresholds.size() - 1]) - state.moves_used + 2)))
	var path: Array = find_hint_path(state.current_number, state.target_number, max_depth)
	if path.is_empty():
		return "No winning hint is available from this position. Try restarting the level."
	var item: Dictionary = path[0] as Dictionary
	var op: String = str(item["op"])
	var value: int = int(item["value"])
	return "To win: %d move(s) left.\nNext move: %s %d" % [path.size(), OperationLogic.symbol(op), value]

func find_hint_path(current_number: int, target_number: int, depth: int) -> Array:
	var visited: Dictionary = {}
	return search_hint_path(current_number, target_number, orbit_items.duplicate(), depth, visited)

func search_hint_path(current_number: int, target_number: int, remaining_items: Array, depth: int, visited: Dictionary) -> Array:
	if depth <= 0:
		return []

	for i in range(remaining_items.size()):
		var raw_item = remaining_items[i]
		var item: Dictionary = raw_item as Dictionary
		var op: String = str(item["op"])
		var value: int = int(item["value"])
		if not OperationLogic.can_apply(current_number, value, op):
			continue

		var next_number: int = OperationLogic.apply(current_number, value, op)
		if next_number == target_number:
			return [item]

		var next_remaining: Array = remaining_items.duplicate()
		next_remaining.remove_at(i)
		var key: String = "%d:%d:%s" % [depth - 1, next_number, items_key(next_remaining)]
		if visited.has(key):
			continue
		visited[key] = true

		var tail: Array = search_hint_path(next_number, target_number, next_remaining, depth - 1, visited)
		if not tail.is_empty():
			var result: Array = [item]
			result.append_array(tail)
			return result

	return []

func items_key(items_to_key: Array) -> String:
	var parts: Array[String] = []
	for raw_item in items_to_key:
		var item: Dictionary = raw_item as Dictionary
		parts.append("%s%d" % [str(item["op"]).substr(0, 1), int(item["value"])])
	return ",".join(parts)

func active_level_data() -> Dictionary:
	return tutorial_levels[tutorial_index] if tutorial_mode else state.current_level_data()

func active_level_title() -> String:
	if tutorial_mode:
		var data: Dictionary = active_level_data()
		var op: String = str(data.get("tutorial_op", (data["allowed_ops"] as Array)[0]))
		var difficulty: String = str(data.get("difficulty", ""))
		return "TUTORIAL: %s %s" % [op.to_upper(), difficulty.to_upper()]
	var data: Dictionary = active_level_data()
	var local_level: int = int(data.get("local_index", LevelData.local_level_number(state.current_level)))
	return "LEVEL %d" % local_level

func _on_popup_next_pressed() -> void:
	complete_popup.hide_popup()
	if tutorial_mode:
		if tutorial_index < tutorial_levels.size() - 1:
			load_tutorial_level(tutorial_index + 1)
			state.save_progress()
			show_game()
		else:
			show_tutorial_difficulty_select(selected_tutorial_op)
		return
	if state.current_level < LevelData.LEVEL_COUNT:
		load_level(state.current_level + 1)
		state.save_progress()
		show_game()
	else:
		show_level_select()

func _on_popup_levels_pressed() -> void:
	complete_popup.hide_popup()
	if tutorial_mode:
		show_level_select()
	else:
		show_level_select()

func tutorial_help_text(data: Dictionary) -> String:
	if not tutorial_mode:
		return ""
	var op: String = str(data.get("tutorial_op", "add"))
	match op:
		"add":
			if state.moves_used == 0:
				return "Tap a green orbit number. Add increases the center number toward the target."
			return "Nice. Keep adding the right numbers until the center reaches the target."
		"subtract":
			if state.moves_used == 0:
				return "Tap a yellow orbit number. Subtract lowers the center number."
			return "Keep subtracting carefully. Grey buttons are unavailable moves."
		"multiply":
			if state.moves_used == 0:
				return "Tap a red orbit number. Multiply grows the center number fast."
			return "Great. Multiplication can jump quickly, so watch the target."
		"divide":
			if state.moves_used == 0:
				return "Tap a blue orbit number. Divide only works when the result is exact."
			return "Good. Only exact divisions stay available."
	return "Choose orbit numbers to transform the center number into the target."
