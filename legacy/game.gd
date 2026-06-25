extends Node2D

const SCREEN_CENTER := Vector2(540, 960)
const ORBIT_RADIUS := 390
const ORBIT_COUNT := 6
const LEVEL_COUNT := 15
const COLOR_BG := Color("#FFFCF6")
const COLOR_TEXT := Color("#11133D")
const COLOR_MUTED := Color("#5C6078")
const COLOR_BORDER := Color("#E8E1D8")
const COLOR_PURPLE := Color("#8B5CF6")
const COLOR_PURPLE_DARK := Color("#6D3FE0")
const COLOR_GOLD := Color("#FFC857")

# Уровни: каждый имеет начальное число, цель, пороги для звёзд,
# разрешённые операции и стартовую последовательность операций (6 штук).
var levels = [
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

# Состояние уровня
var current_level: int = 1
var current_number: int = levels[0]["start"]
var target_number: int = levels[0]["target"]
var has_played: bool = false
var star_ratings: Array = []
var moves_used: int = 0
var max_unlocked_level: int = 1

# Орбита
var orbit_items: Array = []
var orbit_angle: float = 0.0
var is_animating: bool = false

# Возможные числа и операторы
var possible_numbers: Array = [2,3,4,5,6,7,8,9,10,11,12,13]
var possible_ops: Array = ["divide", "multiply", "add", "subtract"]

# Ссылки на ноды
@onready var center_label: Label = $CenterLabel
@onready var goal_label: Label = $GoalLabel
@onready var orbit: Node2D = $Orbit
@onready var level_screen: Control = $LevelScreen
@onready var main_menu: Control = $MainMenu
@onready var settings_screen: Control = $SettingsScreen
@onready var popup: Control = $LevelCompletePopup
var back_button: Button
var operation_info_label: Label
var star_info_label: Label
var operation_legend_panel: Control
var task_label: Label
var game_settings_button: Button
var restart_button: Button
var return_to_game_after_settings: bool = false
var popup_overlay: ColorRect

func text_for(en: String, ru: String) -> String:
	return en

func _ready() -> void:
	randomize()
	setup_initial_state()
	setup_ui_base()
	setup_main_menu()
	setup_level_screen()
	setup_settings_screen()
	setup_level_complete_popup()
	setup_back_button()
	show_main_menu()

func setup_initial_state() -> void:
	star_ratings.resize(LEVEL_COUNT)
	for i in range(LEVEL_COUNT):
		star_ratings[i] = 0
	center_label.visible = false
	goal_label.visible = false
	orbit.visible = false
	level_screen.visible = false
	main_menu.visible = false
	settings_screen.visible = false
	popup.visible = false
	if popup_overlay != null:
		popup_overlay.visible = false

func setup_ui_base() -> void:
	var bg := $Background
	bg.position = Vector2.ZERO
	bg.size = Vector2(1080, 1920)
	bg.color = COLOR_BG
	bg.z_index = -1
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	popup_overlay = ColorRect.new()
	popup_overlay.position = Vector2.ZERO
	popup_overlay.size = Vector2(1080, 1920)
	popup_overlay.color = Color(0.05, 0.06, 0.10, 0.58)
	popup_overlay.visible = false
	popup_overlay.z_index = 40
	popup_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(popup_overlay)

	center_label.position = SCREEN_CENTER - Vector2(220, 80)
	center_label.size = Vector2(440, 160)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.add_theme_font_size_override("font_size", 110)
	center_label.add_theme_color_override("font_color", Color.WHITE)

	goal_label.position = Vector2(0, 72)
	goal_label.size = Vector2(1080, 60)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 30)
	goal_label.add_theme_color_override("font_color", COLOR_TEXT)

	task_label = Label.new()
	task_label.position = Vector2(0, 120)
	task_label.size = Vector2(1080, 90)
	task_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	task_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	task_label.add_theme_font_size_override("font_size", 54)
	task_label.add_theme_color_override("font_color", COLOR_TEXT)
	task_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	task_label.visible = false
	add_child(task_label)

	operation_info_label = Label.new()
	operation_info_label.position = Vector2(70, 1568)
	operation_info_label.size = Vector2(430, 68)
	operation_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	operation_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	operation_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	operation_info_label.add_theme_font_size_override("font_size", 30)
	operation_info_label.add_theme_color_override("font_color", COLOR_TEXT)
	make_label_pill(operation_info_label)
	operation_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	operation_info_label.visible = false
	add_child(operation_info_label)

	star_info_label = Label.new()
	star_info_label.position = Vector2(525, 1568)
	star_info_label.size = Vector2(485, 68)
	star_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	star_info_label.add_theme_font_size_override("font_size", 23)
	star_info_label.add_theme_color_override("font_color", COLOR_TEXT)
	make_label_pill(star_info_label)
	star_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_info_label.visible = false
	add_child(star_info_label)

	operation_legend_panel = Control.new()
	operation_legend_panel.position = Vector2(55, 1710)
	operation_legend_panel.size = Vector2(970, 170)
	operation_legend_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	operation_legend_panel.visible = false
	add_child(operation_legend_panel)
	setup_operation_legend()

func _process(delta: float) -> void:
	if level_screen.visible or main_menu.visible or settings_screen.visible or popup.visible:
		return
	orbit_angle += delta * 0.25
	update_orbit_positions()
	queue_redraw()

func _draw() -> void:
	if not orbit.visible or popup.visible:
		return
	draw_circle(SCREEN_CENTER + Vector2(0, 10), 188, Color(0.22, 0.18, 0.45, 0.14))
	draw_circle(SCREEN_CENTER, 185, COLOR_PURPLE)
	draw_circle(SCREEN_CENTER, 165, COLOR_PURPLE_DARK.lightened(0.08))
	draw_arc(SCREEN_CENTER, ORBIT_RADIUS, 0.0, TAU, 180, COLOR_BORDER, 5.0)

# ---- Главное меню ----
func setup_main_menu() -> void:
	main_menu.position = Vector2.ZERO
	main_menu.size = Vector2(1080, 1920)
	for child in main_menu.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "NUMBER"
	title.position = Vector2(0, 330)
	title.size = Vector2(1080, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	main_menu.add_child(title)

	var orbit_title := Label.new()
	orbit_title.text = "ORBIT"
	orbit_title.position = Vector2(0, 420)
	orbit_title.size = Vector2(1080, 90)
	orbit_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	orbit_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orbit_title.add_theme_font_size_override("font_size", 76)
	orbit_title.add_theme_color_override("font_color", COLOR_PURPLE)
	main_menu.add_child(orbit_title)

	var play_btn := Button.new()
	play_btn.name = "PlayButton"
	play_btn.position = Vector2(220, 760)
	play_btn.size = Vector2(640, 120)
	play_btn.add_theme_font_size_override("font_size", 42)
	make_primary_button(play_btn)
	play_btn.pressed.connect(_on_play_pressed)
	main_menu.add_child(play_btn)

	var levels_btn := Button.new()
	levels_btn.text = "▦  " + text_for("Levels", "Уровни")
	levels_btn.position = Vector2(220, 920)
	levels_btn.size = Vector2(640, 110)
	levels_btn.add_theme_font_size_override("font_size", 38)
	make_menu_button(levels_btn)
	levels_btn.pressed.connect(_on_levels_pressed)
	main_menu.add_child(levels_btn)

	var settings_btn := Button.new()
	settings_btn.text = "⚙  " + text_for("Settings", "Настройки")
	settings_btn.position = Vector2(220, 1060)
	settings_btn.size = Vector2(640, 110)
	settings_btn.add_theme_font_size_override("font_size", 38)
	make_menu_button(settings_btn)
	settings_btn.pressed.connect(_on_settings_pressed)
	main_menu.add_child(settings_btn)

func update_play_button_label() -> void:
	var play_btn: Button = main_menu.get_node("PlayButton")
	if has_played and current_level > 1:
		play_btn.text = "▶  " + text_for("Continue", "Продолжить")
	else:
		play_btn.text = "▶  " + text_for("Play", "Играть")

func make_menu_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#FFFFFF")
	normal.border_color = COLOR_BORDER
	normal.border_width_left = 3
	normal.border_width_right = 3
	normal.border_width_top = 3
	normal.border_width_bottom = 3
	normal.corner_radius_top_left = 26
	normal.corner_radius_top_right = 26
	normal.corner_radius_bottom_left = 26
	normal.corner_radius_bottom_right = 26
	var hover := normal.duplicate()
	hover.bg_color = Color("#F1ECFF")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("#E8DDFF")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", COLOR_TEXT)

func make_primary_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_PURPLE
	normal.border_color = COLOR_PURPLE_DARK
	normal.border_width_bottom = 5
	normal.corner_radius_top_left = 28
	normal.corner_radius_top_right = 28
	normal.corner_radius_bottom_left = 28
	normal.corner_radius_bottom_right = 28
	var hover := normal.duplicate()
	hover.bg_color = COLOR_PURPLE.lightened(0.05)
	var pressed := normal.duplicate()
	pressed.bg_color = COLOR_PURPLE_DARK
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color.WHITE)

func make_label_pill(label: Label) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#FFFFFF")
	panel.border_color = COLOR_BORDER
	panel.border_width_left = 2
	panel.border_width_right = 2
	panel.border_width_top = 2
	panel.border_width_bottom = 2
	panel.corner_radius_top_left = 28
	panel.corner_radius_top_right = 28
	panel.corner_radius_bottom_left = 28
	panel.corner_radius_bottom_right = 28
	label.add_theme_stylebox_override("normal", panel)

func make_card_style(bg: Color, border: Color, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func setup_operation_legend() -> void:
	for child in operation_legend_panel.get_children():
		child.queue_free()
	var cards := [
		{"name": "Add", "desc": "increases", "op": "add", "pos": Vector2(0, 0)},
		{"name": "Subtract", "desc": "decreases", "op": "subtract", "pos": Vector2(505, 0)},
		{"name": "Multiply", "desc": "bigger", "op": "multiply", "pos": Vector2(0, 86)},
		{"name": "Divide", "desc": "smaller", "op": "divide", "pos": Vector2(505, 86)}
	]
	for data in cards:
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.position = data["pos"]
		panel.size = Vector2(465, 72)
		panel.add_theme_stylebox_override("panel", operation_card_style(data["op"]))
		operation_legend_panel.add_child(panel)

		var symbol := Label.new()
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		symbol.text = op_symbol(data["op"])
		symbol.position = Vector2(25, 8)
		symbol.size = Vector2(55, 55)
		symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		symbol.add_theme_font_size_override("font_size", 36)
		symbol.add_theme_color_override("font_color", operation_text_color(data["op"]))
		panel.add_child(symbol)

		var name_lbl := Label.new()
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.text = data["name"]
		name_lbl.position = Vector2(95, 10)
		name_lbl.size = Vector2(330, 28)
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.add_theme_color_override("font_color", operation_text_color(data["op"]))
		panel.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc_lbl.text = "(" + data["desc"] + ")"
		desc_lbl.position = Vector2(95, 38)
		desc_lbl.size = Vector2(340, 24)
		desc_lbl.add_theme_font_size_override("font_size", 16)
		desc_lbl.add_theme_color_override("font_color", COLOR_MUTED)
		panel.add_child(desc_lbl)

func operation_card_style(op: String) -> StyleBoxFlat:
	match op:
		"divide":
			return make_card_style(Color("#EEF7FF"), Color("#BBDFFF"))
		"multiply":
			return make_card_style(Color("#FFF1F1"), Color("#FFD0D0"))
		"add":
			return make_card_style(Color("#F2FFF0"), Color("#CDEFC6"))
		"subtract":
			return make_card_style(Color("#FFF9E8"), Color("#F4DF9D"))
	return make_card_style(Color.WHITE, COLOR_BORDER)

func operation_text_color(op: String) -> Color:
	match op:
		"divide":
			return Color("#246DAD")
		"multiply":
			return Color("#F04A45")
		"add":
			return Color("#19A33A")
		"subtract":
			return Color("#E0A000")
	return COLOR_TEXT

# ---- Выбор уровней ----
func setup_level_screen() -> void:
	level_screen.position = Vector2.ZERO
	level_screen.size = Vector2(1080, 1920)
	for child in level_screen.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = text_for("LEVELS", "УРОВНИ")
	title.position = Vector2(0, 95)
	title.size = Vector2(1080, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	level_screen.add_child(title)

	var subtitle := Label.new()
	subtitle.text = ""
	subtitle.position = Vector2(0, 190)
	subtitle.size = Vector2(1080, 80)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 42)
	subtitle.add_theme_color_override("font_color", Color("#6D637A"))
	level_screen.add_child(subtitle)

	var back := Button.new()
	back.text = text_for("← Back", "← Назад")
	back.size = Vector2(170, 75)
	back.position = Vector2(455, 1740)
	back.add_theme_font_size_override("font_size", 28)
	make_back_button_style(back)
	back.pressed.connect(_on_level_screen_back_pressed)
	level_screen.add_child(back)

	var start_x := 190
	var start_y := 250
	var gap_x := 245
	var gap_y := 215
	var button_size := Vector2(185, 175)

	for i in range(LEVEL_COUNT):
		var level_number := i + 1
		var unlocked := is_level_unlocked(level_number)
		var btn := Button.new()
		btn.text = str(level_number)
		btn.size = button_size
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		var col := i % 3
		var row := int(float(i) / 3.0)
		btn.position = Vector2(start_x + col * gap_x, start_y + row * gap_y)
		btn.add_theme_font_size_override("font_size", 42)
		btn.disabled = not unlocked
		make_level_button(btn, star_ratings[i] > 0, unlocked)
		if unlocked:
			btn.pressed.connect(_on_level_button_pressed.bind(level_number))
		# звёзды
		var star_lbl := Label.new()
		star_lbl.name = "StarLabel"
		star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star_lbl.position = Vector2(0, button_size.y - 58)
		star_lbl.size = Vector2(button_size.x, 40)
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star_lbl.add_theme_font_size_override("font_size", 28)
		star_lbl.add_theme_color_override("font_color", COLOR_GOLD if unlocked else Color("#9EA3B2"))
		star_lbl.text = stars_to_string(star_ratings[i]) if unlocked else "🔒"
		btn.add_child(star_lbl)
		level_screen.add_child(btn)

func is_level_unlocked(level_number: int) -> bool:
	return level_number <= max_unlocked_level

func make_level_button(button: Button, completed: bool = false, unlocked: bool = true) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#EFFBEA") if completed else Color("#FFFFFF")
	if not unlocked:
		normal.bg_color = Color("#FCFBF8")
	normal.border_color = Color("#9EDB8F") if completed else COLOR_BORDER
	normal.border_width_left = 3
	normal.border_width_right = 3
	normal.border_width_top = 3
	normal.border_width_bottom = 3
	normal.corner_radius_top_left = 24
	normal.corner_radius_top_right = 24
	normal.corner_radius_bottom_left = 24
	normal.corner_radius_bottom_right = 24
	var hover := normal.duplicate()
	hover.bg_color = Color("#F1ECFF")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("#DED6EA")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color("#0F6B25") if completed else COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", Color("#9EA3B2"))

func make_back_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#FFFFFF")
	normal.border_color = COLOR_BORDER
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 26
	normal.corner_radius_top_right = 26
	normal.corner_radius_bottom_left = 26
	normal.corner_radius_bottom_right = 26
	var hover := normal.duplicate()
	hover.bg_color = Color("#F1ECFF")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("#DED6EA")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", COLOR_TEXT)

func stars_to_string(count: int) -> String:
	var s := ""
	for i in range(count):
		s += "★"
	for j in range(3 - count):
		s += "☆"
	return s

func format_number(value: int) -> String:
	var text := str(value)
	var result := ""
	var counter := 0
	for i in range(text.length() - 1, -1, -1):
		if counter > 0 and counter % 3 == 0:
			result = "," + result
		result = text.substr(i, 1) + result
		counter += 1
	return result

func _on_level_screen_back_pressed() -> void:
	show_main_menu()

func _on_level_button_pressed(level_number: int) -> void:
	load_level(level_number)
	has_played = true
	show_game_screen()

# ---- Настройки ----
func setup_settings_screen() -> void:
	settings_screen.position = Vector2.ZERO
	settings_screen.size = Vector2(1080, 1920)
	for child in settings_screen.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = text_for("Settings", "Настройки")
	title.position = Vector2(0, 95)
	title.size = Vector2(1080, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	settings_screen.add_child(title)

	var music_lbl := Label.new()
	music_lbl.text = "♫  " + text_for("MUSIC VOLUME", "Громкость музыки")
	music_lbl.position = Vector2(150, 310)
	music_lbl.size = Vector2(780, 60)
	music_lbl.add_theme_font_size_override("font_size", 30)
	music_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	settings_screen.add_child(music_lbl)

	var music_slider := HSlider.new()
	music_slider.name = "MusicSlider"
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = 70
	music_slider.position = Vector2(150, 390)
	music_slider.size = Vector2(720, 60)
	settings_screen.add_child(music_slider)

	var music_value := Label.new()
	music_value.text = "70%"
	music_value.position = Vector2(930, 390)
	music_value.size = Vector2(95, 60)
	music_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	music_value.add_theme_font_size_override("font_size", 26)
	music_value.add_theme_color_override("font_color", COLOR_TEXT)
	settings_screen.add_child(music_value)

	var sound_lbl := Label.new()
	sound_lbl.text = "♬  " + text_for("SOUND VOLUME", "Громкость звука")
	sound_lbl.position = Vector2(150, 560)
	sound_lbl.size = Vector2(780, 60)
	sound_lbl.add_theme_font_size_override("font_size", 30)
	sound_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	settings_screen.add_child(sound_lbl)

	var sound_slider := HSlider.new()
	sound_slider.name = "SoundSlider"
	sound_slider.min_value = 0
	sound_slider.max_value = 100
	sound_slider.value = 80
	sound_slider.position = Vector2(150, 640)
	sound_slider.size = Vector2(720, 60)
	settings_screen.add_child(sound_slider)

	var sound_value := Label.new()
	sound_value.text = "80%"
	sound_value.position = Vector2(930, 640)
	sound_value.size = Vector2(95, 60)
	sound_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sound_value.add_theme_font_size_override("font_size", 26)
	sound_value.add_theme_color_override("font_color", COLOR_TEXT)
	settings_screen.add_child(sound_value)

	var back_btn := Button.new()
	back_btn.text = text_for("← Back", "← Назад")
	back_btn.position = Vector2(405, 1740)
	back_btn.size = Vector2(270, 75)
	back_btn.add_theme_font_size_override("font_size", 28)
	make_back_button_style(back_btn)
	back_btn.pressed.connect(_on_settings_back_pressed)
	settings_screen.add_child(back_btn)

func _on_settings_back_pressed() -> void:
	if return_to_game_after_settings:
		return_to_game_after_settings = false
		show_game_screen()
	else:
		show_main_menu()

func style_slider(slider: HSlider) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color("#E9E4DE")
	base.corner_radius_top_left = 6
	base.corner_radius_top_right = 6
	base.corner_radius_bottom_left = 6
	base.corner_radius_bottom_right = 6
	var fill := base.duplicate()
	fill.bg_color = COLOR_PURPLE
	slider.add_theme_stylebox_override("slider", base)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_icon_override("grabber", make_slider_grabber(COLOR_PURPLE))
	slider.add_theme_icon_override("grabber_highlight", make_slider_grabber(COLOR_PURPLE.lightened(0.08)))

func make_slider_grabber(color: Color) -> ImageTexture:
	var image := Image.create(44, 44, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(44):
		for x in range(44):
			var distance := Vector2(x - 22, y - 22).length()
			if distance <= 20:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

# ---- Попап завершения уровня ----
func setup_level_complete_popup() -> void:
	popup.position = Vector2(120, 610)
	popup.size = Vector2(840, 690)
	popup.z_index = 60
	popup.visible = false
	popup_overlay.visible = false
	for child in popup.get_children():
		child.queue_free()

	var panel := Panel.new()
	panel.size = popup.size
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFFFF")
	sb.border_color = COLOR_BORDER
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 34
	sb.corner_radius_top_right = 34
	sb.corner_radius_bottom_left = 34
	sb.corner_radius_bottom_right = 34
	panel.add_theme_stylebox_override("panel", sb)
	popup.add_child(panel)

	var title := Label.new()
	title.name = "PopupTitle"
	title.text = ""
	title.position = Vector2(0, 90)
	title.size = Vector2(840, 110)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	popup.add_child(title)

	var moves_lbl := Label.new()
	moves_lbl.name = "PopupMoves"
	moves_lbl.text = ""
	moves_lbl.position = Vector2(0, 330)
	moves_lbl.size = Vector2(840, 60)
	moves_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	moves_lbl.add_theme_font_size_override("font_size", 28)
	moves_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	popup.add_child(moves_lbl)

	var stars_lbl := Label.new()
	stars_lbl.name = "PopupStars"
	stars_lbl.text = ""
	stars_lbl.position = Vector2(0, 230)
	stars_lbl.size = Vector2(840, 90)
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stars_lbl.add_theme_font_size_override("font_size", 80)
	stars_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	popup.add_child(stars_lbl)

	var next_btn := Button.new()
	next_btn.name = "PopupNext"
	next_btn.position = Vector2(130, 470)
	next_btn.size = Vector2(580, 100)
	next_btn.add_theme_font_size_override("font_size", 34)
	make_primary_button(next_btn)
	next_btn.pressed.connect(_on_popup_next_pressed)
	popup.add_child(next_btn)

	var levels_btn := Button.new()
	levels_btn.name = "PopupLevels"
	levels_btn.text = text_for("Back to Levels", "К уровням")
	levels_btn.position = Vector2(130, 590)
	levels_btn.size = Vector2(580, 80)
	levels_btn.add_theme_font_size_override("font_size", 28)
	make_menu_button(levels_btn)
	levels_btn.pressed.connect(_on_popup_levels_pressed)
	popup.add_child(levels_btn)

func show_level_complete_popup(stars: int) -> void:
	var title: Label = popup.get_node("PopupTitle")
	var moves_lbl: Label = popup.get_node("PopupMoves")
	var stars_lbl: Label = popup.get_node("PopupStars")

	title.text = text_for("LEVEL %d\nCOMPLETE!", "УРОВЕНЬ %d ПРОЙДЕН") % current_level
	moves_lbl.text = text_for("Moves: %d", "Ходы: %d") % moves_used
	stars_lbl.text = stars_to_string(stars)
	var next_btn: Button = popup.get_node("PopupNext")
	if current_level < LEVEL_COUNT:
		next_btn.text = text_for("Next Level", "Следующий")
		next_btn.visible = true
	else:
		next_btn.visible = false
	popup_overlay.visible = true
	popup.visible = true
	queue_redraw()

func _on_popup_next_pressed() -> void:
	popup.visible = false
	popup_overlay.visible = false
	if current_level < LEVEL_COUNT:
		load_level(current_level + 1)
		show_game_screen()
	else:
		show_level_screen()

func _on_popup_levels_pressed() -> void:
	popup.visible = false
	popup_overlay.visible = false
	show_level_screen()

# ---- Кнопка назад для игры ----
func setup_back_button() -> void:
	back_button = Button.new()
	back_button.text = "←"
	back_button.position = Vector2(55, 55)
	back_button.size = Vector2(70, 70)
	back_button.add_theme_font_size_override("font_size", 36)
	make_back_button_style(back_button)
	back_button.pressed.connect(_on_game_back_pressed)
	add_child(back_button)

	game_settings_button = Button.new()
	game_settings_button.text = "⚙"
	game_settings_button.position = Vector2(955, 55)
	game_settings_button.size = Vector2(70, 70)
	game_settings_button.add_theme_font_size_override("font_size", 30)
	make_back_button_style(game_settings_button)
	game_settings_button.pressed.connect(_on_game_settings_pressed)
	add_child(game_settings_button)

	restart_button = Button.new()
	restart_button.text = "Restart"
	restart_button.position = Vector2(380, 1410)
	restart_button.size = Vector2(320, 72)
	restart_button.add_theme_font_size_override("font_size", 28)
	make_menu_button(restart_button)
	restart_button.pressed.connect(_on_restart_level_pressed)
	add_child(restart_button)

func _on_game_back_pressed() -> void:
	if popup.visible:
		return
	show_level_screen()

func _on_game_settings_pressed() -> void:
	if popup.visible:
		return
	return_to_game_after_settings = true
	show_settings_screen()

func _on_restart_level_pressed() -> void:
	if popup.visible:
		return
	popup.visible = false
	popup_overlay.visible = false
	load_level(current_level)
	show_game_screen()

# ---- Показ нужных экранов ----
func show_main_menu() -> void:
	update_play_button_label()
	settings_screen.visible = false
	level_screen.visible = false
	popup.visible = false
	popup_overlay.visible = false
	orbit.visible = false
	center_label.visible = false
	goal_label.visible = false
	task_label.visible = false
	operation_info_label.visible = false
	star_info_label.visible = false
	operation_legend_panel.visible = false
	back_button.visible = false
	game_settings_button.visible = false
	restart_button.visible = false
	main_menu.visible = true
	setup_level_screen() # обновим звезды
	queue_redraw()

func show_level_screen() -> void:
	settings_screen.visible = false
	main_menu.visible = false
	popup.visible = false
	popup_overlay.visible = false
	orbit.visible = false
	center_label.visible = false
	goal_label.visible = false
	task_label.visible = false
	operation_info_label.visible = false
	star_info_label.visible = false
	operation_legend_panel.visible = false
	back_button.visible = false
	game_settings_button.visible = false
	restart_button.visible = false
	level_screen.visible = true
	setup_level_screen()
	queue_redraw()

func show_settings_screen() -> void:
	settings_screen.visible = true
	level_screen.visible = false
	main_menu.visible = false
	popup.visible = false
	popup_overlay.visible = false
	orbit.visible = false
	center_label.visible = false
	goal_label.visible = false
	task_label.visible = false
	operation_info_label.visible = false
	star_info_label.visible = false
	operation_legend_panel.visible = false
	back_button.visible = false
	game_settings_button.visible = false
	restart_button.visible = false
	queue_redraw()

func show_game_screen() -> void:
	main_menu.visible = false
	level_screen.visible = false
	settings_screen.visible = false
	popup.visible = false
	popup_overlay.visible = false
	orbit.visible = true
	center_label.visible = true
	goal_label.visible = true
	task_label.visible = true
	operation_info_label.visible = true
	star_info_label.visible = true
	operation_legend_panel.visible = true
	back_button.visible = true
	game_settings_button.visible = true
	restart_button.visible = true
	queue_redraw()

# ---- Обработчики главного меню ----
func _on_play_pressed() -> void:
	if not has_played:
		current_level = 1
	load_level(current_level)
	has_played = true
	show_game_screen()

func _on_levels_pressed() -> void:
	show_level_screen()

func _on_settings_pressed() -> void:
	return_to_game_after_settings = false
	show_settings_screen()

# ---- Загрузка уровня ----
func load_level(level_number: int) -> void:
	current_level = level_number
	var data = levels[level_number - 1]
	current_number = data["start"]
	target_number = data["target"]
	moves_used = 0
	orbit_items.clear()
	if data.has("sequence") and data["sequence"].size() >= ORBIT_COUNT:
		# Начальная последовательность
		orbit_items = data["sequence"].duplicate()
	else:
		generate_unique_orbit_items()
	create_orbit_buttons()
	update_labels()

func allowed_ops_for_current_level() -> Array:
	var data = levels[current_level - 1]
	if data.has("allowed_ops"):
		return data["allowed_ops"].duplicate()
	return possible_ops.duplicate()

func valid_numbers_for_op(op: String) -> Array:
	var numbers: Array = []
	for n in possible_numbers:
		match op:
			"divide":
				if n != 0 and current_number % n == 0:
					numbers.append(n)
			"subtract":
				if current_number - n >= 1:
					numbers.append(n)
			_:
				numbers.append(n)
	return numbers

func make_random_orbit_item(used: Dictionary) -> Dictionary:
	var allowed_ops := allowed_ops_for_current_level()
	var available: Array = []
	for op in allowed_ops:
		var nums := valid_numbers_for_op(op)
		for n in nums:
			var key := "%s_%d" % [op, n]
			if not used.has(key):
				available.append({"value": n, "op": op})
	if available.size() == 0:
		for op in allowed_ops:
			var nums := valid_numbers_for_op(op)
			for n in nums:
				available.append({"value": n, "op": op})
	if available.size() == 0:
		return {"value": 2, "op": "add"}
	return available.pick_random()

# ---- Генерация уникальных операций для орбиты ----
func generate_unique_orbit_items() -> void:
	orbit_items.clear()
	var used := {}
	for i in range(ORBIT_COUNT):
		var item := make_random_orbit_item(used)
		var key := "%s_%d" % [item["op"], item["value"]]
		used[key] = true
		orbit_items.append(item)

# ---- Создание кнопок на орбите ----
func create_orbit_buttons() -> void:
	for child in orbit.get_children():
		child.queue_free()
	for item in orbit_items:
		var btn := Button.new()
		btn.text = str(item["value"])
		btn.size = Vector2(122, 122)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.pivot_offset = btn.size * 0.5
		btn.add_theme_font_size_override("font_size", 46)
		btn.set_meta("value", item["value"])
		btn.set_meta("op", item["op"])
		btn.pressed.connect(_on_orbit_button_pressed.bind(btn))
		make_operation_button(btn, item["op"])
		orbit.add_child(btn)
	update_orbit_positions()

func make_operation_button(button: Button, op: String) -> void:
	var normal := StyleBoxFlat.new()
	normal.corner_radius_top_left = 70
	normal.corner_radius_top_right = 70
	normal.corner_radius_bottom_left = 70
	normal.corner_radius_bottom_right = 70
	normal.border_width_left = 4
	normal.border_width_right = 4
	normal.border_width_top = 4
	normal.border_width_bottom = 4
	match op:
		"divide":
			normal.bg_color = Color("#DCEEFF")
			normal.border_color = Color("#4D9DE0")
			button.add_theme_color_override("font_color", Color("#143B63"))
		"multiply":
			normal.bg_color = Color("#FFE0E0")
			normal.border_color = Color("#F04A45")
			button.add_theme_color_override("font_color", Color("#C82424"))
		"add":
			normal.bg_color = Color("#E5F6DA")
			normal.border_color = Color("#58A94F")
			button.add_theme_color_override("font_color", Color("#184A24"))
		"subtract":
			normal.bg_color = Color("#FFF5D6")
			normal.border_color = Color("#E0A000")
			button.add_theme_color_override("font_color", Color("#B97B00"))
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	var pressed := normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.08)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

func op_symbol(op: String) -> String:
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

# ---- Нажатие по орбитальной кнопке ----
func _on_orbit_button_pressed(button: Button) -> void:
	if is_animating or popup.visible:
		return
	is_animating = true
	moves_used += 1

	var value: int = button.get_meta("value")
	var op: String = button.get_meta("op")

	apply_operation(value, op)
	refresh_invalid_operation_buttons(button)
	update_labels()
	pulse_center()

	# обновляем только нажатую кнопку
	update_single_button(button)
	is_animating = false

# ---- Замена одного элемента ----
func update_single_button(button: Button) -> void:
	# уникальные пары (op, value) среди текущих
	var used: Dictionary = {}
	for b in orbit.get_children():
		var val = b.get_meta("value")
		var op_b = b.get_meta("op")
		var key := "%s_%d" % [op_b, val]
		used[key] = true

	var item := make_random_orbit_item(used)
	var new_op: String = item["op"]
	var new_val: int = item["value"]

	button.set_meta("value", new_val)
	button.set_meta("op", new_op)
	button.text = str(new_val)
	make_operation_button(button, new_op)

func refresh_invalid_operation_buttons(skip_button: Button = null) -> void:
	for child in orbit.get_children():
		var button := child as Button
		if button == null or button == skip_button:
			continue
		var op: String = button.get_meta("op")
		var value: int = button.get_meta("value")
		if op == "divide" and (value == 0 or current_number % value != 0):
			update_single_button(button)
		elif op == "subtract" and current_number - value < 1:
			update_single_button(button)

# ---- Применяем операцию ----
func apply_operation(value: int, op: String) -> void:
	match op:
		"divide":
			if value != 0 and current_number % value == 0:
				current_number = int(float(current_number) / float(value))
		"multiply":
			current_number *= value
		"add":
			current_number += value
		"subtract":
			current_number -= value
	if current_number < 1:
		current_number = 1

# ---- Обновляем метки ----
func update_labels() -> void:
	center_label.text = str(current_number)
	goal_label.text = "LEVEL %d" % current_level
	task_label.text = "%d  →  %d" % [current_number, target_number]
	update_level_description()
	if current_number == target_number:
		level_complete()

func update_level_description() -> void:
	var data = levels[current_level - 1]
	var thresholds: Array = [5, 9, 12]
	if data.has("thresholds"):
		thresholds = data["thresholds"].duplicate()
		thresholds.sort()
	operation_info_label.text = "Moves: %d" % moves_used
	star_info_label.text = "3★ ≤ %d     2★ ≤ %d     1★ %d+" % [thresholds[0], thresholds[1], thresholds[1] + 1]

func level_complete() -> void:
	if popup.visible:
		return
	var data = levels[current_level - 1]
	var thresholds: Array = [5, 9, 12]
	if data.has("thresholds"):
		thresholds = data["thresholds"].duplicate()
		thresholds.sort()  # сортируем
	var stars: int = 1
	if moves_used <= thresholds[0]:
		stars = 3
	elif moves_used <= thresholds[1]:
		stars = 2
	else:
		stars = 1
	if star_ratings[current_level - 1] < stars:
		star_ratings[current_level - 1] = stars
	if current_level < LEVEL_COUNT and max_unlocked_level < current_level + 1:
		max_unlocked_level = current_level + 1
	show_level_complete_popup(stars)

func pulse_center() -> void:
	center_label.scale = Vector2(1.25, 1.25)
	var tween = create_tween()
	tween.tween_property(center_label, "scale", Vector2.ONE, 0.2)

func update_orbit_positions() -> void:
	var count := orbit.get_child_count()
	for i in range(count):
		var b = orbit.get_child(i)
		var angle := TAU * float(i) / float(count) - PI / 2.0 + orbit_angle
		var pos := SCREEN_CENTER + Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS
		b.position = pos - b.size * 0.5
