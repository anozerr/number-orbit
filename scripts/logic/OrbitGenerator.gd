class_name OrbitGenerator
extends RefCounted

const ORBIT_COUNT = 6
const POSSIBLE_NUMBERS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15]
const POSSIBLE_OPS = ["divide", "multiply", "add", "subtract"]

static func initial_items(data: Dictionary, current_number: int) -> Array:
	return items_for_move(data, current_number, 0)

static func items_for_move(data: Dictionary, current_number: int, move_index: int) -> Array:
	if data.has("turns"):
		var turns: Array = data["turns"] as Array
		if move_index >= 0 and move_index < turns.size():
			return sanitize_items(data, current_number, (turns[move_index] as Array).duplicate())
	if data.has("sequence"):
		return sanitize_items(data, current_number, (data["sequence"] as Array).duplicate())
	return deterministic_items(data, current_number)

static func generate_items(data: Dictionary, current_number: int) -> Array:
	return deterministic_items(data, current_number)

static func sanitize_items(data: Dictionary, current_number: int, planned_items: Array) -> Array:
	var result: Array = []
	var used: Dictionary = {}
	for raw_item in planned_items:
		var item: Dictionary = raw_item as Dictionary
		var op: String = str(item["op"])
		var value: int = int(item["value"])
		var key: String = "%s_%d" % [op, value]
		if value > 0 and not used.has(key):
			result.append({"value": value, "op": op})
			used[key] = true

	if not result.is_empty():
		return result

	for fallback in deterministic_pool(data, current_number):
		if result.size() >= ORBIT_COUNT:
			break
		var op: String = str(fallback["op"])
		var value: int = int(fallback["value"])
		var key: String = "%s_%d" % [op, value]
		if not used.has(key):
			result.append(fallback)
			used[key] = true

	return result

static func deterministic_items(data: Dictionary, current_number: int) -> Array:
	var result: Array = deterministic_pool(data, current_number)
	while result.size() > ORBIT_COUNT:
		result.pop_back()
	return result

static func deterministic_pool(data: Dictionary, current_number: int) -> Array:
	var allowed_ops: Array = (data["allowed_ops"] as Array).duplicate() if data.has("allowed_ops") else POSSIBLE_OPS.duplicate()
	var pool: Array = []
	for op in allowed_ops:
		for n in POSSIBLE_NUMBERS:
			var operation: String = str(op)
			if OperationLogic.can_apply(current_number, n, operation):
				pool.append({"value": n, "op": operation})
	if pool.is_empty() and not allowed_ops.is_empty():
		pool.append({"value": 2, "op": str(allowed_ops[0])})
	return pool
