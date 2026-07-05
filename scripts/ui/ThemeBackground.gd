class_name ThemeBackground
extends Control

# Themed app background: a flat base color plus two soft radial "blob"
# highlights (top-left and bottom-right), matching the handoff's
# radial-gradient spec. Rebuilds for the active UIStyles theme and resizes
# with the viewport so it always covers the visible area (which can exceed the
# 1080x1920 base under aspect "expand").

var base: ColorRect
var blob_a: TextureRect
var blob_b: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = -100
	base = ColorRect.new()
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	blob_a = _make_blob()
	blob_b = _make_blob()
	get_viewport().size_changed.connect(_layout)
	refresh()

func _make_blob() -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect

func _radial(color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 512
	tex.height = 512
	return tex

func refresh() -> void:
	if base == null:
		return
	base.color = UIStyles.BG
	blob_a.texture = _radial(UIStyles.BG_BLOB_A)
	blob_b.texture = _radial(UIStyles.BG_BLOB_B)
	_layout()

func _layout() -> void:
	if base == null:
		return
	var vp := Layout.viewport_size(self)
	base.position = Vector2.ZERO
	base.size = vp
	# Top-left blob (~15% x, ~10% y) and bottom-right blob (~90% x, ~92% y).
	var blob_size := vp * 1.05
	blob_a.size = blob_size
	blob_a.position = Vector2(vp.x * 0.15, vp.y * 0.10) - blob_size * 0.5
	blob_b.size = blob_size
	blob_b.position = Vector2(vp.x * 0.90, vp.y * 0.92) - blob_size * 0.5
