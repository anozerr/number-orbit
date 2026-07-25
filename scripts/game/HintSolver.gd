class_name HintSolver
extends RefCounted

const PATH_BITS_PER_CHIP := 4
const PATH_CODE_BITS := 48
const PATH_CODE_MASK := (1 << PATH_CODE_BITS) - 1
const LENGTH_SHIFT := PATH_CODE_BITS
const LENGTH_MASK := 0xF
const STARS_SHIFT := LENGTH_SHIFT + 4
const STARS_MASK := 0x3
const NEXT_MOVE_MARKER := "Next move:"


static func next_hint(
	current_number: int,
	target_number: int,
	moves_used: int,
	orbit_items: Array,
	data: Dictionary,
) -> Dictionary:
	var result := best_hint(
		current_number,
		target_number,
		moves_used,
		orbit_items,
		data,
	)
	if not bool(result.get("can_win", false)):
		result["text"] = Locale.t(
			"hint.none", "No winning move from here. Try Restart."
		)
		return result
	var target: Dictionary = result["target"] as Dictionary
	result["text"] = "%s\n%s %s %d" % [
		moves_left_text(int(result["remaining_moves"])),
		NEXT_MOVE_MARKER,
		OperationLogic.symbol(str(target["op"])),
		int(target["value"]),
	]
	return result


static func best_hint(
	current_number: int,
	target_number: int,
	moves_used: int,
	orbit_items: Array,
	data: Dictionary,
) -> Dictionary:
	if str(data.get("star_mode", "")) == LevelData.STAR_MODE_TUTORIAL:
		return _no_win_result()
	var context := create_solver_context(data, target_number)
	var chips: Array = context["chips"] as Array
	if chips.is_empty() or chips.size() > 12:
		return _no_win_result()
	var used_mask := used_mask_from_remaining(orbit_items, chips)
	if used_mask < 0:
		return _no_win_result()
	var packed := solve_context_packed(
		context, current_number, used_mask, moves_used
	)
	return result_from_packed(packed, chips)


static func create_solver_context(
	data: Dictionary,
	target_override: Variant = null,
) -> Dictionary:
	var chips: Array = []
	var turns: Array = data.get("turns", []) as Array
	if not turns.is_empty():
		for raw_item in turns[0] as Array:
			var item: Dictionary = raw_item as Dictionary
			chips.append({
				"value": int(item.get("value", 0)),
				"op": str(item.get("op", "")),
			})
	var memo: Array = []
	memo.resize(1 << chips.size())
	var target := (
		int(data.get("target", 0))
		if target_override == null
		else int(target_override)
	)
	return {
		"chips": chips,
		"target": target,
		"data": data,
		"memo": memo,
	}


static func solve_context_packed(
	context: Dictionary,
	current_number: int,
	used_mask: int,
	moves_used: int,
) -> int:
	var chips: Array = context["chips"] as Array
	if (
		chips.is_empty()
		or chips.size() > 12
		or used_mask < 0
		or used_mask >= (1 << chips.size())
		or current_number == int(context["target"])
	):
		return 0
	return _solve_context_packed(
		context, current_number, used_mask, moves_used
	)


static func _solve_context_packed(
	context: Dictionary,
	current_number: int,
	used_mask: int,
	moves_used: int,
) -> int:
	var memo: Array = context["memo"] as Array
	var bucket: Dictionary
	if memo[used_mask] is Dictionary:
		bucket = memo[used_mask] as Dictionary
		if bucket.has(current_number):
			return int(bucket[current_number])
	else:
		bucket = {}
		memo[used_mask] = bucket

	var chips: Array = context["chips"] as Array
	var target := int(context["target"])
	var data: Dictionary = context["data"] as Dictionary
	var best := 0
	for chip_index in range(chips.size()):
		var bit := 1 << chip_index
		if used_mask & bit:
			continue
		var chip: Dictionary = chips[chip_index] as Dictionary
		var operation := str(chip["op"])
		var operand := int(chip["value"])
		if not OperationLogic.can_apply(current_number, operand, operation):
			continue
		var next_number := OperationLogic.apply(
			current_number, operand, operation
		)
		var candidate := 0
		if next_number == target:
			var projected_stars := StarCalculator.calculate(moves_used + 1, data)
			if projected_stars > 0:
				candidate = pack_result(
					projected_stars, 1, chip_index + 1
				)
		else:
			var child := _solve_context_packed(
				context,
				next_number,
				used_mask | bit,
				moves_used + 1,
			)
			if child != 0:
				var child_length := packed_length(child)
				var path_code := (
					((chip_index + 1) << (PATH_BITS_PER_CHIP * child_length))
					| packed_path_code(child)
				)
				candidate = pack_result(
					packed_stars(child), child_length + 1, path_code
				)
		if _packed_result_is_better(candidate, best):
			best = candidate
	bucket[current_number] = best
	return best


static func pack_result(stars: int, length: int, path_code: int) -> int:
	if stars <= 0 or length <= 0:
		return 0
	return (
		(path_code & PATH_CODE_MASK)
		| ((length & LENGTH_MASK) << LENGTH_SHIFT)
		| ((stars & STARS_MASK) << STARS_SHIFT)
	)


static func packed_stars(packed: int) -> int:
	return (packed >> STARS_SHIFT) & STARS_MASK


static func packed_length(packed: int) -> int:
	return (packed >> LENGTH_SHIFT) & LENGTH_MASK


static func packed_path_code(packed: int) -> int:
	return packed & PATH_CODE_MASK


static func _packed_result_is_better(candidate: int, current: int) -> bool:
	if candidate == 0:
		return false
	if current == 0:
		return true
	var candidate_stars := packed_stars(candidate)
	var current_stars := packed_stars(current)
	if candidate_stars != current_stars:
		return candidate_stars > current_stars
	var candidate_length := packed_length(candidate)
	var current_length := packed_length(current)
	if candidate_length != current_length:
		return candidate_length < current_length
	# Equal-length four-bit paths compare numerically in chip-ID lexicographic
	# order because their most significant nibble is the first physical chip.
	return packed_path_code(candidate) < packed_path_code(current)


static func result_from_packed(packed: int, chips: Array) -> Dictionary:
	if packed == 0:
		return _no_win_result()
	var length := packed_length(packed)
	var path_code := packed_path_code(packed)
	var path_indices: Array[int] = []
	for position in range(length - 1, -1, -1):
		path_indices.append(
			int((path_code >> (PATH_BITS_PER_CHIP * position)) & 0xF) - 1
		)
	var first_index := int(path_indices[0])
	if first_index < 0 or first_index >= chips.size():
		return _no_win_result()
	var first_chip: Dictionary = chips[first_index] as Dictionary
	var path_ids: Array[String] = []
	for chip_index in path_indices:
		path_ids.append("orbit_%d" % chip_index)
	return {
		"can_win": true,
		"stars": packed_stars(packed),
		"remaining_moves": length,
		"path_ids": path_ids,
		"packed": packed,
		"target": {
			"id": "orbit_%d" % first_index,
			"op": str(first_chip["op"]),
			"value": int(first_chip["value"]),
		},
	}


static func used_mask_from_remaining(remaining_items: Array, chips: Array) -> int:
	var remaining_mask := 0
	var all_ids_valid := true
	for raw_item in remaining_items:
		var item: Dictionary = raw_item as Dictionary
		var item_id := str(item.get("id", ""))
		if not item_id.begins_with("orbit_"):
			all_ids_valid = false
			break
		var suffix := item_id.trim_prefix("orbit_")
		if not suffix.is_valid_int():
			all_ids_valid = false
			break
		var chip_index := int(suffix)
		if chip_index < 0 or chip_index >= chips.size():
			all_ids_valid = false
			break
		remaining_mask |= 1 << chip_index

	if not all_ids_valid:
		remaining_mask = 0
		var matched: Array[bool] = []
		matched.resize(chips.size())
		for raw_item in remaining_items:
			var item: Dictionary = raw_item as Dictionary
			var found := -1
			for chip_index in range(chips.size()):
				if matched[chip_index]:
					continue
				var chip: Dictionary = chips[chip_index] as Dictionary
				if (
					str(chip["op"]) == str(item.get("op", ""))
					and int(chip["value"]) == int(item.get("value", 0))
				):
					found = chip_index
					break
			if found < 0:
				return -1
			matched[found] = true
			remaining_mask |= 1 << found

	var all_mask := (1 << chips.size()) - 1
	return all_mask ^ remaining_mask


static func _no_win_result() -> Dictionary:
	return {
		"can_win": false,
		"stars": 0,
		"remaining_moves": 0,
		"path_ids": [],
		"packed": 0,
		"target": {},
	}


static func moves_left_text(count: int) -> String:
	if count == 1:
		return Locale.t("hint.to_win.one", "To win: 1 move left.")
	return Locale.t("hint.to_win.other", "To win: %d moves left.") % count


static func search_path(
	current_number: int,
	target_number: int,
	remaining_items: Array,
	depth: int,
	visited: Dictionary,
) -> Array:
	if depth <= 0:
		return []
	for i in range(remaining_items.size()):
		var item: Dictionary = remaining_items[i] as Dictionary
		var operation := str(item["op"])
		var value := int(item["value"])
		if not OperationLogic.can_apply(current_number, value, operation):
			continue
		var next_number := OperationLogic.apply(
			current_number, value, operation
		)
		if next_number == target_number:
			return [item]
		var next_remaining := remaining_items.duplicate()
		next_remaining.remove_at(i)
		var key := "%d:%d:%s" % [
			depth - 1, next_number, items_key(next_remaining)
		]
		if visited.has(key):
			continue
		visited[key] = true
		var tail := search_path(
			next_number,
			target_number,
			next_remaining,
			depth - 1,
			visited,
		)
		if not tail.is_empty():
			var result: Array = [item]
			result.append_array(tail)
			return result
	return []


static func items_key(items_to_key: Array) -> String:
	var parts: Array[String] = []
	for raw_item in items_to_key:
		var item: Dictionary = raw_item as Dictionary
		parts.append(
			"%s%d" % [str(item["op"]).substr(0, 1), int(item["value"])]
		)
	return ",".join(parts)
