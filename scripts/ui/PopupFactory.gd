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
const SCRIM_TINT_LIGHT := Color(0.03, 0.02, 0.08, 0.34)
const SCRIM_TINT_DARK := Color(0.03, 0.02, 0.08, 0.52)

static var _panel_shader: Shader

static func popup_width(viewport_width: float) -> float:
	return minf(viewport_width - 100.0, POPUP_WIDTH)

static func scrim(viewport_size: Vector2, close_callback: Callable = Callable(), tint_override: Color = Color.TRANSPARENT) -> ColorRect:
	var overlay := ColorRect.new()
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
