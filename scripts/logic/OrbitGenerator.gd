class_name OrbitGenerator
extends RefCounted

const ORBIT_COUNT = 6
const POSSIBLE_NUMBERS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
const POSSIBLE_OPS = ["divide", "multiply", "add", "subtract"]

static func initial_items(data: Dictionary, current_number: int) -> Array:
	if data.has("sequence") and data["sequence"].size() >= ORBIT_COUNT:
		return (data["sequence"] as Array).duplicate()
	return generate_items(data, current_number)

static func generate_items(data: Dictionary, current_number: int) -> Array:
	var items: Array = []
	var used := {}
	for i in range(ORBIT_COUNT):
		var item: Dictionary = random_item(data, current_number, used)
		used["%s_%d" % [item["op"], item["value"]]] = true
		items.append(item)
	return items

static func random_item(data: Dictionary, current_number: int, used: Dictionary) -> Dictionary:
	var allowed_ops: Array = (data["allowed_ops"] as Array).duplicate() if data.has("allowed_ops") else POSSIBLE_OPS.duplicate()
	var available: Array = []
	for op in allowed_ops:
		for n in POSSIBLE_NUMBERS:
			var operation: String = str(op)
			if OperationLogic.can_apply(current_number, n, operation):
				var key: String = "%s_%d" % [operation, n]
				if not used.has(key):
					available.append({"value": n, "op": operation})
	if available.size() == 0:
		for op in allowed_ops:
			for n in POSSIBLE_NUMBERS:
				var operation: String = str(op)
				if OperationLogic.can_apply(current_number, n, operation):
					available.append({"value": n, "op": operation})
	if available.size() == 0:
		return {"value": 2, "op": str(allowed_ops[0]) if allowed_ops.size() > 0 else "add"}
	return available.pick_random() as Dictionary
