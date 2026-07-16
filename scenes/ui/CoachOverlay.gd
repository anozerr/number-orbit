class_name CoachOverlay
extends Control

const PopupFactoryScript = preload("res://scripts/ui/PopupFactory.gd")

signal hiding_started
signal showing_started

const DESIGN_SCALE := 3.0
const PANEL_WIDTH := 820.0
const PANEL_MIN_HEIGHT := 330.0
const PANEL_PAD_X := 60.0
const PANEL_PAD_Y := 42.0
const PANEL_SCREEN_MARGIN := 30.0 * DESIGN_SCALE
const SPOTLIGHT_PADDING := 8.0
const SPOTLIGHT_FEATHER := 20.0
# The shader falloff reads visually smaller than a StyleBox shadow at the same
# numeric extent. This calibration keeps the perceived breathing displacement
# aligned with Double Reward and Hint without changing the purple color.
const COACH_GLOW_EXTENT_SCALE := 1.30
const THEME_TRANSITION_DURATION := 0.35
const FOCUS_PING_DURATION := 0.70

class CoachDimMask:
	extends ColorRect

	var holes: Array[Dictionary] = []
	var shader_material: ShaderMaterial
	var ring_pulse_tween: Tween
	var theme_color_tween: Tween
	var focus_ping_tween: Tween
	var base_edge_tint := Color.TRANSPARENT
	var theme_dim_color := Color.TRANSPARENT
	var display_edge_tint := Color.TRANSPARENT
	var display_dim_color := Color.TRANSPARENT
	var ring_pulse_level := 0.0
	var fade_alpha := 1.0:
		set(value):
			fade_alpha = value
			_update_fade_alpha()

	func _ready() -> void:
		color = Color.WHITE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		shader_material = ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;

uniform vec4 dim_color : source_color = vec4(0.03, 0.02, 0.08, 0.5);
uniform vec4 edge_tint_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float feather_width = 20.0;
uniform float fade_alpha = 1.0;
uniform float ring_alpha_multiplier = 1.0;
uniform float ring_brightness = 1.0;
uniform float ring_glow_size = 18.0;
uniform float ping_scale = 1.0;
uniform float ping_alpha = 0.0;
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
	float dim_amount = 1.0;
	float ring_line = 0.0;
	float ring_glow = 0.0;
	float ping_line = 0.0;
	float ping_glow = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= hole_count) {
			break;
		}
		vec4 rect = hole_rects[i];
		vec2 half_size = rect.zw * 0.5;
		vec2 center = rect.xy + half_size;
		float radius = min(hole_radii[i], min(half_size.x, half_size.y));
		float dist = rounded_box_sdf(p - center, half_size, radius);
		float local_dim = smoothstep(-feather_width, feather_width, dist);
		dim_amount = min(dim_amount, local_dim);
		// max() keeps every hole independent: nearby glows never add into a blob.
		ring_line = max(ring_line, 1.0 - smoothstep(1.5, 2.5, abs(dist)));
		float exterior_glow = smoothstep(1.5, 3.0, dist) * (1.0 - smoothstep(2.0, ring_glow_size, dist));
		ring_glow = max(ring_glow, exterior_glow);

		vec2 ping_half_size = half_size * ping_scale;
		float ping_radius = radius * ping_scale;
		float ping_dist = rounded_box_sdf(p - center, ping_half_size, ping_radius);
		ping_line = max(ping_line, 1.0 - smoothstep(1.5, 2.5, abs(ping_dist)));
		float ping_exterior_glow = smoothstep(1.5, 3.0, ping_dist) * (1.0 - smoothstep(2.0, 18.0, ping_dist));
		ping_glow = max(ping_glow, ping_exterior_glow);
	}
	float dim_alpha = dim_color.a * dim_amount;
	float solid_ring_alpha = ring_line * edge_tint_color.a;
	float breathing_glow_alpha = ring_glow * 0.36 * edge_tint_color.a * ring_alpha_multiplier;
	float edge_alpha = max(solid_ring_alpha, breathing_glow_alpha);
	float expanding_ping = max(ping_line, ping_glow * 0.30);
	float pulse_alpha = expanding_ping * ping_alpha;
	float glow_alpha = clamp(max(edge_alpha, pulse_alpha), 0.0, 1.0);
	float animated_share = clamp(max(breathing_glow_alpha, pulse_alpha) / max(glow_alpha, 0.0001), 0.0, 1.0);
	vec3 glow_rgb = edge_tint_color.rgb * mix(1.0, ring_brightness, animated_share);
	float composed_alpha = dim_alpha + glow_alpha * (1.0 - dim_alpha);
	vec3 composed_rgb = dim_color.rgb;
	if (composed_alpha > 0.0001) {
		composed_rgb = (dim_color.rgb * dim_alpha + glow_rgb * glow_alpha * (1.0 - dim_alpha)) / composed_alpha;
	}
	COLOR = vec4(composed_rgb, composed_alpha * fade_alpha);
}
"""
		shader_material.shader = shader
		material = shader_material
		shader_material.set_shader_parameter("feather_width", SPOTLIGHT_FEATHER)
		_update_shader()
		_update_fade_alpha()
		set_theme_colors(theme_dim_color, base_edge_tint)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_update_shader()

	func set_holes(next_holes: Array[Dictionary]) -> void:
		holes = next_holes
		clear_focus_ping()
		_update_shader()

	func set_theme_colors(dim: Color, edge_tint: Color) -> void:
		if theme_color_tween != null and theme_color_tween.is_valid():
			theme_color_tween.kill()
		theme_dim_color = dim
		base_edge_tint = edge_tint
		if shader_material == null:
			return
		_set_display_dim_color(theme_dim_color)
		_set_display_edge_tint(base_edge_tint)
		start_ring_pulse()

	func transition_theme_colors(dim: Color, edge_tint: Color) -> void:
		theme_dim_color = dim
		base_edge_tint = edge_tint
		if shader_material == null:
			return
		if theme_color_tween != null and theme_color_tween.is_valid():
			theme_color_tween.kill()
		if ring_pulse_tween != null and ring_pulse_tween.is_valid():
			ring_pulse_tween.kill()
		theme_color_tween = create_tween()
		theme_color_tween.set_parallel(true)
		theme_color_tween.tween_method(Callable(self, "_set_display_dim_color"), display_dim_color, theme_dim_color, THEME_TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		theme_color_tween.tween_method(Callable(self, "_set_display_edge_tint"), display_edge_tint, base_edge_tint, THEME_TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		theme_color_tween.finished.connect(start_ring_pulse)

	func _set_display_dim_color(value: Color) -> void:
		display_dim_color = value
		if shader_material != null:
			shader_material.set_shader_parameter("dim_color", display_dim_color)

	func _set_display_edge_tint(value: Color) -> void:
		display_edge_tint = value
		if shader_material != null:
			shader_material.set_shader_parameter("edge_tint_color", display_edge_tint)

	func start_ring_pulse() -> void:
		stop_ring_pulse()
		if shader_material == null or base_edge_tint.a <= 0.0:
			return
		_start_ring_pulse_leg(1.0 if ring_pulse_level < 0.5 else 0.0)

	func stop_ring_pulse() -> void:
		if ring_pulse_tween != null and ring_pulse_tween.is_valid():
			ring_pulse_tween.kill()
		ring_pulse_tween = null

	func _start_ring_pulse_leg(target: float) -> void:
		if shader_material == null or not is_inside_tree():
			return
		var duration := maxf(absf(target - ring_pulse_level) * UIStyles.ATTENTION_PULSE_HALF_PERIOD, 0.05)
		ring_pulse_tween = create_tween()
		ring_pulse_tween.tween_method(Callable(self, "set_ring_pulse"), ring_pulse_level, target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		ring_pulse_tween.finished.connect(func() -> void: _start_ring_pulse_leg(1.0 - target))

	func set_ring_pulse(level: float) -> void:
		if shader_material == null:
			return
		ring_pulse_level = clampf(level, 0.0, 1.0)
		shader_material.set_shader_parameter("ring_alpha_multiplier", UIStyles.attention_glow_alpha(ring_pulse_level))
		shader_material.set_shader_parameter("ring_glow_size", UIStyles.attention_glow_extent(ring_pulse_level) * COACH_GLOW_EXTENT_SCALE)
		shader_material.set_shader_parameter("ring_brightness", 1.0)

	func play_focus_ping() -> void:
		if shader_material == null or holes.is_empty():
			return
		clear_focus_ping()
		_set_focus_ping_progress(0.0)
		focus_ping_tween = create_tween()
		focus_ping_tween.tween_method(Callable(self, "_set_focus_ping_progress"), 0.0, 1.0, FOCUS_PING_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	func clear_focus_ping() -> void:
		if focus_ping_tween != null and focus_ping_tween.is_valid():
			focus_ping_tween.kill()
		if shader_material != null:
			shader_material.set_shader_parameter("ping_alpha", 0.0)

	func _set_focus_ping_progress(progress: float) -> void:
		if shader_material == null:
			return
		shader_material.set_shader_parameter("ping_scale", lerpf(1.0, 1.40, progress))
		shader_material.set_shader_parameter("ping_alpha", lerpf(0.85, 0.0, progress))

	func _update_fade_alpha() -> void:
		if shader_material == null:
			return
		shader_material.set_shader_parameter("fade_alpha", fade_alpha)

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

var dim_mask: CoachDimMask
var panel: Panel
var label: Label
var eyebrow_label: Label
var progress_dots: Array[Panel] = []
var progress_dot_styles: Array[StyleBoxFlat] = []
var panel_theme_tween: Tween
var version := 0
var steps: Array = []
var step_index := 0
var progress_start := 0
var progress_total := 1
var context: Dictionary = {}
var is_hiding := false
var is_showing := false
var is_transitioning_step := false
var step_transition_tween: Tween
var visibility_tween: Tween
var navigation_tween: Tween

const NAVIGATION_FADE_DURATION := 0.28

func build() -> void:
	if visibility_tween != null and visibility_tween.is_valid():
		visibility_tween.kill()
	if navigation_tween != null and navigation_tween.is_valid():
		navigation_tween.kill()
	visibility_tween = null
	navigation_tween = null
	Layout.clear_children_for_rebuild(self)
	position = Vector2.ZERO
	modulate.a = 1.0
	visible = false
	z_index = 90
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not gui_input.is_connected(_on_overlay_input):
		gui_input.connect(_on_overlay_input)

	dim_mask = CoachDimMask.new()
	dim_mask.position = Vector2.ZERO
	dim_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim_mask)
	dim_mask.set_theme_colors(dim_color(), edge_tint_color())

	panel = Panel.new()
	panel.size = Vector2(PANEL_WIDTH, PANEL_MIN_HEIGHT)
	# Use the exact same opaque/frosted glass surface as every regular popup.
	PopupFactoryScript.apply_panel_glass(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 2
	add_child(panel)

	eyebrow_label = Label.new()
	eyebrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eyebrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var eyebrow_font := FontVariation.new()
	eyebrow_font.base_font = UIStyles.FONT_BOLD
	eyebrow_font.spacing_glyph = int(round(1.1 * DESIGN_SCALE))
	# Restore the original coach typography and accent color.
	UIStyles.apply_font(eyebrow_label, eyebrow_font, int(11.0 * DESIGN_SCALE), Color.WHITE)
	eyebrow_label.self_modulate = UIStyles.PURPLE
	panel.add_child(eyebrow_label)

	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Manual wrapping avoids a Godot 4.7 minimum-size bug with em dashes and
	# fallback fonts that can inflate a Label to several thousand pixels.
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.add_theme_constant_override("line_spacing", int(6.0 * DESIGN_SCALE))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyles.apply_font(label, UIStyles.FONT_SEMIBOLD, int(16.0 * DESIGN_SCALE), Color.WHITE)
	label.self_modulate = UIStyles.TEXT
	panel.add_child(label)

	progress_dots.clear()
	progress_dot_styles.clear()

func _rebuild_progress_dots(count: int) -> void:
	for dot in progress_dots:
		if is_instance_valid(dot):
			panel.remove_child(dot)
			dot.queue_free()
	progress_dots.clear()
	progress_dot_styles.clear()
	for i in range(maxi(count, 1)):
		var dot := Panel.new()
		dot.size = Vector2.ONE * (6.0 * DESIGN_SCALE)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = UIStyles.PURPLE if i == 0 else UIStyles.COACH_DOT_INACTIVE
		UIStyles._set_radius(dot_style, int(3.0 * DESIGN_SCALE))
		dot.add_theme_stylebox_override("panel", dot_style)
		panel.add_child(dot)
		progress_dots.append(dot)
		progress_dot_styles.append(dot_style)

func configure_context(next_context: Dictionary) -> void:
	context = next_context.duplicate(true)

func state_snapshot() -> Dictionary:
	if not visible or steps.is_empty() or step_index < 0 or step_index >= steps.size():
		return {}
	return {
		"steps": steps.duplicate(true),
		"step_index": step_index,
		"progress_start": progress_start,
		"progress_total": progress_total,
	}

func layout_to_viewport(viewport_size: Vector2) -> void:
	size = viewport_size
	if dim_mask != null:
		dim_mask.size = viewport_size

func refresh_theme() -> void:
	if dim_mask != null:
		dim_mask.transition_theme_colors(dim_color(), edge_tint_color())
	_transition_panel_theme()

func show_hint(coach_hint: Dictionary, entrance_delay: float = 0.0) -> void:
	if dim_mask == null:
		return
	if visibility_tween != null and visibility_tween.is_valid():
		visibility_tween.kill()
	if navigation_tween != null and navigation_tween.is_valid():
		navigation_tween.kill()
	navigation_tween = null
	version += 1
	is_hiding = false
	is_showing = true
	is_transitioning_step = false
	if step_transition_tween != null and step_transition_tween.is_valid():
		step_transition_tween.kill()
	modulate.a = 1.0
	if panel != null:
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.95, 0.95)
	if dim_mask != null:
		dim_mask.modulate.a = 1.0
		dim_mask.fade_alpha = 0.0
	steps.clear()
	if coach_hint.has("steps"):
		for step in coach_hint["steps"] as Array:
			steps.append(step)
	else:
		steps.append(coach_hint)
	step_index = 0
	progress_start = maxi(0, int(coach_hint.get("progress_start", 0)))
	progress_total = maxi(1, int(coach_hint.get("progress_total", progress_start + steps.size())))
	_rebuild_progress_dots(progress_total)
	# Lay out text only once the Control is visible. Hidden Labels occasionally
	# kept a stale shaped-text cache on the first coach step.
	visible = true
	apply_step()
	var layout_version := version
	call_deferred("_refresh_first_visible_step", layout_version)
	showing_started.emit()
	var show_version := version
	visibility_tween = create_tween()
	var tween := visibility_tween
	if entrance_delay > 0.0:
		tween.tween_interval(entrance_delay)
	tween.tween_property(panel, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(dim_mask, "fade_alpha", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		if show_version == version:
			is_showing = false
			visibility_tween = null
			_play_focus_ping()
	)

func fade_for_navigation() -> void:
	if not visible:
		return
	if navigation_tween != null and navigation_tween.is_valid():
		navigation_tween.kill()
	navigation_tween = create_tween()
	var tween := navigation_tween
	tween.tween_property(self, "modulate:a", 0.0, NAVIGATION_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if navigation_tween == tween:
		navigation_tween = null
		if dim_mask != null:
			dim_mask.stop_ring_pulse()

func apply_step() -> void:
	if step_index < 0 or step_index >= steps.size():
		hide_hint()
		return
	var step: Dictionary = steps[step_index] as Dictionary
	var fallback_text := str(step.get("text", ""))
	var text := Locale.t(str(step.get("key", "")), fallback_text).strip_edges()
	if text.is_empty():
		text = fallback_text.strip_edges()
	var area := str(step.get("area", "target"))
	var rect := rect_for_area(area)
	if dim_mask != null:
		dim_mask.set_theme_colors(dim_color(), edge_tint_color())
		dim_mask.set_holes(holes_for_area(area, rect))
	layout_panel(text)
	panel.position = panel_position_for_rect(rect)

func _refresh_first_visible_step(check_version: int) -> void:
	if check_version != version or not visible or step_index < 0 or step_index >= steps.size():
		return
	apply_step()
	label.visible = true
	label.modulate = Color.WHITE
	label.queue_redraw()
	eyebrow_label.queue_redraw()
	panel.queue_redraw()

func refresh_spotlight() -> void:
	if not visible or step_index < 0 or step_index >= steps.size():
		return
	var step: Dictionary = steps[step_index] as Dictionary
	var area := str(step.get("area", "target"))
	var rect := rect_for_area(area)
	if dim_mask != null:
		dim_mask.set_holes(holes_for_area(area, rect))
	if panel != null:
		panel.position = panel_position_for_rect(rect)

func layout_panel(text: String) -> void:
	# 28 characters keeps even the widest Jakarta/Onest lines safely inside the
	# 700px text lane; clip_text then acts only as a last-resort guard.
	var wrapped_lines := _wrapped_text_lines(text, 28)
	label.text = "\n".join(wrapped_lines)
	label.visible = true
	label.modulate = Color.WHITE
	var visible_step := clampi(progress_start + step_index + 1, 1, progress_total)
	eyebrow_label.text = (("ШАГ %d ИЗ %d" if Locale.language() == "ru" else "STEP %d OF %d") % [visible_step, progress_total])
	var inner_w := PANEL_WIDTH - PANEL_PAD_X * 2.0
	var main_font_size := int(16.0 * DESIGN_SCALE)
	# Godot 4.7 can return multi-thousand-pixel sizes for strings containing an
	# em dash/fallback glyph in both multiline and single-line font measurement.
	# Use deterministic word packing; the Label itself performs the visual wrap.
	var estimated_lines := wrapped_lines.size()
	var line_height := 58.0
	var text_h := line_height * float(estimated_lines) + 18.0 * float(estimated_lines - 1)
	var eyebrow_h := 42.0
	var eyebrow_gap := 24.0
	var bottom_margin := 30.0
	var bottom_h := 18.0
	var content_h := PANEL_PAD_Y + eyebrow_h + eyebrow_gap + text_h + bottom_margin + bottom_h + PANEL_PAD_Y
	var panel_h := maxf(PANEL_MIN_HEIGHT, content_h)
	panel.size = Vector2(PANEL_WIDTH, panel_h)
	panel.pivot_offset = panel.size * 0.5
	eyebrow_label.position = Vector2(PANEL_PAD_X, PANEL_PAD_Y)
	eyebrow_label.size = Vector2(inner_w, eyebrow_h)
	var main_y := PANEL_PAD_Y + eyebrow_h + eyebrow_gap
	var bottom_y := panel_h - PANEL_PAD_Y - bottom_h
	label.position = Vector2(PANEL_PAD_X, main_y)
	label.size = Vector2(inner_w, maxf(text_h, bottom_y - bottom_margin - main_y))
	var dot_size := 6.0 * DESIGN_SCALE
	var dot_gap := 6.0 * DESIGN_SCALE
	var dots_width := float(progress_dots.size()) * dot_size + float(maxi(progress_dots.size() - 1, 0)) * dot_gap
	var dots_x := (PANEL_WIDTH - dots_width) * 0.5
	for i in range(progress_dots.size()):
		var dot := progress_dots[i]
		dot.position = Vector2(dots_x + float(i) * (dot_size + dot_gap), bottom_y + (bottom_h - dot_size) * 0.5)
		progress_dot_styles[i].bg_color = UIStyles.PURPLE if i == visible_step - 1 else UIStyles.COACH_DOT_INACTIVE

func _wrapped_text_lines(text: String, characters_per_line: int) -> PackedStringArray:
	var lines := PackedStringArray()
	var current_line := ""
	var current_length := 0
	for raw_word in text.split(" ", false):
		var word := str(raw_word)
		var word_length := word.length()
		var next_length := word_length if current_length == 0 else current_length + 1 + word_length
		if current_length > 0 and next_length > characters_per_line:
			lines.append(current_line)
			current_line = word
			current_length = word_length
		else:
			current_line = word if current_line.is_empty() else "%s %s" % [current_line, word]
			current_length = next_length
	if not current_line.is_empty():
		lines.append(current_line)
	if lines.is_empty():
		lines.append("")
	return lines

func dim_color() -> Color:
	return UIStyles.COACH_DIM

func active_area() -> String:
	if step_index < 0 or step_index >= steps.size():
		return ""
	var step: Dictionary = steps[step_index] as Dictionary
	return str(step.get("area", ""))

func edge_tint_color() -> Color:
	var color := UIStyles.PURPLE
	color.a = 0.7 if UIStyles.is_dark() else 0.65
	return color

func _transition_panel_theme() -> void:
	if panel == null or label == null or eyebrow_label == null:
		return
	if panel_theme_tween != null and panel_theme_tween.is_valid():
		panel_theme_tween.kill()
	# Theme changes are already screen-crossfaded by Main; rebuilding the exact
	# PopupFactory surface here keeps this card pixel-identical to regular popups.
	PopupFactoryScript.apply_panel_glass(panel)
	panel_theme_tween = create_tween()
	panel_theme_tween.set_parallel(true)
	panel_theme_tween.tween_property(eyebrow_label, "self_modulate", UIStyles.PURPLE, THEME_TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	panel_theme_tween.tween_property(label, "self_modulate", UIStyles.TEXT, THEME_TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(progress_dot_styles.size()):
		var active_index := clampi(progress_start + step_index, 0, progress_total - 1)
		var target := UIStyles.PURPLE if i == active_index else UIStyles.COACH_DOT_INACTIVE
		panel_theme_tween.tween_property(progress_dot_styles[i], "bg_color", target, THEME_TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_focus_ping() -> void:
	if dim_mask != null:
		dim_mask.play_focus_ping()

func holes_for_area(area: String, fallback: Rect2) -> Array[Dictionary]:
	var holes: Array[Dictionary] = []
	match area:
		"none":
			return holes
		"center":
			holes.append(circle_hole(fallback))
		"orbit_buttons":
			for orbit_rect in context.get("orbit_valid_rects", []):
				holes.append(circle_hole(orbit_rect as Rect2))
		"invalid_orbit":
			for invalid_rect in context.get("orbit_invalid_rects", []):
				holes.append(circle_hole(invalid_rect as Rect2))
		"target":
			holes.append(circle_hole(fallback))
		"op_add", "op_subtract", "op_multiply", "op_divide", "hint":
			holes.append(rounded_hole(fallback))
		_:
			if fallback.size != Vector2.ZERO:
				holes.append(rounded_hole(fallback))
	return holes

func circle_hole(rect: Rect2) -> Dictionary:
	var grown := rect.grow(SPOTLIGHT_PADDING)
	return {"rect": grown, "radius": minf(grown.size.x, grown.size.y) * 0.5}

func rounded_hole(rect: Rect2) -> Dictionary:
	var grown := rect.grow(SPOTLIGHT_PADDING)
	var radius := minf(grown.size.y * 0.5, float(UIStyles.CORNER) + SPOTLIGHT_PADDING)
	return {"rect": grown, "radius": radius}

func _on_overlay_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or is_transitioning_step:
		return
	# Пояснительный шаг: тап в любом месте листает дальше.
	var next_index := step_index + 1
	if next_index >= steps.size():
		hide_hint()
	else:
		transition_to_step(next_index)

func transition_to_step(new_index: int) -> void:
	if is_transitioning_step or new_index < 0 or new_index >= steps.size() or dim_mask == null or panel == null:
		return
	is_transitioning_step = true
	if step_transition_tween != null and step_transition_tween.is_valid():
		step_transition_tween.kill()
	var transition_version := version
	var fade_out := create_tween()
	step_transition_tween = fade_out
	fade_out.set_parallel(true)
	fade_out.tween_property(dim_mask, "fade_alpha", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_out.tween_property(panel, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_out.tween_property(panel, "scale", Vector2(0.95, 0.95), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished
	if transition_version != version or not visible:
		is_transitioning_step = false
		return
	step_index = new_index
	apply_step()
	var fade_in := create_tween()
	step_transition_tween = fade_in
	fade_in.set_parallel(true)
	fade_in.tween_property(dim_mask, "fade_alpha", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_in.tween_property(panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_in.tween_property(panel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	if transition_version == version:
		is_transitioning_step = false
		_play_focus_ping()

func fade_out(check_version: int) -> void:
	if visibility_tween != null and visibility_tween.is_valid():
		visibility_tween.kill()
	visibility_tween = create_tween()
	var fade := visibility_tween
	fade.tween_property(panel, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade.parallel().tween_property(panel, "scale", Vector2(0.97, 0.97), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade.parallel().tween_property(dim_mask, "fade_alpha", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade.finished.connect(_finish_fade_out.bind(check_version, fade))

func _finish_fade_out(check_version: int, fade: Tween) -> void:
	if visibility_tween == fade:
		visibility_tween = null
	if check_version == version:
		visible = false
		is_hiding = false
		is_showing = false
		if dim_mask != null:
			dim_mask.stop_ring_pulse()
		modulate.a = 1.0
		if panel != null:
			panel.modulate.a = 1.0
			panel.scale = Vector2.ONE
		if dim_mask != null:
			dim_mask.modulate.a = 1.0
			dim_mask.fade_alpha = 1.0

func hide_hint() -> void:
	if is_hiding:
		return
	version += 1
	is_transitioning_step = false
	if step_transition_tween != null and step_transition_tween.is_valid():
		step_transition_tween.kill()
	if visible:
		is_hiding = true
		is_showing = false
		hiding_started.emit()
		fade_out(version)
	else:
		visible = false
		is_hiding = false
		is_showing = false
		if dim_mask != null:
			dim_mask.stop_ring_pulse()

func rect_for_area(area: String) -> Rect2:
	match area:
		"target":
			return context.get("target_rect", Rect2(Vector2(540, 202), Vector2(268, 268))) as Rect2
		"center":
			var c: Vector2 = context.get("screen_center", Vector2(603, 1240))
			return context.get("center_rect", Rect2(c - Vector2(167.5, 167.5), Vector2(335, 335))) as Rect2
		"orbit":
			return context.get("orbit_fallback_rect", Rect2(Vector2(100, 520), Vector2(880, 880))) as Rect2
		"orbit_buttons":
			return combined_rect(context.get("orbit_valid_rects", []), context.get("orbit_fallback_rect", Rect2(Vector2(100, 520), Vector2(880, 880))) as Rect2).grow(12)
		"invalid_orbit":
			return combined_rect(context.get("orbit_invalid_rects", []), context.get("orbit_fallback_rect", Rect2(Vector2(100, 520), Vector2(880, 880))) as Rect2).grow(12)
		"ops":
			return context.get("ops_rect", Rect2(Vector2(0, 0), Vector2(1072, 147))) as Rect2
		"op_add":
			return op_chip_rect("add")
		"op_subtract":
			return op_chip_rect("subtract")
		"op_multiply":
			return op_chip_rect("multiply")
		"op_divide":
			return op_chip_rect("divide")
		"hint":
			return context.get("hint_rect", Rect2(Vector2(70, 1518), Vector2(455, 174))) as Rect2
	return Rect2(Vector2(140, 152), Vector2(800, 88))

func combined_rect(rects: Array, fallback: Rect2) -> Rect2:
	if rects.is_empty():
		return fallback
	var result: Rect2 = rects[0] as Rect2
	for i in range(1, rects.size()):
		result = result.merge(rects[i] as Rect2)
	return result

# 5.3/5.4: чип оператора по имени (легенда теперь переменной длины, без фикс-индексов).
func op_chip_rect(op: String) -> Rect2:
	var rects: Dictionary = context.get("op_chip_rects", {})
	if rects.has(op):
		return rects[op] as Rect2
	return context.get("ops_rect", Rect2(Vector2(0, 0), Vector2(304, 74))) as Rect2

func panel_position_for_rect(rect: Rect2) -> Vector2:
	var margin := PANEL_SCREEN_MARGIN
	var y := rect.position.y + rect.size.y + 28.0
	if y + panel.size.y > size.y - 70.0:
		y = rect.position.y - panel.size.y - 28.0
	# The gameplay info row remains useful during every tutorial step. If the
	# preferred coach position would cover it (notably the target step), move the
	# card below the row instead of merely leaving the row technically visible.
	var info_rect := context.get("info_rect", Rect2()) as Rect2
	if info_rect.size != Vector2.ZERO:
		var reserved_info := info_rect.grow(12.0)
		if Rect2(Vector2(rect.get_center().x - panel.size.x * 0.5, y), panel.size).intersects(reserved_info):
			y = reserved_info.end.y + 16.0
	y = clampf(y, 70.0, size.y - panel.size.y - 70.0)
	var x := clampf(rect.get_center().x - panel.size.x * 0.5, margin, size.x - panel.size.x - margin)
	return Vector2(x, y)
