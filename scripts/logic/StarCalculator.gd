class_name StarCalculator
extends RefCounted

static func sorted_thresholds(data: Dictionary) -> Array:
	var thresholds: Array = [5, 9, 12]
	if data.has("thresholds"):
		thresholds = (data["thresholds"] as Array).duplicate()
		thresholds.sort()
	return thresholds

static func calculate(moves: int, data: Dictionary) -> int:
	if str(data.get("difficulty", "")) == "Easy":
		return 3
	var thresholds: Array = sorted_thresholds(data)
	if moves <= int(thresholds[0]):
		return 3
	if moves <= int(thresholds[1]):
		return 2
	return 1
