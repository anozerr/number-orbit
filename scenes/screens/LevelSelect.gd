class_name LevelSelectScreen
extends Control

signal back_pressed
signal level_selected(level_number: int)
signal unlock_with_ad_requested(level_number: int)

var locked_popup: Control
var locked_popup_body: Label
var locked_popup_ad_button: Button
var locked_popup_close_button: Button
var locked_popup_level_number: int = -1
var last_scroll: ScrollContainer

func _ready() -> void:
	size = Vector2(1080, 1920)

func rebuild_level_difficulties(star_ratings: Array, max_unlocked_level: int, tutorial_completed: Array = []) -> void:
	for child in get_children():
		child.queue_free()
	last_scroll = null

	var title := Label.new()
	title.text = "LEVELS"
	title.position = Vector2(0, 95)
	title.size = Vector2(1080, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 44, UIStyles.TEXT)
	add_child(title)

	var back := UIStyles.back_button(self)
	back.pressed.connect(func(): back_pressed.emit())

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 220)
	scroll.size = Vector2(1080, 1580)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	last_scroll = scroll

	var content := Control.new()
	scroll.add_child(content)

	var y := 20.0
	y = add_tutorials_section(content, y, tutorial_completed)
	y += 95.0
	var tutorials_done := are_all_tutorials_completed(tutorial_completed)
	for difficulty_index in range(LevelData.DIFFICULTIES.size()):
		y = add_difficulty_section(content, difficulty_index, y, star_ratings, max_unlocked_level, tutorials_done)
		y += 95.0
	content.custom_minimum_size = Vector2(1080, y - 95.0)
	build_locked_level_popup()
	center_on_level_row(max_unlocked_level)

func add_tutorials_section(parent: Control, y: float, tutorial_completed: Array) -> float:
	var title := Label.new()
	title.text = "TUTORIAL"
	title.position = Vector2(0, y)
	title.size = Vector2(1080, 62)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 38, UIStyles.PURPLE)
	parent.add_child(title)

	var start_y := y + 88.0
	var button_size := Vector2(760, 160)
	var completed := are_all_tutorials_completed(tutorial_completed)
	var btn := Button.new()
	btn.text = ""
	btn.size = button_size
	btn.position = Vector2((1080 - button_size.x) * 0.5, start_y)
	btn.add_theme_font_size_override("font_size", 30)
	style_tutorial_button(btn, "add", completed, true)
	UIStyles.add_press_animation(btn)
	btn.pressed.connect(_on_level_button_pressed.bind(-1))
	parent.add_child(btn)

	var icon_texture: Texture2D = UIStyles.ICON_CHECK if completed else UIStyles.ICON_BULB
	var icon_color: Color = Color("#0F6B25") if completed else UIStyles.PURPLE
	UIStyles.icon(icon_texture, btn, Vector2(72, 51), Vector2(58, 58), icon_color)

	var name_lbl := Label.new()
	name_lbl.text = "How to Play"
	name_lbl.position = Vector2(155, 32)
	name_lbl.size = Vector2(500, 56)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(name_lbl, UIStyles.FONT_BOLD, 38, Color("#0F6B25") if completed else UIStyles.TEXT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "Target, orbit, operators, hints and move order"
	desc_lbl.position = Vector2(155, 86)
	desc_lbl.size = Vector2(540, 42)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(desc_lbl, UIStyles.FONT_MEDIUM, 22, UIStyles.MUTED)
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(desc_lbl)

	return start_y + button_size.y

func add_difficulty_section(parent: Control, difficulty_index: int, y: float, star_ratings: Array, max_unlocked_level: int, tutorials_done: bool = true) -> float:
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
		var unlocked: bool = tutorials_done and global_level <= max_unlocked_level
		var rating: int = int(star_ratings[global_level - 1]) if global_level - 1 < star_ratings.size() else 0
		var completed: bool = rating > 0
		var btn := Button.new()
		btn.text = str(global_level)
		btn.size = button_size
		btn.position = Vector2(start_x + (i % 3) * gap_x, start_y + int(float(i) / 3.0) * gap_y)
		btn.add_theme_font_size_override("font_size", 42)
		btn.disabled = false
		style_level_button(btn, completed, unlocked, difficulty_index)
		UIStyles.add_press_animation(btn)
		if unlocked:
			btn.pressed.connect(_on_level_button_pressed.bind(global_level))
		else:
			var can_watch_ad := tutorials_done and global_level == max_unlocked_level + 1
			btn.pressed.connect(show_locked_level_popup.bind(global_level, can_watch_ad))
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

func center_on_level_row(level_number: int) -> void:
	if last_scroll == null or level_number <= 0:
		return
	await get_tree().process_frame
	var row_center_y := row_center_for_level(level_number)
	var desired := int(max(0.0, row_center_y - last_scroll.size.y * 0.5))
	last_scroll.scroll_vertical = desired

func row_center_for_level(level_number: int) -> float:
	var tutorials_height := 20.0 + 88.0 + 160.0
	var section_gap := 95.0
	var difficulty_height := 88.0 + 5.0 * 215.0
	var difficulty_index := LevelData.difficulty_index_for_level(level_number)
	var local_index := LevelData.local_level_number(level_number) - 1
	var section_y := tutorials_height + section_gap + float(difficulty_index) * (difficulty_height + section_gap)
	var start_y := section_y + 88.0
	var row := int(float(local_index) / 3.0)
	return start_y + float(row) * 215.0 + 87.5

func difficulty_color(index: int) -> Color:
	match index:
		0:
			return Color("#34A853")
		1:
			return Color("#D99A00")
		2:
			return Color("#E14C4C")
	return UIStyles.TEXT

func style_level_button(button: Button, completed: bool, unlocked: bool, difficulty_index: int = 0) -> void:
	var normal: StyleBoxFlat = UIStyles.card(Color("#EFFBEA") if completed else Color("#FDFCFA"), Color("#9EDB8F") if completed else UIStyles.BORDER, 24)
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

func are_all_tutorials_completed(tutorial_completed: Array) -> bool:
	if tutorial_completed.is_empty():
		return false
	for completed in tutorial_completed:
		if not bool(completed):
			return false
	return true

func _on_level_button_pressed(level_number: int) -> void:
	level_selected.emit(level_number)

func build_locked_level_popup() -> void:
	if is_instance_valid(locked_popup):
		locked_popup.queue_free()

	locked_popup = Control.new()
	locked_popup.z_index = 100
	locked_popup.size = Vector2(1080, 1920)
	locked_popup.visible = false
	add_child(locked_popup)

	var overlay := ColorRect.new()
	overlay.size = Vector2(1080, 1920)
	overlay.color = Color(0.05, 0.06, 0.10, 0.45)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	locked_popup.add_child(overlay)

	var panel := Panel.new()
	panel.position = Vector2(110, 610)
	panel.size = Vector2(860, 660)
	panel.add_theme_stylebox_override("panel", UIStyles.soft_panel(Color.WHITE, 36))
	locked_popup.add_child(panel)

	var icon_bg := Panel.new()
	icon_bg.position = Vector2(365, -50)
	icon_bg.size = Vector2(130, 130)
	icon_bg.add_theme_stylebox_override("panel", UIStyles.card(UIStyles.PURPLE, Color.WHITE, 65))
	panel.add_child(icon_bg)
	UIStyles.icon(UIStyles.ICON_INFO, icon_bg, Vector2(38, 38), Vector2(54, 54), Color.WHITE)

	var title := Label.new()
	title.text = "LOCKED LEVEL"
	title.position = Vector2(0, 105)
	title.size = Vector2(860, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 36, UIStyles.TEXT)
	panel.add_child(title)

	locked_popup_body = Label.new()
	locked_popup_body.position = Vector2(95, 190)
	locked_popup_body.size = Vector2(670, 130)
	locked_popup_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locked_popup_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	locked_popup_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(locked_popup_body, UIStyles.FONT_MEDIUM, 24, UIStyles.MUTED)
	panel.add_child(locked_popup_body)

	locked_popup_ad_button = Button.new()
	locked_popup_ad_button.text = "Watch Ad"
	locked_popup_ad_button.position = Vector2(145, 405)
	locked_popup_ad_button.size = Vector2(570, 78)
	locked_popup_ad_button.add_theme_font_size_override("font_size", 27)
	UIStyles.primary_button(locked_popup_ad_button)
	locked_popup_ad_button.pressed.connect(func(): unlock_with_ad_requested.emit(locked_popup_level_number))
	panel.add_child(locked_popup_ad_button)

	locked_popup_close_button = Button.new()
	locked_popup_close_button.text = "Cancel"
	locked_popup_close_button.position = Vector2(145, 515)
	locked_popup_close_button.size = Vector2(570, 76)
	locked_popup_close_button.add_theme_font_size_override("font_size", 27)
	UIStyles.menu_button(locked_popup_close_button)
	locked_popup_close_button.pressed.connect(hide_locked_level_popup)
	panel.add_child(locked_popup_close_button)

func show_locked_level_popup(level_number: int, can_watch_ad: bool) -> void:
	if not is_instance_valid(locked_popup):
		build_locked_level_popup()
	locked_popup_level_number = level_number
	locked_popup_body.text = "This level is locked. Complete the previous level%s to open it." % (" or watch an ad" if can_watch_ad else "")
	locked_popup_ad_button.visible = can_watch_ad
	locked_popup_close_button.position.y = 515
	locked_popup.visible = true

func hide_locked_level_popup() -> void:
	if is_instance_valid(locked_popup):
		locked_popup.visible = false

func add_star_icons(parent: Control, count: int) -> void:
	var icon_size := Vector2(24, 24)
	var spacing := 6.0
	var step := icon_size.x + spacing
	var start_x: float = (parent.size.x - icon_size.x * 3.0 - spacing * 2.0) * 0.5
	for i in range(3):
		var texture: Texture2D = UIStyles.ICON_LEVEL_STAR if i < count else UIStyles.ICON_LEVEL_STAR_EMPTY
		var color: Color = UIStyles.GOLD if i < count else Color("#DADDE4")
		UIStyles.icon(texture, parent, Vector2(start_x + i * step, 8), icon_size, color)
