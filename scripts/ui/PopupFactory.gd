class_name PopupFactory
extends RefCounted

const POPUP_WIDTH := 1005.0
const POPUP_PAD := 80.0
const POPUP_RADIUS := 101
const POPUP_BADGE := 214.0
const POPUP_BADGE_Y := -107.0
const POPUP_TITLE_Y := 154.0
const POPUP_PRIMARY_H := 188.0
const POPUP_SECONDARY_H := 168.0
const BADGE_SHADOW := Color(0, 0, 0, 0.10)
const PANEL_BLUR_PX := 52.0
const PANEL_BLUR_LOD := 5.2
const SCRIM_TINT_LIGHT := Color(15.0 / 255.0, 10.0 / 255.0, 30.0 / 255.0, 0.28)
const SCRIM_TINT_DARK := Color(0, 0, 0, 0.50)
const SHEET_OPEN_DURATION := 0.32
const SHEET_CLOSE_DURATION := 0.28
const SCRIM_OPEN_DURATION := 0.30
const SHEET_START_OFFSET := 46.0
const SHEET_START_SCALE := 0.94
const SHEET_HOME_META := "popup_sheet_home"
const SHEET_TWEEN_META := "popup_sheet_tween"
const SHEET_HIDING_META := "popup_sheet_hiding"

static var _panel_shader: Shader

static func popup_width(viewport_width: float) -> float:
	return minf(viewport_width - 100.0, POPUP_WIDTH)

static func scrim(viewport_size: Vector2, close_callback: Callable = Callable(), tint_override: Color = Color.TRANSPARENT) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.name = "PopupScrim"
	overlay.position = Vector2.ZERO
	overlay.size = viewport_size
	overlay.color = tint_override if tint_override != Color.TRANSPARENT else scrim_tint()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if close_callback.is_valid():
		overlay.gui_input.connect(func(event: InputEvent):
			var mb := event as InputEventMouseButton
			if mb != null and mb.pressed:
				close_callback.call()
		)
	return overlay

static func scrim_tint() -> Color:
	return SCRIM_TINT_DARK if UIStyles.is_dark() else SCRIM_TINT_LIGHT

static func register_sheet_panel(panel: Control) -> void:
	if not is_instance_valid(panel):
		return
	panel.set_meta(SHEET_HOME_META, panel.position)
	panel.pivot_offset = panel.size * 0.5

static func find_scrim(root: Control) -> ColorRect:
	if not is_instance_valid(root):
		return null
	var node := root.get_node_or_null("PopupScrim")
	return node as ColorRect

static func show_sheet(root: Control, panel: Control, overlay: CanvasItem = null) -> void:
	if not is_instance_valid(root) or not is_instance_valid(panel):
		return
	var home := _sheet_home(panel)
	var hiding := root.has_meta(SHEET_HIDING_META) and bool(root.get_meta(SHEET_HIDING_META))
	if root.visible and not hiding:
		_kill_sheet_tween(root)
		_apply_sheet_progress(panel, home, 1.0)
		if is_instance_valid(overlay):
			overlay.modulate.a = 1.0
		return

	_kill_sheet_tween(root)
	root.visible = true
	root.set_meta(SHEET_HIDING_META, false)
	_apply_sheet_progress(panel, home, 0.0)
	if is_instance_valid(overlay):
		overlay.modulate.a = 0.0

	var tween := root.create_tween()
	root.set_meta(SHEET_TWEEN_META, tween)
	var animate_panel := func(raw_t: float) -> void:
		_apply_sheet_progress(panel, home, _sheet_ease(raw_t))
	if is_instance_valid(overlay):
		tween.tween_property(overlay, "modulate:a", 1.0, SCRIM_OPEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_method(animate_panel, 0.0, 1.0, SHEET_OPEN_DURATION)
	else:
		tween.tween_method(animate_panel, 0.0, 1.0, SHEET_OPEN_DURATION)
	tween.finished.connect(func() -> void:
		if is_instance_valid(root):
			root.remove_meta(SHEET_TWEEN_META)
	)

static func show_sheet_immediate(root: Control, panel: Control, overlay: CanvasItem = null) -> void:
	if not is_instance_valid(root) or not is_instance_valid(panel):
		return
	_kill_sheet_tween(root)
	root.visible = true
	root.set_meta(SHEET_HIDING_META, false)
	_apply_sheet_progress(panel, _sheet_home(panel), 1.0)
	if is_instance_valid(overlay):
		overlay.modulate.a = 1.0

static func hide_sheet(root: Control, panel: Control, overlay: CanvasItem = null, after_hidden: Callable = Callable()) -> void:
	if not is_instance_valid(root) or not is_instance_valid(panel):
		if after_hidden.is_valid():
			after_hidden.call()
		return
	if not root.visible:
		if after_hidden.is_valid():
			after_hidden.call()
		return

	_kill_sheet_tween(root)
	root.set_meta(SHEET_HIDING_META, true)
	var home := _sheet_home(panel)
	var start_position := panel.position
	var start_scale := panel.scale
	var start_alpha := panel.modulate.a
	var end_position := home + Vector2(0, SHEET_START_OFFSET)
	var end_scale := Vector2(SHEET_START_SCALE, SHEET_START_SCALE)

	var tween := root.create_tween()
	root.set_meta(SHEET_TWEEN_META, tween)
	var animate_panel := func(raw_t: float) -> void:
		var eased := _sheet_ease(raw_t)
		panel.position = start_position.lerp(end_position, eased)
		panel.scale = start_scale.lerp(end_scale, eased)
		panel.modulate.a = lerpf(start_alpha, 0.0, eased)
	if is_instance_valid(overlay):
		tween.tween_property(overlay, "modulate:a", 0.0, SHEET_CLOSE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.parallel().tween_method(animate_panel, 0.0, 1.0, SHEET_CLOSE_DURATION)
	else:
		tween.tween_method(animate_panel, 0.0, 1.0, SHEET_CLOSE_DURATION)
	tween.finished.connect(func() -> void:
		if not is_instance_valid(root):
			return
		root.visible = false
		root.set_meta(SHEET_HIDING_META, false)
		root.remove_meta(SHEET_TWEEN_META)
		_apply_sheet_progress(panel, home, 0.0)
		if is_instance_valid(overlay):
			overlay.modulate.a = 0.0
		if after_hidden.is_valid():
			after_hidden.call()
	)

static func _sheet_home(panel: Control) -> Vector2:
	if panel.has_meta(SHEET_HOME_META):
		var value = panel.get_meta(SHEET_HOME_META)
		if value is Vector2:
			return value
	register_sheet_panel(panel)
	return panel.position

static func _apply_sheet_progress(panel: Control, home: Vector2, progress: float) -> void:
	if not is_instance_valid(panel):
		return
	var p := clampf(progress, 0.0, 1.0)
	var scale_value := lerpf(SHEET_START_SCALE, 1.0, p)
	panel.pivot_offset = panel.size * 0.5
	panel.position = home + Vector2(0, lerpf(SHEET_START_OFFSET, 0.0, p))
	panel.scale = Vector2(scale_value, scale_value)
	panel.modulate.a = p

static func _kill_sheet_tween(root: Control) -> void:
	if not is_instance_valid(root) or not root.has_meta(SHEET_TWEEN_META):
		return
	var maybe_tween = root.get_meta(SHEET_TWEEN_META)
	if maybe_tween is Tween:
		(maybe_tween as Tween).kill()
	root.remove_meta(SHEET_TWEEN_META)

static func _sheet_ease(x: float) -> float:
	return _bezier_y_at_x(clampf(x, 0.0, 1.0), 0.28, 0.85, 0.35, 1.0)

static func _bezier_y_at_x(x: float, x1: float, y1: float, x2: float, y2: float) -> float:
	var t := x
	for _i in range(8):
		var estimate := _bezier_value(t, x1, x2) - x
		var slope := _bezier_slope(t, x1, x2)
		if abs(slope) < 0.00001:
			break
		t = clampf(t - estimate / slope, 0.0, 1.0)
	return _bezier_value(t, y1, y2)

static func _bezier_value(t: float, p1: float, p2: float) -> float:
	var c := 3.0 * p1
	var b := 3.0 * (p2 - p1) - c
	var a := 1.0 - c - b
	return ((a * t + b) * t + c) * t

static func _bezier_slope(t: float, p1: float, p2: float) -> float:
	var c := 3.0 * p1
	var b := 3.0 * (p2 - p1) - c
	var a := 1.0 - c - b
	return (3.0 * a * t + 2.0 * b) * t + c

static func apply_panel_glass(panel: Panel) -> void:
	panel.add_theme_stylebox_override("panel", panel_style())
	var mat := ShaderMaterial.new()
	mat.shader = panel_shader()
	mat.set_shader_parameter("blur_px", PANEL_BLUR_PX)
	mat.set_shader_parameter("blur_lod", PANEL_BLUR_LOD)
	mat.set_shader_parameter("panel_alpha", maxf(UIStyles.GLASS_BG.a, 0.001))
	panel.material = mat

static func panel_shader() -> Shader:
	if _panel_shader == null:
		_panel_shader = Shader.new()
		_panel_shader.code = """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_px = 52.0;
uniform float blur_lod = 5.2;
uniform float panel_alpha = 0.82;

vec4 soft_screen_blur(vec2 uv, vec2 px) {
	vec4 sum = textureLod(screen_texture, uv, blur_lod) * 0.28;
	sum += textureLod(screen_texture, uv + vec2(px.x, 0.0), blur_lod) * 0.10;
	sum += textureLod(screen_texture, uv - vec2(px.x, 0.0), blur_lod) * 0.10;
	sum += textureLod(screen_texture, uv + vec2(0.0, px.y), blur_lod) * 0.10;
	sum += textureLod(screen_texture, uv - vec2(0.0, px.y), blur_lod) * 0.10;
	sum += textureLod(screen_texture, uv + vec2(px.x, px.y) * 0.85, blur_lod) * 0.08;
	sum += textureLod(screen_texture, uv + vec2(-px.x, px.y) * 0.85, blur_lod) * 0.08;
	sum += textureLod(screen_texture, uv + vec2(px.x, -px.y) * 0.85, blur_lod) * 0.08;
	sum += textureLod(screen_texture, uv + vec2(-px.x, -px.y) * 0.85, blur_lod) * 0.08;
	return sum;
}

vec3 soften_detail(vec3 color) {
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 muted = mix(vec3(luma), color, 0.58);
	return mix(vec3(0.5), muted, 0.82);
}

void fragment() {
	vec4 style_color = COLOR;
	vec2 px = SCREEN_PIXEL_SIZE * blur_px;
	vec3 blurred = soften_detail(soft_screen_blur(SCREEN_UV, px).rgb);
	COLOR.rgb = mix(blurred, style_color.rgb, style_color.a);
	COLOR.a = clamp(style_color.a / max(panel_alpha, 0.001), 0.0, 1.0);
}
"""
	return _panel_shader

static func panel_style() -> StyleBoxFlat:
	var s := UIStyles.glass_panel(POPUP_RADIUS)
	return s

static func badge(parent: Control, panel_width: float, top: Color, bottom: Color, icon_tex: Texture2D, icon_px: float) -> TextureRect:
	var d := POPUP_BADGE
	var x := panel_width * 0.5 - d * 0.5
	var glow := Panel.new()
	glow.position = Vector2(x, POPUP_BADGE_Y)
	glow.size = Vector2(d, d)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color(0, 0, 0, 0)
	UIStyles._set_radius(gs, int(d * 0.5) - 2)
	gs.shadow_color = BADGE_SHADOW
	gs.shadow_size = 10
	gs.shadow_offset = Vector2(0, 4)
	glow.add_theme_stylebox_override("panel", gs)
	parent.add_child(glow)

	var circle := TextureRect.new()
	circle.texture = UIStyles.circle_gradient_texture(int(d), top, bottom)
	circle.position = Vector2(x, POPUP_BADGE_Y)
	circle.size = Vector2(d, d)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(circle)
	UIStyles.icon(icon_tex, circle, Vector2((d - icon_px) * 0.5, (d - icon_px) * 0.5), Vector2(icon_px, icon_px), Color.WHITE)
	return circle

static func title(parent: Control, panel_width: float, text: String, y: float = POPUP_TITLE_Y) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.position = Vector2(0, y)
	l.size = Vector2(panel_width, 84)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(l, UIStyles.FONT_EXTRABOLD, 64, UIStyles.TEXT)
	parent.add_child(l)
	return l

static func body(parent: Control, panel_width: float, text: String, y: float, height: float = 200.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(POPUP_PAD, y)
	l.size = Vector2(panel_width - POPUP_PAD * 2.0, height)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(l, UIStyles.FONT_SEMIBOLD, 45, UIStyles.MUTED)
	parent.add_child(l)
	return l

static func primary_button(text: String, panel_width: float, y: float, danger: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.position = Vector2(POPUP_PAD, y)
	b.size = Vector2(panel_width - POPUP_PAD * 2.0, POPUP_PRIMARY_H)
	b.add_theme_font_size_override("font_size", 54)
	if danger:
		UIStyles._gradient_button(b, Color("#FF9B96"), Color("#E0453F"), 67)
	else:
		UIStyles._gradient_button(b, UIStyles.PRIMARY_TOP, UIStyles.PRIMARY_BOTTOM, 67)
	return b

static func secondary_button(text: String, panel_width: float, y: float) -> Button:
	var b := Button.new()
	b.text = text
	b.position = Vector2(POPUP_PAD, y)
	b.size = Vector2(panel_width - POPUP_PAD * 2.0, POPUP_SECONDARY_H)
	b.add_theme_font_size_override("font_size", 50)
	UIStyles.soft_button(b, 67)
	return b
