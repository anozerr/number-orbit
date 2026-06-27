class_name LevelSelectScreen
extends Control

signal back_pressed
signal level_selected(level_number: int)

func _ready() -> void:
	size = Vector2(1080, 1920)

func rebuild(star_ratings: Array, max_unlocked_level: int) -> void:
	rebuild_level_difficulties(star_ratings, max_unlocked_level, [])

func rebuild_level_difficulties(star_ratings: Array, max_unlocked_level: int, tutorial_completed: Array = []) -> void:
	for child in get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "LEVELS"
	title.position = Vector2(0, 95)
	title.size = Vector2(1080, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 44, UIStyles.TEXT)
	add_child(title)

	var back := Button.new()
	back.text = ""
	back.size = Vector2(88, 88)
	back.position = Vector2(55, 52)
	back.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(back)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	UIStyles.icon(UIStyles.ICON_BACK, back, Vector2(23, 23), Vector2(42, 42), UIStyles.TEXT)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 220)
	scroll.size = Vector2(1080, 1580)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	var content := Control.new()
	scroll.add_child(content)

	var y := 20.0
	y = add_tutorials_section(content, y, tutorial_completed)
	y += 95.0
	for difficulty_index in range(LevelData.DIFFICULTIES.size()):
		y = add_difficulty_section(content, difficulty_index, y, star_ratings, max_unlocked_level)
		y += 95.0
	content.custom_minimum_size = Vector2(1080, y - 95.0)

func add_tutorials_section(parent: Control, y: float, tutorial_completed: Array) -> float:
	var title := Label.new()
	title.text = "TUTORIALS"
	title.position = Vector2(0, y)
	title.size = Vector2(1080, 62)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 38, UIStyles.PURPLE)
	parent.add_child(title)

	var ops := ["add", "subtract", "multiply", "divide"]
	var names := ["Add", "Subtract", "Multiply", "Divide"]
	var start_x := 160
	var start_y := y + 88.0
	var gap_x := 210
	var button_size := Vector2(170, 170)

	for i in range(ops.size()):
		var op: String = str(ops[i])
		var completed := is_tutorial_op_completed(tutorial_completed, i)
		var unlocked := true
		var btn := Button.new()
		btn.text = ""
		btn.size = button_size
		btn.position = Vector2(start_x + i * gap_x, start_y)
		btn.add_theme_font_size_override("font_size", 26)
		btn.disabled = not unlocked
		style_tutorial_button(btn, op, completed, unlocked)
		UIStyles.add_press_animation(btn)
		if unlocked:
			btn.pressed.connect(_on_level_button_pressed.bind(-(i + 1)))
		parent.add_child(btn)

		var icon_texture: Texture2D = UIStyles.ICON_CHECK if completed else UIStyles.operation_icon(op)
		var icon_color: Color = Color("#0F6B25") if completed else (UIStyles.operation_text(op) if unlocked else UIStyles.DISABLED)
		UIStyles.icon(icon_texture, btn, Vector2(56, 35), Vector2(58, 58), icon_color)

		var name_lbl := Label.new()
		name_lbl.text = str(names[i])
		name_lbl.position = Vector2(0, 98)
		name_lbl.size = Vector2(button_size.x, 44)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_font(name_lbl, UIStyles.FONT_BOLD, 24, Color("#0F6B25") if completed else (UIStyles.TEXT if unlocked else UIStyles.DISABLED))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(name_lbl)

	return start_y + button_size.y

func add_difficulty_section(parent: Control, difficulty_index: int, y: float, star_ratings: Array, max_unlocked_level: int) -> float:
	var title := Label.new()
	title.text = str(LevelData.DIFFICULTIES[difficulty_index]).to_upper()
	title.position = Vector2(0, y)
	title.size = Vector2(1080, 62)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 38, difficulty_color(difficulty_index))
	parent.add_child(title)

	var start_x := 190
	var start_y := y + 88.0
	var gap_x := 245
	var gap_y := 215
	var button_size := Vector2(185, 175)

	for i in range(LevelData.LEVELS_PER_DIFFICULTY):
		var local_level: int = i + 1
		var global_level: int = difficulty_index * LevelData.LEVELS_PER_DIFFICULTY + local_level
		var unlocked: bool = global_level <= max_unlocked_level
		var rating: int = int(star_ratings[global_level - 1]) if global_level - 1 < star_ratings.size() else 0
		var completed: bool = rating > 0
		var btn := Button.new()
		btn.text = str(global_level)
		btn.size = button_size
		btn.position = Vector2(start_x + (i % 3) * gap_x, start_y + int(float(i) / 3.0) * gap_y)
		btn.add_theme_font_size_override("font_size", 42)
		btn.disabled = not unlocked
		style_level_button(btn, completed, unlocked, difficulty_index)
		UIStyles.add_press_animation(btn)
		if unlocked:
			btn.pressed.connect(_on_level_button_pressed.bind(global_level))
		parent.add_child(btn)

		var star_lbl := Label.new()
		star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star_lbl.position = Vector2(0, button_size.y - 58)
		star_lbl.size = Vector2(button_size.x, 40)
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_child(star_lbl)
		if unlocked:
			add_star_icons(star_lbl, rating)
		else:
			UIStyles.icon(UIStyles.ICON_LOCK, star_lbl, Vector2(76, 2), Vector2(32, 32), UIStyles.DISABLED)

	return start_y + 5.0 * gap_y

func rebuild_levels_for_difficulty(difficulty_index: int, star_ratings: Array, max_unlocked_level: int) -> void:
	for child in get_children():
		child.queue_free()

	var clamped_index: int = int(clamp(difficulty_index, 0, LevelData.DIFFICULTIES.size() - 1))
	var title := Label.new()
	title.text = "%s LEVELS" % str(LevelData.DIFFICULTIES[clamped_index]).to_upper()
	title.position = Vector2(0, 95)
	title.size = Vector2(1080, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 44, UIStyles.TEXT)
	add_child(title)

	var back := Button.new()
	back.text = ""
	back.size = Vector2(88, 88)
	back.position = Vector2(55, 52)
	back.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(back)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	UIStyles.icon(UIStyles.ICON_BACK, back, Vector2(23, 23), Vector2(42, 42), UIStyles.TEXT)

	var start_x := 190
	var start_y := 250
	var gap_x := 245
	var gap_y := 215
	var button_size := Vector2(185, 175)

	for i in range(LevelData.LEVELS_PER_DIFFICULTY):
		var local_level: int = i + 1
		var global_level: int = clamped_index * LevelData.LEVELS_PER_DIFFICULTY + local_level
		var unlocked: bool = global_level <= max_unlocked_level
		var rating: int = int(star_ratings[global_level - 1]) if global_level - 1 < star_ratings.size() else 0
		var completed: bool = rating > 0
		var btn := Button.new()
		btn.text = str(global_level)
		btn.size = button_size
		btn.position = Vector2(start_x + (i % 3) * gap_x, start_y + int(float(i) / 3.0) * gap_y)
		btn.add_theme_font_size_override("font_size", 42)
		btn.disabled = not unlocked
		style_level_button(btn, completed, unlocked, clamped_index)
		UIStyles.add_press_animation(btn)
		if unlocked:
			btn.pressed.connect(_on_level_button_pressed.bind(global_level))
		add_child(btn)

		var star_lbl := Label.new()
		star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star_lbl.position = Vector2(0, button_size.y - 58)
		star_lbl.size = Vector2(button_size.x, 40)
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_child(star_lbl)
		if unlocked:
			add_star_icons(star_lbl, rating)
		else:
			UIStyles.icon(UIStyles.ICON_LOCK, star_lbl, Vector2(76, 2), Vector2(32, 32), UIStyles.DISABLED)

func difficulty_moves_text(index: int) -> String:
	match index:
		0:
			return "Easy • 3–4 moves"
		1:
			return "Medium • 5–6 moves"
		2:
			return "Hard • 7–8 moves"
	return ""

func completed_levels_in_range(star_ratings: Array, first_level: int, last_level: int) -> int:
	var count := 0
	for level_number in range(first_level, last_level + 1):
		var index: int = level_number - 1
		if index >= 0 and index < star_ratings.size() and int(star_ratings[index]) > 0:
			count += 1
	return count

func style_difficulty_button(button: Button, completed: bool, unlocked: bool) -> void:
	var bg: Color = Color("#EFFBEA") if completed else Color.WHITE
	var border: Color = Color("#9EDB8F") if completed else UIStyles.BORDER
	if not unlocked:
		bg = Color("#FDFCFA")
	var normal: StyleBoxFlat = UIStyles.card(bg, border, 30)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)

func difficulty_color(index: int) -> Color:
	match index:
		0:
			return Color("#34A853")
		1:
			return Color("#D99A00")
		2:
			return Color("#E14C4C")
	return UIStyles.TEXT

func rebuild_tutorial_ops(tutorial_completed: Array) -> void:
	for child in get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "TUTORIALS"
	title.position = Vector2(0, 95)
	title.size = Vector2(1080, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 44, UIStyles.TEXT)
	add_child(title)

	var back := Button.new()
	back.text = ""
	back.size = Vector2(88, 88)
	back.position = Vector2(55, 52)
	back.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(back)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	UIStyles.icon(UIStyles.ICON_BACK, back, Vector2(23, 23), Vector2(42, 42), UIStyles.TEXT)

	var ops := ["add", "subtract", "multiply", "divide"]
	var names := ["Add", "Subtract", "Multiply", "Divide"]
	var start_y := 285
	var gap_y := 215
	var button_size := Vector2(760, 160)

	for i in range(ops.size()):
		var op: String = str(ops[i])
		var completed := is_tutorial_op_completed(tutorial_completed, i)
		var btn := Button.new()
		btn.text = ""
		btn.size = button_size
		btn.position = Vector2((1080 - button_size.x) * 0.5, start_y + i * gap_y)
		btn.add_theme_font_size_override("font_size", 30)
		style_tutorial_button(btn, op, completed)
		UIStyles.add_press_animation(btn)
		btn.pressed.connect(_on_level_button_pressed.bind(i + 1))
		add_child(btn)

		var op_icon: Texture2D = UIStyles.ICON_CHECK if completed else UIStyles.operation_icon(op)
		UIStyles.icon(op_icon, btn, Vector2(72, 51), Vector2(58, 58), Color("#0F6B25") if completed else UIStyles.operation_text(op))

		var name_lbl := Label.new()
		name_lbl.text = str(names[i])
		name_lbl.position = Vector2(155, 39)
		name_lbl.size = Vector2(460, 62)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_font(name_lbl, UIStyles.FONT_BOLD, 38, Color("#0F6B25") if completed else UIStyles.TEXT)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = "Easy • Medium • Hard"
		desc_lbl.position = Vector2(155, 91)
		desc_lbl.size = Vector2(520, 42)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_font(desc_lbl, UIStyles.FONT_MEDIUM, 22, UIStyles.MUTED)
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(desc_lbl)

func rebuild_tutorial_difficulty(op_index: int, tutorial_completed: Array) -> void:
	for child in get_children():
		child.queue_free()

	var ops := ["add", "subtract", "multiply", "divide"]
	var op_names := ["Add", "Subtract", "Multiply", "Divide"]
	var difficulties := ["Easy", "Medium", "Hard"]
	var op: String = str(ops[int(clamp(op_index, 0, ops.size() - 1))])

	var title := Label.new()
	title.text = "TUTORIALS: %s" % str(op_names[int(clamp(op_index, 0, op_names.size() - 1))]).to_upper()
	title.position = Vector2(0, 95)
	title.size = Vector2(1080, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 44, UIStyles.TEXT)
	add_child(title)

	var back := Button.new()
	back.text = ""
	back.size = Vector2(88, 88)
	back.position = Vector2(55, 52)
	back.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(back)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	UIStyles.icon(UIStyles.ICON_BACK, back, Vector2(23, 23), Vector2(42, 42), UIStyles.TEXT)

	var start_y := 320
	var gap_y := 250
	var button_size := Vector2(760, 180)
	for i in range(difficulties.size()):
		var tutorial_index: int = op_index * 3 + i
		var completed := tutorial_index >= 0 and tutorial_index < tutorial_completed.size() and bool(tutorial_completed[tutorial_index])
		var btn := Button.new()
		btn.text = ""
		btn.size = button_size
		btn.position = Vector2((1080 - button_size.x) * 0.5, start_y + i * gap_y)
		btn.add_theme_font_size_override("font_size", 34)
		style_tutorial_difficulty_button(btn, op, completed)
		UIStyles.add_press_animation(btn)
		btn.pressed.connect(_on_level_button_pressed.bind(i + 1))
		add_child(btn)

		var name_lbl := Label.new()
		name_lbl.text = str(difficulties[i])
		name_lbl.position = Vector2(0, 36)
		name_lbl.size = Vector2(button_size.x, 62)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_font(name_lbl, UIStyles.FONT_BOLD, 38, Color("#0F6B25") if completed else UIStyles.TEXT)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = tutorial_description(i)
		desc_lbl.position = Vector2(0, 94)
		desc_lbl.size = Vector2(button_size.x, 48)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_font(desc_lbl, UIStyles.FONT_MEDIUM, 22, UIStyles.MUTED)
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(desc_lbl)

func tutorial_description(index: int) -> String:
	match index:
		0:
			return "2 right moves from 3 numbers"
		1:
			return "4 right moves from 5 numbers"
		2:
			return "6 right moves from 7 numbers"
	return ""

func style_level_button(button: Button, completed: bool, unlocked: bool, difficulty_index: int = 0) -> void:
	var section_color: Color = difficulty_color(difficulty_index)
	var normal: StyleBoxFlat = UIStyles.card(Color("#EFFBEA") if completed else section_color.lightened(0.89), Color("#9EDB8F") if completed else section_color.lightened(0.35), 24)
	if not unlocked:
		normal.bg_color = Color("#FDFCFA")
		normal.border_color = UIStyles.BORDER
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_font_override("font", UIStyles.FONT_SEMIBOLD)
	var font_color: Color = Color("#0F6B25") if completed else UIStyles.TEXT
	if not unlocked:
		font_color = UIStyles.DISABLED
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", UIStyles.DISABLED)

func style_tutorial_button(button: Button, op: String, completed: bool = false, unlocked: bool = true) -> void:
	var bg: Color = Color("#EFFBEA") if completed else UIStyles.operation_bg(op)
	var border: Color = Color("#9EDB8F") if completed else UIStyles.operation_border(op)
	if not unlocked:
		bg = UIStyles.operation_bg(op).lerp(Color.WHITE, 0.48)
		border = UIStyles.operation_border(op).lightened(0.36)
	var normal: StyleBoxFlat = UIStyles.card(bg, border, 28)
	normal.border_width_left = 3
	normal.border_width_right = 3
	normal.border_width_top = 3
	normal.border_width_bottom = 3
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_font_override("font", UIStyles.FONT_SEMIBOLD)
	var color: Color = Color("#0F6B25") if completed else (UIStyles.operation_text(op) if unlocked else UIStyles.DISABLED)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("font_disabled_color", color)

func style_tutorial_difficulty_button(button: Button, op: String, completed: bool) -> void:
	var bg: Color = Color("#EFFBEA") if completed else Color.WHITE
	var border: Color = Color("#9EDB8F") if completed else UIStyles.operation_border(op).lightened(0.25)
	var normal: StyleBoxFlat = UIStyles.card(bg, border, 30)
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

func is_tutorial_op_completed(tutorial_completed: Array, op_index: int) -> bool:
	var start_index: int = op_index * 3
	if start_index < 0 or start_index + 2 >= tutorial_completed.size():
		return false
	for i in range(3):
		if not bool(tutorial_completed[start_index + i]):
			return false
	return true

func are_all_tutorials_completed(tutorial_completed: Array) -> bool:
	if tutorial_completed.is_empty():
		return false
	for completed in tutorial_completed:
		if not bool(completed):
			return false
	return true

func _on_level_button_pressed(level_number: int) -> void:
	level_selected.emit(level_number)

func add_star_icons(parent: Control, count: int) -> void:
	var icon_size := Vector2(24, 24)
	var spacing := 6.0
	var step := icon_size.x + spacing
	var start_x: float = (parent.size.x - icon_size.x * 3.0 - spacing * 2.0) * 0.5
	for i in range(3):
		var texture: Texture2D = UIStyles.ICON_LEVEL_STAR if i < count else UIStyles.ICON_LEVEL_STAR_EMPTY
		var color: Color = UIStyles.GOLD if i < count else Color("#DADDE4")
		UIStyles.icon(texture, parent, Vector2(start_x + i * step, 8), icon_size, color)
