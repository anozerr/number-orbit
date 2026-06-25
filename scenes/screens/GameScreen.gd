class_name GameScreen
extends Node2D

const OperationLegendScene = preload("res://scenes/ui/OperationLegend.tscn")

signal back_pressed
signal settings_pressed
signal restart_pressed
signal orbit_pressed(value: int, op: String)

const SCREEN_CENTER := Vector2(540, 960)
const ORBIT_RADIUS := 390

var center_label: Label
var level_label: Label
var task_label: Label
var moves_label: Label
var restart_button: Button
var orbit: Node2D
var orbit_angle := 0.0
var last_center_number: int = -999999

func _ready() -> void:
	build()

func build() -> void:
	for child in get_children():
		child.queue_free()

	center_label = Label.new()
	center_label.position = SCREEN_CENTER - Vector2(220, 80)
	center_label.size = Vector2(440, 160)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(center_label, UIStyles.FONT_BOLD, 110, Color.WHITE)
	add_child(center_label)

	level_label = Label.new()
	level_label.position = Vector2(0, 72)
	level_label.size = Vector2(1080, 60)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(level_label, UIStyles.FONT_BOLD, 30, UIStyles.TEXT)
	add_child(level_label)

	task_label = Label.new()
	task_label.position = Vector2(0, 120)
	task_label.size = Vector2(1080, 90)
	task_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	task_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(task_label, UIStyles.FONT_SEMIBOLD, 54, UIStyles.TEXT)
	add_child(task_label)

	var back := Button.new()
	back.text = ""
	back.position = Vector2(55, 52)
	back.size = Vector2(88, 88)
	back.add_theme_font_size_override("font_size", 36)
	UIStyles.menu_button(back)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	UIStyles.icon(UIStyles.ICON_BACK, back, Vector2(23, 23), Vector2(42, 42), UIStyles.TEXT)

	var settings := Button.new()
	settings.text = ""
	settings.position = Vector2(937, 52)
	settings.size = Vector2(88, 88)
	settings.add_theme_font_size_override("font_size", 30)
	UIStyles.menu_button(settings)
	settings.pressed.connect(func(): settings_pressed.emit())
	add_child(settings)
	UIStyles.icon(UIStyles.ICON_GEAR, settings, Vector2(23, 23), Vector2(42, 42), UIStyles.TEXT)

	moves_label = Label.new()
	moves_label.position = Vector2(70, 1568)
	moves_label.size = Vector2(455, 68)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(moves_label, UIStyles.FONT_SEMIBOLD, 28, UIStyles.TEXT)
	UIStyles.pill(moves_label)
	add_child(moves_label)

	restart_button = Button.new()
	restart_button.text = "Restart"
	restart_button.position = Vector2(555, 1568)
	restart_button.size = Vector2(455, 68)
	restart_button.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(restart_button)
	restart_button.pressed.connect(func(): restart_pressed.emit())
	add_child(restart_button)

	var legend: OperationLegend = OperationLegendScene.instantiate()
	legend.position = Vector2(55, 1710)
	add_child(legend)

	orbit = Node2D.new()
	add_child(orbit)

func configure(level_number: int, current_number: int, target_number: int, moves: int, thresholds: Array, orbit_items: Array) -> void:
	level_label.text = "LEVEL %d" % level_number
	task_label.text = "%d  →  %d" % [current_number, target_number]
	center_label.text = str(current_number)
	if last_center_number != current_number:
		pop_center_number()
		last_center_number = current_number
	moves_label.text = "Moves: %d   %s" % [moves, current_stars_string(moves, thresholds)]
	set_orbit_items(orbit_items)
	queue_redraw()

func pop_center_number() -> void:
	if center_label == null:
		return
	center_label.pivot_offset = center_label.size * 0.5
	var tween: Tween = center_label.create_tween()
	tween.tween_property(center_label, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(center_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func current_stars_string(moves: int, thresholds: Array) -> String:
	if moves <= int(thresholds[0]):
		return "★★★"
	if moves <= int(thresholds[1]):
		return "★★"
	return "★"

func set_orbit_items(items: Array) -> void:
	for child in orbit.get_children():
		child.queue_free()
	for item in items:
		var btn := Button.new()
		var value: int = int(item["value"])
		var op: String = str(item["op"])
		btn.text = str(value)
		btn.size = Vector2(122, 122)
		btn.pivot_offset = btn.size * 0.5
		btn.add_theme_font_size_override("font_size", 46)
		btn.set_meta("value", value)
		btn.set_meta("op", op)
		style_operation_button(btn, op)
		btn.pressed.connect(_on_orbit_button_pressed.bind(btn))
		orbit.add_child(btn)
	update_orbit_positions()

func style_operation_button(button: Button, op: String) -> void:
	var normal: StyleBoxFlat = UIStyles.card(UIStyles.operation_bg(op), UIStyles.operation_border(op), 70)
	normal.border_width_left = 4
	normal.border_width_right = 4
	normal.border_width_top = 4
	normal.border_width_bottom = 4
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.04)
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.08)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_font_override("font", UIStyles.FONT_BOLD)
	button.add_theme_color_override("font_color", UIStyles.operation_text(op))
	button.add_theme_color_override("font_hover_color", UIStyles.operation_text(op))
	button.add_theme_color_override("font_pressed_color", UIStyles.operation_text(op))

func _on_orbit_button_pressed(button: Button) -> void:
	orbit_pressed.emit(int(button.get_meta("value")), str(button.get_meta("op")))

func _process(delta: float) -> void:
	if not visible:
		return
	orbit_angle += delta * 0.25
	update_orbit_positions()
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	draw_circle(SCREEN_CENTER + Vector2(0, 24), 178, Color(0.12, 0.10, 0.22, 0.10))
	draw_circle(SCREEN_CENTER, 176, UIStyles.PURPLE)
	draw_arc(SCREEN_CENTER, ORBIT_RADIUS, 0.0, TAU, 180, Color("#E4DED6"), 4.0)

func update_orbit_positions() -> void:
	var count := orbit.get_child_count()
	for i in range(count):
		var b: Button = orbit.get_child(i)
		var angle := TAU * float(i) / float(count) - PI / 2.0 + orbit_angle
		var pos := SCREEN_CENTER + Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS
		b.position = pos - b.size * 0.5
