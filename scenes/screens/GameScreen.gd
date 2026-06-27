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

var center_label: Label
var level_label: Label
var task_label: Label
var goal_panel: Panel
var goal_label: Label
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
var cached_popup_hint_text: String = ""
var cached_popup_move_index: int = -1

func _ready() -> void:
	build()

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

	goal_panel = Panel.new()
	goal_panel.position = Vector2(300, 142)
	goal_panel.size = Vector2(480, 92)
	goal_panel.add_theme_stylebox_override("panel", UIStyles.card(Color("#FFF4CF"), Color("#F0C057"), 28))
	add_child(goal_panel)

	goal_label = Label.new()
	goal_label.position = Vector2(0, 0)
	goal_label.size = goal_panel.size
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(goal_label, UIStyles.FONT_BOLD, 38, Color("#8D6100"))
	goal_panel.add_child(goal_label)

	tutorial_help_label = Label.new()
	tutorial_help_label.position = Vector2(95, 270)
	tutorial_help_label.size = Vector2(890, 82)
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
	moves_panel.position = Vector2(345, 268)
	moves_panel.size = Vector2(390, 94)
	moves_panel.add_theme_stylebox_override("panel", UIStyles.soft_panel(Color.WHITE, 24))
	add_child(moves_panel)

	moves_count_label = Label.new()
	moves_count_label.position = Vector2(0, 10)
	moves_count_label.size = Vector2(390, 36)
	moves_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(moves_count_label, UIStyles.FONT_SEMIBOLD, 24, UIStyles.TEXT)
	moves_panel.add_child(moves_count_label)

	moves_stars_label = Label.new()
	moves_stars_label.position = Vector2(0, 45)
	moves_stars_label.size = Vector2(390, 38)
	moves_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(moves_stars_label, UIStyles.FONT_BOLD, 28, UIStyles.GOLD)
	moves_panel.add_child(moves_stars_label)

	status_label = Label.new()
	status_label.position = Vector2(70, 1488)
	status_label.size = Vector2(940, 58)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(status_label, UIStyles.FONT_SEMIBOLD, 24, Color("#C82424"))
	add_child(status_label)

	restart_button = Button.new()
	restart_button.text = "     Restart"
	restart_button.position = Vector2(555, 1568)
	restart_button.size = Vector2(455, 68)
	restart_button.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(restart_button)
	restart_button.pressed.connect(func(): restart_pressed.emit())
	add_child(restart_button)
	restart_icon = UIStyles.icon(UIStyles.ICON_RESTART, restart_button, Vector2(126, 19), Vector2(30, 30), UIStyles.TEXT)

	bulbs_button = Button.new()
	bulbs_button.text = "     Hint"
	bulbs_button.position = Vector2(70, 1568)
	bulbs_button.size = Vector2(455, 68)
	bulbs_button.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(bulbs_button)
	bulbs_button.pressed.connect(show_hint_popup)
	add_child(bulbs_button)
	UIStyles.icon(UIStyles.ICON_BULB, bulbs_button, Vector2(138, 17), Vector2(34, 34), UIStyles.GOLD)

	operation_legend = OperationLegendScene.instantiate()
	operation_legend.position = Vector2(55, 1710)
	add_child(operation_legend)

	orbit = Node2D.new()
	add_child(orbit)

	build_hint_popup()

func configure(title_text: String, current_number: int, target_number: int, moves: int, thresholds: Array, orbit_items: Array, allowed_ops: Array, failed: bool, hint_points: int, tutorial: bool = false, tutorial_help: String = "") -> void:
	level_failed = failed
	current_number_value = current_number
	current_hint_points = hint_points
	current_moves = moves
	if cached_popup_move_index != current_moves:
		cached_popup_hint_text = ""
		cached_popup_move_index = -1
	level_label.text = title_text
	task_label.text = "%d  →  %d" % [current_number, target_number]
	task_label.visible = false
	goal_label.text = "TARGET  %d" % target_number
	tutorial_help_label.visible = tutorial
	tutorial_help_label.text = tutorial_help
	center_label.text = str(current_number)
	if last_center_number != current_number:
		pop_center_number()
		last_center_number = current_number
	moves_count_label.text = "Moves: %d" % moves
	moves_stars_label.text = current_stars_string(moves, thresholds)
	moves_panel.visible = not tutorial
	status_label.text = "No valid path left. Restart the level." if level_failed else ""
	operation_legend.configure_ops(allowed_ops)
	operation_legend.visible = true
	bulbs_button.visible = not tutorial
	if tutorial:
		restart_button.position = Vector2(70, 1568)
		restart_button.size = Vector2(940, 68)
		restart_button.text = "     Restart"
		if restart_icon != null:
			restart_icon.position = Vector2(362, 19)
	else:
		restart_button.position = Vector2(555, 1568)
		restart_button.size = Vector2(455, 68)
		restart_button.text = "     Restart"
		if restart_icon != null:
			restart_icon.position = Vector2(126, 19)
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
	orbit_pressed.emit(int(button.get_meta("value")), str(button.get_meta("op")), str(button.get_meta("id", "")))

func _process(delta: float) -> void:
	if not visible:
		return
	orbit_angle += delta * 0.25
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
	hint_balance_label.text = "Balance: %d / 80 bulbs" % current_hint_points
	hint_buy_button.visible = false
	hint_ad_button.visible = true
	hint_cancel_button.text = "Cancel"
	hint_popup.visible = true

func clear_hint_cache() -> void:
	cached_popup_hint_text = ""
	cached_popup_move_index = -1
	if hint_popup != null:
		hint_popup.visible = false
