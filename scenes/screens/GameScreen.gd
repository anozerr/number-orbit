class_name GameScreen
extends Node2D

const OperationLegendScene = preload("res://scenes/ui/OperationLegend.tscn")

signal back_pressed
signal settings_pressed
signal restart_pressed
signal orbit_pressed(value: int, op: String, item_id: String)
signal hint_requested

const SCREEN_CENTER := Vector2(540, 960)
const ORBIT_RADIUS := 390

class CoachDimMask:
	extends ColorRect

	var holes: Array[Dictionary] = []
	var shader_material: ShaderMaterial

	func _ready() -> void:
		color = Color.WHITE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		shader_material = ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;

uniform vec4 dim_color : source_color = vec4(0.05, 0.06, 0.10, 0.42);
uniform vec2 mask_size = vec2(1080.0, 1920.0);
uniform int hole_count = 0;
uniform vec4 hole_rects[16];
uniform float hole_radii[16];

float rounded_box_sdf(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 p = UV * mask_size;
	float clear_amount = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= hole_count) {
			break;
		}
		vec4 rect = hole_rects[i];
		vec2 half_size = rect.zw * 0.5;
		vec2 center = rect.xy + half_size;
		float radius = min(hole_radii[i], min(half_size.x, half_size.y));
		float dist = rounded_box_sdf(p - center, half_size, radius);
		clear_amount = max(clear_amount, 1.0 - smoothstep(-1.5, 1.5, dist));
	}
	COLOR = dim_color;
	COLOR.a *= 1.0 - clear_amount;
}
"""
		shader_material.shader = shader
		material = shader_material
		_update_shader()

	func set_holes(next_holes: Array[Dictionary]) -> void:
		holes = next_holes
		_update_shader()

	func _update_shader() -> void:
		if shader_material == null:
			return
		var rects := PackedVector4Array()
		var radii := PackedFloat32Array()
		var count: int = min(holes.size(), 16)
		for i in range(16):
			if i < count:
				var hole: Dictionary = holes[i]
				var rect := Rect2()
				if hole.has("rect"):
					rect = hole["rect"]
				rects.append(Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
				radii.append(float(hole.get("radius", 0.0)))
			else:
				rects.append(Vector4.ZERO)
				radii.append(0.0)
		shader_material.set_shader_parameter("mask_size", size)
		shader_material.set_shader_parameter("hole_count", count)
		shader_material.set_shader_parameter("hole_rects", rects)
		shader_material.set_shader_parameter("hole_radii", radii)

var center_label: Label
var level_label: Label
var task_label: Label
var goal_panel: Panel
var goal_label: Label
var goal_divider: ColorRect
var tutorial_help_label: Label
var moves_panel: Panel
var moves_count_label: Label
var moves_stars_label: Label
var status_label: Label
var bulbs_button: Button
var hint_popup: Control
var hint_body_label: Label
var hint_balance_label: Label
var hint_buy_button: Button
var hint_ad_button: Button
var hint_cancel_button: Button
var restart_button: Button
var restart_icon: TextureRect
var operation_legend: OperationLegend
var orbit: Node2D
var center_circle_texture: Texture2D
var orbit_angle := 0.0
var last_center_number: int = -999999
var level_failed: bool = false
var current_number_value: int = 0
var current_hint_points: int = 0
var current_moves: int = 0
var current_target_value: int = 0
var current_thresholds: Array = []
var current_is_tutorial := false
var cached_popup_hint_text: String = ""
var cached_popup_move_index: int = -1
var previous_failed_state := false
var tutorial_help_text_current := ""
var temporary_help_version := 0
var bulbs_button_icon: TextureRect
var bulbs_button_label: Label
var coach_overlay: Control
var coach_dim_mask: CoachDimMask
var coach_panel: Panel
var coach_label: Label
var coach_version := 0
var coach_steps: Array = []
var coach_step_index := 0
var info_text_tween: Tween
var info_line_error_state: Variant = null

func _ready() -> void:
	build()

func _unhandled_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return
	if operation_legend != null:
		operation_legend.close_callout_if_outside(mouse_event.position)

func build() -> void:
	for child in get_children():
		child.queue_free()
	center_circle_texture = UIStyles.circle_gradient_texture(352, UIStyles.PURPLE.lightened(0.14), UIStyles.PURPLE_DARK)

	center_label = Label.new()
	center_label.position = SCREEN_CENTER - Vector2(220, 80)
	center_label.size = Vector2(440, 160)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(center_label, UIStyles.FONT_BOLD, 110, Color.WHITE)
	add_child(center_label)

	level_label = Label.new()
	level_label.position = Vector2(0, 80)
	level_label.size = Vector2(1080, 50)
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

	goal_panel = Panel.new()
	goal_panel.position = Vector2(140, 152)
	goal_panel.size = Vector2(800, 88)
	goal_panel.add_theme_stylebox_override("panel", UIStyles.card(Color("#FFF4CF"), Color("#F0C057"), 28))
	add_child(goal_panel)
	goal_panel.gui_input.connect(_on_goal_panel_input)

	goal_label = Label.new()
	goal_label.position = Vector2(0, 0)
	goal_label.size = Vector2(400, 88)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(goal_label, UIStyles.FONT_BOLD, 38, Color("#8D6100"))
	goal_panel.add_child(goal_label)

	goal_divider = ColorRect.new()
	goal_divider.position = Vector2(399, 18)
	goal_divider.size = Vector2(2, 52)
	goal_divider.color = Color("#EED37B")
	goal_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_panel.add_child(goal_divider)

	tutorial_help_label = Label.new()
	tutorial_help_label.position = Vector2(95, 262)
	tutorial_help_label.size = Vector2(890, 72)
	tutorial_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_help_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(tutorial_help_label, UIStyles.FONT_MEDIUM, 24, UIStyles.MUTED)
	UIStyles.pill(tutorial_help_label)
	add_child(tutorial_help_label)

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

	moves_panel = Panel.new()
	moves_panel.position = Vector2(400, 0)
	moves_panel.size = Vector2(400, 88)
	moves_panel.add_theme_stylebox_override("panel", empty_panel_style())
	goal_panel.add_child(moves_panel)
	moves_panel.gui_input.connect(_on_moves_panel_input)

	moves_count_label = Label.new()
	moves_count_label.position = Vector2(0, 9)
	moves_count_label.size = Vector2(400, 34)
	moves_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(moves_count_label, UIStyles.FONT_SEMIBOLD, 24, UIStyles.TEXT)
	moves_panel.add_child(moves_count_label)

	moves_stars_label = Label.new()
	moves_stars_label.position = Vector2(0, 43)
	moves_stars_label.size = Vector2(400, 36)
	moves_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(moves_stars_label, UIStyles.FONT_BOLD, 28, UIStyles.GOLD)
	moves_panel.add_child(moves_stars_label)

	status_label = Label.new()
	status_label.position = Vector2(70, 1448)
	status_label.size = Vector2(940, 52)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(status_label, UIStyles.FONT_SEMIBOLD, 24, Color("#C82424"))
	status_label.add_theme_stylebox_override("normal", UIStyles.card(Color("#FFF1F1"), Color("#F5B5B5"), 22))
	status_label.visible = false
	add_child(status_label)

	restart_button = Button.new()
	restart_button.text = "     Restart"
	restart_button.position = Vector2(555, 1534)
	restart_button.size = Vector2(455, 68)
	restart_button.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(restart_button)
	restart_button.pressed.connect(func(): restart_pressed.emit())
	add_child(restart_button)
	restart_icon = UIStyles.icon(UIStyles.ICON_RESTART, restart_button, Vector2(126, 19), Vector2(30, 30), UIStyles.TEXT)

	bulbs_button = Button.new()
	bulbs_button.text = ""
	bulbs_button.position = Vector2(70, 1534)
	bulbs_button.size = Vector2(455, 68)
	bulbs_button.add_theme_font_size_override("font_size", 24)
	UIStyles.menu_button(bulbs_button)
	bulbs_button.pressed.connect(show_hint_popup)
	add_child(bulbs_button)
	bulbs_button_icon = UIStyles.icon(UIStyles.ICON_BULB, bulbs_button, Vector2(0, 17), Vector2(34, 34), UIStyles.GOLD)
	bulbs_button_label = Label.new()
	bulbs_button_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bulbs_button_label.position = Vector2.ZERO
	bulbs_button_label.size = bulbs_button.size
	bulbs_button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bulbs_button_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(bulbs_button_label, UIStyles.FONT_BOLD, 24, UIStyles.TEXT)
	bulbs_button.add_child(bulbs_button_label)

	operation_legend = OperationLegendScene.instantiate()
	operation_legend.position = Vector2(55, 1638)
	add_child(operation_legend)

	orbit = Node2D.new()
	add_child(orbit)

	build_hint_popup()
	build_coach_overlay()

func configure(title_text: String, current_number: int, target_number: int, moves: int, thresholds: Array, orbit_items: Array, allowed_ops: Array, failed: bool, hint_points: int, tutorial: bool = false, tutorial_help: String = "", coach_hint: Dictionary = {}) -> void:
	level_failed = failed
	current_number_value = current_number
	current_hint_points = hint_points
	current_moves = moves
	current_target_value = target_number
	current_thresholds = thresholds.duplicate()
	current_is_tutorial = tutorial
	if cached_popup_move_index != current_moves:
		cached_popup_hint_text = ""
		cached_popup_move_index = -1
	level_label.text = title_text
	task_label.text = "%d  →  %d" % [current_number, target_number]
	task_label.visible = false
	goal_label.text = "TARGET  %d" % target_number
	tutorial_help_text_current = fail_comment_text() if failed else (tutorial_help if tutorial else progress_comment_text(moves))
	tutorial_help_label.visible = true
	tutorial_help_label.modulate.a = 1.0
	if info_text_tween != null and info_text_tween.is_valid():
		info_text_tween.kill()
	apply_info_line_style(failed)
	set_info_text_alpha(1.0, failed)
	tutorial_help_label.text = tutorial_help_text_current
	center_label.text = str(current_number)
	if last_center_number != current_number:
		pop_center_number()
		last_center_number = current_number
	moves_count_label.text = "Moves: %d" % moves
	moves_stars_label.text = current_stars_string(moves, thresholds)
	moves_panel.visible = not tutorial
	goal_divider.visible = not tutorial
	goal_label.size = Vector2(800 if tutorial else 400, 88)
	status_label.text = "No valid moves left — tap Restart." if level_failed else ""
	status_label.visible = false
	operation_legend.configure_ops(allowed_ops)
	operation_legend.visible = true
	bulbs_button.visible = not tutorial
	update_hint_button_label(hint_points)
	if tutorial:
		restart_button.position = Vector2(70, 1534)
		restart_button.size = Vector2(940, 68)
		restart_button.text = "     Restart"
		if restart_icon != null:
			restart_icon.position = Vector2(362, 19)
	else:
		restart_button.position = Vector2(555, 1534)
		restart_button.size = Vector2(455, 68)
		restart_button.text = "     Restart"
		if restart_icon != null:
			restart_icon.position = Vector2(126, 19)
	if level_failed and not previous_failed_state:
		pulse_failure_controls()
	previous_failed_state = level_failed
	set_orbit_items(orbit_items)
	if tutorial and not coach_hint.is_empty():
		show_coach_hint(coach_hint)
	else:
		hide_coach_hint()
	queue_redraw()

func pop_center_number() -> void:
	if center_label == null:
		return
	center_label.pivot_offset = center_label.size * 0.5
	var tween: Tween = center_label.create_tween()
	tween.tween_property(center_label, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(center_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func pulse_failure_controls() -> void:
	if restart_button == null:
		return
	var tween := restart_button.create_tween()
	tween.tween_property(restart_button, "scale", Vector2(1.04, 1.04), 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(restart_button, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func current_stars_string(moves: int, thresholds: Array) -> String:
	if moves <= int(thresholds[0]):
		return "★★★"
	if moves <= int(thresholds[1]):
		return "★★"
	return "★"

func _on_moves_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed:
		pop_moves_panel()
		show_temporary_help(star_requirements_text(), false)

func _on_goal_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed:
		pop_goal_panel()
		if current_is_tutorial or (event as InputEventMouseButton).position.x <= 400.0:
			show_temporary_help("Reach %d exactly by tapping orbit numbers in the right order." % current_target_value, false)

func star_requirements_text() -> String:
	if current_thresholds.size() < 3:
		return "Use fewer moves to earn more stars."
	if current_thresholds[0] == current_thresholds[1] and current_thresholds[1] == current_thresholds[2]:
		return "These early levels are simple: finish the target and you keep three stars."
	return "★★★ %d moves    ★★ %d moves    ★ %d moves" % [int(current_thresholds[0]), int(current_thresholds[1]), int(current_thresholds[2])]

func progress_comment_text(moves: int) -> String:
	if current_thresholds.size() < 3:
		return "Choose orbit numbers carefully. Tap Target or Moves for details."
	var three_star_moves := int(current_thresholds[0])
	var two_star_moves := int(current_thresholds[1])
	if moves == 0:
		return "Choose orbit numbers carefully. Tap Target or Moves for details."
	if moves <= three_star_moves:
		return "Good move. You are still on track for three stars."
	if moves <= two_star_moves:
		return "Still good. Two stars are still within reach."
	return "Almost there. Finish the target with the moves you have left."

func fail_comment_text() -> String:
	return "No valid moves left — tap Restart."

func apply_info_line_style(error: bool = false) -> void:
	if info_line_error_state != null and bool(info_line_error_state) == error:
		return
	if error:
		tutorial_help_label.add_theme_stylebox_override("normal", UIStyles.card(Color("#FFF1F1"), Color("#F5B5B5"), 24))
		UIStyles.apply_font(tutorial_help_label, UIStyles.FONT_SEMIBOLD, 24, Color("#C82424"))
	else:
		UIStyles.pill(tutorial_help_label)
		UIStyles.apply_font(tutorial_help_label, UIStyles.FONT_MEDIUM, 24, UIStyles.MUTED)
	info_line_error_state = error

func update_hint_button_label(hint_points: int) -> void:
	if bulbs_button_label == null:
		return
	bulbs_button_label.text = "Hint"
	var label_width: float = bulbs_button_label.get_theme_font("font").get_string_size(bulbs_button_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, bulbs_button_label.get_theme_font_size("font_size")).x
	var group_width := 34.0 + 12.0 + label_width
	if bulbs_button_icon != null:
		bulbs_button_icon.position = Vector2((bulbs_button.size.x - group_width) * 0.5, 17)
	bulbs_button_label.position = Vector2((bulbs_button.size.x - group_width) * 0.5 + 46.0, 0)
	bulbs_button_label.size = Vector2(label_width + 8.0, bulbs_button.size.y)

func pop_moves_panel() -> void:
	if moves_panel == null:
		return
	moves_panel.pivot_offset = moves_panel.size * 0.5
	var tween := moves_panel.create_tween()
	tween.tween_property(moves_panel, "scale", Vector2(1.035, 1.035), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(moves_panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func show_temporary_help(text: String, error: bool = false) -> void:
	temporary_help_version += 1
	var version := temporary_help_version
	tutorial_help_label.visible = true
	if info_text_tween != null and info_text_tween.is_valid():
		info_text_tween.kill()
	apply_info_line_style(error)
	info_text_tween = tutorial_help_label.create_tween()
	info_text_tween.tween_method(set_info_text_alpha.bind(error), 1.0, 0.34, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await info_text_tween.finished
	if version != temporary_help_version:
		return
	tutorial_help_label.text = text
	set_info_text_alpha(0.34, error)
	info_text_tween = tutorial_help_label.create_tween()
	info_text_tween.tween_method(set_info_text_alpha.bind(error), 0.34, 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(3.0).timeout
	if version != temporary_help_version:
		return
	info_text_tween = tutorial_help_label.create_tween()
	info_text_tween.tween_method(set_info_text_alpha.bind(error), 1.0, 0.34, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await info_text_tween.finished
	if version != temporary_help_version:
		return
	tutorial_help_label.text = tutorial_help_text_current
	tutorial_help_label.visible = true
	apply_info_line_style(level_failed)
	set_info_text_alpha(0.34, level_failed)
	info_text_tween = tutorial_help_label.create_tween()
	info_text_tween.tween_method(set_info_text_alpha.bind(level_failed), 0.34, 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func set_info_text_alpha(alpha: float, error: bool = false) -> void:
	var color := Color("#C82424") if error else UIStyles.MUTED
	color.a = alpha
	tutorial_help_label.add_theme_color_override("font_color", color)

func pop_goal_panel() -> void:
	if goal_panel == null:
		return
	goal_panel.pivot_offset = goal_panel.size * 0.5
	var tween := goal_panel.create_tween()
	tween.tween_property(goal_panel, "scale", Vector2(1.035, 1.035), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(goal_panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func empty_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.border_width_left = 0
	style.border_width_right = 0
	style.border_width_top = 0
	style.border_width_bottom = 0
	return style

func set_orbit_items(items: Array) -> void:
	var desired_ids: Dictionary = {}
	for item in items:
		var value: int = int(item["value"])
		var op: String = str(item["op"])
		var item_id: String = str(item.get("id", "%s_%d_%d" % [op, value, orbit.get_child_count()]))
		var slot: int = int(item["slot"]) if item.has("slot") else orbit.get_child_count()
		var slot_count: int = int(item["slot_count"]) if item.has("slot_count") else items.size()
		desired_ids[item_id] = true
		var btn: Button = find_orbit_button(item_id)
		var is_new := false
		if btn == null:
			btn = Button.new()
			btn.size = Vector2(122, 122)
			btn.pivot_offset = btn.size * 0.5
			btn.add_theme_font_size_override("font_size", 46)
			btn.pressed.connect(_on_orbit_button_pressed.bind(btn))
			UIStyles.add_press_animation(btn)
			orbit.add_child(btn)
			is_new = true
		btn.visible = true
		btn.text = str(value)
		btn.set_meta("id", item_id)
		btn.set_meta("value", value)
		btn.set_meta("op", op)
		btn.set_meta("slot", slot)
		btn.set_meta("slot_count", slot_count)
		var target_angle := orbit_angle_for_slot(slot, slot_count)
		if item.has("orbit_target_angle"):
			target_angle = float(item["orbit_target_angle"])
		if is_new or not btn.has_meta("orbit_display_angle"):
			btn.set_meta("orbit_display_angle", target_angle)
		if bool(item.get("orbit_snap_to_target", false)):
			btn.set_meta("orbit_display_angle", target_angle)
		btn.set_meta("orbit_target_angle", target_angle)
		btn.set_meta("orbit_force_clockwise", bool(item.get("orbit_force_clockwise", false)))
		var valid_operation := OperationLogic.can_apply(current_number_value, value, op)
		style_operation_button(btn, op, valid_operation)
		btn.disabled = level_failed or not valid_operation
		if is_new:
			btn.position = orbit_target_position(btn) - btn.size * 0.5
	for child in orbit.get_children():
		var btn := child as Button
		if btn != null and not desired_ids.has(str(btn.get_meta("id"))):
			btn.visible = false
			btn.disabled = true
	update_orbit_positions(false)

func find_orbit_button(item_id: String) -> Button:
	for child in orbit.get_children():
		var btn := child as Button
		if btn != null and not btn.is_queued_for_deletion() and str(btn.get_meta("id", "")) == item_id:
			return btn
	return null

func style_operation_button(button: Button, op: String, valid: bool = true) -> void:
	var bg: Color = UIStyles.operation_bg(op)
	var border: Color = UIStyles.operation_border(op)
	var text_color: Color = UIStyles.operation_text(op)
	if not valid:
		bg = Color("#F2F3F5")
		border = Color("#D5D8E0")
		text_color = Color("#A5ACB8")
	var normal: StyleBoxFlat = UIStyles.card(bg, border, 70)
	normal.border_width_left = 4
	normal.border_width_right = 4
	normal.border_width_top = 4
	normal.border_width_bottom = 4
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_font_override("font", UIStyles.FONT_BOLD)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color)

func _on_orbit_button_pressed(button: Button) -> void:
	if button == null or button.is_queued_for_deletion() or button.disabled:
		return
	var item_id := str(button.get_meta("id", ""))
	if item_id.is_empty():
		return
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.90, 0.90), 0.055).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	orbit_pressed.emit(int(button.get_meta("value")), str(button.get_meta("op")), str(button.get_meta("id", "")))

func _process(delta: float) -> void:
	if not visible:
		return
	if coach_overlay != null and coach_overlay.visible:
		queue_redraw()
		return
	var speed := 0.25
	orbit_angle += delta * speed
	update_orbit_positions(false)
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	if center_circle_texture != null:
		draw_texture_rect(center_circle_texture, Rect2(SCREEN_CENTER - Vector2(176, 176), Vector2(352, 352)), false)
	draw_arc(SCREEN_CENTER, ORBIT_RADIUS, 0.0, TAU, 180, Color("#E4DED6"), 4.0)

func update_orbit_positions(snap: bool = false) -> void:
	for i in range(orbit.get_child_count()):
		var b := orbit.get_child(i) as Button
		if b == null or b.is_queued_for_deletion() or not b.visible:
			continue
		var target := orbit_target_position(b) - b.size * 0.5
		if snap:
			b.set_meta("orbit_display_angle", float(b.get_meta("orbit_target_angle", orbit_angle_for_button(b))))
			b.position = target
		else:
			var current_angle := float(b.get_meta("orbit_display_angle", orbit_angle_for_button(b)))
			var target_angle := float(b.get_meta("orbit_target_angle", orbit_angle_for_button(b)))
			if bool(b.get_meta("orbit_force_clockwise", false)):
				var clockwise_delta: float = fposmod(target_angle - current_angle, TAU)
				if clockwise_delta > PI * 0.75:
					current_angle = current_angle + angle_difference(current_angle, target_angle) * 0.16
				elif clockwise_delta < 0.002:
					current_angle = target_angle
				else:
					current_angle += clockwise_delta * 0.16
			else:
				current_angle = current_angle + angle_difference(current_angle, target_angle) * 0.115
			b.set_meta("orbit_display_angle", current_angle)
			b.position = orbit_position_for_angle(current_angle) - b.size * 0.5

func orbit_target_position(button: Button) -> Vector2:
	return orbit_position_for_angle(orbit_angle_for_button(button))

func orbit_angle_for_button(button: Button) -> float:
	var slot: int = int(button.get_meta("slot")) if button.has_meta("slot") else 0
	var slot_count: int = max(1, int(button.get_meta("slot_count")) if button.has_meta("slot_count") else orbit.get_child_count())
	return orbit_angle_for_slot(slot, slot_count)

func orbit_angle_for_slot(slot: int, slot_count: int) -> float:
	return TAU * float(slot) / float(max(1, slot_count)) - PI / 2.0

func orbit_position_for_angle(angle_without_spin: float) -> Vector2:
	var angle := angle_without_spin + orbit_angle
	return SCREEN_CENTER + Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS

func clear_orbit_buttons() -> void:
	if orbit == null:
		return
	for child in orbit.get_children().duplicate():
		orbit.remove_child(child)
		child.free()

func build_hint_popup() -> void:
	hint_popup = Control.new()
	hint_popup.size = Vector2(1080, 1920)
	hint_popup.visible = false
	add_child(hint_popup)

	var overlay := ColorRect.new()
	overlay.size = Vector2(1080, 1920)
	overlay.color = Color(0.05, 0.06, 0.10, 0.45)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hint_popup.add_child(overlay)

	var panel := Panel.new()
	panel.position = Vector2(110, 625)
	panel.size = Vector2(860, 570)
	panel.add_theme_stylebox_override("panel", UIStyles.soft_panel(Color.WHITE, 36))
	hint_popup.add_child(panel)

	var icon_bg := Panel.new()
	icon_bg.position = Vector2(365, -50)
	icon_bg.size = Vector2(130, 130)
	icon_bg.add_theme_stylebox_override("panel", UIStyles.card(UIStyles.PURPLE, Color.WHITE, 65))
	panel.add_child(icon_bg)
	UIStyles.icon(UIStyles.ICON_BULB, icon_bg, Vector2(36, 36), Vector2(58, 58), Color.WHITE)

	var title := Label.new()
	title.text = "HINT"
	title.position = Vector2(0, 105)
	title.size = Vector2(860, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_BOLD, 38, UIStyles.TEXT)
	panel.add_child(title)

	hint_body_label = Label.new()
	hint_body_label.text = "Spend bulbs to reveal one next move."
	hint_body_label.position = Vector2(95, 178)
	hint_body_label.size = Vector2(670, 120)
	hint_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(hint_body_label, UIStyles.FONT_MEDIUM, 25, UIStyles.MUTED)
	panel.add_child(hint_body_label)

	hint_balance_label = Label.new()
	hint_balance_label.position = Vector2(0, 300)
	hint_balance_label.size = Vector2(860, 42)
	hint_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(hint_balance_label, UIStyles.FONT_SEMIBOLD, 22, UIStyles.TEXT)
	panel.add_child(hint_balance_label)

	hint_buy_button = Button.new()
	hint_buy_button.text = "Use Hint"
	hint_buy_button.position = Vector2(195, 360)
	hint_buy_button.size = Vector2(470, 78)
	hint_buy_button.add_theme_font_size_override("font_size", 27)
	UIStyles.primary_button(hint_buy_button)
	hint_buy_button.pressed.connect(func(): hint_requested.emit())
	panel.add_child(hint_buy_button)

	hint_ad_button = Button.new()
	hint_ad_button.text = "Watch Ad"
	hint_ad_button.position = Vector2(195, 360)
	hint_ad_button.size = Vector2(470, 78)
	hint_ad_button.add_theme_font_size_override("font_size", 27)
	UIStyles.primary_button(hint_ad_button)
	hint_ad_button.visible = false
	panel.add_child(hint_ad_button)

	hint_cancel_button = Button.new()
	hint_cancel_button.text = "Cancel"
	hint_cancel_button.position = Vector2(195, 465)
	hint_cancel_button.size = Vector2(470, 76)
	hint_cancel_button.add_theme_font_size_override("font_size", 27)
	UIStyles.menu_button(hint_cancel_button)
	hint_cancel_button.pressed.connect(func(): hint_popup.visible = false)
	panel.add_child(hint_cancel_button)

func show_hint_popup() -> void:
	if cached_popup_move_index == current_moves and not cached_popup_hint_text.is_empty():
		hint_body_label.text = cached_popup_hint_text
		hint_balance_label.text = "Balance: %d bulbs" % current_hint_points
		hint_buy_button.visible = false
		hint_ad_button.visible = false
		hint_cancel_button.text = "Back"
	else:
		hint_body_label.text = "Spend 80 bulbs to reveal the next winning move."
		hint_balance_label.text = "Balance: %d bulbs" % current_hint_points
		hint_buy_button.visible = true
		hint_ad_button.visible = false
		hint_cancel_button.text = "Cancel"
	hint_popup.visible = true

func show_hint_result(message: String, balance: int) -> void:
	current_hint_points = balance
	cached_popup_hint_text = message
	cached_popup_move_index = current_moves
	hint_body_label.text = message
	hint_balance_label.text = "Balance: %d bulbs" % current_hint_points
	hint_buy_button.visible = false
	hint_ad_button.visible = false
	hint_cancel_button.text = "Back"
	hint_popup.visible = true

func show_insufficient_hint_balance(balance: int) -> void:
	current_hint_points = balance
	cached_popup_hint_text = ""
	cached_popup_move_index = -1
	hint_body_label.text = "Not enough bulbs for a hint."
	hint_balance_label.text = "Balance: %d / %d bulbs" % [current_hint_points, GameState.HINT_COST]
	hint_buy_button.visible = false
	hint_ad_button.visible = true
	hint_cancel_button.text = "Cancel"
	hint_popup.visible = true

func clear_hint_cache() -> void:
	cached_popup_hint_text = ""
	cached_popup_move_index = -1
	if hint_popup != null:
		hint_popup.visible = false

func build_coach_overlay() -> void:
	coach_overlay = Control.new()
	coach_overlay.position = Vector2.ZERO
	coach_overlay.size = Vector2(1080, 1920)
	coach_overlay.visible = false
	coach_overlay.z_index = 90
	coach_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	coach_overlay.gui_input.connect(_on_coach_overlay_input)
	add_child(coach_overlay)

	coach_dim_mask = CoachDimMask.new()
	coach_dim_mask.position = Vector2.ZERO
	coach_dim_mask.size = Vector2(1080, 1920)
	coach_dim_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coach_overlay.add_child(coach_dim_mask)

	coach_panel = Panel.new()
	coach_panel.size = Vector2(760, 112)
	coach_panel.add_theme_stylebox_override("panel", UIStyles.soft_panel(Color.WHITE, 26))
	coach_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coach_panel.z_index = 2
	coach_overlay.add_child(coach_panel)

	coach_label = Label.new()
	coach_label.position = Vector2(34, 16)
	coach_label.size = Vector2(692, 80)
	coach_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coach_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coach_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(coach_label, UIStyles.FONT_SEMIBOLD, 24, UIStyles.TEXT)
	coach_panel.add_child(coach_label)

func show_coach_hint(coach_hint: Dictionary) -> void:
	if coach_overlay == null:
		return
	coach_version += 1
	coach_steps.clear()
	if coach_hint.has("steps"):
		for step in coach_hint["steps"] as Array:
			coach_steps.append(step)
	else:
		coach_steps.append(coach_hint)
	coach_step_index = 0
	apply_coach_step()
	coach_overlay.visible = true
	coach_overlay.modulate.a = 0.0
	var tween := coach_overlay.create_tween()
	tween.tween_property(coach_overlay, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func apply_coach_step() -> void:
	if coach_step_index < 0 or coach_step_index >= coach_steps.size():
		hide_coach_hint()
		return
	var step: Dictionary = coach_steps[coach_step_index] as Dictionary
	var area := str(step.get("area", "target"))
	var rect := coach_rect_for_area(area)
	if coach_dim_mask != null:
		coach_dim_mask.set_holes(coach_holes_for_area(area, rect))
	coach_label.text = str(step.get("text", ""))
	coach_panel.position = coach_panel_position_for_rect(rect)

func coach_holes_for_area(area: String, fallback: Rect2) -> Array[Dictionary]:
	var holes: Array[Dictionary] = []
	match area:
		"none":
			return holes
		"center":
			holes.append({"rect": fallback.grow(4), "radius": fallback.size.x * 0.5 + 4.0})
		"orbit_buttons":
			for orbit_rect in visible_orbit_button_rects(false):
				holes.append({"rect": orbit_rect.grow(8), "radius": orbit_rect.size.x * 0.5 + 8.0})
		"invalid_orbit":
			for invalid_rect in visible_orbit_button_rects(true):
				holes.append({"rect": invalid_rect.grow(8), "radius": invalid_rect.size.x * 0.5 + 8.0})
		"target":
			holes.append({"rect": fallback.grow(5), "radius": 32.0})
		"op_add", "op_subtract", "op_multiply", "op_divide", "op_unavailable", "hint":
			holes.append({"rect": fallback.grow(5), "radius": 20.0})
		_:
			if fallback.size != Vector2.ZERO:
				holes.append({"rect": fallback.grow(5), "radius": 26.0})
	return holes

func _on_coach_overlay_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return
	coach_step_index += 1
	if coach_step_index >= coach_steps.size():
		hide_coach_hint()
	else:
		apply_coach_step()

func fade_coach_overlay_out(version: int) -> void:
	var fade := coach_overlay.create_tween()
	fade.tween_property(coach_overlay, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade.finished
	if version == coach_version:
		coach_overlay.visible = false

func hide_coach_hint() -> void:
	coach_version += 1
	if coach_overlay != null:
		if coach_overlay.visible:
			fade_coach_overlay_out(coach_version)
		else:
			coach_overlay.visible = false

func coach_rect_for_area(area: String) -> Rect2:
	match area:
		"target":
			return Rect2(Vector2(140, 152), Vector2(800, 88))
		"center":
			return Rect2(SCREEN_CENTER - Vector2(176, 176), Vector2(352, 352))
		"orbit":
			return Rect2(Vector2(100, 520), Vector2(880, 880))
		"orbit_buttons":
			return combined_rect(visible_orbit_button_rects(false), Rect2(Vector2(100, 520), Vector2(880, 880))).grow(12)
		"invalid_orbit":
			return combined_rect(visible_orbit_button_rects(true), Rect2(Vector2(100, 520), Vector2(880, 880))).grow(12)
		"ops":
			return Rect2(Vector2(55, 1638), Vector2(970, 235))
		"op_add":
			return operation_card_rect(0)
		"op_subtract":
			return operation_card_rect(1)
		"op_multiply":
			return operation_card_rect(2)
		"op_divide":
			return operation_card_rect(3)
		"op_unavailable":
			return operation_card_rect(4)
		"hint":
			return Rect2(Vector2(70, 1534), Vector2(455, 68))
	return Rect2(Vector2(140, 152), Vector2(800, 88))

func visible_orbit_button_rects(only_invalid: bool) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if orbit == null:
		return rects
	for child in orbit.get_children():
		var btn := child as Button
		if btn == null or not btn.visible:
			continue
		var is_invalid := btn.disabled
		if only_invalid and not is_invalid:
			continue
		if not only_invalid and is_invalid:
			continue
		rects.append(Rect2(btn.position, btn.size).grow(4))
	return rects

func first_invalid_orbit_button_rect() -> Rect2:
	var rects := visible_orbit_button_rects(true)
	return rects[0] if not rects.is_empty() else Rect2()

func combined_rect(rects: Array[Rect2], fallback: Rect2) -> Rect2:
	if rects.is_empty():
		return fallback
	var result := rects[0]
	for i in range(1, rects.size()):
		result = result.merge(rects[i])
	return result

func operation_card_rect(index: int) -> Rect2:
	const CARD_SIZE := Vector2(304, 74)
	const CARD_GAP := 28.0
	var local_pos := Vector2.ZERO
	if index < 3:
		local_pos = Vector2(index * (CARD_SIZE.x + CARD_GAP), 48)
	else:
		local_pos = Vector2((index - 3) * (CARD_SIZE.x + CARD_GAP) + (CARD_SIZE.x + CARD_GAP) * 0.5, 138)
	return Rect2(operation_legend.position + local_pos, CARD_SIZE)

func coach_panel_position_for_rect(rect: Rect2) -> Vector2:
	var y := rect.position.y + rect.size.y + 24.0
	if y + coach_panel.size.y > 1500:
		y = rect.position.y - coach_panel.size.y - 24.0
	return Vector2(clamp(rect.get_center().x - coach_panel.size.x * 0.5, 45.0, 1080.0 - coach_panel.size.x - 45.0), y)
