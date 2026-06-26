class_name LevelData
extends RefCounted

const LEVEL_COUNT := 15
const ALL_OPS := ["add", "subtract", "multiply", "divide"]

static func get_levels() -> Array:
	return [
		level(10, 10, 20, [3, 4, 5], ALL_OPS, [
			items([5, "add"], [3, "multiply"], [25, "subtract"], [2, "add"], [2, "subtract"], [3, "add"])
		]),
		level(30, 30, 38, [4, 5, 6], ALL_OPS, [
			items([3, "divide"], [5, "add"], [4, "multiply"], [22, "subtract"], [2, "add"], [3, "subtract"], [4, "add"])
		]),
		level(8, 8, 25, [4, 5, 6], ALL_OPS, [
			items([7, "add"], [3, "multiply"], [5, "divide"], [16, "add"], [2, "add"], [3, "subtract"], [3, "add"])
		]),
		level(64, 64, 54, [5, 6, 7], ALL_OPS, [
			items([4, "divide"], [9, "add"], [5, "multiply"], [17, "subtract"], [2, "divide"], [2, "add"], [3, "subtract"], [3, "add"])
		]),
		level(12, 12, 73, [5, 6, 7], ALL_OPS, [
			items([5, "add"], [4, "multiply"], [8, "subtract"], [3, "multiply"], [2, "divide"], [2, "subtract"], [3, "add"])
		]),
		level(96, 96, 72, [4, 5, 6], ALL_OPS, [
			items([6, "divide"], [11, "add"], [3, "multiply"], [9, "subtract"], [2, "add"], [2, "subtract"], [5, "add"])
		]),
		level(15, 15, 144, [5, 6, 8], ALL_OPS, [
			items([5, "multiply"], [9, "add"], [3, "divide"], [8, "multiply"], [16, "subtract"], [2, "add"], [2, "subtract"], [6, "add"])
		]),
		level(44, 44, 395, [5, 6, 8], ALL_OPS, [
			items([4, "add"], [2, "divide"], [5, "multiply"], [15, "add"], [3, "multiply"], [10, "subtract"], [2, "add"], [2, "subtract"])
		]),
		level(90, 90, 211, [6, 7, 8], ALL_OPS, [
			items([9, "divide"], [7, "add"], [4, "multiply"], [8, "subtract"], [5, "multiply"], [31, "add"], [2, "add"], [2, "subtract"])
		]),
		level(21, 21, 1231, [7, 8, 9], ALL_OPS, [
			items([3, "multiply"], [12, "add"], [5, "multiply"], [25, "subtract"], [2, "divide"], [7, "multiply"], [2, "subtract"], [3, "add"], [6, "add"])
		]),
		level(128, 128, 917, [5, 7, 9], ALL_OPS, [
			items([8, "divide"], [14, "add"], [5, "multiply"], [27, "subtract"], [7, "multiply"], [56, "add"], [5, "add"], [6, "subtract"], [1, "subtract"])
		]),
		level(36, 36, 2343, [6, 7, 9], ALL_OPS, [
			items([4, "multiply"], [6, "add"], [5, "multiply"], [3, "divide"], [11, "add"], [9, "multiply"], [2, "add"], [2, "subtract"], [6, "subtract"])
		]),
		level(210, 210, 2024, [8, 9, 10], ALL_OPS, [
			items([7, "divide"], [11, "add"], [5, "multiply"], [3, "subtract"], [4, "multiply"], [8, "divide"], [17, "multiply"], [307, "add"], [2, "add"], [77, "subtract"])
		]),
		level(250, 250, 13214, [8, 9, 10], ALL_OPS, [
			items([5, "divide"], [7, "add"], [8, "multiply"], [16, "subtract"], [3, "multiply"], [4, "add"], [10, "multiply"], [26, "subtract"], [2, "add"], [2, "subtract"])
		]),
		level(24, 24, 12261, [8, 9, 10], ALL_OPS, [
			items([5, "multiply"], [7, "add"], [3, "multiply"], [30, "subtract"], [27, "divide"], [100, "multiply"], [9, "multiply"], [561, "add"], [2, "add"], [6, "subtract"])
		])
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
