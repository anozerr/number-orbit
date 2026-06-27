class_name GameState
extends RefCounted

var levels: Array = []
var current_level: int = 1
var current_number: int = 1
var target_number: int = 10
var moves_used: int = 0
var max_unlocked_level: int = 3
var star_ratings: Array = []
var bulb_rewards_claimed: Array = []
var tutorial_completed: Array = []
var has_played: bool = false
var is_level_failed: bool = false
var hint_points: int = 0
var cached_hint_move_index: int = -1
var cached_hint_text: String = ""

const HINT_COST := 80

func setup(level_data: Array) -> void:
	levels = level_data
	max_unlocked_level = min(3, levels.size())
	star_ratings.resize(levels.size())
	bulb_rewards_claimed.resize(levels.size())
	for i in range(levels.size()):
		star_ratings[i] = 0
		bulb_rewards_claimed[i] = false
	tutorial_completed.resize(LevelData.get_tutorial_levels().size())
	for i in range(tutorial_completed.size()):
		tutorial_completed[i] = false
	load_level(1)

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
		var group_start: int = max_unlocked_level - int(posmod(max_unlocked_level - 1, 3))
		var group_end: int = min(group_start + 2, levels.size())
		if not is_level_group_completed(group_start, group_end):
			return
		max_unlocked_level = min(levels.size(), group_end + 3)

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
