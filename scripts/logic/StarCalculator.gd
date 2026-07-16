class_name StarCalculator
extends RefCounted

static func calculate(moves: int, data: Dictionary) -> int:
	match str(data.get("star_mode", "")):
		LevelData.STAR_MODE_TUTORIAL:
			return 0
		LevelData.STAR_MODE_ALWAYS_THREE:
			return 3
		LevelData.STAR_MODE_TIERED:
			for raw_band in star_bands(data):
				var band: Dictionary = raw_band as Dictionary
				if (
					moves >= int(band.get("min_moves", -1))
					and moves <= int(band.get("max_moves", -1))
				):
					return int(band.get("stars", 0))
	return 0

static func star_bands(data: Dictionary) -> Array:
	if not data.get("star_bands", null) is Array:
		return []
	var bands: Array = (data["star_bands"] as Array).duplicate(true)
	bands.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("stars", 0)) > int(b.get("stars", 0))
	)
	return bands
