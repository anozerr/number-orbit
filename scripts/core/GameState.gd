class_name GameState
extends RefCounted

var levels: Array = []
var current_level: int = 1
var current_number: int = 1
var target_number: int = 10
var moves_used: int = 0
var max_unlocked_level: int = 1
var star_ratings: Array = []
var has_played: bool = false

func setup(level_data: Array) -> void:
	levels = level_data
	star_ratings.resize(levels.size())
	for i in range(levels.size()):
		star_ratings[i] = 0
	load_level(1)

func load_level(level_number: int) -> Dictionary:
	current_level = int(clamp(level_number, 1, levels.size()))
	var data: Dictionary = levels[current_level - 1]
	current_number = int(data["start"])
	target_number = int(data["target"])
	moves_used = 0
	return data

func current_level_data() -> Dictionary:
	return levels[current_level - 1]

func unlock_next_level() -> void:
	if current_level < levels.size():
		max_unlocked_level = max(max_unlocked_level, current_level + 1)

func is_level_unlocked(level_number: int) -> bool:
	return level_number <= max_unlocked_level

func set_stars(stars: int) -> void:
	var index: int = current_level - 1
	star_ratings[index] = max(int(star_ratings[index]), stars)
