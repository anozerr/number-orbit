class_name HintSolver
extends RefCounted

static func next_hint_text(current_number: int, target_number: int, moves_used: int, orbit_items: Array, data: Dictionary) -> String:
	var max_depth: int = orbit_items.size()
	if str(data.get("difficulty", "")) != "Easy":
		var thresholds: Array = StarCalculator.sorted_thresholds(data)
		var one_star_budget: int = int(thresholds[thresholds.size() - 1]) - moves_used
		max_depth = min(orbit_items.size(), max(0, one_star_budget))
	var path: Array = find_path(current_number, target_number, orbit_items, max_depth)
	if path.is_empty():
		return Locale.t("hint.none", "No winning move from here. Try Restart.")
	var item: Dictionary = path[0] as Dictionary
	var op: String = str(item["op"])
	var value: int = int(item["value"])
	return "%s\nNext move: %s %d" % [Locale.t("hint.to_win", "To win: %d move(s) left.") % path.size(), OperationLogic.symbol(op), value]

static func find_path(current_number: int, target_number: int, orbit_items: Array, depth: int) -> Array:
	var visited: Dictionary = {}
	for search_depth in range(1, depth + 1):
		visited.clear()
		var path := search_path(current_number, target_number, orbit_items.duplicate(), search_depth, visited)
		if not path.is_empty():
			return path
	return []

static func search_path(current_number: int, target_number: int, remaining_items: Array, depth: int, visited: Dictionary) -> Array:
	if depth <= 0:
		return []

	for i in range(remaining_items.size()):
		var raw_item = remaining_items[i]
		var item: Dictionary = raw_item as Dictionary
		var op: String = str(item["op"])
		var value: int = int(item["value"])
		if not OperationLogic.can_apply(current_number, value, op):
			continue

		var next_number: int = OperationLogic.apply(current_number, value, op)
		if next_number == target_number:
			return [item]

		var next_remaining: Array = remaining_items.duplicate()
		next_remaining.remove_at(i)
		var key: String = "%d:%d:%s" % [depth - 1, next_number, items_key(next_remaining)]
		if visited.has(key):
			continue
		visited[key] = true

		var tail: Array = search_path(next_number, target_number, next_remaining, depth - 1, visited)
		if not tail.is_empty():
			var result: Array = [item]
			result.append_array(tail)
			return result

	return []

static func items_key(items_to_key: Array) -> String:
	var parts: Array[String] = []
	for raw_item in items_to_key:
		var item: Dictionary = raw_item as Dictionary
		parts.append("%s%d" % [str(item["op"]).substr(0, 1), int(item["value"])])
	return ",".join(parts)
