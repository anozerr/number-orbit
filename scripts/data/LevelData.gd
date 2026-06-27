class_name LevelData
extends RefCounted

const LEVELS_PER_DIFFICULTY := 15
const DIFFICULTIES := ["Easy", "Medium", "Hard"]
const LEVEL_COUNT := LEVELS_PER_DIFFICULTY * 3
const ALL_OPS := ["add", "subtract", "multiply", "divide"]

static func get_levels() -> Array:
	var levels: Array = []
	levels.append_array(easy_levels())
	levels.append_array(medium_levels())
	levels.append_array(hard_levels())
	for i in range(levels.size()):
		var data: Dictionary = (levels[i] as Dictionary).duplicate()
		data["global_index"] = i + 1
		levels[i] = data
	return levels

static func easy_levels() -> Array:
	return [
		level_from_solution(8, [2, 3, 4], "Easy", 1, items([2, "subtract"], [8, "multiply"]), items([12, "multiply"], [12, "subtract"], [7, "divide"], [10, "add"])),
		level_from_solution(24, [2, 3, 4], "Easy", 2, items([12, "subtract"], [4, "multiply"]), items([5, "multiply"], [3, "divide"], [3, "multiply"], [12, "multiply"])),
		level_from_solution(24, [2, 3, 4], "Easy", 3, items([13, "subtract"], [8, "subtract"]), items([12, "multiply"], [2, "divide"], [10, "subtract"], [9, "divide"])),
		level_from_solution(30, [2, 3, 4], "Easy", 4, items([4, "subtract"], [12, "add"]), items([2, "divide"], [8, "subtract"], [11, "add"], [3, "subtract"])),
		level_from_solution(10, [2, 3, 4], "Easy", 5, items([5, "multiply"], [8, "subtract"]), items([6, "multiply"], [7, "add"], [6, "subtract"], [3, "add"])),
		level_from_solution(48, [3, 4, 5], "Easy", 6, items([12, "subtract"], [2, "subtract"], [2, "multiply"]), items([11, "add"], [10, "subtract"], [10, "divide"], [13, "subtract"])),
		level_from_solution(10, [3, 4, 5], "Easy", 7, items([2, "divide"], [3, "multiply"], [11, "add"]), items([12, "add"], [2, "subtract"], [12, "divide"], [6, "divide"])),
		level_from_solution(96, [3, 4, 5], "Easy", 8, items([4, "add"], [3, "multiply"], [9, "subtract"]), items([8, "add"], [5, "multiply"], [8, "divide"], [7, "divide"])),
		level_from_solution(12, [3, 4, 5], "Easy", 9, items([11, "add"], [2, "multiply"], [8, "add"]), items([3, "subtract"], [12, "add"], [10, "add"], [2, "add"])),
		level_from_solution(60, [3, 4, 5], "Easy", 10, items([7, "multiply"], [3, "divide"], [3, "subtract"]), items([11, "add"], [2, "subtract"], [11, "multiply"], [11, "divide"])),
		level_from_solution(12, [4, 5, 6], "Easy", 11, items([3, "multiply"], [11, "add"], [6, "add"], [10, "multiply"]), items([10, "subtract"], [7, "subtract"], [6, "subtract"], [12, "multiply"])),
		level_from_solution(30, [4, 5, 6], "Easy", 12, items([12, "add"], [7, "multiply"], [2, "divide"], [11, "subtract"]), items([5, "divide"], [8, "add"], [4, "subtract"], [13, "add"])),
		level_from_solution(60, [4, 5, 6], "Easy", 13, items([2, "add"], [6, "subtract"], [10, "subtract"], [2, "divide"]), items([13, "divide"], [10, "divide"], [5, "divide"], [7, "multiply"])),
		level_from_solution(8, [4, 5, 6], "Easy", 14, items([4, "subtract"], [5, "multiply"], [12, "multiply"], [12, "add"]), items([11, "multiply"], [7, "subtract"], [12, "divide"], [3, "subtract"])),
		level_from_solution(12, [4, 5, 6], "Easy", 15, items([3, "add"], [2, "subtract"], [8, "add"], [12, "multiply"]), items([9, "subtract"], [7, "add"], [4, "subtract"], [10, "add"]))
	]

static func medium_levels() -> Array:
	return [
		level_from_solution(96, [4, 5, 6], "Medium", 1, items([3, "add"], [12, "multiply"], [8, "add"], [8, "add"]), items([9, "divide"], [6, "add"], [2, "divide"], [2, "multiply"])),
		level_from_solution(180, [4, 5, 6], "Medium", 2, items([2, "add"], [5, "add"], [3, "multiply"], [3, "multiply"]), items([6, "divide"], [12, "subtract"], [12, "add"], [2, "multiply"])),
		level_from_solution(96, [4, 5, 6], "Medium", 3, items([5, "multiply"], [10, "subtract"], [13, "subtract"], [6, "multiply"]), items([3, "subtract"], [12, "subtract"], [11, "subtract"], [3, "divide"])),
		level_from_solution(96, [4, 5, 6], "Medium", 4, items([5, "multiply"], [4, "divide"], [12, "divide"], [6, "add"]), items([4, "add"], [5, "subtract"], [3, "add"], [13, "subtract"])),
		level_from_solution(18, [4, 5, 6], "Medium", 5, items([5, "add"], [12, "add"], [9, "add"], [6, "multiply"]), items([8, "add"], [11, "multiply"], [3, "divide"], [12, "subtract"])),
		level_from_solution(8, [5, 6, 7], "Medium", 6, items([8, "add"], [2, "add"], [3, "subtract"], [4, "multiply"], [9, "subtract"]), items([8, "multiply"], [2, "multiply"], [2, "divide"], [10, "divide"])),
		level_from_solution(15, [5, 6, 7], "Medium", 7, items([3, "multiply"], [3, "multiply"], [3, "add"], [2, "multiply"], [5, "add"]), items([6, "subtract"], [4, "divide"], [4, "subtract"], [6, "add"])),
		level_from_solution(10, [5, 6, 7], "Medium", 8, items([10, "multiply"], [9, "subtract"], [3, "subtract"], [8, "multiply"], [8, "add"]), items([5, "divide"], [4, "multiply"], [5, "add"], [7, "subtract"])),
		level_from_solution(96, [5, 6, 7], "Medium", 9, items([12, "multiply"], [5, "add"], [8, "multiply"], [5, "multiply"], [7, "subtract"]), items([4, "subtract"], [4, "multiply"], [4, "add"], [6, "divide"])),
		level_from_solution(15, [5, 6, 7], "Medium", 10, items([3, "subtract"], [9, "multiply"], [5, "add"], [9, "add"], [4, "multiply"]), items([3, "divide"], [10, "multiply"], [12, "subtract"], [4, "add"])),
		level_from_solution(8, [6, 7, 8], "Medium", 11, items([11, "multiply"], [8, "subtract"], [3, "multiply"], [6, "add"], [5, "multiply"], [11, "multiply"]), items([10, "add"], [12, "subtract"], [12, "add"], [5, "divide"])),
		level_from_solution(12, [6, 7, 8], "Medium", 12, items([13, "multiply"], [12, "multiply"], [8, "divide"], [4, "add"], [10, "multiply"], [9, "subtract"]), items([3, "subtract"], [9, "multiply"], [5, "subtract"], [13, "subtract"])),
		level_from_solution(180, [6, 7, 8], "Medium", 13, items([4, "divide"], [12, "multiply"], [9, "add"], [6, "multiply"], [4, "subtract"], [8, "multiply"]), items([9, "multiply"], [2, "multiply"], [8, "divide"], [4, "multiply"])),
		level_from_solution(96, [6, 7, 8], "Medium", 14, items([6, "add"], [12, "multiply"], [7, "add"], [2, "subtract"], [5, "multiply"], [9, "add"]), items([8, "divide"], [12, "add"], [8, "add"], [9, "multiply"])),
		level_from_solution(30, [6, 7, 8], "Medium", 15, items([11, "subtract"], [5, "multiply"], [5, "subtract"], [2, "multiply"], [13, "multiply"], [8, "subtract"]), items([7, "divide"], [12, "divide"], [9, "subtract"], [12, "multiply"]))
	]

static func hard_levels() -> Array:
	return [
		level_from_solution(72, [6, 7, 8], "Hard", 1, items([11, "multiply"], [13, "subtract"], [4, "add"], [6, "multiply"], [9, "divide"], [7, "multiply"]), items([5, "add"], [2, "multiply"], [5, "divide"], [3, "multiply"])),
		level_from_solution(12, [6, 7, 8], "Hard", 2, items([9, "add"], [13, "multiply"], [8, "multiply"], [12, "multiply"], [4, "add"], [3, "subtract"]), items([5, "subtract"], [3, "add"], [2, "add"], [4, "subtract"])),
		level_from_solution(18, [6, 7, 8], "Hard", 3, items([11, "multiply"], [3, "multiply"], [13, "multiply"], [3, "multiply"], [4, "multiply"], [7, "add"]), items([12, "subtract"], [12, "add"], [13, "divide"], [6, "multiply"])),
		level_from_solution(10, [6, 7, 8], "Hard", 4, items([4, "subtract"], [11, "add"], [3, "multiply"], [9, "multiply"], [2, "add"], [12, "subtract"]), items([5, "divide"], [7, "subtract"], [9, "subtract"], [13, "divide"])),
		level_from_solution(120, [6, 7, 8], "Hard", 5, items([13, "multiply"], [8, "multiply"], [13, "subtract"], [7, "divide"], [10, "subtract"], [10, "subtract"]), items([9, "divide"], [6, "multiply"], [8, "subtract"], [6, "subtract"])),
		level_from_solution(42, [7, 8, 9], "Hard", 6, items([11, "multiply"], [7, "subtract"], [13, "add"], [3, "multiply"], [6, "add"], [10, "multiply"], [2, "add"]), items([7, "multiply"], [2, "multiply"], [2, "divide"])),
		level_from_solution(10, [7, 8, 9], "Hard", 7, items([12, "multiply"], [9, "subtract"], [9, "multiply"], [3, "subtract"], [8, "add"], [3, "subtract"], [13, "multiply"]), items([11, "add"], [5, "divide"], [12, "subtract"])),
		level_from_solution(24, [7, 8, 9], "Hard", 8, items([11, "subtract"], [11, "multiply"], [7, "add"], [3, "add"], [2, "multiply"], [12, "multiply"], [5, "subtract"]), items([8, "multiply"], [11, "divide"], [12, "subtract"])),
		level_from_solution(24, [7, 8, 9], "Hard", 9, items([11, "subtract"], [3, "multiply"], [11, "subtract"], [13, "multiply"], [6, "add"], [11, "subtract"], [12, "multiply"]), items([4, "subtract"], [11, "add"], [2, "subtract"])),
		level_from_solution(48, [7, 8, 9], "Hard", 10, items([4, "multiply"], [6, "subtract"], [10, "multiply"], [3, "multiply"], [7, "subtract"], [6, "multiply"], [5, "subtract"]), items([13, "subtract"], [13, "add"], [5, "divide"])),
		level_from_solution(96, [8, 9, 10], "Hard", 11, items([3, "add"], [11, "subtract"], [12, "subtract"], [6, "multiply"], [3, "multiply"], [12, "add"], [10, "add"], [4, "multiply"]), items([4, "subtract"], [12, "subtract"])),
		level_from_solution(48, [8, 9, 10], "Hard", 12, items([6, "divide"], [2, "add"], [3, "add"], [7, "subtract"], [11, "multiply"], [5, "subtract"], [10, "multiply"], [10, "multiply"]), items([3, "multiply"], [4, "add"])),
		level_from_solution(72, [8, 9, 10], "Hard", 13, items([12, "divide"], [12, "add"], [3, "add"], [10, "multiply"], [5, "subtract"], [6, "multiply"], [7, "add"], [7, "add"]), items([4, "multiply"], [3, "multiply"])),
		level_from_solution(8, [8, 9, 10], "Hard", 14, items([8, "add"], [7, "add"], [11, "multiply"], [4, "subtract"], [9, "multiply"], [7, "subtract"], [13, "add"], [5, "subtract"]), items([10, "subtract"], [5, "multiply"])),
		level_from_solution(36, [8, 9, 10], "Hard", 15, items([12, "divide"], [8, "add"], [8, "multiply"], [7, "add"], [13, "add"], [10, "multiply"], [9, "multiply"], [13, "add"]), items([6, "add"], [10, "add"]))
	]

static func get_tutorial_levels() -> Array:
	return [
		tutorial_level(1, 10, "add", "Easy", [2, 2, 2], [
			items([2, "add"], [5, "add"], [7, "add"])
		]),
		tutorial_level(3, 32, "add", "Medium", [4, 4, 4], [
			items([11, "add"], [4, "add"], [7, "add"], [8, "add"], [6, "add"])
		]),
		tutorial_level(5, 49, "add", "Hard", [6, 6, 6], [
			items([12, "add"], [3, "add"], [8, "add"], [5, "add"], [11, "add"], [6, "add"], [4, "add"])
		]),
		tutorial_level(20, 7, "subtract", "Easy", [2, 2, 2], [
			items([6, "subtract"], [5, "subtract"], [7, "subtract"])
		]),
		tutorial_level(42, 14, "subtract", "Medium", [4, 4, 4], [
			items([10, "subtract"], [4, "subtract"], [7, "subtract"], [8, "subtract"], [6, "subtract"])
		]),
		tutorial_level(80, 24, "subtract", "Hard", [6, 6, 6], [
			items([14, "subtract"], [5, "subtract"], [10, "subtract"], [8, "subtract"], [11, "subtract"], [7, "subtract"], [9, "subtract"])
		]),
		tutorial_level(2, 42, "multiply", "Easy", [2, 2, 2], [
			items([3, "multiply"], [5, "multiply"], [7, "multiply"])
		]),
		tutorial_level(2, 1344, "multiply", "Medium", [4, 4, 4], [
			items([7, "multiply"], [3, "multiply"], [5, "multiply"], [8, "multiply"], [4, "multiply"])
		]),
		tutorial_level(2, 16128, "multiply", "Hard", [6, 6, 6], [
			items([8, "multiply"], [2, "multiply"], [6, "multiply"], [5, "multiply"], [7, "multiply"], [3, "multiply"], [4, "multiply"])
		]),
		tutorial_level(210, 15, "divide", "Easy", [2, 2, 2], [
			items([2, "divide"], [5, "divide"], [7, "divide"])
		]),
		tutorial_level(1260, 6, "divide", "Medium", [4, 4, 4], [
			items([7, "divide"], [2, "divide"], [4, "divide"], [5, "divide"], [3, "divide"])
		]),
		tutorial_level(55440, 6, "divide", "Hard", [6, 6, 6], [
			items([11, "divide"], [2, "divide"], [9, "divide"], [5, "divide"], [7, "divide"], [3, "divide"], [4, "divide"])
		])
	]

static func level(start: int, original_start: int, target: int, thresholds: Array, allowed_ops: Array, turns: Array) -> Dictionary:
	return {
		"start": start,
		"original_start": original_start,
		"target": target,
		"thresholds": thresholds,
		"allowed_ops": allowed_ops,
		"turns": turns,
		"sequence": turns[0]
	}

static func level_from_solution(start: int, thresholds: Array, difficulty: String, local_index: int, solution: Array, distractors: Array) -> Dictionary:
	var target: int = apply_item_sequence(start, solution)
	var all_items: Array = []
	all_items.append_array(solution)
	all_items.append_array(distractors)
	var data: Dictionary = level(start, start, target, thresholds, ops_from_items(all_items), [all_items])
	data["difficulty"] = difficulty
	data["local_index"] = local_index
	data["solution_length"] = solution.size()
	return data

static func ops_from_items(level_items: Array) -> Array:
	var result: Array = []
	for op in ALL_OPS:
		for raw_item in level_items:
			var step: Dictionary = raw_item as Dictionary
			if str(step["op"]) == op:
				result.append(op)
				break
	return result

static func apply_item_sequence(start: int, sequence: Array) -> int:
	var current: int = start
	for raw_item in sequence:
		var step: Dictionary = raw_item as Dictionary
		current = OperationLogic.apply(current, int(step["value"]), str(step["op"]))
	return current

static func difficulty_index_for_level(level_number: int) -> int:
	return int(clamp(int(float(level_number - 1) / float(LEVELS_PER_DIFFICULTY)), 0, DIFFICULTIES.size() - 1))

static func local_level_number(level_number: int) -> int:
	return int(posmod(level_number - 1, LEVELS_PER_DIFFICULTY)) + 1

static func tutorial_level(start: int, target: int, op: String, difficulty: String, thresholds: Array, turns: Array) -> Dictionary:
	var data: Dictionary = level(start, start, target, thresholds, [op], turns)
	data["tutorial_op"] = op
	data["difficulty"] = difficulty
	return data

static func items(a: Array, b: Array = [], c: Array = [], d: Array = [], e: Array = [], f: Array = [], g: Array = [], h: Array = [], i: Array = [], j: Array = []) -> Array:
	var result: Array = []
	for raw in [a, b, c, d, e, f, g, h, i, j]:
		if not raw.is_empty():
			result.append(item(raw))
	return result

static func item(raw: Array) -> Dictionary:
	return {"value": int(raw[0]), "op": str(raw[1])}
