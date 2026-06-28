class_name GameState
extends RefCounted

const SAVE_VERSION := 1
const SAVE_PATH := "user://number_orbit_save.json"
const HINT_COST := 80

var levels: Array = []
var current_level: int = 1
var current_number: int = 1
var target_number: int = 10
var moves_used: int = 0
var max_unlocked_level: int = 1
var star_ratings: Array = []
var bulb_rewards_claimed: Array = []
var tutorial_completed: Array = []
var has_played: bool = false
var is_level_failed: bool = false
var hint_points: int = 0
var cached_hint_move_index: int = -1
var cached_hint_text: String = ""
var music_volume: int = 80
var sound_volume: int = 80

func setup(level_data: Array, load_saved: bool = true) -> void:
	levels = level_data
	max_unlocked_level = min(1, levels.size())
	current_level = 1
	current_number = 1
	target_number = 10
	moves_used = 0
	has_played = false
	is_level_failed = false
	hint_points = 0
	cached_hint_move_index = -1
	cached_hint_text = ""
	music_volume = 80
	sound_volume = 80
	star_ratings.resize(levels.size())
	bulb_rewards_claimed.resize(levels.size())
	for i in range(levels.size()):
		star_ratings[i] = 0
		bulb_rewards_claimed[i] = false
	tutorial_completed.resize(LevelData.get_tutorial_levels().size())
	for i in range(tutorial_completed.size()):
		tutorial_completed[i] = false
	load_level(1)
	if load_saved:
		load_progress()

func load_level(level_number: int) -> Dictionary:
	current_level = int(clamp(level_number, 1, levels.size()))
	var data: Dictionary = levels[current_level - 1]
	current_number = int(data["start"])
	target_number = int(data["target"])
	moves_used = 0
	is_level_failed = false
	clear_cached_hint()
	return data

func current_level_data() -> Dictionary:
	return levels[current_level - 1]

func unlock_next_level() -> void:
	while max_unlocked_level < levels.size():
		var index: int = max_unlocked_level - 1
		if index < 0 or index >= star_ratings.size() or int(star_ratings[index]) <= 0:
			return
		max_unlocked_level = min(levels.size(), max_unlocked_level + 1)

func is_level_group_completed(first_level: int, last_level: int) -> bool:
	for level_number in range(first_level, last_level + 1):
		var index: int = level_number - 1
		if index < 0 or index >= star_ratings.size() or int(star_ratings[index]) <= 0:
			return false
	return true

func is_level_unlocked(level_number: int) -> bool:
	return level_number <= max_unlocked_level

func set_stars(stars: int) -> void:
	var index: int = current_level - 1
	star_ratings[index] = max(int(star_ratings[index]), stars)

func set_tutorial_completed(index: int) -> void:
	if index >= 0 and index < tutorial_completed.size():
		tutorial_completed[index] = true

func is_tutorial_completed(index: int) -> bool:
	return index >= 0 and index < tutorial_completed.size() and bool(tutorial_completed[index])

func is_tutorial_op_completed(op_index: int) -> bool:
	var start_index: int = op_index * 3
	if start_index < 0 or start_index + 2 >= tutorial_completed.size():
		return false
	for i in range(3):
		if not bool(tutorial_completed[start_index + i]):
			return false
	return true

func are_all_tutorials_completed() -> bool:
	for completed in tutorial_completed:
		if not bool(completed):
			return false
	return true

func claim_level_reward(stars: int) -> int:
	var index: int = current_level - 1
	var previous_reward: int = reward_for_stars(int(star_ratings[index]))
	var new_reward: int = reward_for_stars(stars)
	var delta: int = max(0, new_reward - previous_reward)
	hint_points += delta
	bulb_rewards_claimed[index] = new_reward > 0
	return delta

func reward_for_stars(stars: int) -> int:
	match stars:
		3:
			return 50
		2:
			return 30
		1:
			return 20
	return 0

func can_afford_hint() -> bool:
	return hint_points >= HINT_COST

func spend_hint() -> bool:
	if not can_afford_hint():
		return false
	hint_points -= HINT_COST
	return true

func has_cached_hint_for_current_move() -> bool:
	return cached_hint_move_index == moves_used and not cached_hint_text.is_empty()

func cache_hint(text: String) -> void:
	cached_hint_move_index = moves_used
	cached_hint_text = text

func clear_cached_hint() -> void:
	cached_hint_move_index = -1
	cached_hint_text = ""

func save_progress() -> void:
	var data := {
		"save_version": SAVE_VERSION,
		"current_level_id": current_level_id(),
		"max_unlocked_level": max_unlocked_level,
		"stars_by_level_id": stars_by_level_id(),
		"tutorial_completed_by_id": tutorial_completed_by_id(),
		"hint_points": hint_points,
		"has_played": has_played,
		"music_volume": music_volume,
		"sound_volume": sound_volume
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed as Dictionary
	load_save_v1(data)

func load_save_v1(data: Dictionary) -> void:
	hint_points = max(0, int(data.get("hint_points", hint_points)))
	has_played = bool(data.get("has_played", has_played))
	music_volume = int(clamp(int(data.get("music_volume", music_volume)), 0, 100))
	sound_volume = int(clamp(int(data.get("sound_volume", sound_volume)), 0, 100))
	load_stars_from_ids(data.get("stars_by_level_id", {}))
	load_tutorials_from_ids(data.get("tutorial_completed_by_id", {}))
	recalculate_max_unlocked_level()
	var saved_level := level_number_for_id(str(data.get("current_level_id", "")))
	if saved_level > 0:
		current_level = saved_level

func recalculate_max_unlocked_level() -> void:
	max_unlocked_level = min(1, levels.size())
	while max_unlocked_level < levels.size():
		var index: int = max_unlocked_level - 1
		if index < 0 or index >= star_ratings.size() or int(star_ratings[index]) <= 0:
			return
		max_unlocked_level = min(levels.size(), max_unlocked_level + 1)

func stars_by_level_id() -> Dictionary:
	var result := {}
	for i in range(levels.size()):
		var data: Dictionary = levels[i] as Dictionary
		result[str(data.get("id", "level_%03d" % (i + 1)))] = int(star_ratings[i])
	return result

func tutorial_completed_by_id() -> Dictionary:
	var tutorials: Array = LevelData.get_tutorial_levels()
	var result := {}
	for i in range(tutorials.size()):
		var data: Dictionary = tutorials[i] as Dictionary
		result[str(data.get("id", "tutorial_%03d" % (i + 1)))] = bool(tutorial_completed[i])
	return result

func load_stars_from_ids(raw) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var by_id: Dictionary = raw as Dictionary
	for i in range(levels.size()):
		var data: Dictionary = levels[i] as Dictionary
		var id := str(data.get("id", ""))
		if by_id.has(id):
			star_ratings[i] = int(clamp(int(by_id[id]), 0, 3))

func load_tutorials_from_ids(raw) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var by_id: Dictionary = raw as Dictionary
	var tutorials: Array = LevelData.get_tutorial_levels()
	for i in range(tutorial_completed.size()):
		var data: Dictionary = tutorials[i] as Dictionary
		var id := str(data.get("id", ""))
		if by_id.has(id):
			tutorial_completed[i] = bool(by_id[id])

func current_level_id() -> String:
	var data: Dictionary = levels[current_level - 1] as Dictionary
	return str(data.get("id", ""))

func level_number_for_id(level_id: String) -> int:
	if level_id.is_empty():
		return -1
	for i in range(levels.size()):
		var data: Dictionary = levels[i] as Dictionary
		if str(data.get("id", "")) == level_id:
			return i + 1
	return -1
