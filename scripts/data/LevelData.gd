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
		var data: Dictionary = (levels[i] as Dictionary).duplicate(true)
		data["global_index"] = i + 1
		data["id"] = level_id(str(data.get("difficulty", "level")), int(data.get("local_index", i + 1)))
		levels[i] = data
	return levels

static func easy_levels() -> Array:
	return levels_from_specs("Easy", [
		spec(10, [2, 2, 2], items([4, "add"], [5, "add"]), items([8, "add"])),
		spec(31, [2, 2, 2], items([6, "subtract"], [5, "subtract"]), items([4, "subtract"])),
		spec(5, [3, 3, 3], items([3, "add"], [4, "add"], [6, "add"]), items([2, "add"])),
		spec(3, [2, 2, 2], items([4, "multiply"], [2, "multiply"]), items([5, "multiply"])),
		spec(40, [3, 3, 3], items([8, "subtract"], [6, "subtract"], [5, "subtract"]), items([2, "subtract"], [3, "subtract"])),
		spec(72, [2, 2, 2], items([3, "divide"], [4, "divide"]), items([6, "divide"])),
		spec(2, [3, 3, 3], items([3, "multiply"], [4, "multiply"], [2, "multiply"]), items([5, "multiply"])),
		spec(240, [3, 3, 3], items([5, "divide"], [4, "divide"], [3, "divide"]), items([2, "divide"], [8, "divide"])),
		spec(8, [3, 3, 3], items([6, "add"], [3, "add"], [4, "subtract"]), items([8, "add"], [10, "add"], [7, "subtract"])),
		spec(20, [4, 4, 4], items([7, "add"], [5, "subtract"], [8, "add"], [4, "subtract"]), items([5, "add"], [3, "subtract"])),
		spec(14, [3, 3, 3], items([4, "subtract"], [3, "multiply"], [5, "subtract"]), items([6, "subtract"], [2, "multiply"])),
		spec(10, [3, 3, 3], items([2, "add"], [2, "divide"], [5, "add"]), items([3, "add"], [4, "add"], [3, "divide"])),
		spec(2, [3, 3, 3], items([2, "multiply"], [2, "add"], [4, "add"]), items([5, "add"], [6, "multiply"], [7, "multiply"])),
		spec(36, [3, 3, 3], items([8, "subtract"], [4, "divide"], [5, "subtract"]), items([6, "subtract"], [6, "divide"])),
		spec(30, [3, 3, 3], items([3, "multiply"], [5, "divide"], [2, "divide"]), items([2, "multiply"], [3, "divide"]))
	])

static func medium_levels() -> Array:
	return generated_progression_levels("Medium", 16)

static func hard_levels() -> Array:
	return generated_progression_levels("Hard", 31)

static func get_tutorial_levels() -> Array:
	var steps: Array = [
		tutorial_step(
			"tutorial_add", "TUTORIAL: ADD", 1, [2, 3, 4], ["add"],
			items([4, "add"], [5, "add"]), items([2, "add"]),
			"Tap green orbit numbers. They add to the center number.",
			"Nice. Keep adding until the center reaches the target.",
			[
				{"area": "center", "text": "This purple circle is your center number. Every orbit tap changes it."},
				{"area": "target", "text": "TARGET is the exact number you need to reach."},
				{"area": "orbit_buttons", "text": "These green orbit circles are available moves. Tap one to use it, then it disappears."},
				{"area": "op_add", "text": "Green means Add. Add increases the center number."}
			],
			"Excellent. Now let’s talk about taking numbers away."
		),
		tutorial_step(
			"tutorial_subtract", "TUTORIAL: SUBTRACT", 9, [2, 3, 4], ["subtract"],
			items([2, "subtract"], [4, "subtract"]), items([8, "subtract"]),
			"Orange orbit numbers subtract from the center.",
			"Some orange numbers can turn grey if they would push the center below 1.",
			[
				{"area": "op_subtract", "text": "Orange means Subtract. It moves the center number downward."},
				{"area": "orbit_buttons", "text": "Choose the orange numbers in the right order. After one move, a too-large subtract can become grey."}
			],
			"Good. But sometimes the fastest path is to make the number bigger first.",
			{
				1: {"steps": [
					{"area": "invalid_orbit", "text": "Grey circles are unavailable now: they would push the center below 1."},
					{"area": "op_unavailable", "text": "Grey always means: this move cannot be used in the current situation."}
				]}
			}
		),
		tutorial_step(
			"tutorial_multiply", "TUTORIAL: MULTIPLY", 2, [2, 3, 4], ["multiply"],
			items([3, "multiply"], [4, "multiply"]), items([5, "multiply"]),
			"Red orbit numbers multiply. They make the center grow fast.",
			"Multiply can be powerful, but the order still matters.",
			[
				{"area": "op_multiply", "text": "Red means Multiply. It can make a small number much bigger."},
				{"area": "orbit_buttons", "text": "Use multiplication carefully: one wrong tap can overshoot the target."}
			],
			"Great. Next: division only works when it divides evenly."
		),
		tutorial_step(
			"tutorial_divide", "TUTORIAL: DIVIDE", 48, [2, 3, 4], ["divide"],
			items([3, "divide"], [4, "divide"]), items([6, "divide"], [8, "divide"]),
			"Blue orbit numbers divide, but only when the result is exact.",
			"Grey division numbers cannot be used because they do not divide evenly right now.",
			[
				{"area": "op_divide", "text": "Blue means Divide. It makes the center smaller only when division is exact."},
				{"area": "orbit_buttons", "text": "Blue numbers are available only while they divide the center exactly."}
			],
			"Perfect. One last idea: the right numbers can still fail in the wrong order.",
			{
				1: {"steps": [
					{"area": "invalid_orbit", "text": "This grey division number is blocked now because it does not divide evenly."}
				]}
			}
		),
		tutorial_step(
			"tutorial_order", "TUTORIAL: ORDER", 8, [2, 3, 4], ALL_OPS,
			items([3, "multiply"], [6, "subtract"]), items([5, "add"], [2, "divide"]),
			"Order matters. The same operators can lead to very different results.",
			"Watch the center number and choose the next move with intention.",
			[
				{"area": "orbit_buttons", "text": "Now all four colors can appear together. The puzzle is not just what to tap, but when."}
			],
			"You’re ready. Levels are now unlocked."
		)
	]
	for i in range(steps.size()):
		var data: Dictionary = steps[i] as Dictionary
		data["tutorial_index"] = i
		data["local_index"] = i + 1
		steps[i] = data
	return steps

static func tutorial_step(id: String, title: String, start: int, thresholds: Array, allowed_ops: Array, solution: Array, distractors: Array, help_start: String, help_after: String, coach_steps: Array, complete_teaser: String, coach_after_moves: Dictionary = {}) -> Dictionary:
	var target: int = apply_item_sequence(start, solution)
	var all_items: Array = interleave_items(solution, distractors)
	var data: Dictionary = level(start, start, target, thresholds, allowed_ops, [all_items])
	data["id"] = id
	data["title"] = title
	data["help_start"] = help_start
	data["help_after"] = help_after
	data["coach"] = {"steps": coach_steps}
	data["coach_after_moves"] = coach_after_moves
	data["complete_teaser"] = complete_teaser
	data["sequence"] = solution
	return data

static func levels_from_specs(difficulty: String, specs: Array) -> Array:
	var result: Array = []
	for i in range(specs.size()):
		var data: Dictionary = spec_to_level(specs[i] as Dictionary, difficulty, i + 1)
		result.append(data)
	return result

static func generated_progression_levels(difficulty: String, first_global_level: int) -> Array:
	var result: Array = []
	for offset in range(15):
		var global_level := first_global_level + offset
		var local_index := offset + 1
		var solution_length := progression_solution_length(global_level)
		var item_count := progression_item_count(global_level)
		result.append(generated_progression_level(difficulty, local_index, global_level, solution_length, item_count))
	return result

static func progression_solution_length(global_level: int) -> int:
	if global_level <= 20:
		return 4
	if global_level <= 25:
		return 5
	if global_level <= 30:
		return 6
	if global_level <= 35:
		return 7
	if global_level <= 40:
		return 8
	return 9

static func progression_item_count(global_level: int) -> int:
	if global_level <= 20:
		return 7
	if global_level <= 25:
		return 8
	if global_level <= 30:
		return 9
	if global_level <= 35:
		return 10
	if global_level <= 40:
		return 11
	return 12

static func generated_progression_level(difficulty: String, local_index: int, global_level: int, solution_length: int, item_count: int) -> Dictionary:
	var template := progression_template(global_level)
	var start := int(template["start"])
	var solution: Array = template["solution"] as Array
	var target := apply_item_sequence(start, solution)
	var all_items: Array = template["items"] as Array
	var thresholds := [solution_length, solution_length + 1, solution_length + 2]
	var data := level(start, start, target, thresholds, ops_from_items(all_items), [all_items])
	data["difficulty"] = difficulty
	data["local_index"] = local_index
	data["solution_length"] = solution_length
	data["sequence"] = solution
	data["star_bands"] = [
		{"stars": 3, "moves": thresholds[0]},
		{"stars": 2, "moves": thresholds[1]},
		{"stars": 1, "moves": thresholds[2]}
	]
	return data

static func progression_template(global_level: int) -> Dictionary:
	var raw_templates := {
		16: {"start": 16, "items": [[8, "add"], [40, "add"], [2, "divide"], [8, "divide"], [8, "multiply"], [4, "subtract"], [5, "multiply"]], "solution": [[8, "multiply"], [2, "divide"], [8, "add"], [40, "add"]]},
		17: {"start": 76, "items": [[32, "subtract"], [17, "add"], [2, "divide"], [5, "subtract"], [7, "multiply"], [44, "add"], [13, "add"]], "solution": [[13, "add"], [17, "add"], [44, "add"], [5, "subtract"]]},
		18: {"start": 181, "items": [[41, "subtract"], [4, "add"], [9, "subtract"], [12, "divide"], [5, "subtract"], [9, "multiply"], [16, "add"]], "solution": [[41, "subtract"], [16, "add"], [9, "subtract"], [5, "subtract"]]},
		19: {"start": 214, "items": [[2, "divide"], [29, "subtract"], [20, "add"], [4, "multiply"], [30, "subtract"], [35, "add"], [50, "subtract"]], "solution": [[29, "subtract"], [20, "add"], [35, "add"], [30, "subtract"]]},
		20: {"start": 196, "items": [[30, "add"], [15, "subtract"], [43, "add"], [2, "multiply"], [4, "divide"], [20, "subtract"], [3, "multiply"]], "solution": [[20, "subtract"], [43, "add"], [15, "subtract"], [30, "add"]]},
		21: {"start": 40, "items": [[7, "add"], [16, "add"], [9, "multiply"], [3, "divide"], [10, "divide"], [22, "add"], [16, "subtract"], [14, "subtract"]], "solution": [[16, "add"], [7, "add"], [3, "divide"], [9, "multiply"], [22, "add"]]},
		22: {"start": 23, "items": [[8, "multiply"], [19, "multiply"], [2, "subtract"], [26, "add"], [23, "divide"], [17, "subtract"], [16, "subtract"], [22, "add"]], "solution": [[22, "add"], [8, "multiply"], [17, "subtract"], [2, "subtract"], [16, "subtract"]]},
		23: {"start": 15, "items": [[34, "add"], [3, "divide"], [8, "multiply"], [2, "subtract"], [15, "divide"], [6, "multiply"], [5, "multiply"], [32, "add"]], "solution": [[3, "divide"], [34, "add"], [2, "subtract"], [32, "add"], [6, "multiply"]]},
		24: {"start": 182, "items": [[12, "add"], [16, "add"], [33, "add"], [3, "multiply"], [2, "divide"], [17, "subtract"], [31, "subtract"], [2, "multiply"]], "solution": [[31, "subtract"], [2, "multiply"], [16, "add"], [12, "add"], [17, "subtract"]]},
		25: {"start": 142, "items": [[12, "divide"], [3, "divide"], [3, "multiply"], [24, "subtract"], [6, "add"], [24, "add"], [5, "multiply"], [2, "divide"]], "solution": [[5, "multiply"], [3, "multiply"], [6, "add"], [2, "divide"], [3, "divide"]]},
		26: {"start": 27, "items": [[19, "add"], [2, "add"], [3, "multiply"], [16, "subtract"], [3, "divide"], [5, "add"], [3, "subtract"], [11, "subtract"], [6, "multiply"]], "solution": [[5, "add"], [6, "multiply"], [3, "divide"], [19, "add"], [3, "multiply"], [11, "subtract"]]},
		27: {"start": 80, "items": [[6, "multiply"], [17, "add"], [44, "subtract"], [2, "divide"], [5, "multiply"], [29, "subtract"], [4, "divide"], [22, "add"], [2, "multiply"]], "solution": [[29, "subtract"], [44, "subtract"], [6, "multiply"], [5, "multiply"], [2, "multiply"], [22, "add"]]},
		28: {"start": 87, "items": [[3, "divide"], [11, "subtract"], [20, "subtract"], [5, "multiply"], [42, "add"], [6, "multiply"], [29, "divide"], [38, "add"], [45, "subtract"]], "solution": [[5, "multiply"], [45, "subtract"], [11, "subtract"], [20, "subtract"], [38, "add"], [42, "add"]]},
		29: {"start": 100, "items": [[4, "divide"], [35, "subtract"], [20, "add"], [5, "multiply"], [5, "divide"], [7, "multiply"], [24, "subtract"], [26, "add"], [44, "add"]], "solution": [[5, "divide"], [20, "add"], [44, "add"], [5, "multiply"], [26, "add"], [35, "subtract"]]},
		30: {"start": 29, "items": [[56, "multiply"], [61, "divide"], [31, "add"], [4, "multiply"], [35, "add"], [3, "multiply"], [18, "add"], [38, "subtract"], [38, "add"]], "solution": [[4, "multiply"], [3, "multiply"], [18, "add"], [31, "add"], [38, "add"], [35, "add"]]},
		31: {"start": 346, "items": [[9, "multiply"], [35, "add"], [40, "subtract"], [2, "divide"], [8, "add"], [34, "subtract"], [12, "divide"], [33, "subtract"], [12, "add"], [6, "multiply"]], "solution": [[40, "subtract"], [34, "subtract"], [6, "multiply"], [8, "add"], [2, "divide"], [9, "multiply"], [12, "divide"]]},
		32: {"start": 346, "items": [[3, "divide"], [9, "multiply"], [33, "subtract"], [7, "multiply"], [53, "divide"], [3, "subtract"], [5, "multiply"], [39, "subtract"], [30, "subtract"], [41, "add"]], "solution": [[30, "subtract"], [39, "subtract"], [41, "add"], [7, "multiply"], [3, "divide"], [33, "subtract"], [3, "subtract"]]},
		33: {"start": 77, "items": [[9, "multiply"], [21, "add"], [5, "multiply"], [27, "subtract"], [32, "subtract"], [9, "divide"], [45, "subtract"], [7, "divide"], [15, "add"], [18, "subtract"]], "solution": [[15, "add"], [9, "multiply"], [32, "subtract"], [18, "subtract"], [45, "subtract"], [27, "subtract"], [21, "add"]]},
		34: {"start": 352, "items": [[11, "divide"], [31, "subtract"], [9, "multiply"], [17, "add"], [8, "divide"], [21, "add"], [4, "subtract"], [36, "add"], [5, "multiply"], [43, "add"]], "solution": [[31, "subtract"], [17, "add"], [36, "add"], [11, "divide"], [43, "add"], [21, "add"], [9, "multiply"]]},
		35: {"start": 242, "items": [[2, "divide"], [29, "subtract"], [27, "add"], [3, "multiply"], [9, "add"], [22, "subtract"], [6, "multiply"], [5, "multiply"], [12, "divide"], [31, "subtract"]], "solution": [[6, "multiply"], [5, "multiply"], [31, "subtract"], [27, "add"], [3, "multiply"], [12, "divide"], [2, "divide"]]},
		36: {"start": 287, "items": [[6, "multiply"], [7, "multiply"], [38, "add"], [36, "add"], [8, "multiply"], [29, "subtract"], [44, "subtract"], [35, "add"], [9, "divide"], [37, "add"], [27, "add"]], "solution": [[38, "add"], [35, "add"], [9, "divide"], [27, "add"], [37, "add"], [36, "add"], [7, "multiply"], [44, "subtract"]]},
		37: {"start": 151, "items": [[7, "multiply"], [6, "subtract"], [32, "add"], [13, "divide"], [2, "multiply"], [10, "divide"], [9, "add"], [4, "divide"], [29, "add"], [4, "subtract"], [25, "add"]], "solution": [[9, "add"], [4, "divide"], [25, "add"], [7, "multiply"], [2, "multiply"], [32, "add"], [29, "add"], [4, "subtract"]]},
		38: {"start": 231, "items": [[12, "subtract"], [3, "subtract"], [8, "divide"], [19, "add"], [2, "add"], [8, "multiply"], [10, "add"], [13, "subtract"], [34, "subtract"], [3, "multiply"], [45, "subtract"]], "solution": [[45, "subtract"], [34, "subtract"], [8, "divide"], [19, "add"], [8, "multiply"], [2, "add"], [3, "multiply"], [12, "subtract"]]},
		39: {"start": 211, "items": [[3, "multiply"], [7, "divide"], [20, "subtract"], [40, "add"], [12, "add"], [9, "subtract"], [16, "add"], [2, "add"], [9, "multiply"], [19, "divide"], [15, "add"]], "solution": [[40, "add"], [15, "add"], [7, "divide"], [9, "multiply"], [3, "multiply"], [9, "subtract"], [20, "subtract"], [12, "add"]]},
		40: {"start": 239, "items": [[3, "multiply"], [7, "divide"], [20, "subtract"], [40, "add"], [12, "add"], [9, "subtract"], [16, "add"], [2, "add"], [9, "multiply"], [17, "divide"], [15, "add"]], "solution": [[40, "add"], [15, "add"], [7, "divide"], [9, "multiply"], [3, "multiply"], [9, "subtract"], [20, "subtract"], [12, "add"]]},
		41: {"start": 338, "items": [[36, "subtract"], [45, "add"], [28, "add"], [8, "divide"], [37, "subtract"], [2, "multiply"], [15, "add"], [25, "subtract"], [5, "multiply"], [2, "add"], [2, "subtract"], [10, "divide"]], "solution": [[25, "subtract"], [15, "add"], [8, "divide"], [28, "add"], [45, "add"], [2, "multiply"], [5, "multiply"], [37, "subtract"], [36, "subtract"]]},
		42: {"start": 48, "items": [[5, "multiply"], [23, "add"], [15, "subtract"], [8, "divide"], [8, "add"], [36, "add"], [27, "add"], [42, "add"], [11, "add"], [13, "add"], [33, "add"], [25, "subtract"]], "solution": [[36, "add"], [13, "add"], [33, "add"], [42, "add"], [11, "add"], [23, "add"], [5, "multiply"], [27, "add"], [8, "add"]]},
		43: {"start": 117, "items": [[18, "subtract"], [13, "add"], [27, "subtract"], [21, "subtract"], [27, "add"], [4, "multiply"], [4, "divide"], [25, "subtract"], [9, "multiply"], [16, "add"], [36, "add"], [7, "divide"]], "solution": [[36, "add"], [16, "add"], [4, "multiply"], [27, "add"], [13, "add"], [9, "multiply"], [25, "subtract"], [27, "subtract"], [4, "divide"]]},
		44: {"start": 219, "items": [[10, "divide"], [16, "add"], [39, "add"], [22, "subtract"], [11, "add"], [4, "multiply"], [45, "add"], [21, "add"], [3, "multiply"], [2, "add"], [2, "subtract"], [6, "divide"]], "solution": [[11, "add"], [10, "divide"], [16, "add"], [45, "add"], [21, "add"], [39, "add"], [3, "multiply"], [22, "subtract"], [4, "multiply"]]},
		45: {"start": 380, "items": [[4, "add"], [27, "add"], [22, "subtract"], [26, "subtract"], [2, "subtract"], [7, "multiply"], [19, "subtract"], [8, "divide"], [41, "add"], [30, "add"], [3, "divide"], [32, "add"]], "solution": [[2, "subtract"], [27, "add"], [3, "divide"], [41, "add"], [30, "add"], [7, "multiply"], [4, "add"], [19, "subtract"], [32, "add"]]}
	}
	var raw: Dictionary = raw_templates[global_level] as Dictionary
	return {"start": int(raw["start"]), "items": item_list(raw["items"] as Array), "solution": item_list(raw["solution"] as Array)}

static func spec(start: int, thresholds: Array, solution: Array, distractors: Array) -> Dictionary:
	return {"start": start, "thresholds": thresholds, "solution": solution, "distractors": distractors}

static func spec_to_level(raw: Dictionary, difficulty: String, local_index: int) -> Dictionary:
	var solution: Array = raw["solution"] as Array
	var distractors: Array = raw["distractors"] as Array
	var target: int = apply_item_sequence(int(raw["start"]), solution)
	var all_items: Array = interleave_items(solution, distractors)
	var thresholds: Array = raw["thresholds"] as Array
	var data: Dictionary = level(int(raw["start"]), int(raw["start"]), target, thresholds, ops_from_items(all_items), [all_items])
	data["difficulty"] = difficulty
	data["local_index"] = local_index
	data["solution_length"] = solution.size()
	data["sequence"] = solution
	return data

static func interleave_items(solution: Array, distractors: Array) -> Array:
	if solution.size() <= 1:
		return distractors + solution
	var gaps: int = solution.size() - 1
	var distractor_count: int = distractors.size()
	var result: Array = [solution[0]]
	var used: int = 0
	for g in range(gaps):
		var count: int = int((g + 1) * distractor_count / float(gaps)) - int(g * distractor_count / float(gaps))
		for _i in range(count):
			result.append(distractors[used])
			used += 1
		result.append(solution[g + 1])
	while used < distractor_count:
		result.append(distractors[used])
		used += 1
	return result

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

static func level_id(difficulty: String, local_index: int) -> String:
	return "%s_%03d" % [difficulty.to_lower(), local_index]

static func items(a: Array, b: Array = [], c: Array = [], d: Array = [], e: Array = [], f: Array = [], g: Array = [], h: Array = [], i: Array = [], j: Array = []) -> Array:
	var result: Array = []
	for raw in [a, b, c, d, e, f, g, h, i, j]:
		if not raw.is_empty():
			result.append(item(raw))
	return result

static func item(raw: Array) -> Dictionary:
	return {"value": int(raw[0]), "op": str(raw[1])}

static func item_list(raw_items: Array) -> Array:
	var result: Array = []
	for raw in raw_items:
		result.append(item(raw as Array))
	return result
