class_name CoachOverlay
extends Control

signal hiding_started
signal showing_started

const PANEL_WIDTH := 912.0
const PANEL_PAD := 54.0
const SPOTLIGHT_PADDING := 2.0
const SPOTLIGHT_DIM_DARK := Color(0.02, 0.012, 0.05, 0.66)
const SPOTLIGHT_DIM_LIGHT := Color(0.03, 0.02, 0.08, 0.44)
const SPOTLIGHT_EDGE_DARK := Color(1, 1, 1, 0.0)
const SPOTLIGHT_EDGE_LIGHT := Color(0, 0, 0, 0.0)
const SPOTLIGHT_FEATHER := 52.0

class CoachDimMask:
	extends ColorRect

	var holes: Array[Dictionary] = []
	var shader_material: ShaderMaterial
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
uniform float feather_width = 52.0;
uniform float fade_alpha = 1.0;
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
	float edge_amount = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= hole_count) {
			break;
		}
		vec4 rect = hole_rects[i];
		vec2 half_size = rect.zw * 0.5;
		vec2 center = rect.xy + half_size;
		float radius = min(hole_radii[i], min(half_size.x, half_size.y));
		float dist = rounded_box_sdf(p - center, half_size, radius);
		float local_dim = smoothstep(-feather_width * 0.35, feather_width, dist);
		dim_amount = min(dim_amount, local_dim);
		edge_amount = max(edge_amount, (1.0 - local_dim) * step(0.0, dist));
	}
	COLOR = dim_color;
	COLOR.a *= dim_amount * fade_alpha;
	float edge_strength = edge_amount * edge_tint_color.a;
	COLOR.rgb = mix(COLOR.rgb, edge_tint_color.rgb, edge_strength);
}
"""
		shader_material.shader = shader
		material = shader_material
		shader_material.set_shader_parameter("feather_width", SPOTLIGHT_FEATHER)
		_update_shader()
		_update_fade_alpha()

	func set_holes(next_holes: Array[Dictionary]) -> void:
		holes = next_holes
		_update_shader()

	func set_theme_colors(dim: Color, edge_tint: Color) -> void:
		if shader_material == null:
			return
		shader_material.set_shader_parameter("dim_color", dim)
		shader_material.set_shader_parameter("edge_tint_color", edge_tint)

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
var version := 0
var steps: Array = []
var step_index := 0
var context: Dictionary = {}
var is_hiding := false
var is_showing := false

func build() -> void:
	for child in get_children():
		child.queue_free()
	position = Vector2.ZERO
	visible = false
	z_index = 90
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_overlay_input)

	dim_mask = CoachDimMask.new()
	dim_mask.position = Vector2.ZERO
	dim_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim_mask)
	dim_mask.set_theme_colors(dim_color(), edge_tint_color())

	panel = Panel.new()
	panel.size = Vector2(PANEL_WIDTH, 150)
	panel.add_theme_stylebox_override("panel", UIStyles.glass_panel(UIStyles.CORNER, true))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 2
	add_child(panel)

	label = Label.new()
	label.position = Vector2(PANEL_PAD, 30)
	label.size = Vector2(PANEL_WIDTH - PANEL_PAD * 2.0, 90)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(label, UIStyles.FONT_SEMIBOLD, 40, UIStyles.TEXT)
	panel.add_child(label)

func configure_context(next_context: Dictionary) -> void:
	context = next_context.duplicate(true)

func layout_to_viewport(viewport_size: Vector2) -> void:
	size = viewport_size
	if dim_mask != null:
		dim_mask.size = viewport_size

func refresh_theme() -> void:
	if dim_mask != null:
		dim_mask.set_theme_colors(dim_color(), edge_tint_color())

func show_hint(coach_hint: Dictionary) -> void:
	if dim_mask == null:
		return
	version += 1
	is_hiding = false
	is_showing = true
	modulate.a = 1.0
	if panel != null:
		panel.modulate.a = 0.0
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
	apply_step()
	visible = true
	showing_started.emit()
	var show_version := version
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(dim_mask, "fade_alpha", 1.0, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		if show_version == version:
			is_showing = false
	)

func apply_step() -> void:
	if step_index < 0 or step_index >= steps.size():
		hide_hint()
		return
	var step: Dictionary = steps[step_index] as Dictionary
	var area := str(step.get("area", "target"))
	var rect := rect_for_area(area)
	if dim_mask != null:
		dim_mask.set_holes(holes_for_area(area, rect))
	var text := Locale.t(str(step.get("key", "")), str(step.get("text", "")))
	layout_panel(text)
	panel.position = panel_position_for_rect(rect)

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
	label.text = text
	var inner_w := PANEL_WIDTH - PANEL_PAD * 2.0
	var text_h := UIStyles.FONT_SEMIBOLD.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, inner_w, 40).y
	var panel_h := clampf(text_h + 60.0, 132.0, 460.0)
	panel.size = Vector2(PANEL_WIDTH, panel_h)
	label.position = Vector2(PANEL_PAD, 30)
	label.size = Vector2(inner_w, panel_h - 60.0)

func dim_color() -> Color:
	return SPOTLIGHT_DIM_DARK if UIStyles.is_dark() else SPOTLIGHT_DIM_LIGHT

func edge_tint_color() -> Color:
	return SPOTLIGHT_EDGE_DARK if UIStyles.is_dark() else SPOTLIGHT_EDGE_LIGHT

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
		"op_add", "op_subtract", "op_multiply", "op_divide", "op_unavailable", "hint":
			holes.append(rounded_hole(fallback))
		_:
			if fallback.size != Vector2.ZERO:
				holes.append(rounded_hole(fallback))
	return holes

func circle_hole(rect: Rect2) -> Dictionary:
	var grown := rect.grow(SPOTLIGHT_PADDING)
	return {"rect": grown, "radius": minf(grown.size.x, grown.size.y) * 0.5}

func rounded_hole(rect: Rect2) -> Dictionary:
	return {"rect": rect.grow(SPOTLIGHT_PADDING), "radius": float(UIStyles.CORNER) + SPOTLIGHT_PADDING}

func _on_overlay_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return
	step_index += 1
	if step_index >= steps.size():
		hide_hint()
	else:
		apply_step()

func fade_out(check_version: int) -> void:
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(panel, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.tween_property(dim_mask, "fade_alpha", 0.0, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade.finished
	if check_version == version:
		visible = false
		is_hiding = false
		is_showing = false
		modulate.a = 1.0
		if panel != null:
			panel.modulate.a = 1.0
		if dim_mask != null:
			dim_mask.modulate.a = 1.0
			dim_mask.fade_alpha = 1.0

func hide_hint() -> void:
	if is_hiding:
		return
	version += 1
	if visible:
		is_hiding = true
		is_showing = false
		hiding_started.emit()
		fade_out(version)
	else:
		visible = false
		is_hiding = false
		is_showing = false

func rect_for_area(area: String) -> Rect2:
	match area:
		"target":
			return context.get("target_rect", Rect2(Vector2(540, 202), Vector2(268, 268))) as Rect2
		"center":
			var c: Vector2 = context.get("screen_center", Vector2(603, 1240))
			return Rect2(c - Vector2(176, 176), Vector2(352, 352))
		"orbit":
			return context.get("orbit_fallback_rect", Rect2(Vector2(100, 520), Vector2(880, 880))) as Rect2
		"orbit_buttons":
			return combined_rect(context.get("orbit_valid_rects", []), context.get("orbit_fallback_rect", Rect2(Vector2(100, 520), Vector2(880, 880))) as Rect2).grow(12)
		"invalid_orbit":
			return combined_rect(context.get("orbit_invalid_rects", []), context.get("orbit_fallback_rect", Rect2(Vector2(100, 520), Vector2(880, 880))) as Rect2).grow(12)
		"ops":
			return context.get("ops_rect", Rect2(Vector2(0, 0), Vector2(1072, 147))) as Rect2
		"op_add":
			return op_rect(0)
		"op_subtract":
			return op_rect(1)
		"op_multiply":
			return op_rect(2)
		"op_divide":
			return op_rect(3)
		"op_unavailable":
			return op_rect(4)
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

func op_rect(index: int) -> Rect2:
	var rects: Array = context.get("op_rects", [])
	if index >= 0 and index < rects.size():
		return rects[index] as Rect2
	return context.get("ops_rect", Rect2(Vector2(0, 0), Vector2(304, 74))) as Rect2

func panel_position_for_rect(rect: Rect2) -> Vector2:
	var margin := 45.0
	var y := rect.position.y + rect.size.y + 28.0
	if y + panel.size.y > size.y - 70.0:
		y = rect.position.y - panel.size.y - 28.0
	y = clampf(y, 70.0, size.y - panel.size.y - 70.0)
	var x := clampf(rect.get_center().x - panel.size.x * 0.5, margin, size.x - panel.size.x - margin)
	return Vector2(x, y)
