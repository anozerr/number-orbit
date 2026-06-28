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
		spec(16, [2, 3, 4], items([9, "add"], [4, "add"]), items([14, "add"], [7, "add"])),
		spec(37, [2, 3, 4], items([5, "subtract"], [11, "subtract"]), items([2, "subtract"], [14, "subtract"])),
		spec(39, [2, 3, 4], items([6, "multiply"], [8, "multiply"]), items([4, "multiply"], [5, "multiply"])),
		spec(120, [3, 4, 5], items([2, "divide"], [3, "divide"], [4, "divide"]), items([5, "divide"], [6, "divide"])),
		spec(9, [2, 3, 4], items([2, "add"], [3, "add"]), items([7, "add"], [11, "add"])),
		spec(72, [3, 4, 5], items([6, "subtract"], [12, "subtract"], [4, "subtract"]), items([14, "subtract"], [5, "subtract"])),
		spec(26, [3, 4, 5], items([8, "multiply"], [3, "multiply"], [6, "multiply"]), items([2, "multiply"], [9, "multiply"])),
		spec(48, [3, 4, 5], items([2, "divide"], [4, "divide"], [3, "divide"]), items([16, "divide"])),
		spec(70, [3, 4, 5], items([6, "subtract"], [3, "add"], [13, "add"]), items([12, "subtract"], [11, "add"])),
		spec(45, [3, 4, 5], items([2, "multiply"], [8, "multiply"], [4, "divide"]), items([6, "multiply"], [9, "divide"])),
		spec(72, [4, 5, 6], items([9, "add"], [3, "multiply"], [8, "add"], [4, "multiply"]), items([9, "multiply"], [7, "multiply"])),
		spec(68, [4, 5, 6], items([8, "subtract"], [5, "divide"], [6, "divide"], [2, "divide"]), items([3, "divide"], [12, "subtract"])),
		spec(65, [4, 5, 6], items([5, "divide"], [2, "add"], [3, "divide"], [14, "add"]), items([7, "divide"], [8, "divide"])),
		spec(20, [4, 5, 6], items([4, "multiply"], [3, "subtract"], [10, "subtract"], [8, "multiply"]), items([2, "multiply"], [6, "multiply"])),
		spec(3, [4, 5, 6], items([13, "add"], [12, "subtract"], [5, "add"], [3, "add"]), items([11, "subtract"], [3, "subtract"]))
	])

static func medium_levels() -> Array:
	return levels_from_specs("Medium", [
		spec(31, [3, 4, 5], items([8, "add"], [11, "subtract"], [4, "multiply"]), items([7, "multiply"], [9, "add"])),
		spec(58, [3, 4, 5], items([2, "divide"], [13, "subtract"], [8, "add"]), items([10, "add"], [14, "subtract"])),
		spec(60, [3, 4, 5], items([6, "divide"], [5, "multiply"], [2, "add"]), items([14, "add"], [3, "divide"])),
		spec(50, [3, 4, 5], items([5, "divide"], [8, "subtract"], [9, "multiply"]), items([6, "divide"], [5, "subtract"])),
		spec(52, [3, 4, 5], items([3, "subtract"], [5, "multiply"], [11, "add"]), items([8, "multiply"], [2, "subtract"])),
		spec(43, [4, 5, 6], items([6, "subtract"], [9, "subtract"], [2, "add"], [6, "divide"]), items([11, "subtract"], [7, "add"])),
		spec(66, [4, 5, 6], items([5, "multiply"], [3, "divide"], [3, "add"], [14, "add"]), items([2, "divide"], [7, "divide"])),
		spec(26, [4, 5, 6], items([2, "divide"], [4, "subtract"], [9, "multiply"], [3, "divide"]), items([13, "subtract"], [8, "multiply"])),
		spec(37, [4, 5, 6], items([5, "subtract"], [14, "add"], [11, "add"], [2, "multiply"]), items([9, "multiply"], [3, "add"])),
		spec(63, [4, 5, 6], items([6, "add"], [3, "divide"], [2, "add"], [7, "subtract"]), items([9, "divide"], [10, "subtract"])),
		spec(3, [5, 6, 7], items([14, "add"], [8, "add"], [8, "multiply"], [13, "add"], [3, "divide"]), items([6, "divide"], [2, "multiply"], [6, "multiply"])),
		spec(5, [5, 6, 7], items([5, "divide"], [6, "multiply"], [3, "multiply"], [14, "subtract"], [2, "subtract"]), items([5, "multiply"], [9, "multiply"], [7, "multiply"])),
		spec(20, [5, 6, 7], items([11, "add"], [7, "subtract"], [6, "multiply"], [13, "add"], [9, "multiply"]), items([2, "add"], [11, "subtract"], [3, "multiply"])),
		spec(71, [5, 6, 7], items([13, "add"], [4, "divide"], [2, "subtract"], [12, "add"], [8, "add"]), items([7, "add"], [4, "add"], [3, "subtract"])),
		spec(75, [5, 6, 7], items([7, "multiply"], [3, "multiply"], [5, "divide"], [4, "add"], [7, "add"]), items([9, "multiply"], [9, "divide"], [8, "multiply"]))
	])

static func hard_levels() -> Array:
	return levels_from_specs("Hard", [
		spec(19, [5, 6, 7], items([2, "multiply"], [9, "add"], [2, "subtract"], [4, "add"], [7, "divide"]), items([4, "subtract"], [9, "divide"], [4, "multiply"])),
		spec(42, [5, 6, 7], items([7, "divide"], [11, "add"], [8, "multiply"], [9, "add"], [6, "subtract"]), items([14, "subtract"], [2, "divide"], [3, "subtract"])),
		spec(48, [5, 6, 7], items([6, "subtract"], [6, "divide"], [8, "multiply"], [14, "add"], [9, "add"]), items([2, "add"], [4, "divide"], [9, "subtract"])),
		spec(59, [5, 6, 7], items([3, "multiply"], [6, "multiply"], [5, "subtract"], [7, "divide"], [13, "add"]), items([2, "divide"], [14, "add"], [9, "divide"])),
		spec(78, [6, 7, 8], items([10, "subtract"], [2, "divide"], [7, "subtract"], [7, "multiply"], [3, "add"], [2, "add"]), items([13, "add"], [7, "divide"], [10, "add"])),
		spec(50, [6, 7, 8], items([2, "divide"], [10, "add"], [7, "add"], [4, "multiply"], [8, "add"], [10, "subtract"]), items([7, "multiply"], [2, "multiply"], [3, "divide"])),
		spec(28, [6, 7, 8], items([7, "divide"], [4, "multiply"], [10, "add"], [11, "subtract"], [5, "multiply"], [6, "add"]), items([7, "multiply"], [8, "add"], [14, "add"])),
		spec(40, [6, 7, 8], items([8, "divide"], [4, "add"], [9, "multiply"], [12, "add"], [3, "divide"], [2, "subtract"]), items([2, "multiply"], [7, "divide"], [9, "divide"])),
		spec(52, [7, 8, 9], items([2, "divide"], [8, "multiply"], [12, "add"], [5, "multiply"], [3, "multiply"], [4, "add"], [2, "subtract"]), items([7, "divide"], [5, "divide"], [11, "subtract"])),
		spec(56, [7, 8, 9], items([9, "add"], [4, "multiply"], [6, "multiply"], [9, "subtract"], [3, "divide"], [11, "subtract"], [13, "subtract"]), items([4, "add"], [10, "subtract"], [9, "divide"])),
		spec(75, [7, 8, 9], items([11, "subtract"], [4, "multiply"], [2, "divide"], [8, "subtract"], [6, "multiply"], [10, "add"], [2, "multiply"]), items([3, "divide"], [7, "subtract"], [9, "multiply"])),
		spec(53, [7, 8, 9], items([9, "add"], [6, "multiply"], [12, "subtract"], [5, "subtract"], [5, "divide"], [11, "add"], [5, "add"]), items([9, "multiply"], [2, "divide"], [9, "divide"])),
		spec(24, [8, 9, 10], items([14, "add"], [7, "multiply"], [11, "subtract"], [5, "divide"], [13, "add"], [6, "multiply"], [8, "subtract"], [11, "add"]), items([5, "add"], [6, "divide"])),
		spec(71, [8, 9, 10], items([2, "multiply"], [9, "multiply"], [11, "add"], [7, "add"], [2, "divide"], [8, "divide"], [9, "divide"], [2, "subtract"]), items([8, "multiply"], [4, "divide"])),
		spec(29, [8, 9, 10], items([12, "add"], [2, "multiply"], [9, "subtract"], [9, "multiply"], [5, "subtract"], [2, "divide"], [6, "multiply"], [5, "add"]), items([7, "divide"], [3, "add"]))
	])

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
			"Yellow orbit numbers subtract from the center.",
			"Some yellow numbers can turn grey if they would push the center below 1.",
			[
				{"area": "op_subtract", "text": "Yellow means Subtract. It moves the center number downward."},
				{"area": "orbit_buttons", "text": "Choose the yellow numbers in the right order. After one move, a too-large subtract can become grey."}
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
	data["tutorial_op"] = "mixed"
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

static func spec(start: int, thresholds: Array, solution: Array, distractors: Array) -> Dictionary:
	return {"start": start, "thresholds": thresholds, "solution": solution, "distractors": distractors}

static func spec_to_level(raw: Dictionary, difficulty: String, local_index: int) -> Dictionary:
	var solution: Array = raw["solution"] as Array
	var distractors: Array = raw["distractors"] as Array
	if difficulty != "Easy":
		distractors = add_neutral_detours(solution, distractors, 2)
	var target: int = apply_item_sequence(int(raw["start"]), solution)
	var all_items: Array = safe_level_items(int(raw["start"]), target, solution, distractors)
	var thresholds: Array = raw["thresholds"] as Array
	if difficulty != "Easy":
		thresholds = [solution.size(), solution.size() + 2, solution.size() + 4]
	var data: Dictionary = level(int(raw["start"]), int(raw["start"]), target, thresholds, ops_from_items(all_items), [all_items])
	data["difficulty"] = difficulty
	data["local_index"] = local_index
	data["solution_length"] = solution.size()
	data["sequence"] = solution
	return data

static func add_neutral_detours(solution: Array, distractors: Array, pair_count: int) -> Array:
	var result: Array = distractors.duplicate(true)
	var used: Dictionary = {}
	for raw_group in [solution, distractors]:
		for raw_item in raw_group:
			var step: Dictionary = raw_item as Dictionary
			used["%s_%d" % [str(step["op"]), int(step["value"])]] = true
	var values := [15, 13, 11, 10, 8, 6, 4, 2]
	var added := 0
	for value in values:
		if added >= pair_count:
			break
		var add_key := "add_%d" % value
		var subtract_key := "subtract_%d" % value
		if used.has(add_key) or used.has(subtract_key):
			continue
		result.append({"value": value, "op": "add"})
		result.append({"value": value, "op": "subtract"})
		used[add_key] = true
		used[subtract_key] = true
		added += 1
	return result

static func safe_level_items(start: int, target: int, solution: Array, distractors: Array) -> Array:
	var kept_distractors: Array = []
	for raw_item in distractors:
		var candidate_distractors: Array = kept_distractors.duplicate()
		candidate_distractors.append(raw_item)
		var candidate_items: Array = interleave_items(solution, candidate_distractors)
		if shortest_path_within(start, target, candidate_items, max(0, solution.size() - 1)) == -1:
			kept_distractors.append(raw_item)
	return interleave_items(solution, kept_distractors)

static func shortest_path_within(start: int, target: int, level_items: Array, max_depth: int) -> int:
	if start == target:
		return 0
	for depth in range(1, max_depth + 1):
		if has_path_at_depth(start, target, level_items, depth):
			return depth
	return -1

static func has_path_at_depth(current: int, target: int, remaining: Array, depth: int) -> bool:
	if depth <= 0:
		return current == target
	for i in range(remaining.size()):
		var item: Dictionary = remaining[i] as Dictionary
		var op := str(item["op"])
		var value := int(item["value"])
		if not OperationLogic.can_apply(current, value, op):
			continue
		var next_remaining := remaining.duplicate()
		next_remaining.remove_at(i)
		if has_path_at_depth(OperationLogic.apply(current, value, op), target, next_remaining, depth - 1):
			return true
	return false

static func interleave_items(solution: Array, distractors: Array) -> Array:
	var result: Array = []
	var max_count: int = max(solution.size(), distractors.size())
	for i in range(max_count):
		if i < distractors.size():
			result.append(distractors[i])
		if i < solution.size():
			result.append(solution[i])
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
