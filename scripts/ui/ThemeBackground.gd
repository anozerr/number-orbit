class_name ThemeBackground
extends Control

# Themed app background: a flat base color plus two soft radial "blob"
# highlights (top-left and bottom-right), matching the handoff's radial-gradient
# spec. Rebuilds for the active UIStyles theme and resizes with the viewport so
# it always covers the visible area (which can exceed the base under aspect
# "expand").
#
# Rendered by ONE fragment shader rather than a baked GradientTexture2D: a baked
# 8-bit gradient stretched across the whole screen only has 256 steps per channel
# spread over thousands of pixels, so it shows visible banding — especially on
# the dark theme and wherever a translucent glass panel samples it. The shader
# composites in float precision and applies triangular-PDF (TPDF) dithering right
# before the 8-bit framebuffer write, which shapes quantization into ±1 LSB noise
# that the eye cannot see — no bands.

var rect: ColorRect
var _material: ShaderMaterial

# Blob centers as viewport fractions (top-left ~15%/10%, bottom-right ~90%/92%).
const BLOB_A_CENTER := Vector2(0.15, 0.10)
const BLOB_B_CENTER := Vector2(0.90, 0.92)
# Falloff radius in normalized UV. The old blob texture was viewport*1.05 with a
# radial gradient reaching full transparency at half its size → 0.5 * 1.05.
const BLOB_RADIUS := 0.525

static var _shader: Shader

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -100
	_material = ShaderMaterial.new()
	_material.shader = _background_shader()
	rect = ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = _material
	add_child(rect)
	get_viewport().size_changed.connect(_layout)
	refresh()

func refresh() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("base_color", UIStyles.BG)
	_material.set_shader_parameter("blob_a_color", UIStyles.BG_BLOB_A)
	_material.set_shader_parameter("blob_b_color", UIStyles.BG_BLOB_B)
	_material.set_shader_parameter("blob_a_center", BLOB_A_CENTER)
	_material.set_shader_parameter("blob_b_center", BLOB_B_CENTER)
	_material.set_shader_parameter("blob_radius", BLOB_RADIUS)
	_layout()

func _layout() -> void:
	if rect == null:
		return
	var vp := Layout.viewport_size(self)
	rect.position = Vector2.ZERO
	rect.size = vp

static func _background_shader() -> Shader:
	if _shader != null:
		return _shader
	_shader = Shader.new()
	# Plain vec4 uniforms (no source_color hint): 2D renders in sRGB with no HDR,
	# so straight-space mix() here reproduces the exact colors the old layered
	# ColorRect + TextureRects produced, just without the 8-bit banding.
	_shader.code = """
shader_type canvas_item;

uniform vec4 base_color;
uniform vec4 blob_a_color;
uniform vec4 blob_b_color;
uniform vec2 blob_a_center = vec2(0.15, 0.10);
uniform vec2 blob_b_center = vec2(0.90, 0.92);
uniform float blob_radius = 0.525;

// Hash for value-noise dithering (Dave Hoskins, hash12).
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	// Linear radial falloff in UV — equal-radius circle in UV reads as the same
	// screen-filling ellipse the stretched blob texture used to produce.
	float fa = 1.0 - clamp(distance(UV, blob_a_center) / blob_radius, 0.0, 1.0);
	float fb = 1.0 - clamp(distance(UV, blob_b_center) / blob_radius, 0.0, 1.0);
	vec3 col = base_color.rgb;
	col = mix(col, blob_a_color.rgb, blob_a_color.a * fa);
	col = mix(col, blob_b_color.rgb, blob_b_color.a * fb);
	// TPDF dither at ±1 LSB: two hashes sum to a triangular distribution, which
	// decorrelates the 8-bit rounding so no bands form. Static (no time term) so
	// the background stays perfectly still with no shimmer.
	float r1 = hash12(FRAGCOORD.xy);
	float r2 = hash12(FRAGCOORD.xy + vec2(37.0, 17.0));
	col += (r1 + r2 - 1.0) / 255.0;
	COLOR = vec4(col, 1.0);
}
"""
	return _shader
