class_name GameScreen
extends Node2D

const OperationLegendScene = preload("res://scenes/ui/OperationLegend.tscn")
const HintPopupScript = preload("res://scenes/ui/HintPopup.gd")
const CoachOverlayScript = preload("res://scenes/ui/CoachOverlay.gd")
const AudioManagerScript = preload("res://scripts/audio/AudioManager.gd")

signal back_pressed
signal settings_pressed
signal restart_pressed
signal orbit_pressed(value: int, op: String, item_id: String)
signal hint_requested
signal hint_ad_requested

var screen_center := Vector2(603, 1240)
const ORBIT_RADIUS := 388
# Actual orbit radius, recomputed each layout to fill the available band while
# staying within the fixed 1206-wide canvas (set in _apply_layout).
var orbit_radius: float = float(ORBIT_RADIUS)
const EDGE_MARGIN := 67.0
const TOP_BUTTON_Y := 74.0
const TOP_STATUS_Y := 202.0
const TOP_STATUS_SIZE := Vector2(1072, 214)
const TARGET_BUBBLE_SIZE := Vector2(268, 268)
const INFO_LINE_Y := 364.0
const INFO_LINE_SIZE := Vector2(1072, 121)
# Marquee text lane (right of the info icon), rest offset, and edge-fade width.
const INFO_TEXT_LEFT := 150.0
const INFO_CLIP_RIGHT_PAD := 44.0
const INFO_REST_X := 48.0
const INFO_FADE_PX := 44.0
const ACTION_BUTTON_Y := 1518.0
const ACTION_BUTTON_HEIGHT := 174.0
const LEGEND_Y := 1626.0
const CENTER_CIRCLE_DIAMETER := 335
const CENTER_CIRCLE_RADIUS := CENTER_CIRCLE_DIAMETER * 0.5

var center_label: Label
var center_panel: Control
var center_circle: TextureRect
var level_label: Label
var level_bg: Panel
var moves_bg: Panel
var target_panel: Control
var target_circle: TextureRect
var level_hover: Panel
var moves_hover: Panel
var goal_label: Label
var info_panel: Panel
var info_icon: TextureRect
var tutorial_help_label: Label
var _status_notch_shader: Shader
var moves_count_label: Label
var bulbs_button: Button
var restart_button: Button
var back_button: Button
var settings_button: Button
var hint_popup: Control
var operation_legend: OperationLegend
var orbit: Node2D
var center_circle_texture: Texture2D
var orbit_angle := 0.0
var orbit_spin_factor := 1.0
var orbit_spin_tween: Tween
var last_center_number: int = -999999
var level_failed: bool = false
var current_number_value: int = 0
var current_hint_points: int = 0
var current_moves: int = 0
var current_target_value: int = 0
var current_thresholds: Array = []
var current_star_bands: Array = []
var current_is_tutorial := false
var previous_failed_state := false
var tutorial_help_text_current := ""
var coach_overlay: Control
var info_line_error_state: Variant = null
# --- Info-line marquee (single scrolling line: enters from the right, rests 3s,
# exits left into the edge fade, then reverts to the default caption). ---
var info_clip: Control
var info_fade_material: ShaderMaterial
var info_default_text := ""
var info_temp_active := false
var info_marquee_version := 0
var info_marquee_tween: Tween
var hint_highlight_item_id := ""
var hint_highlight_tween: Tween

func _ready() -> void:
	build()
	get_viewport().size_changed.connect(_apply_layout)

# Responsive layout: anchors the top cluster below the safe-area, the action
# row + legend above the home indicator, and centers the orbit in the viewport.
func _apply_layout() -> void:
	if level_bg == null:
		return
	var vp := Layout.viewport_size(self)
	var center_x := vp.x * 0.5
	var top := Layout.content_top(self)
	var bottom := Layout.content_bottom(self)

	var status_x := center_x - TOP_STATUS_SIZE.x * 0.5

	# Header circles at top + 74 — identical to the Levels/Settings header so the
	# Back and gear buttons sit in exactly the same spot across screens.
	if back_button != null:
		back_button.position = Vector2(status_x, top + 74.0)
	if settings_button != null:
		settings_button.position = Vector2(status_x + TOP_STATUS_SIZE.x - 127.0, top + 74.0)

	# Status pill (mockup top+255) + floating target centered on it. The two halves
	# sit side by side, meeting under the target badge.
	var status_y := top + 255.0
	level_bg.position = Vector2(status_x, status_y)
	moves_bg.position = Vector2(status_x + TOP_STATUS_SIZE.x * 0.5, status_y)
	var target_center := Vector2(center_x, status_y + TOP_STATUS_SIZE.y * 0.5)
	target_panel.position = target_center - TARGET_BUBBLE_SIZE * 0.5

	# Info line (mockup top+523).
	var info_y := top + 523.0
	info_panel.position = Vector2(center_x - INFO_LINE_SIZE.x * 0.5, info_y)
	if info_fade_material != null:
		var clip_left := info_panel.position.x + INFO_TEXT_LEFT
		info_fade_material.set_shader_parameter("clip_left", clip_left)
		info_fade_material.set_shader_parameter("clip_right", clip_left + info_clip.size.x)
		info_fade_material.set_shader_parameter("viewport_w", vp.x)

	# Legend + action row anchored to the bottom safe area (mockup offsets from
	# the content-area bottom: chips 134, action row a further 54 above).
	var legend_w := TOP_STATUS_SIZE.x
	operation_legend.set_width(legend_w)
	var legend_h := OperationLegend.CARD_HEIGHT
	var legend_y := Layout.content_bottom_line(self) - legend_h
	operation_legend.position = Vector2(center_x - legend_w * 0.5, legend_y)

	var action_y := legend_y - 54.0 - ACTION_BUTTON_HEIGHT
	if current_is_tutorial:
		bulbs_button.visible = false
		restart_button.position = Vector2(status_x, action_y)
		restart_button.size = Vector2(TOP_STATUS_SIZE.x, ACTION_BUTTON_HEIGHT)
	else:
		bulbs_button.visible = true
		var half := (TOP_STATUS_SIZE.x - 47.0) * 0.5
		bulbs_button.position = Vector2(status_x, action_y)
		bulbs_button.size = Vector2(half, ACTION_BUTTON_HEIGHT)
		restart_button.position = Vector2(status_x + half + 47.0, action_y)
		restart_button.size = Vector2(half, ACTION_BUTTON_HEIGHT)
	bulbs_button.pivot_offset = bulbs_button.size * 0.5
	restart_button.pivot_offset = restart_button.size * 0.5

	# Orbit centered between the info line and the action row; radius fills the
	# band but is capped by the fixed 1206-wide canvas so satellites never leave
	# the content column (mockup radius 388 at reference size).
	var orbit_top := info_y + INFO_LINE_SIZE.y + 20.0
	var orbit_bottom := action_y - 20.0
	screen_center = Vector2(center_x, (orbit_top + orbit_bottom) * 0.5)
	# Grow the orbit until a satellite's OUTER edge sits at SIDE_MARGIN — the same
	# 67px margin as the Back/gear buttons and the LEVEL/MOVES pill — unless the
	# vertical band is the tighter limit (short screens).
	var sat_half := 94.0  # satellite radius
	var max_r_w := center_x - Layout.SIDE_MARGIN - sat_half
	var max_r_v := (orbit_bottom - orbit_top) * 0.5 - sat_half
	orbit_radius = maxf(300.0, minf(max_r_w, max_r_v))
	center_panel.position = screen_center - Vector2(CENTER_CIRCLE_RADIUS, CENTER_CIRCLE_RADIUS)

	# Full-screen overlays cover the whole viewport.
	if hint_popup != null:
		hint_popup.layout_to_viewport(vp)
	if coach_overlay != null:
		coach_overlay.configure_context(coach_context())
		coach_overlay.layout_to_viewport(vp)
	queue_redraw()

func build() -> void:
	clear_hint_highlight()
	for child in get_children():
		child.queue_free()
	# Same fill as the primary Play/Continue button (mockup parity): diagonal
	# PRIMARY_TOP→PRIMARY_BOTTOM gradient.
	center_circle_texture = UIStyles.circle_gradient_texture(CENTER_CIRCLE_DIAMETER, UIStyles.PRIMARY_TOP, UIStyles.PRIMARY_BOTTOM)

	center_panel = Control.new()
	center_panel.size = Vector2(CENTER_CIRCLE_DIAMETER, CENTER_CIRCLE_DIAMETER)
	center_panel.position = screen_center - Vector2(CENTER_CIRCLE_RADIUS, CENTER_CIRCLE_RADIUS)
	center_panel.pivot_offset = center_panel.size * 0.5
	center_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(center_panel)
	center_panel.gui_input.connect(_on_center_panel_input)
	center_panel.mouse_exited.connect(func() -> void: UIStyles.press_hold(center_panel, false))

	center_circle = TextureRect.new()
	center_circle.position = Vector2.ZERO
	center_circle.size = center_panel.size
	center_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_circle.texture = center_circle_texture
	center_circle.stretch_mode = TextureRect.STRETCH_SCALE
	center_panel.add_child(center_circle)

	center_label = Label.new()
	center_label.position = Vector2((CENTER_CIRCLE_DIAMETER - 490) * 0.5, (CENTER_CIRCLE_DIAMETER - 180) * 0.5)
	center_label.size = Vector2(490, 180)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyles.apply_font(center_label, UIStyles.FONT_EXTRABOLD, 101, Color.WHITE)
	center_panel.add_child(center_label)

	# The status pill is TWO independent, self-contained blocks — LEVEL (left) and
	# MOVES (right). Each is a half-width rounded panel whose inner edge is a
	# concave arc cut around the target; fill and border come from one SDF shape.
	# two meet under the target badge, which hides the seam. Kept separate so each
	# can highlight — and later animate — on its own.
	var half_size := Vector2(TOP_STATUS_SIZE.x * 0.5, TOP_STATUS_SIZE.y)
	var notch_c := TARGET_BUBBLE_SIZE.x * 0.5 + 16.0
	var mid_y := TOP_STATUS_SIZE.y * 0.5
	var text_w := half_size.x - notch_c

	# LEFT (LEVEL) — notch cut on the inner (right) edge.
	level_bg = make_status_block(Vector2(EDGE_MARGIN, TOP_STATUS_Y), half_size, Vector2(half_size.x, mid_y), notch_c)
	level_bg.pivot_offset = Vector2(text_w * 0.5, mid_y)
	add_child(level_bg)
	level_hover = make_status_hover(half_size, Vector2(half_size.x, mid_y), notch_c)
	level_bg.add_child(level_hover)
	level_label = make_status_label()
	level_label.position = Vector2(0, 0)
	level_label.size = Vector2(text_w, TOP_STATUS_SIZE.y)
	level_bg.add_child(level_label)
	level_label.gui_input.connect(_on_level_panel_input)
	level_label.mouse_exited.connect(func() -> void: UIStyles.press_hold(level_bg, false))
	UIStyles.attach_hover_tint(level_label, level_hover)

	# RIGHT (MOVES) — notch cut on the inner (left) edge.
	moves_bg = make_status_block(Vector2(EDGE_MARGIN + half_size.x, TOP_STATUS_Y), half_size, Vector2(0, mid_y), notch_c)
	moves_bg.pivot_offset = Vector2(notch_c + text_w * 0.5, mid_y)
	add_child(moves_bg)
	moves_hover = make_status_hover(half_size, Vector2(0, mid_y), notch_c)
	moves_bg.add_child(moves_hover)
	moves_count_label = make_status_label()
	moves_count_label.position = Vector2(notch_c, 0)
	moves_count_label.size = Vector2(text_w, TOP_STATUS_SIZE.y)
	moves_bg.add_child(moves_count_label)
	moves_count_label.gui_input.connect(_on_moves_panel_input)
	moves_count_label.mouse_exited.connect(func() -> void: UIStyles.press_hold(moves_bg, false))
	UIStyles.attach_hover_tint(moves_count_label, moves_hover)

	target_panel = Control.new()
	target_panel.position = Vector2(603, TOP_STATUS_Y + TOP_STATUS_SIZE.y * 0.5) - TARGET_BUBBLE_SIZE * 0.5
	target_panel.size = TARGET_BUBBLE_SIZE
	target_panel.pivot_offset = target_panel.size * 0.5
	target_panel.z_index = 6
	target_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(target_panel)
	target_panel.gui_input.connect(_on_goal_panel_input)
	target_panel.mouse_exited.connect(func() -> void: UIStyles.press_hold(target_panel, false))

	target_circle = TextureRect.new()
	target_circle.position = Vector2.ZERO
	target_circle.size = TARGET_BUBBLE_SIZE
	target_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_circle.texture = UIStyles.circle_gradient_texture(int(TARGET_BUBBLE_SIZE.x), UIStyles.TEAL_TOP, UIStyles.TEAL_BOTTOM)
	target_circle.stretch_mode = TextureRect.STRETCH_SCALE
	target_panel.add_child(target_circle)

	goal_label = Label.new()
	goal_label.position = Vector2.ZERO
	goal_label.size = TARGET_BUBBLE_SIZE
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Light number in BOTH themes (design review) — white reads on the teal bubble.
	UIStyles.apply_font(goal_label, UIStyles.FONT_EXTRABOLD, 74, Color.WHITE)
	target_panel.add_child(goal_label)

	info_panel = Panel.new()
	info_panel.position = Vector2(EDGE_MARGIN, INFO_LINE_Y)
	info_panel.size = INFO_LINE_SIZE
	info_panel.add_theme_stylebox_override("panel", UIStyles.glass_panel(67))
	add_child(info_panel)
	# Reset so the next apply_info_line_style() re-applies font/style: the label is
	# freshly rebuilt here, but the cached error-state would otherwise short-circuit
	# the re-style (leaving a stale font size after a theme rebuild).
	info_line_error_state = null
	# Likewise clear the marquee's cached caption: the label was just recreated
	# empty, so `set_info_default` must repopulate it even if the resting text is
	# unchanged (else a theme/language rebuild leaves the info line blank).
	info_default_text = ""
	info_temp_active = false
	info_icon = UIStyles.icon(UIStyles.ICON_INFO, info_panel, Vector2(90, 35), Vector2(50, 50), UIStyles.PURPLE)

	# Scrolling-text lane, right of the icon, with a screen-space edge fade so the
	# caption dissolves at the left/right just like the level-tile scroll fade.
	info_clip = Control.new()
	info_clip.position = Vector2(INFO_TEXT_LEFT, 0)
	info_clip.size = Vector2(INFO_LINE_SIZE.x - INFO_TEXT_LEFT - INFO_CLIP_RIGHT_PAD, INFO_LINE_SIZE.y)
	info_clip.clip_contents = true
	info_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_fade_material = ShaderMaterial.new()
	var fade_shader := Shader.new()
	fade_shader.code = """
shader_type canvas_item;
uniform float clip_left = 0.0;
uniform float clip_right = 1000.0;
uniform float fade_px = 64.0;
uniform float viewport_w = 1206.0;
void fragment() {
	float x = SCREEN_UV.x * viewport_w;
	float a = smoothstep(clip_left, clip_left + fade_px, x) * smoothstep(clip_right, clip_right - fade_px, x);
	COLOR *= texture(TEXTURE, UV);
	COLOR.a *= a;
}
"""
	info_fade_material.shader = fade_shader
	info_fade_material.set_shader_parameter("fade_px", INFO_FADE_PX)
	info_clip.material = info_fade_material
	info_panel.add_child(info_clip)

	tutorial_help_label = Label.new()
	tutorial_help_label.position = Vector2(info_clip.size.x, 0)
	tutorial_help_label.size = Vector2(info_clip.size.x, INFO_LINE_SIZE.y)
	tutorial_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tutorial_help_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_help_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	tutorial_help_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_help_label.use_parent_material = true
	UIStyles.apply_font(tutorial_help_label, UIStyles.FONT_MEDIUM, 40, UIStyles.MUTED)
	info_clip.add_child(tutorial_help_label)

	back_button = UIStyles.back_button(self, Vector2(EDGE_MARGIN, TOP_BUTTON_Y))
	back_button.pressed.connect(func(): back_pressed.emit())

	settings_button = UIStyles.circle_button(self, Vector2(1206.0 - EDGE_MARGIN - 127.0, TOP_BUTTON_Y), 127.0)
	settings_button.pressed.connect(func(): settings_pressed.emit())
	UIStyles.icon(UIStyles.ICON_GEAR, settings_button, Vector2(33, 33), Vector2(60, 60), UIStyles.TEXT)

	# Text-only Hint / Restart pills (icon-less was a deliberate revert).
	restart_button = Button.new()
	restart_button.text = Locale.t("game.restart", "Restart")
	restart_button.position = Vector2(555, ACTION_BUTTON_Y)
	restart_button.size = Vector2(455, ACTION_BUTTON_HEIGHT)
	restart_button.add_theme_font_size_override("font_size", 47)
	UIStyles.menu_button(restart_button)
	restart_button.pressed.connect(func(): restart_pressed.emit())
	add_child(restart_button)

	bulbs_button = Button.new()
	bulbs_button.text = Locale.t("game.hint", "Hint")
	bulbs_button.position = Vector2(70, ACTION_BUTTON_Y)
	bulbs_button.size = Vector2(455, ACTION_BUTTON_HEIGHT)
	bulbs_button.add_theme_font_size_override("font_size", 47)
	UIStyles.menu_button(bulbs_button)
	bulbs_button.pressed.connect(func():
		if hint_popup != null and hint_popup.has_method("has_cached_result") and hint_popup.has_cached_result():
			hint_requested.emit()
		else:
			hint_popup.show_prompt()
	)
	add_child(bulbs_button)

	operation_legend = OperationLegendScene.instantiate()
	add_child(operation_legend)
	operation_legend.operator_info.connect(func(text: String) -> void: show_temporary_help(text))

	orbit = Node2D.new()
	add_child(orbit)

	hint_popup = HintPopupScript.new()
	add_child(hint_popup)
	hint_popup.build(Layout.viewport_size(self).x)
	hint_popup.hint_requested.connect(func(): hint_requested.emit())
	hint_popup.hint_ad_requested.connect(func(): hint_ad_requested.emit())

	coach_overlay = CoachOverlayScript.new()
	add_child(coach_overlay)
	coach_overlay.build()
	coach_overlay.connect("showing_started", _on_coach_showing_started)
	coach_overlay.connect("hiding_started", _on_coach_hiding_started)
	_apply_layout()

func configure(title_text: String, current_number: int, target_number: int, moves: int, thresholds: Array, star_bands: Array, orbit_items: Array, allowed_ops: Array, failed: bool, hint_points: int, tutorial: bool = false, tutorial_help: String = "", coach_hint: Dictionary = {}) -> void:
	var previous_moves := current_moves
	if moves != previous_moves:
		clear_hint_highlight()
	level_failed = failed
	current_number_value = current_number
	current_hint_points = hint_points
	current_moves = moves
	current_target_value = target_number
	current_thresholds = thresholds.duplicate()
	current_star_bands = star_bands.duplicate(true)
	current_is_tutorial = tutorial
	if hint_popup != null:
		hint_popup.configure_state(current_moves, current_hint_points)
	level_label.text = title_text
	goal_label.text = str(target_number)
	tutorial_help_text_current = fail_comment_text() if failed else (tutorial_help if tutorial else progress_comment_text(moves))
	info_panel.visible = true
	tutorial_help_label.visible = true
	set_info_default(tutorial_help_text_current, failed)
	center_label.text = str(current_number)
	if last_center_number != current_number:
		pop_center_number()
		last_center_number = current_number
	moves_count_label.text = Locale.t("game.moves", "MOVES %d") % moves
	moves_count_label.visible = true
	goal_label.size = TARGET_BUBBLE_SIZE
	operation_legend.configure_ops(allowed_ops)
	operation_legend.visible = true
	bulbs_button.visible = not tutorial
	update_hint_button_label(hint_points)
	_apply_layout()
	if level_failed and not previous_failed_state:
		pulse_failure_controls()
	previous_failed_state = level_failed
	set_orbit_items(orbit_items)
	if tutorial and not coach_hint.is_empty():
		coach_overlay.configure_context(coach_context())
		coach_overlay.show_hint(coach_hint)
	else:
		coach_overlay.hide_hint()
	queue_redraw()

func pop_center_number() -> void:
	UIStyles.pop_scale(center_label, 1.08, 0.08, 0.14)

func pulse_failure_controls() -> void:
	UIStyles.pop_scale(restart_button, 1.04, 0.13, 0.18)

func _on_moves_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		AudioManagerScript.play_ui_tap()
		UIStyles.press_hold(moves_bg, true)
		if current_is_tutorial:
			show_temporary_help(Locale.t("game.tap.moves_tut", "Tutorial moves earn no stars."), false)
		else:
			show_temporary_help(star_requirements_text(), false)
	else:
		UIStyles.press_hold(moves_bg, false)

func _on_level_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		AudioManagerScript.play_ui_tap()
		UIStyles.press_hold(level_bg, true)
		if current_is_tutorial:
			show_temporary_help(Locale.t("game.tap.level_tut", "One step at a time."), false)
		else:
			show_temporary_help(Locale.t("game.tap.level", "Beat this to unlock the next."), false)
	else:
		UIStyles.press_hold(level_bg, false)

func _on_goal_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		AudioManagerScript.play_ui_tap()
		UIStyles.press_hold(target_panel, true)
		show_temporary_help(Locale.t("game.tap.target", "Reach %d using orbit numbers.") % current_target_value, false)
	else:
		UIStyles.press_hold(target_panel, false)

func _on_center_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		AudioManagerScript.play_ui_tap()
		UIStyles.press_hold(center_panel, true)
		show_temporary_help(Locale.t("game.tap.center", "Your number. Moves change it."), false)
	else:
		UIStyles.press_hold(center_panel, false)

func star_requirements_text() -> String:
	if current_star_bands.is_empty() and current_thresholds.size() < 3:
		return Locale.t("game.stars.fewer", "Fewer moves earn more stars.")
	if not current_star_bands.is_empty():
		if current_star_bands.size() == 1 and int((current_star_bands[0] as Dictionary).get("stars", 0)) == 3:
			return Locale.t("game.stars.three_in", "%d moves for 3 stars.") % int((current_star_bands[0] as Dictionary).get("moves", 0))
		var parts: Array[String] = []
		for raw_band in current_star_bands:
			var band: Dictionary = raw_band as Dictionary
			parts.append("%s %d" % [star_text(int(band.get("stars", 1))), int(band.get("moves", 0))])
		return " · ".join(parts)
	if current_thresholds[0] == current_thresholds[1] and current_thresholds[1] == current_thresholds[2]:
		return Locale.t("game.stars.keep3", "Finish to keep 3 stars.")
	return "★★★ %d · ★★ %d · ★ %d" % [int(current_thresholds[0]), int(current_thresholds[1]), int(current_thresholds[2])]

func star_text(count: int) -> String:
	match count:
		3:
			return "★★★"
		2:
			return "★★"
	return "★"

func progress_comment_text(moves: int) -> String:
	if current_thresholds.size() < 3:
		return Locale.t("game.info", "Tap orbit numbers to reach the target.")
	if not current_star_bands.is_empty():
		if moves == 0:
			return Locale.t("game.info", "Tap orbit numbers to reach the target.")
		for raw_band in current_star_bands:
			var band: Dictionary = raw_band as Dictionary
			if moves <= int(band.get("moves", 0)):
				match int(band.get("stars", 1)):
					3:
						return Locale.t("game.progress.on3", "On track for 3 stars.")
					2:
						return Locale.t("game.progress.on2", "2 stars still in reach.")
					_:
						return Locale.t("game.progress.almost", "Almost there — reach the target.")
		return Locale.t("game.progress.almost", "Almost there — reach the target.")
	var three_star_moves := int(current_thresholds[0])
	var two_star_moves := int(current_thresholds[1])
	if moves == 0:
		return Locale.t("game.info", "Tap orbit numbers to reach the target.")
	if moves <= three_star_moves:
		return Locale.t("game.progress.on3", "On track for 3 stars.")
	if moves <= two_star_moves:
		return Locale.t("game.progress.on2", "2 stars still in reach.")
	return Locale.t("game.progress.almost", "Almost there — reach the target.")

func fail_comment_text() -> String:
	return Locale.t("game.fail", "No moves left — tap Restart.")

func apply_info_line_style(error: bool = false) -> void:
	if info_line_error_state != null and bool(info_line_error_state) == error:
		return
	if error:
		var danger_bg := Color(UIStyles.DANGER_BOTTOM.r, UIStyles.DANGER_BOTTOM.g, UIStyles.DANGER_BOTTOM.b, 0.14)
		var danger_border := Color(UIStyles.DANGER_BOTTOM.r, UIStyles.DANGER_BOTTOM.g, UIStyles.DANGER_BOTTOM.b, 0.5)
		info_panel.add_theme_stylebox_override("panel", UIStyles.card(danger_bg, danger_border, 40))
		UIStyles.apply_font(tutorial_help_label, UIStyles.FONT_SEMIBOLD, 40, UIStyles.DANGER_TEXT)
		if info_icon != null:
			info_icon.modulate = UIStyles.DANGER_TEXT
	else:
		info_panel.add_theme_stylebox_override("panel", UIStyles.glass_panel(40))
		UIStyles.apply_font(tutorial_help_label, UIStyles.FONT_MEDIUM, 40, UIStyles.MUTED)
		if info_icon != null:
			info_icon.modulate = UIStyles.PURPLE
	info_line_error_state = error

func update_hint_button_label(_hint_points: int) -> void:
	if bulbs_button != null:
		bulbs_button.text = Locale.t("game.hint", "Hint")

# A temporary caption (operator tap / panel tap): marquees in, rests 3s, then
# marquees out and the default caption returns.
func show_temporary_help(text: String, _error: bool = false) -> void:
	info_temp_active = true
	_play_info_marquee(text, true, level_failed)

# The resting caption (progress / fail text). Only re-runs the marquee when the
# text actually changes or a temporary message is currently occupying the line.
func set_info_default(text: String, error: bool) -> void:
	var changed := text != info_default_text
	info_default_text = text
	if current_moves == 0 or tutorial_help_label.text == "":
		info_temp_active = false
		set_info_immediate(text, error)
		return
	if changed or info_temp_active:
		info_temp_active = false
		_play_info_marquee(text, false, error)

func set_info_immediate(text: String, error: bool) -> void:
	if tutorial_help_label == null:
		return
	info_marquee_version += 1
	if info_marquee_tween != null and info_marquee_tween.is_valid():
		info_marquee_tween.kill()
	apply_info_line_style(error)
	var new_w := _info_text_width(text)
	tutorial_help_label.text = text
	tutorial_help_label.size = Vector2(new_w, INFO_LINE_SIZE.y)
	tutorial_help_label.position.x = _info_rest_x_for_width(new_w)

func _info_text_width(text: String) -> float:
	return UIStyles.FONT_MEDIUM.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x

func _info_rest_x_for_width(text_width: float) -> float:
	if info_clip == null:
		return INFO_REST_X
	var readable_left := INFO_FADE_PX
	var readable_w := maxf(0.0, info_clip.size.x - INFO_FADE_PX * 2.0)
	if text_width <= readable_w:
		return readable_left + (readable_w - text_width) * 0.5
	return readable_left

func _play_info_marquee(text: String, temp: bool, error: bool) -> void:
	if info_clip == null:
		return
	info_marquee_version += 1
	var v := info_marquee_version
	if info_marquee_tween != null and info_marquee_tween.is_valid():
		info_marquee_tween.kill()
	apply_info_line_style(error)
	var clip_w := info_clip.size.x
	var new_w := _info_text_width(text)
	var cur_out_x := -tutorial_help_label.size.x - 40.0
	var new_out_x := -new_w - 40.0
	info_marquee_tween = create_tween()
	# Slide the current caption out to the left (skip if already off-screen/empty).
	if tutorial_help_label.text != "" and tutorial_help_label.position.x > cur_out_x:
		info_marquee_tween.tween_property(tutorial_help_label, "position:x", cur_out_x, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Swap the text and jump to the right-hand entry point (inside the fade).
	info_marquee_tween.tween_callback(func() -> void:
		if v != info_marquee_version:
			return
		tutorial_help_label.text = text
		tutorial_help_label.size = Vector2(new_w, INFO_LINE_SIZE.y)
		tutorial_help_label.position.x = clip_w
	)
	# Glide in and rest centered between the left/right fades when it fits.
	info_marquee_tween.tween_property(tutorial_help_label, "position:x", _info_rest_x_for_width(new_w), 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if temp:
		info_marquee_tween.tween_interval(3.0)
		info_marquee_tween.tween_property(tutorial_help_label, "position:x", new_out_x, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		info_marquee_tween.tween_callback(func() -> void:
			if v == info_marquee_version:
				info_temp_active = false
				_play_info_marquee(info_default_text, false, level_failed)
		)

# --- Status pill (LEVEL / MOVES) building blocks ------------------------------

# A half-width status block: the straight outer border is the same glass style as
# the rest of the UI; the shader only cuts the target notch and draws that arc.
func make_status_block(pos: Vector2, size: Vector2, notch_center: Vector2, notch_radius: float) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UIStyles.glass_panel(67))
	panel.material = status_notch_material(notch_center, notch_radius, size, UIStyles.GLASS_BORDER)
	return panel

# The hover tint overlay for a status block: a full-size rounded panel shaped by
# the same notch, recolored + faded in on hover (theme-aware via
# UIStyles.fade_hover_tint) so the WHOLE block — arc included — lights up.
func make_status_hover(size: Vector2, notch_center: Vector2, notch_radius: float) -> Panel:
	var overlay := Panel.new()
	overlay.position = Vector2.ZERO
	overlay.size = size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.modulate.a = 0.0
	overlay.add_theme_stylebox_override("panel", status_hover_style())
	overlay.material = status_notch_material(notch_center, notch_radius, size, Color(0, 0, 0, 0))
	return overlay

func status_hover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0)
	UIStyles._set_radius(style, 67)
	return style

# A centered status label (LEVEL / MOVES text). It also handles taps + hover, so
# it is mouse-STOP; the caller sets position/size.
func make_status_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	UIStyles.apply_font(label, UIStyles.FONT_BOLD, 44, UIStyles.STATUSBAR_TEXT)
	return label

# Shared status shape shader material. The panel's own StyleBoxFlat draws the
# normal glass frame; this shader clips the target notch and adds the missing arc
# with the same border color/width. `panel_size` maps UV → pixels.
func status_notch_material(notch_center: Vector2, notch_radius: float, panel_size: Vector2, border_color: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = status_notch_shader()
	mat.set_shader_parameter("notch_center", notch_center)
	mat.set_shader_parameter("notch_radius", notch_radius)
	mat.set_shader_parameter("panel_size", panel_size)
	mat.set_shader_parameter("border_color", border_color)
	return mat

func status_notch_shader() -> Shader:
	if _status_notch_shader == null:
		_status_notch_shader = Shader.new()
		_status_notch_shader.code = """
shader_type canvas_item;
uniform vec2 notch_center = vec2(536.0, 107.0);
uniform float notch_radius = 150.0;
uniform vec2 panel_size = vec2(536.0, 214.0);
uniform vec4 border_color : source_color = vec4(0.0);
uniform float outer_radius = 67.0;
uniform float border_width = 3.0;
uniform float notch_border_width = 3.6;

float rounded_box_sdf(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 p = UV * panel_size;
	float rect_d = rounded_box_sdf(p - panel_size * 0.5, panel_size * 0.5, outer_radius);
	float notch_d = distance(p, notch_center) - notch_radius;
	float shape_d = max(rect_d, -notch_d);
	float alpha = 1.0 - smoothstep(-1.0, 1.0, shape_d);
	float rect_inside = max(-rect_d, 0.0);
	float rect_border = (1.0 - smoothstep(border_width - 1.0, border_width + 1.0, rect_inside)) * alpha;
	float notch_border = (1.0 - smoothstep(notch_border_width - 1.0, notch_border_width + 1.0, notch_d)) * step(0.0, notch_d) * alpha;
	notch_border *= 1.0 - rect_border * 0.82;
	vec4 fill = vec4(COLOR.rgb, COLOR.a * alpha);
	float border_a = notch_border * border_color.a;
	float out_a = border_a + fill.a * (1.0 - border_a);
	vec3 out_rgb = fill.rgb;
	if (out_a > 0.0) {
		out_rgb = (border_color.rgb * border_a + fill.rgb * fill.a * (1.0 - border_a)) / out_a;
	}
	COLOR = vec4(out_rgb, out_a);
}
"""
	return _status_notch_shader

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
			btn.size = Vector2(188, 188)
			btn.pivot_offset = btn.size * 0.5
			btn.add_theme_font_size_override("font_size", 67)
			btn.pressed.connect(_on_orbit_button_pressed.bind(btn))
			UIStyles.add_press_animation(btn)
			orbit.add_child(btn)
			is_new = true
		btn.modulate.a = 1.0
		btn.scale = Vector2.ONE
		btn.set_meta("popping", false)
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
			animate_orbit_disappear(btn)
	update_orbit_positions(false)

func animate_orbit_disappear(button: Button) -> void:
	if button == null or button.is_queued_for_deletion():
		return
	if bool(button.get_meta("popping", false)):
		return
	button.set_meta("popping", true)
	button.disabled = true
	button.pivot_offset = button.size * 0.5
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.16, 1.16), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.72, 0.72), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(button, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		if button == null or button.is_queued_for_deletion():
			return
		button.visible = false
		button.modulate.a = 1.0
		button.scale = Vector2.ONE
		button.set_meta("popping", false)
	)

func find_orbit_button(item_id: String) -> Button:
	for child in orbit.get_children():
		var btn := child as Button
		if btn != null and not btn.is_queued_for_deletion() and str(btn.get_meta("id", "")) == item_id:
			return btn
	return null

func style_operation_button(button: Button, op: String, valid: bool = true) -> void:
	# Satellite matches its operator's chip: fill = plate color, border + number =
	# the plate's TEXT color (easier to tell apart than the old white bubbles).
	var bg: Color = UIStyles.operation_plate(op)
	var border: Color = UIStyles.operation_text(op)
	var text_color: Color = UIStyles.operation_text(op)
	if not valid:
		bg = UIStyles.BG.lerp(Color.WHITE, 0.03) if UIStyles.is_dark() else Color("#F1F0F5")
		border = UIStyles.LOCKED_BORDER
		text_color = UIStyles.DISABLED
	var normal: StyleBoxFlat = UIStyles.card(bg, border, 94)
	normal.border_width_left = 4
	normal.border_width_right = 4
	normal.border_width_top = 4
	normal.border_width_bottom = 4
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	if valid and str(button.get_meta("id", "")) == hint_highlight_item_id:
		apply_hint_shadow(normal, op)
		apply_hint_shadow(hover, op)
		apply_hint_shadow(pressed, op)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_font_override("font", UIStyles.FONT_BOLD)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color)

func apply_hint_shadow(style: StyleBoxFlat, op: String) -> void:
	var shadow := UIStyles.operation_border(op)
	shadow.a = 0.34 if UIStyles.is_dark() else 0.26
	style.shadow_color = shadow
	style.shadow_size = 20
	style.shadow_offset = Vector2.ZERO

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

func reveal_hint_result(message: String, balance: int, target: Dictionary) -> void:
	current_hint_points = balance
	if hint_popup != null and hint_popup.has_method("cache_result"):
		hint_popup.cache_result(message, balance)
	var reveal := func() -> void:
		highlight_hint_target(target)
	if hint_popup != null and hint_popup.visible:
		hint_popup.hide_popup(reveal)
	else:
		reveal.call()

func highlight_hint_target(target: Dictionary) -> void:
	clear_hint_highlight()
	if target.is_empty():
		return
	var item_id := str(target.get("id", ""))
	var button := find_orbit_button(item_id) if not item_id.is_empty() else null
	if button == null:
		button = find_orbit_button_by_move(str(target.get("op", "")), int(target.get("value", 0)))
	if button == null:
		return
	hint_highlight_item_id = str(button.get_meta("id", ""))
	var op := str(button.get_meta("op", target.get("op", "")))
	var value := int(button.get_meta("value", target.get("value", 0)))
	var valid_operation := OperationLogic.can_apply(current_number_value, value, op)
	style_operation_button(button, op, valid_operation)
	if hint_highlight_tween != null and hint_highlight_tween.is_valid():
		hint_highlight_tween.kill()
	button.pivot_offset = button.size * 0.5
	button.scale = Vector2.ONE
	hint_highlight_tween = button.create_tween()
	hint_highlight_tween.tween_property(button, "scale", Vector2(1.035, 1.035), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hint_highlight_tween.tween_property(button, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func find_orbit_button_by_move(op: String, value: int) -> Button:
	for child in orbit.get_children():
		var btn := child as Button
		if btn == null or btn.is_queued_for_deletion():
			continue
		if str(btn.get_meta("op", "")) == op and int(btn.get_meta("value", 0)) == value:
			return btn
	return null

func clear_hint_highlight() -> void:
	if hint_highlight_tween != null and hint_highlight_tween.is_valid():
		hint_highlight_tween.kill()
	hint_highlight_item_id = ""

func _process(delta: float) -> void:
	if not visible:
		return
	var speed := 0.25
	orbit_angle += delta * speed * orbit_spin_factor
	update_orbit_positions(false)
	if coach_overlay != null and coach_overlay.visible:
		coach_overlay.configure_context(coach_context())
		coach_overlay.refresh_spotlight()
	queue_redraw()

func _on_coach_showing_started() -> void:
	stop_orbit_spin_smoothly()

func _on_coach_hiding_started() -> void:
	start_orbit_spin_ramp()

func stop_orbit_spin_smoothly() -> void:
	if orbit_spin_tween != null and orbit_spin_tween.is_valid():
		orbit_spin_tween.kill()
	orbit_spin_tween = create_tween()
	orbit_spin_tween.tween_property(self, "orbit_spin_factor", 0.0, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func start_orbit_spin_ramp() -> void:
	if orbit_spin_tween != null and orbit_spin_tween.is_valid():
		orbit_spin_tween.kill()
	orbit_spin_factor = 0.0
	orbit_spin_tween = create_tween()
	orbit_spin_tween.tween_property(self, "orbit_spin_factor", 1.0, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	if not visible:
		return
	# Slightly wider ring, filled with the purple-button color (mid of the primary
	# gradient) instead of the faint neutral ring.
	var ring_color := UIStyles.PRIMARY_TOP.lerp(UIStyles.PRIMARY_BOTTOM, 0.5)
	ring_color.a = 0.55
	draw_arc(screen_center, orbit_radius, 0.0, TAU, 200, ring_color, 6.0, true)

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
	return screen_center + Vector2(cos(angle), sin(angle)) * orbit_radius

func clear_orbit_buttons() -> void:
	clear_hint_highlight()
	if orbit == null:
		return
	for child in orbit.get_children().duplicate():
		orbit.remove_child(child)
		child.free()

func show_hint_popup() -> void:
	if hint_popup != null:
		hint_popup.show_prompt()

func show_hint_result(message: String, balance: int) -> void:
	current_hint_points = balance
	if hint_popup != null:
		hint_popup.show_result(message, balance)

func show_insufficient_hint_balance(balance: int) -> void:
	current_hint_points = balance
	if hint_popup != null:
		hint_popup.show_insufficient_balance(balance)

func clear_hint_cache() -> void:
	if hint_popup != null:
		hint_popup.clear_cache()

func coach_context() -> Dictionary:
	var op_rects: Array[Rect2] = []
	for i in range(5):
		op_rects.append(operation_card_rect(i))
	return {
		"screen_center": screen_center,
		"target_rect": Rect2(target_panel.position, target_panel.size) if target_panel != null else Rect2(Vector2(540, TOP_STATUS_Y + TOP_STATUS_SIZE.y * 0.5) - TARGET_BUBBLE_SIZE * 0.5, TARGET_BUBBLE_SIZE),
		"orbit_valid_rects": visible_orbit_button_rects(false),
		"orbit_invalid_rects": visible_orbit_button_rects(true),
		"orbit_fallback_rect": Rect2(Vector2(100, 520), Vector2(880, 880)),
		"ops_rect": Rect2(operation_legend.position, operation_legend.size),
		"op_rects": op_rects,
		"hint_rect": Rect2(bulbs_button.position, bulbs_button.size) if bulbs_button != null else Rect2(Vector2(70, ACTION_BUTTON_Y), Vector2(455, ACTION_BUTTON_HEIGHT))
	}

func visible_orbit_button_rects(only_invalid: bool) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if orbit == null:
		return rects
	for child in orbit.get_children():
		var btn := child as Button
		if btn == null or not btn.visible:
			continue
		if bool(btn.get_meta("popping", false)):
			continue
		var is_invalid := btn.disabled
		if only_invalid and not is_invalid:
			continue
		if not only_invalid and is_invalid:
			continue
		rects.append(Rect2(btn.position, btn.size).grow(4))
	return rects

func combined_rect(rects: Array[Rect2], fallback: Rect2) -> Rect2:
	if rects.is_empty():
		return fallback
	var result := rects[0]
	for i in range(1, rects.size()):
		result = result.merge(rects[i])
	return result

func operation_card_rect(index: int) -> Rect2:
	if operation_legend != null and operation_legend.has_method("card_rect"):
		var local_rect: Rect2 = operation_legend.card_rect(index)
		return Rect2(operation_legend.position + local_rect.position, local_rect.size)
	return Rect2(operation_legend.position, Vector2(304, 74))
