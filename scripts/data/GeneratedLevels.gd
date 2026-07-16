class_name GeneratedLevels
extends RefCounted

# Hand-authored first chapter. Orbit pairs are stored in clockwise display order.
# Row: [global, difficulty, local_index, start, target, shortest, is_meme,
#       orbit, primary_solution, explicit_star_contract]
const RAW := [
	[1, "Easy", 1, 12, 22, 2, false,
		[[4, "add"], [3, "add"], [6, "add"]],
		[[4, "add"], [6, "add"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[2, "Easy", 2, 23, 30, 2, false,
		[[2, "add"], [3, "add"], [5, "add"], [4, "add"], [6, "add"]],
		[[2, "add"], [5, "add"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[3, "Easy", 3, 37, 52, 3, false,
		[[2, "add"], [3, "add"], [4, "add"], [5, "add"], [9, "add"], [7, "add"]],
		[[2, "add"], [4, "add"], [9, "add"]],
		{"star_mode": "always_three", "winning_lengths": [3]}],
	[4, "Easy", 4, 35, 26, 2, false,
		[[4, "subtract"], [2, "subtract"], [5, "subtract"]],
		[[4, "subtract"], [5, "subtract"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[5, "Easy", 5, 48, 38, 2, false,
		[[3, "subtract"], [4, "subtract"], [7, "subtract"], [6, "subtract"], [2, "subtract"]],
		[[3, "subtract"], [7, "subtract"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[6, "Easy", 6, 76, 60, 3, false,
		[[2, "subtract"], [4, "subtract"], [6, "subtract"], [5, "subtract"], [8, "subtract"], [7, "subtract"]],
		[[2, "subtract"], [6, "subtract"], [8, "subtract"]],
		{"star_mode": "always_three", "winning_lengths": [3]}],
	[7, "Easy", 7, 13, 78, 2, false,
		[[2, "multiply"], [5, "multiply"], [3, "multiply"]],
		[[2, "multiply"], [3, "multiply"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[8, "Easy", 8, 4, 80, 2, false,
		[[4, "multiply"], [2, "multiply"], [5, "multiply"], [7, "multiply"], [3, "multiply"]],
		[[4, "multiply"], [5, "multiply"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[9, "Easy", 9, 3, 72, 3, false,
		[[2, "multiply"], [5, "multiply"], [3, "multiply"], [7, "multiply"], [4, "multiply"], [9, "multiply"]],
		[[2, "multiply"], [3, "multiply"], [4, "multiply"]],
		{"star_mode": "always_three", "winning_lengths": [3]}],
	[10, "Easy", 10, 90, 100, 3, true,
		[[3, "subtract"], [4, "add"], [5, "add"], [7, "add"], [8, "add"], [6, "subtract"]],
		[[3, "subtract"], [5, "add"], [8, "add"]],
		{"star_mode": "tiered", "T2": 4, "T1": 5}],
	[11, "Easy", 11, 96, 12, 2, false,
		[[2, "divide"], [5, "divide"], [4, "divide"]],
		[[2, "divide"], [4, "divide"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[12, "Easy", 12, 84, 14, 2, false,
		[[2, "divide"], [4, "divide"], [3, "divide"], [7, "divide"], [5, "divide"]],
		[[2, "divide"], [3, "divide"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[13, "Easy", 13, 160, 2, 3, false,
		[[2, "divide"], [3, "divide"], [5, "divide"], [4, "divide"], [8, "divide"], [9, "divide"]],
		[[8, "divide"], [5, "divide"], [2, "divide"]],
		{"star_mode": "always_three", "winning_lengths": [3]}],
]

static func levels() -> Array:
	var out: Array = []
	for entry in RAW:
		out.append(_build(entry as Array))
	for global_index in range(RAW.size() + 1, 101):
		out.append(_placeholder(global_index))
	return out

static func _placeholder(global_index: int) -> Dictionary:
	var difficulty := "Easy"
	var local_index := global_index
	if global_index <= 30:
		difficulty = "Easy"
		local_index = global_index
	elif global_index <= 60:
		difficulty = "Medium"
		local_index = global_index - 30
	elif global_index <= 90:
		difficulty = "Hard"
		local_index = global_index - 60
	elif global_index <= 99:
		difficulty = "Extreme"
		local_index = global_index - 90
	else:
		difficulty = "Impossible"
		local_index = 1
	return {
		"start": 0,
		"original_start": 0,
		"target": 0,
		"allowed_ops": [],
		"turns": [[]],
		"sequence": [],
		"difficulty": difficulty,
		"local_index": local_index,
		"solution_length": 0,
		"star_mode": "always_three",
		"star_bands": [{"stars": 3, "winning_lengths": []}],
		"placeholder": true,
	}

static func _build(entry: Array) -> Dictionary:
	var start: int = int(entry[3])
	var shortest: int = int(entry[5])
	var orbit: Array = _items(entry[7])
	var contract: Dictionary = entry[9] as Dictionary
	var data: Dictionary = {
		"start": start,
		"original_start": start,
		"target": int(entry[4]),
		"allowed_ops": _ops(orbit),
		"turns": [orbit],
		"sequence": _items(entry[8]),
		"difficulty": str(entry[1]),
		"local_index": int(entry[2]),
		"solution_length": shortest,
		"star_mode": str(contract["star_mode"]),
		"star_bands": _star_bands(shortest, contract),
	}
	if bool(entry[6]):
		data["meme"] = true
	return data

static func _star_bands(shortest: int, contract: Dictionary) -> Array:
	if str(contract["star_mode"]) == "always_three":
		return [{
			"stars": 3,
			"winning_lengths": (contract["winning_lengths"] as Array).duplicate(),
		}]
	var t2: int = int(contract["T2"])
	var t1: int = int(contract["T1"])
	return [
		{"stars": 3, "min_moves": shortest, "max_moves": shortest},
		{"stars": 2, "min_moves": shortest + 1, "max_moves": t2},
		{"stars": 1, "min_moves": t2 + 1, "max_moves": t1},
	]

static func _items(pairs: Array) -> Array:
	var result: Array = []
	for pair in pairs:
		result.append({"value": int(pair[0]), "op": str(pair[1])})
	return result

static func _ops(items: Array) -> Array:
	var result: Array = []
	for operation in ["add", "subtract", "multiply", "divide"]:
		for item in items:
			if str(item["op"]) == operation:
				result.append(operation)
				break
	return result
