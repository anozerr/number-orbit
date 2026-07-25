class_name LevelData
extends RefCounted

# The map keeps its full 100-level structure. Levels 1–13 are hand-authored;
# levels 31–100 are openable placeholders until their puzzles are designed.
const DIFFICULTIES := ["Easy", "Medium", "Hard", "Extreme", "Impossible"]
const DIFFICULTY_COUNTS := [30, 30, 30, 9, 1]
const LEVEL_COUNT := 100
const PLAYABLE_LEVEL_COUNT := 100
const ALL_OPS := ["add", "subtract", "multiply", "divide"]
const STAR_MODE_ALWAYS_THREE := "always_three"
const STAR_MODE_TIERED := "tiered"
const STAR_MODE_TUTORIAL := "tutorial"
const VALID_STAR_MODES := [
	STAR_MODE_ALWAYS_THREE,
	STAR_MODE_TIERED,
	STAR_MODE_TUTORIAL,
]

static func get_levels() -> Array:
	# The hand-authored chapter plus openable placeholders through level 100.
	return _prepare_levels(GeneratedLevels.levels())

static func _prepare_levels(raw_levels: Array) -> Array:
	var levels: Array = []
	for i in range(raw_levels.size()):
		var data: Dictionary = (raw_levels[i] as Dictionary).duplicate(true)
		if not _has_explicit_star_contract(data):
			push_error("L%d lacks an explicit star_mode/star_bands contract" % (i + 1))
			return []
		data["global_index"] = i + 1
		data["id"] = level_id(
			str(data.get("difficulty", "level")),
			int(data.get("local_index", i + 1)),
		)
		levels.append(data)
	return levels

static func _has_explicit_star_contract(data: Dictionary) -> bool:
	var mode := str(data.get("star_mode", ""))
	return mode in VALID_STAR_MODES and data.get("star_bands", null) is Array

static func get_tutorial_levels() -> Array:
	var steps: Array = [
		tutorial_step(
			"tutorial_add", "TUTORIAL: ADD", 1, ["add"],
			items([4, "add"], [5, "add"]), items([2, "add"]),
			"Tap green numbers — they add up.",
			"Keep adding up to the target.",
			[
				{"area": "center", "key": "coach.add.center", "text": "This purple circle is your center number. Every tap changes it."},
				{"area": "target", "key": "coach.add.target", "text": "Target is the exact number to reach."},
				{"area": "orbit_buttons", "key": "coach.add.orbit", "text": "These green circles are your moves. Tap one to use it, then it disappears."},
				{"area": "op_add", "key": "coach.add.op", "text": "Green means Add — it increases the center number."}
			],
			"Excellent. Now let's talk about taking numbers away."
		),
		tutorial_step(
			"tutorial_subtract", "TUTORIAL: SUBTRACT", 9, ["subtract"],
			items([2, "subtract"], [4, "subtract"]), items([8, "subtract"]),
			"Red numbers subtract from center.",
			"Grey means it would drop below 1.",
			[
				{"area": "op_subtract", "key": "coach.subtract.op", "text": "Red means Subtract — it moves the center down."},
				{"area": "orbit_buttons", "key": "coach.subtract.orbit", "text": "Pick the red numbers in the right order. A too-large subtract can turn grey."}
			],
			"Good. Sometimes it's faster to make the number bigger first.",
			{
				1: {"steps": [
					{"area": "invalid_orbit", "key": "coach.subtract.grey", "text": "Grey circles are unavailable now — they would push the center below 1."}
				]}
			}
		),
		tutorial_step(
			"tutorial_multiply", "TUTORIAL: MULTIPLY", 2, ["multiply"],
			items([3, "multiply"], [4, "multiply"]), items([5, "multiply"]),
			"Blue numbers multiply the center.",
			"Choose the multiplier that reaches the target.",
			[
				{"area": "op_multiply", "key": "coach.multiply.op", "text": "Blue means Multiply — a small number can grow fast."},
				{"area": "orbit_buttons", "key": "coach.multiply.orbit", "text": "Multiply carefully: one wrong tap can overshoot the target."}
			],
			"Great. Next: division only works when it divides evenly."
		),
		tutorial_step(
			"tutorial_divide", "TUTORIAL: DIVIDE", 48, ["divide"],
			items([3, "divide"], [4, "divide"]), items([6, "divide"], [8, "divide"]),
			"Orange divides — only when exact.",
			"Grey won't divide evenly right now.",
			[
				{"area": "op_divide", "key": "coach.divide.op", "text": "Orange means Divide — it works only when the division is exact."},
				{"area": "orbit_buttons", "key": "coach.divide.orbit", "text": "Orange numbers are available only while they divide the center exactly."}
			],
			"Perfect. One last idea: the right numbers can still fail in the wrong order.",
			{
				1: {"steps": [
					{"area": "invalid_orbit", "key": "coach.divide.grey", "text": "This orange number is grey now because it won't divide evenly."}
				]}
			}
		),
		tutorial_step(
			"tutorial_order", "TUTORIAL: ORDER", 6, ALL_OPS,
			items([2, "divide"], [5, "add"], [3, "multiply"], [4, "subtract"]), [],
			"Order matters — plan each move.",
			"Watch the center, choose wisely.",
			[
				{"area": "orbit_buttons", "key": "coach.order.orbit", "text": "Now all four colors can appear together. It's not just what to tap, but when."}
			],
			"You're ready. Levels are now unlocked."
		)
	]
	for i in range(steps.size()):
		var data: Dictionary = steps[i] as Dictionary
		data["tutorial_index"] = i
		data["local_index"] = i + 1
		steps[i] = data
	return steps

static func tutorial_step(id: String, title: String, start: int, allowed_ops: Array, solution: Array, distractors: Array, help_start: String, help_after: String, coach_steps: Array, complete_teaser: String, coach_after_moves: Dictionary = {}) -> Dictionary:
	var target: int = apply_item_sequence(start, solution)
	var all_items: Array = interleave_items(solution, distractors)
	var data: Dictionary = level(start, target, allowed_ops, [all_items])
	data["star_mode"] = STAR_MODE_TUTORIAL
	data["star_bands"] = []
	data["id"] = id
	data["title"] = title
	data["help_start"] = help_start
	data["help_after"] = help_after
	data["coach"] = {"steps": coach_steps}
	data["coach_after_moves"] = coach_after_moves
	data["complete_teaser"] = complete_teaser
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

static func level(start: int, target: int, allowed_ops: Array, turns: Array) -> Dictionary:
	return {
		"start": start,
		"original_start": start,
		"target": target,
		"allowed_ops": allowed_ops,
		"turns": turns,
		"sequence": turns[0]
	}

static func apply_item_sequence(start: int, sequence: Array) -> int:
	var current: int = start
	for raw_item in sequence:
		var step: Dictionary = raw_item as Dictionary
		current = OperationLogic.apply(current, int(step["value"]), str(step["op"]))
	return current

static func difficulty_index_for_level(level_number: int) -> int:
	var cumulative: int = 0
	for i in range(DIFFICULTIES.size()):
		cumulative += int(DIFFICULTY_COUNTS[i])
		if level_number <= cumulative:
			return i
	return DIFFICULTIES.size() - 1

# Count of all levels in the bands before `index` (its first global level - 1).
static func difficulty_start_offset(index: int) -> int:
	var offset: int = 0
	for i in range(int(clamp(index, 0, DIFFICULTIES.size()))):
		offset += int(DIFFICULTY_COUNTS[i])
	return offset

static func difficulty_level_count(index: int) -> int:
	if index >= 0 and index < DIFFICULTY_COUNTS.size():
		return int(DIFFICULTY_COUNTS[index])
	return 0

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
