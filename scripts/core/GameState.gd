class_name GameState
extends RefCounted

# v4: the first hand-authored chapter replaces the v9 puzzles while reusing
# level ids. Existing level progress is reset once; user preferences survive.
const SAVE_VERSION := 4
const SAVE_PATH := "user://number_orbit_save.json"
const STARTING_LUMENS := 100
const REPLAY_HINT_COST := 10
const FINAL_REWARD := 500
# Hint price per difficulty band; index matches LevelData.DIFFICULTIES.
# Placeholder levels keep the later band prices active on the 100-level map.
const BAND_HINT_COST := [10, 30, 60, 150, 250]
# One rewarded ad always grants a flat lumen top-up and nothing else — hints and
# skips are bought with lumens. See §7.
const AD_REWARD_LUMENS := 50
# Level-skip price per band. Placeholders can be opened through level 100.
const BAND_SKIP_COST := [50, 100, 200, 400, 0]

var levels: Array = []
var current_level: int = 1
var current_number: int = 1
var target_number: int = 10
var moves_used: int = 0
var max_unlocked_level: int = 1
var star_ratings: Array = []
var tutorial_completed: Array = []
var has_played: bool = false
var is_level_failed: bool = false
var lumens: int = 0
var cached_hint_move_index: int = -1
var cached_hint_text: String = ""
var cached_hint_target: Dictionary = {}
var music_volume: int = 80
var sound_volume: int = 80
var haptics_enabled: bool = true
var theme: String = "light"
var language: String = "en"
var full_reset_migration_applied := false

var _save_path: String = SAVE_PATH

func setup(level_data: Array, load_saved: bool = true) -> void:
	levels = level_data
	_reset_all_persistent_defaults()
	if load_saved:
		load_progress()

# Test-only seam for isolated migration fixtures. Production never calls it.
func configure_save_path_for_test(save_path: String) -> bool:
	if not save_path.is_absolute_path() or save_path.begins_with("user://"):
		push_error("GameState test save path must be an isolated absolute path")
		return false
	_save_path = save_path
	return true

func configured_save_path() -> String:
	return _save_path

func _reset_all_persistent_defaults() -> void:
	max_unlocked_level = min(1, levels.size())
	current_level = 1
	current_number = 1
	target_number = 10
	moves_used = 0
	has_played = false
	is_level_failed = false
	lumens = STARTING_LUMENS
	cached_hint_move_index = -1
	cached_hint_text = ""
	cached_hint_target = {}
	music_volume = 80
	sound_volume = 80
	haptics_enabled = true
	theme = "light"
	language = "en"
	star_ratings.resize(levels.size())
	for i in range(levels.size()):
		star_ratings[i] = 0
	tutorial_completed.resize(LevelData.get_tutorial_levels().size())
	for i in range(tutorial_completed.size()):
		tutorial_completed[i] = false
	if not levels.is_empty():
		load_level(1)
	full_reset_migration_applied = false

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

func unlock_level(level_number: int) -> void:
	max_unlocked_level = max(max_unlocked_level, int(clamp(level_number, 1, levels.size())))

func set_stars(stars: int) -> void:
	var index: int = current_level - 1
	star_ratings[index] = max(int(star_ratings[index]), stars)

func set_tutorial_completed(index: int) -> void:
	if index >= 0 and index < tutorial_completed.size():
		tutorial_completed[index] = true

func is_tutorial_completed(index: int) -> bool:
	return index >= 0 and index < tutorial_completed.size() and bool(tutorial_completed[index])

func are_all_tutorials_completed() -> bool:
	for completed in tutorial_completed:
		if not bool(completed):
			return false
	return true

func claim_level_reward(stars: int) -> int:
	var index: int = current_level - 1
	var previous_reward: int = reward_for_stars_at_level(int(star_ratings[index]), current_level)
	var new_reward: int = reward_for_stars_at_level(stars, current_level)
	var delta: int = max(0, new_reward - previous_reward)
	lumens += delta
	return delta

# 3★ reward at level L equals the hint price of L+1 ("3★ = one hint forward").
# 2★ ≈ ⅔ and 1★ ≈ ⅓ of that (snapped to a tidy 10), so neither fully covers the
# next hint. The final bundled level pays a flat trophy on completion.
func reward_for_stars_at_level(stars: int, level_number: int) -> int:
	if stars <= 0:
		return 0
	if level_number >= LevelData.LEVEL_COUNT:
		return FINAL_REWARD
	var three: int = hint_cost_for_level(level_number + 1)
	match stars:
		3:
			return three
		2:
			return int(snapped(three * 2.0 / 3.0, 10.0))
		1:
			return int(snapped(three / 3.0, 10.0))
	return 0

func hint_cost_for_level(level_number: int) -> int:
	var band: int = LevelData.difficulty_index_for_level(level_number)
	if band < 0 or band >= BAND_HINT_COST.size():
		return int(BAND_HINT_COST[BAND_HINT_COST.size() - 1])
	return int(BAND_HINT_COST[band])

# Price of the next hint on the current level. A level already at 3★ charges the
# flat replay price; 1–2★ or unbeaten levels pay full band price, so a cheap
# hint can never sell a 3★ upgrade — see §7.
func current_hint_cost() -> int:
	var index: int = current_level - 1
	if index >= 0 and index < star_ratings.size() and int(star_ratings[index]) == 3:
		return REPLAY_HINT_COST
	return hint_cost_for_level(current_level)

func can_afford_hint() -> bool:
	return lumens >= current_hint_cost()

func spend_hint() -> bool:
	var cost: int = current_hint_cost()
	if lumens < cost:
		return false
	lumens -= cost
	return true

func grant_ad_reward() -> void:
	lumens += AD_REWARD_LUMENS

func skip_cost_for_level(level_number: int) -> int:
	var band: int = LevelData.difficulty_index_for_level(level_number)
	if band < 0 or band >= BAND_SKIP_COST.size():
		return 0
	return int(BAND_SKIP_COST[band])

# A locked level can be opened for lumens only if it is the very next level and
# tutorials are finished. This also applies to placeholder levels through L100.
func can_skip_level(level_number: int) -> bool:
	if not are_all_tutorials_completed():
		return false
	if level_number != max_unlocked_level + 1:
		return false
	if level_number > LevelData.LEVEL_COUNT:
		return false
	return true

func try_skip_level(level_number: int) -> bool:
	if not can_skip_level(level_number):
		return false
	var cost: int = skip_cost_for_level(level_number)
	if lumens < cost:
		return false
	lumens -= cost
	unlock_level(level_number)
	has_played = true
	return true

func has_cached_hint_for_current_move() -> bool:
	return cached_hint_move_index == moves_used and not cached_hint_text.is_empty()

func cache_hint(text: String, target: Dictionary = {}) -> void:
	cached_hint_move_index = moves_used
	cached_hint_text = text
	cached_hint_target = target.duplicate(true)

func clear_cached_hint() -> void:
	cached_hint_move_index = -1
	cached_hint_text = ""
	cached_hint_target = {}

func save_progress() -> void:
	var data := {
		"save_version": SAVE_VERSION,
		"current_level_id": current_level_id(),
		"max_unlocked_level": max_unlocked_level,
		"stars_by_level_id": stars_by_level_id(),
		"tutorial_completed_by_id": tutorial_completed_by_id(),
		"lumens": lumens,
		"has_played": has_played,
		"music_volume": music_volume,
		"sound_volume": sound_volume,
		"haptics_enabled": haptics_enabled,
		"theme": theme,
		"language": language
	}
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()

func load_progress() -> void:
	full_reset_migration_applied = false
	if not FileAccess.file_exists(_save_path):
		return
	var file := FileAccess.open(_save_path, FileAccess.READ)
	if file == null:
		return
	var save_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_error := json.parse(save_text)
	if parse_error != OK:
		_apply_full_reset_migration()
		return
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		_apply_full_reset_migration()
		return
	var data: Dictionary = parsed as Dictionary
	var stored_version := int(data.get("save_version", 1))
	# The older v9 migration remains a full reset. A v3 save already has the
	# current schema, so only its obsolete level progress/economy is reset.
	if stored_version < 3:
		_apply_full_reset_migration()
		return
	if stored_version < SAVE_VERSION:
		_apply_level_content_reset_migration(data)
		return
	load_current_save(data)

func _apply_full_reset_migration() -> void:
	_reset_all_persistent_defaults()
	full_reset_migration_applied = true
	save_progress()

func _apply_level_content_reset_migration(data: Dictionary) -> void:
	_reset_all_persistent_defaults()
	music_volume = int(clamp(int(data.get("music_volume", music_volume)), 0, 100))
	sound_volume = int(clamp(int(data.get("sound_volume", sound_volume)), 0, 100))
	haptics_enabled = bool(data.get("haptics_enabled", haptics_enabled))
	theme = "dark" if str(data.get("theme", theme)) == "dark" else "light"
	language = str(data.get("language", language))
	load_tutorials_from_ids(data.get("tutorial_completed_by_id", {}))
	full_reset_migration_applied = true
	save_progress()

func load_current_save(data: Dictionary) -> void:
	lumens = max(0, int(data.get("lumens", lumens)))
	has_played = bool(data.get("has_played", has_played))
	music_volume = int(clamp(int(data.get("music_volume", music_volume)), 0, 100))
	sound_volume = int(clamp(int(data.get("sound_volume", sound_volume)), 0, 100))
	haptics_enabled = bool(data.get("haptics_enabled", haptics_enabled))
	theme = "dark" if str(data.get("theme", theme)) == "dark" else "light"
	language = str(data.get("language", language))
	load_stars_from_ids(data.get("stars_by_level_id", {}))
	load_tutorials_from_ids(data.get("tutorial_completed_by_id", {}))
	recalculate_max_unlocked_level()
	max_unlocked_level = max(max_unlocked_level, int(clamp(int(data.get("max_unlocked_level", max_unlocked_level)), 1, levels.size())))
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
