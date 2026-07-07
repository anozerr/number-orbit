class_name OrbitSlots
extends RefCounted

static func assign(items: Array) -> Array:
	var result: Array = []
	var slots: Array = spread_order(items.size())
	for i in range(items.size()):
		var item: Dictionary = (items[i] as Dictionary).duplicate()
		item["id"] = "orbit_%d" % i
		item["slot"] = int(slots[i])
		item["slot_count"] = items.size()
		result.append(item)
	return result

static func spread_order(count: int) -> Array:
	match count:
		1:
			return [0]
		2:
			return [0, 1]
		3:
			return [0, 2, 1]
		4:
			return [0, 2, 1, 3]
		5:
			return [0, 2, 4, 1, 3]
		6:
			return [0, 3, 1, 4, 2, 5]
		7:
			return [0, 3, 6, 2, 5, 1, 4]
		8:
			return [0, 4, 1, 5, 2, 6, 3, 7]
		9:
			return [0, 4, 8, 3, 7, 2, 6, 1, 5]
		10:
			return [0, 5, 1, 6, 2, 7, 3, 8, 4, 9]
	var result: Array = []
	var step: int = int(max(1, floor(float(count) * 0.5)))
	var used: Dictionary = {}
	var slot := 0
	while result.size() < count:
		if not used.has(slot):
			result.append(slot)
			used[slot] = true
		slot = (slot + step) % count
		if used.has(slot):
			for candidate in range(count):
				if not used.has(candidate):
					slot = candidate
					break
	return result

static func reflow(items: Array, removed_slot: int = -1, old_slot_count: int = 0, removed_angle_override: float = INF) -> Array:
	var result: Array = []
	for raw_item in items:
		result.append((raw_item as Dictionary).duplicate())
	if result.is_empty():
		return result

	var new_count: int = result.size()
	if old_slot_count <= 0:
		old_slot_count = new_count + 1
	if removed_slot < 0:
		var slots: Array = spread_order(new_count)
		for i in range(new_count):
			var item: Dictionary = (result[i] as Dictionary).duplicate()
			item["slot"] = int(slots[i])
			item["slot_count"] = new_count
			item.erase("orbit_target_angle")
			item.erase("orbit_snap_to_target")
			item.erase("orbit_force_clockwise")
			result[i] = item
		return result

	var removed_angle: float = removed_angle_override
	if is_inf(removed_angle):
		removed_angle = angle_for_slot(removed_slot, old_slot_count)
	var anchor_index := 0
	var best_distance := INF
	for i in range(new_count):
		var candidate: Dictionary = result[i] as Dictionary
		var candidate_slot: int = int(candidate.get("slot", i))
		var candidate_angle: float = float(candidate.get("orbit_target_angle", angle_for_slot(candidate_slot, old_slot_count)))
		var distance: float = fposmod(candidate_angle - removed_angle, TAU)
		if distance < 0.001:
			distance = TAU
		if distance < best_distance:
			best_distance = distance
			anchor_index = i

	var anchor: Dictionary = result[anchor_index] as Dictionary
	var anchor_old_slot: int = int(anchor.get("slot", 0))
	var anchor_angle: float = float(anchor.get("orbit_target_angle", angle_for_slot(anchor_old_slot, old_slot_count)))
	var order: Array = []
	for i in range(new_count):
		var item: Dictionary = result[i] as Dictionary
		var old_slot: int = int(item.get("slot", i))
		var old_angle: float = float(item.get("orbit_target_angle", angle_for_slot(old_slot, old_slot_count)))
		var clockwise_distance: float = fposmod(old_angle - anchor_angle, TAU)
		order.append({"index": i, "distance": clockwise_distance, "old_slot": old_slot, "old_angle": old_angle})
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distance"]) < float(b["distance"])
	)

	for rank in range(order.size()):
		var info: Dictionary = order[rank] as Dictionary
		var i: int = int(info["index"])
		var old_angle: float = float(info["old_angle"])
		var target_angle: float = anchor_angle + (TAU * float(rank) / float(new_count))
		while target_angle < old_angle - 0.001:
			target_angle += TAU
		if target_angle - old_angle > PI:
			target_angle -= TAU
		var item: Dictionary = (result[i] as Dictionary).duplicate()
		item["slot"] = rank
		item["slot_count"] = new_count
		item["orbit_target_angle"] = target_angle
		item["orbit_force_clockwise"] = true
		item["orbit_snap_to_target"] = rank == 0
		result[i] = item
	return result

static func angle_for_slot(slot: int, slot_count: int) -> float:
	return TAU * float(slot) / float(max(1, slot_count)) - PI / 2.0
