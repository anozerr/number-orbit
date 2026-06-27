class_name UIStyles
extends RefCounted

const FONT_REGULAR: FontFile = preload("res://assets/fonts/static/Inter_28pt-Regular.ttf")
const FONT_MEDIUM: FontFile = preload("res://assets/fonts/static/Inter_28pt-Medium.ttf")
const FONT_SEMIBOLD: FontFile = preload("res://assets/fonts/static/Inter_28pt-SemiBold.ttf")
const FONT_BOLD: FontFile = preload("res://assets/fonts/static/Inter_28pt-Bold.ttf")

const ICON_BACK: Texture2D = preload("res://assets/images/icons/arrow-left.svg")
const ICON_CHECK: Texture2D = preload("res://assets/images/icons/check.svg")
const ICON_DIVIDE: Texture2D = preload("res://assets/images/icons/divide.svg")
const ICON_LEVELS: Texture2D = preload("res://assets/images/icons/dots-nine.svg")
const ICON_GEAR: Texture2D = preload("res://assets/images/icons/gear.svg")
const ICON_GLOBE: Texture2D = preload("res://assets/images/icons/globe.svg")
const ICON_BULB: Texture2D = preload("res://assets/images/icons/lightbulb.svg")
const ICON_LOCK: Texture2D = preload("res://assets/images/icons/lock.svg")
const ICON_MINUS: Texture2D = preload("res://assets/images/icons/minus.svg")
const ICON_MUSIC: Texture2D = preload("res://assets/images/icons/music-notes.svg")
const ICON_PLAY: Texture2D = preload("res://assets/images/icons/play.svg")
const ICON_PLAY_WHITE: Texture2D = preload("res://assets/images/icons/play-white.svg")
const ICON_PLUS: Texture2D = preload("res://assets/images/icons/plus.svg")
const ICON_RESTART: Texture2D = preload("res://assets/images/icons/arrow-counter-clockwise.svg")
const ICON_SPEAKER: Texture2D = preload("res://assets/images/icons/speaker-high.svg")
const ICON_STAR: Texture2D = preload("res://assets/images/icons/star-fill.svg")
const ICON_STAR_EMPTY: Texture2D = preload("res://assets/images/icons/star-empty-white.svg")
const ICON_LEVEL_STAR: Texture2D = preload("res://assets/images/icons/star-level-fill.svg")
const ICON_LEVEL_STAR_EMPTY: Texture2D = preload("res://assets/images/icons/star-level-empty.svg")
const ICON_X: Texture2D = preload("res://assets/images/icons/x.svg")

const BG: Color = Color("#FFFCF7")
const TEXT: Color = Color("#101633")
const MUTED: Color = Color("#5C6078")
const BORDER: Color = Color("#E9E3DB")
const PURPLE: Color = Color("#8B5CF6")
const PURPLE_DARK: Color = Color("#6D3FE0")
const PURPLE_SOFT: Color = Color("#BFA7FF")
const GOLD: Color = Color("#FFC857")
const DISABLED: Color = Color("#A8ADB8")

static var _rounded_gradient_cache: Dictionary = {}
static var _circle_gradient_cache: Dictionary = {}

static func card(bg: Color = Color.WHITE, border: Color = BORDER, radius: int = 26) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.10, 0.10, 0.18, 0.055)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 8)
	return style

static func soft_panel(bg: Color = Color.WHITE, radius: int = 34) -> StyleBoxFlat:
	var style: StyleBoxFlat = card(bg, Color(1, 1, 1, 0.70), radius)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.shadow_color = Color(0.12, 0.12, 0.22, 0.075)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 10)
	return style

static func apply_font(control: Control, font: Font = FONT_SEMIBOLD, size: int = 28, color: Color = TEXT) -> void:
	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)

static func menu_button(button: Button) -> void:
	var normal: StyleBoxFlat = soft_panel(Color.WHITE, 30)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	apply_font(button, FONT_SEMIBOLD, int(button.get_theme_font_size("font_size")), TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_focus_color", TEXT)
	add_press_animation(button)

static func primary_button(button: Button) -> void:
	var normal: StyleBoxTexture = gradient_style(PURPLE.lightened(0.13), PURPLE_DARK, 30, Vector2i(740, 120))
	var hover: StyleBoxTexture = normal.duplicate() as StyleBoxTexture
	var pressed: StyleBoxTexture = normal.duplicate() as StyleBoxTexture
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	apply_font(button, FONT_SEMIBOLD, int(button.get_theme_font_size("font_size")), Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	add_embedded_shadow(button, Color(0.38, 0.19, 0.85, 0.24))
	add_press_animation(button)

static func gradient_style(top: Color, bottom: Color, radius: int, texture_size: Vector2i) -> StyleBoxTexture:
	var texture: ImageTexture = rounded_gradient_texture(top, bottom, radius, texture_size)
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = radius
	style.texture_margin_right = radius
	style.texture_margin_top = radius
	style.texture_margin_bottom = radius
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

static func rounded_gradient_texture(top: Color, bottom: Color, radius: int, texture_size: Vector2i) -> ImageTexture:
	var key := "%s:%s:%d:%d:%d" % [top.to_html(true), bottom.to_html(true), radius, texture_size.x, texture_size.y]
	if _rounded_gradient_cache.has(key):
		return _rounded_gradient_cache[key] as ImageTexture
	var image: Image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var w: int = texture_size.x
	var h: int = texture_size.y
	for y in range(h):
		var t: float = float(y) / float(max(1, h - 1))
		var color: Color = top.lerp(bottom, t)
		for x in range(w):
			if is_inside_rounded_rect(x, y, w, h, radius):
				image.set_pixel(x, y, color)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_rounded_gradient_cache[key] = texture
	return texture

static func circle_gradient_texture(diameter: int, top: Color, bottom: Color) -> ImageTexture:
	var key := "%d:%s:%s" % [diameter, top.to_html(true), bottom.to_html(true)]
	if _circle_gradient_cache.has(key):
		return _circle_gradient_cache[key] as ImageTexture
	var image: Image = Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var radius: float = float(diameter) * 0.5
	var center := Vector2(radius, radius)
	for y in range(diameter):
		for x in range(diameter):
			var offset := Vector2(float(x), float(y)) - center
			if offset.length() <= radius:
				var t: float = float(y) / float(max(1, diameter - 1))
				image.set_pixel(x, y, top.lerp(bottom, t))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_circle_gradient_cache[key] = texture
	return texture

static func is_inside_rounded_rect(x: int, y: int, w: int, h: int, radius: int) -> bool:
	var cx: int = clamp(x, radius, w - radius - 1)
	var cy: int = clamp(y, radius, h - radius - 1)
	return Vector2(x - cx, y - cy).length() <= float(radius)

static func pill(label: Label) -> void:
	label.add_theme_stylebox_override("normal", soft_panel(Color.WHITE, 24))

static func icon(texture: Texture2D, parent: Node, position: Vector2, size: Vector2, color: Color = TEXT) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.texture = texture
	rect.position = position
	rect.size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.modulate = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

static func add_press_animation(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	button.mouse_entered.connect(func() -> void:
		if not is_instance_valid(button) or button.disabled:
			return
		var tween: Tween = button.create_tween()
		tween.tween_property(button, "scale", Vector2(1.018, 1.018), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	button.mouse_exited.connect(func() -> void:
		if not is_instance_valid(button):
			return
		var tween: Tween = button.create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	button.pressed.connect(func() -> void:
		if not is_instance_valid(button):
			return
		var tween: Tween = button.create_tween()
		tween.tween_property(button, "scale", Vector2(0.965, 0.965), 0.055).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

static func add_embedded_shadow(button: Button, color: Color) -> void:
	var shadow := Panel.new()
	shadow.name = "SoftShadow"
	shadow.position = Vector2(0, 10)
	shadow.size = button.size
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.z_index = -1
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_right = 0
	style.border_width_top = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	style.shadow_color = color
	style.shadow_size = 22
	style.shadow_offset = Vector2(0, 8)
	shadow.add_theme_stylebox_override("panel", style)
	button.add_child(shadow)

static func operation_icon(op: String) -> Texture2D:
	match op:
		"divide":
			return ICON_DIVIDE
		"multiply":
			return ICON_X
		"add":
			return ICON_PLUS
		"subtract":
			return ICON_MINUS
	return ICON_PLUS

static func operation_bg(op: String) -> Color:
	match op:
		"divide":
			return Color("#DCEEFF")
		"multiply":
			return Color("#FFE0E0")
		"add":
			return Color("#E5F6DA")
		"subtract":
			return Color("#FFF5D6")
	return Color.WHITE

static func operation_border(op: String) -> Color:
	match op:
		"divide":
			return Color("#4D9DE0")
		"multiply":
			return Color("#F04A45")
		"add":
			return Color("#58A94F")
		"subtract":
			return Color("#E0A000")
	return BORDER

static func operation_text(op: String) -> Color:
	match op:
		"divide":
			return Color("#143B63")
		"multiply":
			return Color("#C82424")
		"add":
			return Color("#184A24")
		"subtract":
			return Color("#B97B00")
	return TEXT
