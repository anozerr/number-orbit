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
	for raw_band in star_bands(data):
		var band: Dictionary = raw_band as Dictionary
		if moves <= int(band.get("moves", 0)):
			return int(band.get("stars", 1))
	var thresholds: Array = sorted_thresholds(data)
	if moves <= int(thresholds[0]):
		return 3
	if moves <= int(thresholds[1]):
		return 2
	return 1

static func star_bands(data: Dictionary) -> Array:
	if str(data.get("difficulty", "")) == "Easy":
		return []
	if data.has("star_bands"):
		var bands: Array = (data["star_bands"] as Array).duplicate(true)
		bands.sort_custom(func(a, b): return int((a as Dictionary).get("moves", 0)) < int((b as Dictionary).get("moves", 0)))
		return bands
	var thresholds: Array = sorted_thresholds(data)
	return [
		{"stars": 3, "moves": int(thresholds[0])},
		{"stars": 2, "moves": int(thresholds[1])},
		{"stars": 1, "moves": int(thresholds[2])}
	]
