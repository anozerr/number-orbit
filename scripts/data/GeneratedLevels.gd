class_name GeneratedLevels
extends RefCounted

# Hand-authored first chapter. Orbit pairs are stored in clockwise display order.
# Row: [global, difficulty, local_index, start, target, shortest, is_meme,
#       orbit, primary_solution, explicit_star_contract]
const RAW := [
	# --- Chapter 1 (1-15): + x4 | - x4 | x x3 | ÷ x3 | boss. L1-14 always_three
	# (max 3 stars, small orbit, all chips single-digit). S3 subtract drills 7,8
	# grey a chip mid-descent; L14 is pure ÷ with a poison chip: tapping ÷8 greys
	# the needed ÷4/÷6 for good (use-it-or-lose-it), so the win must avoid ÷8.
	[1, "Easy", 1, 12, 22, 2, false,
		[[4, "add"], [3, "add"], [6, "add"]],
		[[4, "add"], [6, "add"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[2, "Easy", 2, 20, 35, 2, false,
		[[9, "add"], [6, "add"], [4, "add"], [8, "add"]],
		[[9, "add"], [6, "add"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[3, "Easy", 3, 23, 37, 3, false,
		[[4, "add"], [6, "add"], [2, "add"], [5, "add"], [7, "add"]],
		[[2, "add"], [5, "add"], [7, "add"]],
		{"star_mode": "always_three", "winning_lengths": [3]}],
	[4, "Easy", 4, 37, 52, 3, false,
		[[9, "add"], [3, "add"], [7, "add"], [2, "add"], [4, "add"], [5, "add"]],
		[[2, "add"], [4, "add"], [9, "add"]],
		{"star_mode": "always_three", "winning_lengths": [3]}],
	[5, "Easy", 5, 35, 26, 2, false,
		[[4, "subtract"], [2, "subtract"], [5, "subtract"]],
		[[4, "subtract"], [5, "subtract"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[6, "Easy", 6, 40, 31, 2, false,
		[[7, "subtract"], [2, "subtract"], [8, "subtract"], [5, "subtract"]],
		[[7, "subtract"], [2, "subtract"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[7, "Easy", 7, 18, 2, 3, false,
		[[4, "subtract"], [8, "subtract"], [6, "subtract"], [3, "subtract"], [7, "subtract"]],
		[[7, "subtract"], [6, "subtract"], [3, "subtract"]],
		{"star_mode": "always_three", "winning_lengths": [3]}],
	[8, "Easy", 8, 21, 3, 3, false,
		[[4, "subtract"], [8, "subtract"], [2, "subtract"], [9, "subtract"], [5, "subtract"]],
		[[9, "subtract"], [5, "subtract"], [4, "subtract"]],
		{"star_mode": "always_three", "winning_lengths": [3]}],
	[9, "Easy", 9, 13, 78, 2, false,
		[[2, "multiply"], [5, "multiply"], [3, "multiply"]],
		[[2, "multiply"], [3, "multiply"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[10, "Easy", 10, 4, 80, 2, false,
		[[4, "multiply"], [2, "multiply"], [5, "multiply"], [7, "multiply"], [3, "multiply"]],
		[[4, "multiply"], [5, "multiply"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[11, "Easy", 11, 3, 72, 3, false,
		[[9, "multiply"], [3, "multiply"], [4, "multiply"], [5, "multiply"], [7, "multiply"], [2, "multiply"]],
		[[2, "multiply"], [3, "multiply"], [4, "multiply"]],
		{"star_mode": "always_three", "winning_lengths": [3]}],
	[12, "Easy", 12, 48, 6, 2, false,
		[[2, "divide"], [4, "divide"], [3, "divide"]],
		[[2, "divide"], [4, "divide"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[13, "Easy", 13, 120, 10, 2, false,
		[[2, "divide"], [6, "divide"], [3, "divide"], [4, "divide"], [5, "divide"]],
		[[2, "divide"], [6, "divide"]],
		{"star_mode": "always_three", "winning_lengths": [2]}],
	[14, "Easy", 14, 360, 5, 3, false,
		[[8, "divide"], [6, "divide"], [3, "divide"], [2, "divide"], [5, "divide"], [4, "divide"]],
		[[3, "divide"], [4, "divide"], [6, "divide"]],
		{"star_mode": "always_three", "winning_lengths": [3]}],
	[15, "Easy", 15, 89, 99, 3, true,
		[[4, "add"], [2, "subtract"], [6, "subtract"], [8, "add"], [7, "add"], [3, "subtract"]],
		[[2, "subtract"], [4, "add"], [8, "add"]],
		{"star_mode": "tiered", "T2": 4, "T1": 5}],

	# --- Chapter 2 (16-30): every two-operation pair, in a fixed progression.
	# Every level has real 3/2/1-star routes. Distinct winning lengths above S
	# are split in half: the easier half earns 2 stars, the harder half 1 star.
	# L30 is the "404: x4 not found" boss: build x4 without an x4 chip.
	[16, "Easy", 16, 51, 60, 3, false,
		[[11, "add"], [10, "subtract"], [5, "subtract"], [10, "add"], [8, "add"], [3, "subtract"], [6, "add"]],
		[[11, "add"], [10, "subtract"], [8, "add"]],
		{"star_mode": "tiered", "T2": 4, "T1": 6}],
	[17, "Easy", 17, 10, 4, 3, false,
		[[2, "add"], [3, "subtract"], [11, "subtract"], [10, "add"], [7, "add"], [4, "subtract"], [5, "subtract"]],
		[[10, "add"], [11, "subtract"], [5, "subtract"]],
		{"star_mode": "tiered", "T2": 4, "T1": 6}],
	[18, "Easy", 18, 2, 74, 3, false,
		[[5, "add"], [9, "add"], [8, "add"], [4, "add"], [10, "multiply"], [2, "multiply"]],
		[[5, "add"], [10, "multiply"], [4, "add"]],
		{"star_mode": "tiered", "T2": 4, "T1": 6}],
	[19, "Easy", 19, 14, 231, 3, false,
		[[4, "multiply"], [3, "add"], [5, "add"], [7, "multiply"], [6, "add"], [10, "add"], [2, "multiply"]],
		[[2, "multiply"], [5, "add"], [7, "multiply"]],
		{"star_mode": "tiered", "T2": 4, "T1": 6}],
	[20, "Easy", 20, 20, 41, 3, false,
		[[8, "subtract"], [4, "subtract"], [2, "multiply"], [3, "multiply"], [11, "subtract"], [9, "subtract"], [7, "multiply"]],
		[[3, "multiply"], [11, "subtract"], [8, "subtract"]],
		{"star_mode": "tiered", "T2": 4, "T1": 6}],
	[21, "Easy", 21, 16, 200, 3, false,
		[[6, "subtract"], [5, "multiply"], [3, "multiply"], [7, "subtract"], [4, "multiply"], [2, "multiply"], [11, "subtract"]],
		[[6, "subtract"], [5, "multiply"], [4, "multiply"]],
		{"star_mode": "tiered", "T2": 5, "T1": 7}],
	[22, "Easy", 22, 81, 16, 3, false,
		[[2, "divide"], [5, "add"], [11, "add"], [6, "divide"], [8, "divide"], [3, "add"], [4, "add"]],
		[[4, "add"], [11, "add"], [6, "divide"]],
		{"star_mode": "tiered", "T2": 4, "T1": 6}],
	[23, "Easy", 23, 62, 13, 3, false,
		[[4, "add"], [2, "add"], [11, "divide"], [10, "add"], [12, "add"], [6, "divide"], [3, "divide"], [9, "add"]],
		[[4, "add"], [6, "divide"], [2, "add"]],
		{"star_mode": "tiered", "T2": 5, "T1": 7}],
	[24, "Easy", 24, 184, 17, 3, false,
		[[11, "subtract"], [7, "subtract"], [4, "divide"], [10, "divide"], [3, "subtract"], [9, "subtract"], [2, "divide"]],
		[[11, "subtract"], [3, "subtract"], [10, "divide"]],
		{"star_mode": "tiered", "T2": 4, "T1": 6}],
	[25, "Easy", 25, 256, 14, 3, false,
		[[8, "divide"], [16, "divide"], [9, "subtract"], [7, "subtract"], [4, "divide"], [2, "divide"], [11, "subtract"], [6, "subtract"]],
		[[8, "divide"], [11, "subtract"], [7, "subtract"]],
		{"star_mode": "tiered", "T2": 4, "T1": 6}],
	[26, "Easy", 26, 357, 7, 3, false,
		[[7, "divide"], [7, "subtract"], [8, "subtract"], [12, "subtract"], [9, "subtract"], [6, "divide"], [14, "divide"], [5, "subtract"]],
		[[7, "divide"], [9, "subtract"], [6, "divide"]],
		{"star_mode": "tiered", "T2": 4, "T1": 6}],
	[27, "Easy", 27, 6, 63, 3, false,
		[[4, "divide"], [7, "multiply"], [2, "multiply"], [2, "divide"], [6, "multiply"], [12, "multiply"], [6, "divide"]],
		[[6, "multiply"], [4, "divide"], [7, "multiply"]],
		{"star_mode": "tiered", "T2": 4, "T1": 6}],
	[28, "Easy", 28, 68, 255, 3, false,
		[[10, "multiply"], [12, "multiply"], [2, "divide"], [6, "divide"], [2, "multiply"], [3, "multiply"], [8, "divide"], [4, "divide"]],
		[[10, "multiply"], [3, "multiply"], [8, "divide"]],
		{"star_mode": "tiered", "T2": 5, "T1": 7}],
	[29, "Easy", 29, 168, 336, 3, false,
		[[9, "multiply"], [4, "multiply"], [9, "divide"], [7, "divide"], [3, "multiply"], [7, "multiply"], [3, "divide"], [6, "divide"]],
		[[3, "multiply"], [4, "multiply"], [6, "divide"]],
		{"star_mode": "tiered", "T2": 5, "T1": 7}],
	[30, "Easy", 30, 101, 404, 3, true,
		[[2, "multiply"], [7, "multiply"], [4, "divide"], [3, "divide"], [6, "multiply"], [8, "multiply"], [6, "divide"], [12, "divide"]],
		[[2, "multiply"], [6, "multiply"], [3, "divide"]],
		{"star_mode": "tiered", "T2": 4, "T1": 5}],
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
