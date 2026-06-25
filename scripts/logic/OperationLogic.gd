class_name OperationLogic
extends RefCounted

static func can_apply(current_number: int, value: int, op: String) -> bool:
	match op:
		"divide":
			return value != 0 and current_number % value == 0
		"subtract":
			return current_number - value >= 1
		"multiply", "add":
			return true
	return false

static func apply(current_number: int, value: int, op: String) -> int:
	match op:
		"divide":
			if can_apply(current_number, value, op):
				return int(float(current_number) / float(value))
		"multiply":
			return current_number * value
		"add":
			return current_number + value
		"subtract":
			return max(1, current_number - value)
	return current_number

static func symbol(op: String) -> String:
	match op:
		"divide":
			return "÷"
		"multiply":
			return "×"
		"add":
			return "+"
		"subtract":
			return "−"
	return "?"
