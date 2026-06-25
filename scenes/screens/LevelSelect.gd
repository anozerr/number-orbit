class_name LevelSelectScreen
extends Control

signal back_pressed
signal level_selected(level_number: int)

func _ready() -> void:
	size = Vector2(1080, 1920)

func rebuild(star_ratings: Array, max_unlocked_level: int) -> void:
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
	back.text = "     Back"
	back.size = Vector2(170, 75)
	back.position = Vector2(455, 1740)
	back.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(back)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	UIStyles.icon(UIStyles.ICON_BACK, back, Vector2(28, 22), Vector2(30, 30), UIStyles.TEXT)

	var start_x := 190
	var start_y := 250
	var gap_x := 245
	var gap_y := 215
	var button_size := Vector2(185, 175)

	for i in range(LevelData.LEVEL_COUNT):
		var level_number: int = i + 1
		var unlocked: bool = level_number <= max_unlocked_level
		var completed: bool = int(star_ratings[i]) > 0
		var btn := Button.new()
		btn.text = str(level_number)
		btn.size = button_size
		btn.position = Vector2(start_x + (i % 3) * gap_x, start_y + int(float(i) / 3.0) * gap_y)
		btn.add_theme_font_size_override("font_size", 42)
		btn.disabled = not unlocked
		style_level_button(btn, completed, unlocked)
		if unlocked:
			btn.pressed.connect(_on_level_button_pressed.bind(level_number))
		add_child(btn)

		var star_lbl := Label.new()
		star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star_lbl.position = Vector2(0, button_size.y - 58)
		star_lbl.size = Vector2(button_size.x, 40)
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_child(star_lbl)
		if unlocked:
			style_stars_label(star_lbl, int(star_ratings[i]))
		else:
			UIStyles.icon(UIStyles.ICON_LOCK, star_lbl, Vector2(76, 2), Vector2(32, 32), UIStyles.DISABLED)

func style_level_button(button: Button, completed: bool, unlocked: bool) -> void:
	var normal: StyleBoxFlat = UIStyles.card(Color("#EFFBEA") if completed else Color.WHITE, Color("#9EDB8F") if completed else UIStyles.BORDER, 24)
	if not unlocked:
		normal.bg_color = Color("#FCFBF8")
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#F1ECFF")
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#DED6EA")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_font_override("font", UIStyles.FONT_SEMIBOLD)
	button.add_theme_color_override("font_color", Color("#0F6B25") if completed else UIStyles.TEXT)
	button.add_theme_color_override("font_disabled_color", Color("#9EA3B2"))

func _on_level_button_pressed(level_number: int) -> void:
	level_selected.emit(level_number)

func style_stars_label(label: Label, count: int) -> void:
	label.text = level_stars_text(count)
	label.add_theme_font_override("font", UIStyles.FONT_BOLD)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", UIStyles.GOLD if count > 0 else Color("#DADDE4"))

func level_stars_text(count: int) -> String:
	var filled: String = ""
	for i in range(count):
		filled += "★"
	for i in range(3 - count):
		filled += "☆"
	return filled
