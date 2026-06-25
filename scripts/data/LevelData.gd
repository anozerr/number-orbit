class_name LevelData
extends RefCounted

const LEVEL_COUNT := 15

static func get_levels() -> Array:
	return [
		{"start": 1, "target": 10, "thresholds": [3, 5, 7], "allowed_ops": ["add"], "sequence": [
			{"value": 2, "op": "add"}, {"value": 3, "op": "add"}, {"value": 4, "op": "add"},
			{"value": 5, "op": "add"}, {"value": 6, "op": "add"}, {"value": 7, "op": "add"}
		]},
		{"start": 25, "target": 14, "thresholds": [2, 4, 6], "allowed_ops": ["subtract"], "sequence": [
			{"value": 3, "op": "subtract"}, {"value": 4, "op": "subtract"}, {"value": 5, "op": "subtract"},
			{"value": 6, "op": "subtract"}, {"value": 7, "op": "subtract"}, {"value": 8, "op": "subtract"}
		]},
		{"start": 10, "target": 21, "thresholds": [3, 5, 7], "allowed_ops": ["add", "subtract"], "sequence": [
			{"value": 6, "op": "add"}, {"value": 8, "op": "add"}, {"value": 3, "op": "subtract"},
			{"value": 5, "op": "add"}, {"value": 4, "op": "subtract"}, {"value": 7, "op": "subtract"}
		]},
		{"start": 2, "target": 120, "thresholds": [3, 5, 7], "allowed_ops": ["multiply"], "sequence": [
			{"value": 2, "op": "multiply"}, {"value": 3, "op": "multiply"}, {"value": 4, "op": "multiply"},
			{"value": 5, "op": "multiply"}, {"value": 6, "op": "multiply"}, {"value": 7, "op": "multiply"}
		]},
		{"start": 120, "target": 5, "thresholds": [3, 5, 7], "allowed_ops": ["divide"], "sequence": [
			{"value": 2, "op": "divide"}, {"value": 3, "op": "divide"}, {"value": 4, "op": "divide"},
			{"value": 5, "op": "divide"}, {"value": 6, "op": "divide"}, {"value": 10, "op": "divide"}
		]},
		{"start": 3, "target": 45, "thresholds": [4, 6, 8], "allowed_ops": ["add", "subtract", "multiply"], "sequence": [
			{"value": 5, "op": "multiply"}, {"value": 9, "op": "add"}, {"value": 2, "op": "multiply"},
			{"value": 3, "op": "subtract"}, {"value": 7, "op": "add"}, {"value": 6, "op": "subtract"}
		]},
		{"start": 64, "target": 15, "thresholds": [3, 5, 7], "allowed_ops": ["add", "subtract", "divide"], "sequence": [
			{"value": 2, "op": "divide"}, {"value": 4, "op": "divide"}, {"value": 8, "op": "divide"},
			{"value": 7, "op": "add"}, {"value": 8, "op": "subtract"}, {"value": 5, "op": "subtract"}
		]},
		{"start": 12, "target": 50, "thresholds": [3, 5, 7], "allowed_ops": ["add", "subtract", "multiply", "divide"], "sequence": [
			{"value": 3, "op": "divide"}, {"value": 4, "op": "multiply"}, {"value": 8, "op": "add"},
			{"value": 6, "op": "subtract"}, {"value": 11, "op": "add"}, {"value": 5, "op": "subtract"}
		]},
		{"start": 81, "target": 32, "thresholds": [3, 5, 7], "allowed_ops": ["add", "subtract", "multiply", "divide"], "sequence": [
			{"value": 3, "op": "divide"}, {"value": 9, "op": "divide"}, {"value": 4, "op": "multiply"},
			{"value": 4, "op": "subtract"}, {"value": 7, "op": "add"}, {"value": 6, "op": "subtract"}
		]},
		{"start": 18, "target": 100, "thresholds": [5, 7, 9], "allowed_ops": ["add", "subtract", "multiply", "divide"], "sequence": [
			{"value": 5, "op": "multiply"}, {"value": 12, "op": "add"}, {"value": 3, "op": "divide"},
			{"value": 3, "op": "multiply"}, {"value": 2, "op": "subtract"}, {"value": 7, "op": "add"}
		]},
		{"start": 144, "target": 27, "thresholds": [4, 6, 8], "allowed_ops": ["add", "subtract", "multiply", "divide"], "sequence": [
			{"value": 12, "op": "divide"}, {"value": 5, "op": "add"}, {"value": 2, "op": "multiply"},
			{"value": 7, "op": "subtract"}, {"value": 3, "op": "divide"}, {"value": 11, "op": "add"}
		]},
		{"start": 96, "target": 143, "thresholds": [4, 6, 8], "allowed_ops": ["add", "subtract", "multiply", "divide"], "sequence": [
			{"value": 6, "op": "divide"}, {"value": 8, "op": "multiply"}, {"value": 12, "op": "add"},
			{"value": 3, "op": "add"}, {"value": 5, "op": "subtract"}, {"value": 2, "op": "divide"}
		]},
		{"start": 132, "target": 89, "thresholds": [3, 5, 7], "allowed_ops": ["add", "subtract", "multiply", "divide"], "sequence": [
			{"value": 11, "op": "divide"}, {"value": 8, "op": "multiply"}, {"value": 7, "op": "subtract"},
			{"value": 3, "op": "divide"}, {"value": 10, "op": "add"}, {"value": 2, "op": "multiply"}
		]},
		{"start": 45, "target": 110, "thresholds": [4, 6, 8], "allowed_ops": ["add", "subtract", "multiply", "divide"], "sequence": [
			{"value": 5, "op": "divide"}, {"value": 7, "op": "add"}, {"value": 7, "op": "multiply"},
			{"value": 2, "op": "subtract"}, {"value": 3, "op": "divide"}, {"value": 2, "op": "multiply"}
		]},
		{"start": 168, "target": 251, "thresholds": [4, 6, 8], "allowed_ops": ["add", "subtract", "multiply", "divide"], "sequence": [
			{"value": 7, "op": "divide"}, {"value": 10, "op": "multiply"}, {"value": 13, "op": "add"},
			{"value": 2, "op": "subtract"}, {"value": 3, "op": "divide"}, {"value": 5, "op": "add"}
		]}
	]
