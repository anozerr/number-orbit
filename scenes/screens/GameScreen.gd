class_name GameScreen
extends Node2D

const OperationLegendScene = preload("res://scenes/ui/OperationLegend.tscn")

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
# Coach tooltip (tutorial spotlight). Opaque popup surface, sized to the base
# design system rather than the old pre-redesign 760/font-24 panel.
const COACH_PANEL_WIDTH := 912.0
const COACH_PANEL_PAD := 54.0

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

uniform vec4 dim_color : source_color = vec4(0.03, 0.02, 0.08, 0.5);
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float rim_width = 30.0;
uniform vec2 mask_size = vec2(1206.0, 2622.0);
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
	float rim = 0.0;
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
		// Soft ring hugging the OUTSIDE of the hole edge — defines the focus even
		// when the dim reads weakly (dark theme over a dark background).
		rim = max(rim, smoothstep(rim_width, 1.5, dist) * step(1.5, dist));
	}
	COLOR = dim_color;
	COLOR.a *= 1.0 - clear_amount;
	float rim_a = rim * rim_color.a * (1.0 - clear_amount);
	COLOR.rgb = mix(COLOR.rgb, rim_color.rgb, rim_a);
	COLOR.a = max(COLOR.a, rim_a);
}
"""
		shader_material.shader = shader
		material = shader_material
		_update_shader()

	func set_holes(next_holes: Array[Dictionary]) -> void:
		holes = next_holes
		_update_shader()

	func set_theme_colors(dim: Color, rim: Color) -> void:
		if shader_material == null:
			return
		shader_material.set_shader_parameter("dim_color", dim)
		shader_material.set_shader_parameter("rim_color", rim)

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
var level_bg: Panel
var moves_bg: Panel
var target_panel: Panel
var level_hover: Panel
var moves_hover: Panel
var goal_label: Label
var info_panel: Panel
var info_icon: TextureRect
var tutorial_help_label: Label
var _status_notch_shader: Shader
var moves_count_label: Label
var bulbs_button: Button
var hint_popup: Control
var hint_body_label: Label
var hint_balance_label: Label
var hint_buy_button: Button
var hint_ad_button: Button
var hint_cancel_button: Button
var hint_move_circle: Panel
var hint_move_label: Label
var restart_button: Button
var back_button: Button
var settings_button: Button
var hint_overlay: ColorRect
var hint_panel: Panel
var operation_legend: OperationLegend
var orbit: Node2D
var center_circle_texture: Texture2D
var center_shadow_style: StyleBoxFlat
var orbit_angle := 0.0
var last_center_number: int = -999999
var level_failed: bool = false
var current_number_value: int = 0
var current_hint_points: int = 0
var current_moves: int = 0
var current_target_value: int = 0
var current_thresholds: Array = []
var current_star_bands: Array = []
var current_is_tutorial := false
var cached_popup_hint_text: String = ""
var cached_popup_move_index: int = -1
var previous_failed_state := false
var tutorial_help_text_current := ""
var coach_overlay: Control
var coach_dim_mask: CoachDimMask
var coach_panel: Panel
var coach_label: Label
var coach_version := 0
var coach_steps: Array = []
var coach_step_index := 0
var info_line_error_state: Variant = null
# --- Info-line marquee (single scrolling line: enters from the right, rests 3s,
# exits left into the edge fade, then reverts to the default caption). ---
var info_clip: Control
var info_fade_material: ShaderMaterial
var info_default_text := ""
var info_temp_active := false
var info_marquee_version := 0
var info_marquee_tween: Tween

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
	center_label.position = screen_center - Vector2(245, 90)

	# Full-screen overlays cover the whole viewport.
	if hint_popup != null:
		hint_popup.size = vp
	if hint_overlay != null:
		hint_overlay.size = vp
	if hint_panel != null:
		hint_panel.position = (vp - hint_panel.size) * 0.5
	if coach_overlay != null:
		coach_overlay.size = vp
	if coach_dim_mask != null:
		coach_dim_mask.size = vp
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return
	if operation_legend != null:
		operation_legend.close_callout_if_outside(mouse_event.position)

func build() -> void:
	for child in get_children():
		child.queue_free()
	# Same fill as the primary Play/Continue button (mockup parity): diagonal
	# PRIMARY_TOP→PRIMARY_BOTTOM gradient.
	center_circle_texture = UIStyles.circle_gradient_texture(CENTER_CIRCLE_DIAMETER, UIStyles.PRIMARY_TOP, UIStyles.PRIMARY_BOTTOM)
	center_shadow_style = make_center_shadow_style()

	center_label = Label.new()
	center_label.position = screen_center - Vector2(245, 90)
	center_label.size = Vector2(490, 180)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(center_label, UIStyles.FONT_EXTRABOLD, 101, Color.WHITE)
	add_child(center_label)

	# The status pill is TWO independent, self-contained blocks — LEVEL (left) and
	# MOVES (right). Each is a half-width rounded panel whose inner edge is a
	# concave arc cut around the target (its own fill, border, shadow and rim); the
	# two meet under the target badge, which hides the seam. Kept separate so each
	# can highlight — and later animate — on its own.
	var half_size := Vector2(TOP_STATUS_SIZE.x * 0.5, TOP_STATUS_SIZE.y)
	var notch_c := TARGET_BUBBLE_SIZE.x * 0.5 + 16.0
	var mid_y := TOP_STATUS_SIZE.y * 0.5
	var text_w := half_size.x - notch_c

	# LEFT (LEVEL) — notch cut on the inner (right) edge.
	level_bg = make_status_block(Vector2(EDGE_MARGIN, TOP_STATUS_Y), half_size, Vector2(half_size.x, mid_y), notch_c)
	add_child(level_bg)
	level_hover = make_status_hover(half_size, Vector2(half_size.x, mid_y), notch_c)
	level_bg.add_child(level_hover)
	level_label = make_status_label()
	level_label.position = Vector2(0, 0)
	level_label.size = Vector2(text_w, TOP_STATUS_SIZE.y)
	level_bg.add_child(level_label)
	level_label.gui_input.connect(_on_level_panel_input)
	UIStyles.attach_hover_tint(level_label, level_hover)

	# RIGHT (MOVES) — notch cut on the inner (left) edge.
	moves_bg = make_status_block(Vector2(EDGE_MARGIN + half_size.x, TOP_STATUS_Y), half_size, Vector2(0, mid_y), notch_c)
	add_child(moves_bg)
	moves_hover = make_status_hover(half_size, Vector2(0, mid_y), notch_c)
	moves_bg.add_child(moves_hover)
	moves_count_label = make_status_label()
	moves_count_label.position = Vector2(notch_c, 0)
	moves_count_label.size = Vector2(text_w, TOP_STATUS_SIZE.y)
	moves_bg.add_child(moves_count_label)
	moves_count_label.gui_input.connect(_on_moves_panel_input)
	UIStyles.attach_hover_tint(moves_count_label, moves_hover)

	target_panel = Panel.new()
	target_panel.position = Vector2(603, TOP_STATUS_Y + TOP_STATUS_SIZE.y * 0.5) - TARGET_BUBBLE_SIZE * 0.5
	target_panel.size = TARGET_BUBBLE_SIZE
	target_panel.z_index = 6
	target_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var target_style := UIStyles.gradient_style(UIStyles.TEAL_TOP, UIStyles.TEAL_BOTTOM, 134, Vector2i(268, 268))
	target_panel.add_theme_stylebox_override("panel", target_style)
	add_child(target_panel)
	target_panel.gui_input.connect(_on_goal_panel_input)

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
	bulbs_button.pressed.connect(show_hint_popup)
	add_child(bulbs_button)

	operation_legend = OperationLegendScene.instantiate()
	add_child(operation_legend)
	operation_legend.operator_info.connect(func(text: String) -> void: show_temporary_help(text))

	orbit = Node2D.new()
	add_child(orbit)

	build_hint_popup()
	build_coach_overlay()
	_apply_layout()

func configure(title_text: String, current_number: int, target_number: int, moves: int, thresholds: Array, star_bands: Array, orbit_items: Array, allowed_ops: Array, failed: bool, hint_points: int, tutorial: bool = false, tutorial_help: String = "", coach_hint: Dictionary = {}) -> void:
	level_failed = failed
	current_number_value = current_number
	current_hint_points = hint_points
	current_moves = moves
	current_target_value = target_number
	current_thresholds = thresholds.duplicate()
	current_star_bands = star_bands.duplicate(true)
	current_is_tutorial = tutorial
	if cached_popup_move_index != current_moves:
		cached_popup_hint_text = ""
		cached_popup_move_index = -1
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
		show_coach_hint(coach_hint)
	else:
		hide_coach_hint()
	queue_redraw()

func pop_center_number() -> void:
	UIStyles.pop_scale(center_label, 1.08, 0.08, 0.14)

func pulse_failure_controls() -> void:
	UIStyles.pop_scale(restart_button, 1.04, 0.13, 0.18)

func _on_moves_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed:
		if current_is_tutorial:
			show_temporary_help(Locale.t("game.tap.moves_tut", "Tutorial moves earn no stars."), false)
		else:
			show_temporary_help(star_requirements_text(), false)

func _on_level_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed:
		if current_is_tutorial:
			show_temporary_help(Locale.t("game.tap.level_tut", "One step at a time."), false)
		else:
			show_temporary_help(Locale.t("game.tap.level", "Beat this to unlock the next."), false)

func _on_goal_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed:
		pop_goal_panel()
		show_temporary_help(Locale.t("game.tap.target", "Reach %d using orbit numbers.") % current_target_value, false)

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
	if changed or info_temp_active:
		info_temp_active = false
		_play_info_marquee(text, false, error)

func _info_text_width(text: String) -> float:
	return UIStyles.FONT_MEDIUM.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x

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
	# Glide in and rest near the left edge.
	info_marquee_tween.tween_property(tutorial_help_label, "position:x", INFO_REST_X, 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if temp:
		info_marquee_tween.tween_interval(3.0)
		info_marquee_tween.tween_property(tutorial_help_label, "position:x", new_out_x, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		info_marquee_tween.tween_callback(func() -> void:
			if v == info_marquee_version:
				info_temp_active = false
				_play_info_marquee(info_default_text, false, level_failed)
		)

func pop_goal_panel() -> void:
	UIStyles.pop_scale(target_panel, 1.045)

# --- Status pill (LEVEL / MOVES) building blocks ------------------------------

# A half-width status block: a rounded glass panel (own fill, border, shadow)
# with a concave notch cut around the target on its inner edge + a thin rim
# hugging that arc. Mouse-transparent; the label inside handles input.
func make_status_block(pos: Vector2, size: Vector2, notch_center: Vector2, notch_radius: float) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UIStyles.soft_panel(Color.WHITE, 67))
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
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0)
	s.anti_aliasing = true
	s.corner_radius_top_left = 67
	s.corner_radius_top_right = 67
	s.corner_radius_bottom_left = 67
	s.corner_radius_bottom_right = 67
	overlay.add_theme_stylebox_override("panel", s)
	overlay.material = status_notch_material(notch_center, notch_radius, size, Color(0, 0, 0, 0))
	return overlay

# A centered status label (LEVEL / MOVES text). It also handles taps + hover, so
# it is mouse-STOP; the caller sets position/size.
func make_status_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	UIStyles.apply_font(label, UIStyles.FONT_BOLD, 44, UIStyles.STATUSBAR_TEXT)
	return label

# Shared notch shader material: punches the circular hole (leaving the concave
# arc around the target) at `notch_center` and strokes a thin rim in `rim_color`
# (pass a transparent rim for the hover overlay). `panel_size` maps UV → pixels.
func status_notch_material(notch_center: Vector2, notch_radius: float, panel_size: Vector2, rim_color: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = status_notch_shader()
	mat.set_shader_parameter("notch_center", notch_center)
	mat.set_shader_parameter("notch_radius", notch_radius)
	mat.set_shader_parameter("panel_size", panel_size)
	mat.set_shader_parameter("rim_color", rim_color)
	return mat

func status_notch_shader() -> Shader:
	if _status_notch_shader == null:
		_status_notch_shader = Shader.new()
		_status_notch_shader.code = """
shader_type canvas_item;
uniform vec2 notch_center = vec2(536.0, 107.0);
uniform float notch_radius = 150.0;
uniform vec2 panel_size = vec2(536.0, 214.0);
uniform vec4 rim_color : source_color = vec4(0.0);
uniform float rim_width = 2.5;
void fragment() {
	float d = distance(UV * panel_size, notch_center);
	COLOR.a *= smoothstep(notch_radius - 1.0, notch_radius + 1.0, d);
	float rim_outer = notch_radius + rim_width;
	float rim = smoothstep(notch_radius - 0.75, notch_radius + 0.75, d) * (1.0 - smoothstep(rim_outer - 0.75, rim_outer + 0.75, d));
	COLOR.rgb = mix(COLOR.rgb, rim_color.rgb, rim * rim_color.a * 1.4);
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
	if center_shadow_style != null:
		draw_style_box(center_shadow_style, Rect2(screen_center - Vector2(CENTER_CIRCLE_RADIUS, CENTER_CIRCLE_RADIUS), Vector2(CENTER_CIRCLE_DIAMETER, CENTER_CIRCLE_DIAMETER)))
	if center_circle_texture != null:
		draw_texture_rect(center_circle_texture, Rect2(screen_center - Vector2(CENTER_CIRCLE_RADIUS, CENTER_CIRCLE_RADIUS), Vector2(CENTER_CIRCLE_DIAMETER, CENTER_CIRCLE_DIAMETER)), false)
	# Slightly wider ring, filled with the purple-button color (mid of the primary
	# gradient) instead of the faint neutral ring.
	var ring_color := UIStyles.PRIMARY_TOP.lerp(UIStyles.PRIMARY_BOTTOM, 0.5)
	ring_color.a = 0.55
	draw_arc(screen_center, orbit_radius, 0.0, TAU, 200, ring_color, 6.0, true)

func make_center_shadow_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_right = 0
	style.border_width_top = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = int(CENTER_CIRCLE_RADIUS)
	style.corner_radius_top_right = int(CENTER_CIRCLE_RADIUS)
	style.corner_radius_bottom_left = int(CENTER_CIRCLE_RADIUS)
	style.corner_radius_bottom_right = int(CENTER_CIRCLE_RADIUS)
	# Purple glow halo under the center orb (matches the mockup's colored drop
	# shadow); larger + softer in dark theme where the glow reads as a halo.
	# Identical to the Continue/Play button shadow (SHADOW_CARD 10/4) so the
	# center orb reads as the same material, per design review.
	style.shadow_color = UIStyles.SHADOW_CARD
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style

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
	if orbit == null:
		return
	for child in orbit.get_children().duplicate():
		orbit.remove_child(child)
		child.free()

func build_hint_popup() -> void:
	hint_popup = Control.new()
	hint_popup.z_index = 100
	hint_popup.size = Vector2(1080, 1920)
	hint_popup.visible = false
	add_child(hint_popup)

	hint_overlay = ColorRect.new()
	hint_overlay.size = Vector2(1080, 1920)
	hint_overlay.color = Color(0.03, 0.02, 0.08, 0.55)
	hint_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hint_popup.add_child(hint_overlay)

	var pw := UIStyles.popup_width(Layout.viewport_size(self).x)
	var panel := Panel.new()
	panel.size = Vector2(pw, 1003)
	panel.add_theme_stylebox_override("panel", UIStyles.popup_panel_style())
	hint_popup.add_child(panel)
	hint_panel = panel

	UIStyles.popup_badge(panel, pw, Color("#FFD98F"), Color("#F5A93D"), UIStyles.ICON_BULB, 101.0)
	UIStyles.popup_title(panel, pw, Locale.t("hint.title", "HINT"))

	hint_body_label = UIStyles.popup_body(panel, pw, "Spend bulbs to reveal one next move.", 264.0, 130.0)

	hint_move_circle = Panel.new()
	hint_move_circle.position = Vector2(pw * 0.5 - 87, 350)
	hint_move_circle.size = Vector2(174, 174)
	hint_move_circle.visible = false
	panel.add_child(hint_move_circle)
	hint_move_label = Label.new()
	hint_move_label.position = Vector2.ZERO
	hint_move_label.size = hint_move_circle.size
	hint_move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_move_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(hint_move_label, UIStyles.FONT_EXTRABOLD, 60, UIStyles.TEXT)
	hint_move_circle.add_child(hint_move_label)

	hint_balance_label = Label.new()
	hint_balance_label.position = Vector2(0, 430)
	hint_balance_label.size = Vector2(pw, 58)
	hint_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_balance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(hint_balance_label, UIStyles.FONT_SEMIBOLD, 44, UIStyles.MUTED)
	panel.add_child(hint_balance_label)

	hint_buy_button = UIStyles.popup_primary_button(Locale.t("hint.use", "Use Hint"), pw, 520.0)
	hint_buy_button.pressed.connect(func(): hint_requested.emit())
	panel.add_child(hint_buy_button)

	hint_ad_button = UIStyles.popup_primary_button(Locale.t("levels.locked.watch_ad", "Watch Ad"), pw, 520.0)
	hint_ad_button.pressed.connect(func(): hint_ad_requested.emit())
	hint_ad_button.visible = false
	panel.add_child(hint_ad_button)

	hint_cancel_button = UIStyles.popup_secondary_button(Locale.t("common.cancel", "Cancel"), pw, 755.0)
	hint_cancel_button.pressed.connect(func(): hint_popup.visible = false)
	panel.add_child(hint_cancel_button)

func show_hint_popup() -> void:
	reset_hint_popup_layout()
	if cached_popup_move_index == current_moves and not cached_popup_hint_text.is_empty():
		apply_hint_result_text(cached_popup_hint_text)
		hint_balance_label.text = Locale.t("hint.balance", "Balance: %d bulbs") % current_hint_points
		hint_buy_button.visible = false
		hint_ad_button.visible = false
		hint_cancel_button.text = Locale.t("common.back", "Back")
	else:
		hint_body_label.text = Locale.t("hint.body", "Spend %d bulbs to reveal the next winning move.") % GameState.HINT_COST
		hide_hint_move_circle()
		hint_balance_label.text = Locale.t("hint.balance", "Balance: %d bulbs") % current_hint_points
		hint_buy_button.visible = true
		hint_ad_button.visible = false
		hint_cancel_button.text = Locale.t("common.cancel", "Cancel")
	hint_popup.visible = true

func show_hint_result(message: String, balance: int) -> void:
	current_hint_points = balance
	cached_popup_hint_text = message
	cached_popup_move_index = current_moves
	reset_hint_popup_layout()
	apply_hint_result_text(message)
	hint_balance_label.text = Locale.t("hint.balance", "Balance: %d bulbs") % current_hint_points
	hint_buy_button.visible = false
	hint_ad_button.visible = false
	hint_cancel_button.text = Locale.t("common.back", "Back")
	hint_popup.visible = true

func show_insufficient_hint_balance(balance: int) -> void:
	current_hint_points = balance
	cached_popup_hint_text = ""
	cached_popup_move_index = -1
	reset_hint_popup_layout()
	hint_body_label.text = Locale.t("hint.insufficient", "Not enough bulbs for a hint.")
	hide_hint_move_circle()
	hint_balance_label.text = Locale.t("hint.balance_short", "Balance: %d / %d bulbs") % [current_hint_points, GameState.HINT_COST]
	hint_buy_button.visible = false
	hint_ad_button.visible = true
	hint_cancel_button.text = Locale.t("common.cancel", "Cancel")
	hint_popup.visible = true

func reset_hint_popup_layout() -> void:
	var pw := hint_panel.size.x
	hint_body_label.position = Vector2(UIStyles.POPUP_PAD, 264)
	hint_body_label.size = Vector2(pw - UIStyles.POPUP_PAD * 2.0, 130)
	hint_balance_label.position = Vector2(0, 430)
	hint_balance_label.size = Vector2(pw, 58)
	hide_hint_move_circle()

func apply_hint_result_text(message: String) -> void:
	var parsed := parse_hint_move(message)
	if parsed.is_empty():
		hint_body_label.text = message
		hide_hint_move_circle()
		return
	var moves_left := extract_hint_moves_left(message)
	var tap_next := Locale.t("hint.tap_next", "Tap this orbit number next.")
	hint_body_label.text = "%s\n%s" % [moves_left, tap_next] if not moves_left.is_empty() else tap_next
	var pw := hint_panel.size.x
	hint_body_label.position = Vector2(UIStyles.POPUP_PAD, 250)
	hint_body_label.size = Vector2(pw - UIStyles.POPUP_PAD * 2.0, 110)
	hint_balance_label.position = Vector2(0, 600)
	show_hint_move_circle(str(parsed["op"]), int(parsed["value"]))

func extract_hint_moves_left(message: String) -> String:
	# The "moves left" caption is the line that is NOT the internal "Next move:"
	# marker (which is parsed, never shown), so this stays language-independent.
	for line in message.split("\n", false):
		var trimmed := str(line).strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("Next move:"):
			continue
		return trimmed
	return ""

func parse_hint_move(message: String) -> Dictionary:
	var marker := "Next move:"
	var idx := message.find(marker)
	if idx < 0:
		return {}
	var tail := message.substr(idx + marker.length()).strip_edges()
	var parts := tail.split(" ", false)
	if parts.size() < 2:
		return {}
	var op := op_from_hint_symbol(str(parts[0]))
	if op.is_empty():
		return {}
	return {"op": op, "value": int(parts[1])}

func op_from_hint_symbol(symbol: String) -> String:
	match symbol:
		"+":
			return "add"
		"−", "-":
			return "subtract"
		"×", "x", "*":
			return "multiply"
		"÷", "/":
			return "divide"
	return ""

func show_hint_move_circle(op: String, value: int) -> void:
	if hint_move_circle == null or hint_move_label == null:
		return
	hint_move_circle.visible = true
	hint_move_circle.position = Vector2(hint_panel.size.x * 0.5 - 87, 390)
	var style: StyleBoxFlat = UIStyles.card(UIStyles.operation_bg(op), UIStyles.operation_border(op), 90)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	hint_move_circle.add_theme_stylebox_override("panel", style)
	hint_move_label.text = str(value)
	UIStyles.apply_font(hint_move_label, UIStyles.FONT_BOLD, 50, UIStyles.operation_text(op))

func hide_hint_move_circle() -> void:
	if hint_move_circle != null:
		hint_move_circle.visible = false

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
	coach_dim_mask.size = Vector2(1206, 2622)
	coach_dim_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coach_overlay.add_child(coach_dim_mask)
	coach_dim_mask.set_theme_colors(coach_dim_color(), coach_rim_color())

	# Opaque, readable tooltip (matches the popup surface, both themes) — the old
	# translucent glass let the dimmed screen bleed through and washed out the text.
	coach_panel = Panel.new()
	coach_panel.size = Vector2(COACH_PANEL_WIDTH, 150)
	coach_panel.add_theme_stylebox_override("panel", UIStyles.glass_panel(UIStyles.CORNER, true))
	coach_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coach_panel.z_index = 2
	coach_overlay.add_child(coach_panel)

	coach_label = Label.new()
	coach_label.position = Vector2(COACH_PANEL_PAD, 30)
	coach_label.size = Vector2(COACH_PANEL_WIDTH - COACH_PANEL_PAD * 2.0, 90)
	coach_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coach_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coach_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(coach_label, UIStyles.FONT_SEMIBOLD, 40, UIStyles.TEXT)
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
	var text := Locale.t(str(step.get("key", "")), str(step.get("text", "")))
	layout_coach_panel(text)
	coach_panel.position = coach_panel_position_for_rect(rect)

# Fit the tooltip to its (possibly wrapped) text so no line is clipped.
func layout_coach_panel(text: String) -> void:
	coach_label.text = text
	var inner_w := COACH_PANEL_WIDTH - COACH_PANEL_PAD * 2.0
	var text_h := UIStyles.FONT_SEMIBOLD.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, inner_w, 40).y
	var panel_h := clampf(text_h + 60.0, 132.0, 460.0)
	coach_panel.size = Vector2(COACH_PANEL_WIDTH, panel_h)
	coach_label.position = Vector2(COACH_PANEL_PAD, 30)
	coach_label.size = Vector2(inner_w, panel_h - 60.0)

func coach_dim_color() -> Color:
	return Color(0.02, 0.012, 0.05, 0.62) if UIStyles.is_dark() else Color(0.03, 0.02, 0.08, 0.46)

func coach_rim_color() -> Color:
	# Subtle bright halo only in dark theme (where the dim reads weakly); light
	# theme gets enough separation from the scrim alone.
	return Color(1, 1, 1, 0.14) if UIStyles.is_dark() else Color(1, 1, 1, 0.0)

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
			holes.append({"rect": fallback.grow(5), "radius": fallback.size.x * 0.5 + 5.0})
		"op_add", "op_subtract", "op_multiply", "op_divide", "op_unavailable", "hint":
			# Match the new pill roundness (chips/buttons use UIStyles.CORNER = 67).
			holes.append({"rect": fallback.grow(6), "radius": float(UIStyles.CORNER) + 6.0})
		_:
			if fallback.size != Vector2.ZERO:
				holes.append({"rect": fallback.grow(6), "radius": float(UIStyles.CORNER) + 6.0})
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
			if target_panel != null:
				return Rect2(target_panel.position, target_panel.size)
			return Rect2(Vector2(540, TOP_STATUS_Y + TOP_STATUS_SIZE.y * 0.5) - TARGET_BUBBLE_SIZE * 0.5, TARGET_BUBBLE_SIZE)
		"center":
			return Rect2(screen_center - Vector2(176, 176), Vector2(352, 352))
		"orbit":
			return Rect2(Vector2(100, 520), Vector2(880, 880))
		"orbit_buttons":
			return combined_rect(visible_orbit_button_rects(false), Rect2(Vector2(100, 520), Vector2(880, 880))).grow(12)
		"invalid_orbit":
			return combined_rect(visible_orbit_button_rects(true), Rect2(Vector2(100, 520), Vector2(880, 880))).grow(12)
		"ops":
			return Rect2(operation_legend.position, operation_legend.size)
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
			return Rect2(Vector2(70, ACTION_BUTTON_Y), Vector2(455, ACTION_BUTTON_HEIGHT))
	return Rect2(Vector2(140, 152), Vector2(800, 88))

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

func coach_panel_position_for_rect(rect: Rect2) -> Vector2:
	var vp := coach_overlay.size if coach_overlay != null else Layout.viewport_size(self)
	var margin := 45.0
	var y := rect.position.y + rect.size.y + 28.0
	# Prefer below the focus; flip above if it would run off the bottom.
	if y + coach_panel.size.y > vp.y - 70.0:
		y = rect.position.y - coach_panel.size.y - 28.0
	y = clampf(y, 70.0, vp.y - coach_panel.size.y - 70.0)
	var x := clampf(rect.get_center().x - coach_panel.size.x * 0.5, margin, vp.x - coach_panel.size.x - margin)
	return Vector2(x, y)
