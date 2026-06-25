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
const ICON_SPEAKER: Texture2D = preload("res://assets/images/icons/speaker-high.svg")
const ICON_STAR: Texture2D = preload("res://assets/images/icons/star-fill.svg")
const ICON_STAR_EMPTY: Texture2D = preload("res://assets/images/icons/star-empty-white.svg")
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
	style.shadow_color = Color(0.10, 0.10, 0.18, 0.08)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 10)
	return style

static func soft_panel(bg: Color = Color.WHITE, radius: int = 34) -> StyleBoxFlat:
	var style: StyleBoxFlat = card(bg, Color(1, 1, 1, 0.70), radius)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.shadow_color = Color(0.12, 0.12, 0.22, 0.11)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 14)
	return style

static func apply_font(control: Control, font: Font = FONT_SEMIBOLD, size: int = 28, color: Color = TEXT) -> void:
	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)

static func menu_button(button: Button) -> void:
	var normal: StyleBoxFlat = soft_panel(Color.WHITE, 30)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#F8F5FF")
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#F0E9FF")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	apply_font(button, FONT_SEMIBOLD, int(button.get_theme_font_size("font_size")), TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_focus_color", TEXT)
	add_press_animation(button)

static func primary_button(button: Button) -> void:
	var normal: StyleBoxFlat = card(PURPLE, PURPLE_DARK, 28)
	normal.border_width_bottom = 5
	normal.shadow_color = Color(0.42, 0.22, 0.88, 0.28)
	normal.shadow_size = 26
	normal.shadow_offset = Vector2(0, 14)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = PURPLE.lightened(0.05)
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = PURPLE_DARK
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	apply_font(button, FONT_SEMIBOLD, int(button.get_theme_font_size("font_size")), Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	add_press_animation(button)

static func pill(label: Label) -> void:
	label.add_theme_stylebox_override("normal", soft_panel(Color.WHITE, 24))

static func icon(texture: Texture2D, parent: Node, position: Vector2, size: Vector2, color: Color = TEXT) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.texture = texture
	rect.position = position
	rect.size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

static func add_press_animation(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	button.pressed.connect(func() -> void:
		if not is_instance_valid(button):
			return
		var tween: Tween = button.create_tween()
		tween.tween_property(button, "scale", Vector2(0.965, 0.965), 0.055).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

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
