class_name UIStyles
extends RefCounted

const AudioManagerScript = preload("res://scripts/audio/AudioManager.gd")

# ============================================================================
# Theme-aware design system ("Soft Glass Indigo").
#
# Colors are exposed as `static var`s (not const) so a single `set_theme()`
# call re-points every token to the active palette. Existing call sites like
# `UIStyles.TEXT` keep working and become theme-reactive after screens rebuild.
# Fonts use the Plus Jakarta Sans variable font via FontVariation per weight.
# ============================================================================

const FONT_500: FontFile = preload("res://assets/fonts/jakarta/jakarta-500.woff2")
const FONT_600: FontFile = preload("res://assets/fonts/jakarta/jakarta-600.woff2")
const FONT_700: FontFile = preload("res://assets/fonts/jakarta/jakarta-700.woff2")
const FONT_800: FontFile = preload("res://assets/fonts/jakarta/jakarta-800.woff2")

# Cyrillic companion to Plus Jakarta Sans. Plus Jakarta ships Latin only, so
# Russian would fall back to a mismatched OS font. Onest is a geometric-humanist
# sans designed in the same spirit as Jakarta (matching x-height, roundness and
# weight range) with full Cyrillic — static per-weight subsets so bold stays
# bold (the variable wght axis does not apply in Godot 4.7). Latin keeps using
# Jakarta; only Cyrillic glyphs fall through to Onest.
const ONEST_500: FontFile = preload("res://assets/fonts/onest/onest-cyrillic-500.woff2")
const ONEST_600: FontFile = preload("res://assets/fonts/onest/onest-cyrillic-600.woff2")
const ONEST_700: FontFile = preload("res://assets/fonts/onest/onest-cyrillic-700.woff2")
const ONEST_800: FontFile = preload("res://assets/fonts/onest/onest-cyrillic-800.woff2")

# --- Icons (theme-independent; recolored at use site via modulate) ---
const ICON_BACK: Texture2D = preload("res://assets/images/icons/arrow-left.svg")
const ICON_CHECK: Texture2D = preload("res://assets/images/icons/check.svg")
const ICON_LEVELS: Texture2D = preload("res://assets/images/icons/dots-nine.svg")
const ICON_GEAR: Texture2D = preload("res://assets/images/icons/gear.svg")
const ICON_INFO: Texture2D = preload("res://assets/images/icons/info.svg")
const ICON_BULB: Texture2D = preload("res://assets/images/icons/lightbulb.svg")
const ICON_LOCK: Texture2D = preload("res://assets/images/icons/lock.svg")
const ICON_MUSIC: Texture2D = preload("res://assets/images/icons/music-notes.svg")
const ICON_SPEAKER: Texture2D = preload("res://assets/images/icons/speaker-high.svg")
const ICON_STAR: Texture2D = preload("res://assets/images/icons/star-fill.svg")
const ICON_STAR_EMPTY: Texture2D = preload("res://assets/images/icons/star-empty-white.svg")
const ICON_LEVEL_STAR: Texture2D = preload("res://assets/images/icons/star-level-fill.svg")
const ICON_LEVEL_STAR_EMPTY: Texture2D = preload("res://assets/images/icons/star-level-empty.svg")
const ICON_X: Texture2D = preload("res://assets/images/icons/x.svg")

# --- Optional Phosphor additions (loaded lazily; may not exist yet) ---
const CARET_LEFT_PATH := "res://assets/images/icons/caret-left.svg"
const CARET_RIGHT_PATH := "res://assets/images/icons/caret-right.svg"
const WARNING_CIRCLE_PATH := "res://assets/images/icons/warning-circle.svg"
const GLOBE_PATH := "res://assets/images/icons/globe.svg"
const SPARKLE_PATH := "res://assets/images/icons/sparkle-fill.svg"

# Shared attention-glow motion. Semantic colors stay owned by each feature, but
# every persistent highlight breathes through the same 18→28px halo and rhythm.
# The range sits between the former tutorial (24px) and Hint (36px) treatments.
const ATTENTION_PULSE_HALF_PERIOD := 1.10
const ATTENTION_GLOW_MIN_EXTENT := 18.0
const ATTENTION_GLOW_MAX_EXTENT := 28.0
const ATTENTION_GLOW_MIN_ALPHA := 0.42
const ATTENTION_GLOW_MAX_ALPHA := 1.0

# --- Fonts (built once in _static_init) ---
static var FONT_REGULAR: Font
static var FONT_MEDIUM: Font
static var FONT_SEMIBOLD: Font
static var FONT_BOLD: Font
static var FONT_EXTRABOLD: Font

# --- Theme-reactive color tokens (set by set_theme) ---
static var BG: Color
static var BG_BLOB_A: Color
static var BG_BLOB_B: Color
static var TEXT: Color
static var MUTED: Color
static var STATUSBAR_TEXT: Color
static var BORDER: Color
static var GLASS_BG: Color
static var GLASS_BORDER: Color
static var GLASS_POPUP_BG: Color
static var GLASS_POPUP_BORDER: Color
static var LOCKED_BG: Color
static var LOCKED_BORDER: Color
static var PURPLE: Color
static var PURPLE_DARK: Color
static var PRIMARY_TOP: Color
static var PRIMARY_BOTTOM: Color
static var GOLD: Color
static var STAR_EMPTY: Color
static var DISABLED: Color
static var DANGER_TEXT: Color
static var DANGER_TOP: Color
static var DANGER_BOTTOM: Color
static var TEAL_TOP: Color
static var TEAL_BOTTOM: Color
static var TARGET_TEXT: Color
static var RING: Color
static var ORBIT_RING: Color
static var ON_ACCENT: Color
static var OPERATION_COLORS: Dictionary
static var COACH_DIM: Color
static var COACH_PANEL_BG: Color
static var COACH_PANEL_BORDER: Color
static var COACH_PANEL_MUTED: Color
static var COACH_DOT_INACTIVE: Color

static var _theme_name: String = "light"
static var _rounded_gradient_cache: Dictionary = {}
static var _circle_gradient_cache: Dictionary = {}
static var _smooth_panel_cache: Dictionary = {}
static var _circle_panel_cache: Dictionary = {}
static var _icon_cache: Dictionary = {}

static func _static_init() -> void:
	# Plus Jakarta Sans ships Latin only, so non-Latin scripts (e.g. Cyrillic for
	# Russian) render as tofu. Chain an OS system font as a fallback on every
	# weight: Latin keeps using Jakarta, Cyrillic falls through to the system.
	_install_cyrillic_fallback()
	# Static weight files (the variable font's wght axis did not apply reliably).
	FONT_REGULAR = FONT_500
	FONT_MEDIUM = FONT_500
	FONT_SEMIBOLD = FONT_600
	FONT_BOLD = FONT_700
	FONT_EXTRABOLD = FONT_800
	set_theme("light")

# ============================================================================
# Theme palettes
# ============================================================================

static func _install_cyrillic_fallback() -> void:
	# Cyrillic falls through to the weight-matched Onest subset first (keeps the
	# Jakarta look + boldness), then a Cyrillic-capable OS font as a last resort.
	var onest := {FONT_500: ONEST_500, FONT_600: ONEST_600, FONT_700: ONEST_700, FONT_800: ONEST_800}
	var weights := {FONT_500: 500, FONT_600: 600, FONT_700: 700, FONT_800: 800}
	for file in weights:
		var sys := SystemFont.new()
		sys.font_names = PackedStringArray(["Inter", "Roboto", "Helvetica Neue", "Arial", "sans-serif"])
		sys.font_weight = int(weights[file])
		(file as FontFile).fallbacks = [onest[file] as Font, sys]

static func theme_name() -> String:
	return _theme_name

static func set_theme(name: String) -> void:
	_theme_name = "dark" if name == "dark" else "light"
	_rounded_gradient_cache.clear()
	_circle_gradient_cache.clear()
	var t: Dictionary = _dark_palette() if _theme_name == "dark" else _light_palette()
	BG = t["bg"]
	BG_BLOB_A = t["blob_a"]
	BG_BLOB_B = t["blob_b"]
	TEXT = t["text"]
	MUTED = t["muted"]
	STATUSBAR_TEXT = t["statusbar_text"]
	GLASS_BG = t["glass_bg"]
	GLASS_BORDER = t["glass_border"]
	GLASS_POPUP_BG = t["glass_popup_bg"]
	GLASS_POPUP_BORDER = t["glass_popup_border"]
	LOCKED_BG = t["locked_bg"]
	LOCKED_BORDER = t["locked_border"]
	BORDER = t["glass_border"]
	PURPLE = t["accent"]
	PURPLE_DARK = t["accent_dark"]
	PRIMARY_TOP = t["primary_top"]
	PRIMARY_BOTTOM = t["primary_bottom"]
	GOLD = t["gold"]
	STAR_EMPTY = t["star_empty"]
	DISABLED = t["disabled"]
	DANGER_TEXT = t["danger_text"]
	DANGER_TOP = t["danger_top"]
	DANGER_BOTTOM = t["danger_bottom"]
	TEAL_TOP = t["teal_top"]
	TEAL_BOTTOM = t["teal_bottom"]
	TARGET_TEXT = t["target_text"]
	RING = t["ring"]
	ORBIT_RING = t["orbit_ring"]
	ON_ACCENT = t["on_accent"]
	OPERATION_COLORS = t["operations"]
	COACH_DIM = t["coach_dim"]
	COACH_PANEL_BG = t["coach_panel_bg"]
	COACH_PANEL_BORDER = t["coach_panel_border"]
	COACH_PANEL_MUTED = t["coach_panel_muted"]
	COACH_DOT_INACTIVE = t["coach_dot_inactive"]

static func is_dark() -> bool:
	return _theme_name == "dark"

static func _light_palette() -> Dictionary:
	return {
		"bg": Color("#FBF9FF"),
		"blob_a": Color("#E4D9FF"),
		"blob_b": Color("#D8C6FF"),
		"text": Color("#1B1233"),
		"muted": Color("#726C88"),
		"statusbar_text": Color("#5A5175"),
		"glass_bg": Color(1, 1, 1, 0.82),
		"glass_border": Color(0.106, 0.071, 0.2, 0.10),
		"glass_popup_bg": Color(1, 1, 1, 1.0),
		"glass_popup_border": Color(0.106, 0.071, 0.2, 0.09),
		"locked_bg": Color(1, 1, 1, 0.60),
		"locked_border": Color(0.106, 0.071, 0.2, 0.08),
		"accent": Color("#9B7BF2"),
		"accent_dark": Color("#5B32C4"),
		"primary_top": Color("#9B7BF2"),
		"primary_bottom": Color("#5B32C4"),
		"gold": Color("#F5A623"),
		"star_empty": Color("#D8D2E0"),
		"disabled": Color("#71757F"),
		"danger_text": Color("#C82424"),
		"danger_top": Color("#FF9B96"),
		"danger_bottom": Color("#E0453F"),
		"teal_top": Color("#7FE3D2"),
		"teal_bottom": Color("#2FB6A8"),
		"target_text": Color("#075E66"),
		"ring": Color("#FBF9FF"),
		"orbit_ring": Color(0.545, 0.361, 0.965, 0.25),
		"on_accent": Color.WHITE,
		"coach_dim": Color(0.078, 0.055, 0.141, 0.46),
		"coach_panel_bg": Color("#FFFFFF"),
		"coach_panel_border": Color(0.106, 0.071, 0.2, 0.09),
		"coach_panel_muted": Color("#8983A0"),
		"coach_dot_inactive": Color(0.106, 0.071, 0.2, 0.10),
		"operations": {
			"add": _operation_swatch("#248E4D", "#155E34", "#E4F5E9", 0.16),
			"subtract": _operation_swatch("#DC3B3B", "#8E1B1B", "#FBE1E0", 0.16),
			"multiply": _operation_swatch("#1478D4", "#184F94", "#E4EFFB", 0.16),
			"divide": _operation_swatch("#E27A20", "#8A4408", "#FBEAD7", 0.16),
		},
	}

static func _dark_palette() -> Dictionary:
	return {
		"bg": Color("#100C1F"),
		"blob_a": Color(0.545, 0.361, 0.965, 0.35),
		"blob_b": Color(0.356, 0.196, 0.768, 0.40),
		"text": Color("#F5F3FF"),
		"muted": Color("#A79CC7"),
		"statusbar_text": Color("#A79CC7"),
		"glass_bg": Color(1, 1, 1, 0.07),
		"glass_border": Color(1, 1, 1, 0.14),
		"glass_popup_bg": Color(0.118, 0.094, 0.216, 1.0),
		"glass_popup_border": Color(1, 1, 1, 0.16),
		"locked_bg": Color(1, 1, 1, 0.04),
		"locked_border": Color(1, 1, 1, 0.08),
		"accent": Color("#A78BFA"),
		"accent_dark": Color("#7C3AED"),
		"primary_top": Color("#A78BFA"),
		"primary_bottom": Color("#7C3AED"),
		"gold": Color("#FBBF24"),
		"star_empty": Color("#4A4460"),
		"disabled": Color("#837C99"),
		"danger_text": Color("#F87171"),
		"danger_top": Color("#F87171"),
		"danger_bottom": Color("#B91C1C"),
		"teal_top": Color("#5EEAD4"),
		"teal_bottom": Color("#14B8A6"),
		"target_text": Color("#053B3B"),
		"ring": Color(0.078, 0.055, 0.149, 0.45),
		"orbit_ring": Color(0.655, 0.545, 0.980, 0.28),
		"on_accent": Color.WHITE,
		"coach_dim": Color(0.031, 0.020, 0.071, 0.58),
		"coach_panel_bg": Color("#1E1837"),
		"coach_panel_border": Color(1, 1, 1, 0.16),
		"coach_panel_muted": Color("#A79CC7"),
		"coach_dot_inactive": Color(1, 1, 1, 0.14),
		"operations": {
			"add": _operation_swatch("#4CD477", "#74E39A", "#173326", 0.14),
			"subtract": _operation_swatch("#FF6060", "#FF9D9D", "#3A1A1E", 0.14),
			"multiply": _operation_swatch("#4C9DFF", "#80B9FF", "#182740", 0.14),
			"divide": _operation_swatch("#FF9F45", "#FFC183", "#35251A", 0.16),
		},
	}

# ============================================================================
# Operator semantics (theme-aware)
# ============================================================================

static func _operation_swatch(border_hex: String, text_hex: String, plate_hex: String, bg_alpha: float) -> Dictionary:
	var border := Color(border_hex)
	var background := border
	background.a = bg_alpha
	return {
		"bg": background,
		"border": border,
		"text": Color(text_hex),
		"plate": Color(plate_hex),
	}

static func _operation_color(op: String, token: String, fallback: Color) -> Color:
	var swatch: Dictionary = OPERATION_COLORS.get(op, {}) as Dictionary
	var color: Color = swatch.get(token, fallback)
	return color

static func operation_bg(op: String) -> Color:
	return _operation_color(op, "bg", Color(1, 1, 1, 0.05) if is_dark() else Color(0, 0, 0, 0.05))

static func operation_border(op: String) -> Color:
	return _operation_color(op, "border", Color(1, 1, 1, 0.18) if is_dark() else Color("#B8B2C4"))

static func operation_text(op: String) -> Color:
	return _operation_color(op, "text", MUTED if is_dark() else Color("#8A8494"))

# Fill color of an operator's chip/plate (shared by the legend chips and the
# orbit satellites so a satellite matches its operator's plate).
static func operation_plate(op: String) -> Color:
	if op == "unavailable":
		return BG.lerp(Color.WHITE, 0.07) if is_dark() else Color("#ECEBF1")
	return _operation_color(op, "plate", BG.lerp(Color.WHITE, 0.07) if is_dark() else Color("#ECEBF1"))

# Difficulty accent color for level-select labels/chips.
static func difficulty_color(difficulty: String) -> Color:
	match difficulty:
		"Easy": return operation_border("add")
		"Medium": return GOLD
		"Hard": return operation_border("subtract")
		"Extreme": return Color("#A855F7")
		"Impossible": return Color("#EC4899")
		"Expert", "Master": return PURPLE
	return PURPLE

# ============================================================================
# Style builders
# ============================================================================

# Universal corner radius from the iPhone 17 Pro mockup (67px on the 1206-wide
# canvas). The canvas width is fixed under stretch "expand", so this stays
# device-independent.
const CORNER := 67
const SMOOTH_CORNER_DETAIL := 96
const SMOOTH_ANTIALIASING_SIZE := 1.25
const SMOOTH_PANEL_SUPERSAMPLE := 1
const PANEL_BORDER_WIDTH := 3

# Primary glass surface used across the redesign. Thin rounded borders use an
# analytic SDF nine-patch instead of StyleBoxFlat: this avoids the faceted
# double edge StyleBoxFlat produces after fractional canvas_items scaling.
static func glass_panel(radius: int = CORNER, heavy: bool = false) -> StyleBoxTexture:
	return smooth_panel(
		GLASS_POPUP_BG if heavy else GLASS_BG,
		GLASS_POPUP_BORDER if heavy else GLASS_BORDER,
		radius,
		PANEL_BORDER_WIDTH
	)

# Tutorial coach card and its non-step P.S. note share one exact glass surface.
static func coach_caption_panel(radius: int = 96) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COACH_PANEL_BG
	style.border_color = COACH_PANEL_BORDER
	_set_border(style, 3)
	_set_radius(style, radius)
	style.shadow_color = Color(0.078, 0.039, 0.157, 0.28)
	style.shadow_size = 120
	style.shadow_offset = Vector2(0, 60)
	return style

static func locked_panel(radius: int = CORNER) -> StyleBoxTexture:
	return smooth_panel(LOCKED_BG, LOCKED_BORDER, radius, PANEL_BORDER_WIDTH)

# Generic filled card (used for colored bubbles / chips with explicit colors).
static func card(bg: Color = Color.WHITE, border: Color = Color.TRANSPARENT, radius: int = CORNER) -> StyleBoxTexture:
	return smooth_panel(bg, border if border.a > 0.0 else GLASS_BORDER, radius, PANEL_BORDER_WIDTH)

# Back-compat alias — old call sites used soft_panel(); now maps to glass.
static func soft_panel(_bg: Color = Color.WHITE, radius: int = 34) -> StyleBoxTexture:
	return glass_panel(radius, false)

# Appearance segmented-toggle track (mockup: faint purple in light, faint white
# in dark, 3px border, full corner).
static func appearance_toggle_bg() -> StyleBoxTexture:
	var bg: Color
	var border: Color
	if is_dark():
		bg = Color(1, 1, 1, 0.05)
		border = Color(1, 1, 1, 0.10)
	else:
		bg = Color(0.545, 0.361, 0.965, 0.08)
		border = Color(0.545, 0.361, 0.965, 0.16)
	return smooth_panel(bg, border, CORNER, PANEL_BORDER_WIDTH)

# Uniform rounded fill + optional border, baked as an analytic SDF nine-patch.
# The small texture is stretched only through its straight center strips;
# corners retain their exact antialiased pixel coverage.
static func smooth_panel(bg: Color, border: Color, radius: int, border_width: int = PANEL_BORDER_WIDTH) -> StyleBoxTexture:
	var safe_radius := maxi(radius, 0)
	var safe_border := maxi(border_width, 0)
	var key := "%s:%s:%d:%d" % [bg.to_html(true), border.to_html(true), safe_radius, safe_border]
	var texture: ImageTexture
	if _smooth_panel_cache.has(key):
		texture = _smooth_panel_cache[key] as ImageTexture
	else:
		texture = _build_smooth_panel_texture(bg, border, safe_radius, safe_border)
		_smooth_panel_cache[key] = texture
	var margin := safe_radius + safe_border
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_right = margin
	style.texture_margin_top = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

static func _build_smooth_panel_texture(bg: Color, border: Color, radius: int, border_width: int) -> ImageTexture:
	var margin := radius + border_width
	var patch_size := maxi(2, margin * 2 + 2)
	var scale := SMOOTH_PANEL_SUPERSAMPLE
	var high_size := patch_size * scale
	var image := Image.create(high_size, high_size, false, Image.FORMAT_RGBA8)
	var half := Vector2(high_size, high_size) * 0.5
	var edge_rgb := border if border.a > 0.0 else bg
	for y in range(high_size):
		for x in range(high_size):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5) - half
			var outer_distance := rounded_rect_sdf(p, half, float(radius * scale))
			var outer_alpha := 1.0 - smoothstep(-1.0, 1.0, outer_distance)
			if outer_alpha <= 0.0:
				image.set_pixel(x, y, Color(edge_rgb.r, edge_rgb.g, edge_rgb.b, 0.0))
				continue
			var inner_alpha := 1.0
			if border_width > 0 and border.a > 0.0:
				var inset := float(border_width * scale)
				var inner_half := half - Vector2(inset, inset)
				var inner_radius := float(maxi(radius - border_width, 0) * scale)
				var inner_distance := rounded_rect_sdf(p, inner_half, inner_radius)
				inner_alpha = 1.0 - smoothstep(-1.0, 1.0, inner_distance)
			var color := border.lerp(bg, inner_alpha) if border_width > 0 and border.a > 0.0 else bg
			color.a *= outer_alpha
			image.set_pixel(x, y, color)
	if scale > 1:
		image.resize(patch_size, patch_size, Image.INTERPOLATE_LANCZOS)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

# Circular glass surface baked as ONE full-size SDF texture (not a nine-patch).
# A nine-patch whose opposing corner margins sum to more than the control size —
# which is the case for any icon button, where radius ≈ half the diameter —
# overlaps its corner regions in the middle and leaves faint antialiased seams at
# the four cardinal points (12/3/6/9 o'clock). Baking the whole disc removes the
# center strip entirely, so no seam can form. The edge stays smooth under the
# canvas's fractional scaling, exactly like circle_gradient_texture.
static func circle_panel(diameter: int, bg: Color, border: Color, border_width: int = PANEL_BORDER_WIDTH) -> StyleBoxTexture:
	var safe_d := maxi(diameter, 1)
	var safe_border := maxi(border_width, 0)
	var key := "%d:%s:%s:%d" % [safe_d, bg.to_html(true), border.to_html(true), safe_border]
	var texture: ImageTexture
	if _circle_panel_cache.has(key):
		texture = _circle_panel_cache[key] as ImageTexture
	else:
		texture = _build_circle_texture(safe_d, bg, border, safe_border)
		_circle_panel_cache[key] = texture
	var style := StyleBoxTexture.new()
	style.texture = texture
	# Zero texture margins → the texture is drawn as a single stretched quad with
	# no nine-slice, so there is no center strip and no seam.
	style.texture_margin_left = 0
	style.texture_margin_right = 0
	style.texture_margin_top = 0
	style.texture_margin_bottom = 0
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

static func _build_circle_texture(diameter: int, bg: Color, border: Color, border_width: int) -> ImageTexture:
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var center := Vector2(diameter, diameter) * 0.5
	var outer_r := float(diameter) * 0.5
	var inner_r := outer_r - float(border_width)
	var has_border := border_width > 0 and border.a > 0.0
	# Fully-transparent pixels keep the rim's RGB (alpha 0) so the linear filter /
	# mipmaps never bleed black into the antialiased edge.
	var edge_rgb := border if has_border else bg
	for y in range(diameter):
		for x in range(diameter):
			var d := (Vector2(float(x) + 0.5, float(y) + 0.5) - center).length()
			var outer_alpha := sdf_alpha(d - outer_r)
			if outer_alpha <= 0.0:
				image.set_pixel(x, y, Color(edge_rgb.r, edge_rgb.g, edge_rgb.b, 0.0))
				continue
			var inner_alpha := sdf_alpha(d - inner_r) if has_border else 1.0
			var color := border.lerp(bg, inner_alpha) if has_border else bg
			color.a *= outer_alpha
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

static func _set_border(style: StyleBoxFlat, width: int) -> void:
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width

static func _set_radius(style: StyleBoxFlat, radius: int) -> void:
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.corner_detail = SMOOTH_CORNER_DETAIL
	style.anti_aliasing = true
	style.anti_aliasing_size = SMOOTH_ANTIALIASING_SIZE

static func apply_font(control: Control, font: Font = null, size: int = 28, color: Color = Color.TRANSPARENT) -> void:
	control.add_theme_font_override("font", font if font != null else FONT_SEMIBOLD)
	control.add_theme_font_size_override("font_size", size)
	var resolved := TEXT if color == Color.TRANSPARENT else color
	control.add_theme_color_override("font_color", resolved)

# ============================================================================
# Buttons
# ============================================================================

static func menu_button(button: Button, radius: int = CORNER) -> void:
	var normal := glass_panel(radius, false)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal.duplicate())
	button.add_theme_stylebox_override("pressed", normal.duplicate())
	button.add_theme_stylebox_override("disabled", normal.duplicate())
	apply_font(button, FONT_SEMIBOLD, int(button.get_theme_font_size("font_size")), TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_focus_color", TEXT)
	add_press_animation(button, radius)

static func primary_button(button: Button, radius: int = CORNER) -> void:
	_gradient_button(button, PRIMARY_TOP, PRIMARY_BOTTOM, radius)

static func danger_button(button: Button, radius: int = CORNER) -> void:
	_gradient_button(button, DANGER_TOP, DANGER_BOTTOM, radius)

static func _gradient_button(button: Button, top: Color, bottom: Color, radius: int) -> void:
	# Bake the gradient at the button's REAL size (9-slicing a fixed-size bake
	# breaks once corner margins exceed the button: corners overlap and the
	# button renders as an inflated pill bleeding over its neighbors).
	var restyle := func() -> void:
		var size := Vector2i(button.size)
		if size.x <= 0 or size.y <= 0:
			return
		var normal := gradient_style(top, bottom, radius, size)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", normal.duplicate())
		button.add_theme_stylebox_override("pressed", normal.duplicate())
		button.add_theme_stylebox_override("disabled", normal.duplicate())
	restyle.call()
	button.resized.connect(restyle)
	apply_font(button, FONT_BOLD, int(button.get_theme_font_size("font_size")), ON_ACCENT)
	button.add_theme_color_override("font_hover_color", ON_ACCENT)
	button.add_theme_color_override("font_pressed_color", ON_ACCENT)
	button.add_theme_color_override("font_focus_color", ON_ACCENT)
	add_press_animation(button, radius)

static func gradient_style(top: Color, bottom: Color, radius: int, texture_size: Vector2i) -> StyleBoxTexture:
	# Radius may not exceed half the smaller side, or the 9-slice corner
	# margins overlap and the fill distorts.
	var r := mini(radius, mini(texture_size.x, texture_size.y) / 2)
	var texture := rounded_gradient_texture(top, bottom, r, texture_size)
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = r
	style.texture_margin_right = r
	style.texture_margin_top = r
	style.texture_margin_bottom = r
	# Content margins default to the texture margins (r≈67), which inflates a
	# button's minimum size and makes it overflow its slot (e.g. the dark theme
	# toggle bled past its container). Zero them — buttons are sized explicitly.
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

static func rounded_gradient_texture(top: Color, bottom: Color, radius: int, texture_size: Vector2i) -> ImageTexture:
	var key := "%s:%s:%d:%d:%d" % [top.to_html(true), bottom.to_html(true), radius, texture_size.x, texture_size.y]
	if _rounded_gradient_cache.has(key):
		return _rounded_gradient_cache[key] as ImageTexture
	var image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var w := texture_size.x
	var h := texture_size.y
	# Diagonal 135° gradient (top-left → bottom-right) to match the mockup's
	# linear-gradient(135deg,…); reads glossier than a flat vertical fill.
	var denom := float(max(1, w + h - 2))
	for y in range(h):
		for x in range(w):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			var dist := rounded_rect_sdf(p - Vector2(w, h) * 0.5, Vector2(w, h) * 0.5, float(radius))
			var alpha := sdf_alpha(dist)
			if alpha > 0.0:
				var t := float(x + y) / denom
				var color := top.lerp(bottom, t)
				color.a *= alpha
				image.set_pixel(x, y, color)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_rounded_gradient_cache[key] = texture
	return texture

static func circle_gradient_texture(diameter: int, top: Color, bottom: Color) -> ImageTexture:
	var key := "%d:%s:%s" % [diameter, top.to_html(true), bottom.to_html(true)]
	if _circle_gradient_cache.has(key):
		return _circle_gradient_cache[key] as ImageTexture
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var radius := float(diameter) * 0.5
	var center := Vector2(radius, radius)
	var denom := float(max(1, 2 * (diameter - 1)))
	for y in range(diameter):
		for x in range(diameter):
			var offset := Vector2(float(x) + 0.5, float(y) + 0.5) - center
			var alpha := sdf_alpha(offset.length() - radius)
			if alpha > 0.0:
				# Diagonal 135° gradient to match the primary button's fill.
				var t := float(x + y) / denom
				var color := top.lerp(bottom, t)
				color.a *= alpha
				image.set_pixel(x, y, color)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_circle_gradient_cache[key] = texture
	return texture

static func rounded_rect_sdf(p: Vector2, half_size: Vector2, radius: float) -> float:
	var q := Vector2(absf(p.x), absf(p.y)) - half_size + Vector2(radius, radius)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - radius

static func sdf_alpha(distance: float) -> float:
	return 1.0 - smoothstep(-1.0, 1.0, distance)

# ============================================================================
# Icons & helpers
# ============================================================================

static func has_icon(path: String) -> bool:
	return load_icon(path) != null

static func load_icon(path: String) -> Texture2D:
	if not _icon_cache.has(path):
		var tex: Texture2D = null
		if ResourceLoader.exists(path):
			tex = load(path)
		_icon_cache[path] = tex
	return _icon_cache[path] as Texture2D

static func sparkle_mark(parent: Node, position: Vector2, size: Vector2, color: Color = Color.WHITE) -> Control:
	var tex := load_icon(SPARKLE_PATH)
	if tex != null:
		return icon(tex, parent, position, size, color)
	var icon := Control.new()
	icon.position = position
	icon.size = size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	_draw_phosphor_sparkle(icon, size, color)
	return icon

static func recolor_sparkle_mark(icon: Control, color: Color) -> void:
	if not is_instance_valid(icon):
		return
	if icon is CanvasItem:
		(icon as CanvasItem).modulate = color
	for child in icon.get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate = color

static func _draw_phosphor_sparkle(parent: Control, size: Vector2, color: Color) -> void:
	var main := Polygon2D.new()
	main.color = Color.WHITE
	main.modulate = color
	var raw := [
		Vector2(112, 54),
		Vector2(137, 120),
		Vector2(203, 144),
		Vector2(137, 168),
		Vector2(112, 234),
		Vector2(87, 168),
		Vector2(21, 144),
		Vector2(87, 120),
	]
	var points := PackedVector2Array()
	for point in raw:
		points.append(Vector2(point.x / 256.0 * size.x, point.y / 256.0 * size.y))
	main.polygon = points
	parent.add_child(main)
	_add_sparkle_cross(parent, Vector2(size.x * 176.0 / 256.0, size.y * 68.0 / 256.0), size.x * 40.0 / 256.0, maxf(2.0, size.x * 0.10), color)
	_add_sparkle_cross(parent, Vector2(size.x * 204.0 / 256.0, size.y * 112.0 / 256.0), size.x * 32.0 / 256.0, maxf(2.0, size.x * 0.09), color)

static func _add_sparkle_cross(parent: Control, center: Vector2, length: float, width: float, color: Color) -> void:
	for axis in [Vector2.RIGHT, Vector2.DOWN]:
		var line := Line2D.new()
		line.width = width
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.default_color = Color.WHITE
		line.modulate = color
		line.add_point(center - axis * length * 0.5)
		line.add_point(center + axis * length * 0.5)
		parent.add_child(line)

# Icons ship as white-fill monochrome SVGs, so a plain modulate multiply can
# tint them to any theme color (including dynamic recolors via .modulate).
static func icon(texture: Texture2D, parent: Node, position: Vector2, size: Vector2, color: Color = Color.TRANSPARENT) -> TextureRect:
	var rect := TextureRect.new()
	# expand_mode must be set before size: with the default KEEP_SIZE the hi-res
	# (256px) texture would force a large minimum size and ignore the set size.
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture = texture
	rect.custom_minimum_size = Vector2.ZERO
	rect.position = position
	rect.size = size
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rect.modulate = color if color != Color.TRANSPARENT else TEXT
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

# Circular glass icon button (header back/settings pattern). It uses the same
# analytic SDF border as the larger glass panels.
static func circle_button(parent: Node, position: Vector2, diameter: float = 127.0) -> Button:
	var button := Button.new()
	button.position = position
	button.size = Vector2(diameter, diameter)
	# A full-disc bake (not a nine-patch) — the corner margins of a nine-patch
	# whose radius is half the size overlap and leave seams at the cardinal points.
	var normal := circle_panel(int(round(diameter)), GLASS_BG, GLASS_BORDER, PANEL_BORDER_WIDTH)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal.duplicate())
	button.add_theme_stylebox_override("pressed", normal.duplicate())
	button.add_theme_stylebox_override("disabled", normal.duplicate())
	# Hover overlay radius = true half-diameter so the tint stays a perfect circle.
	add_press_animation(button, int(diameter * 0.5))
	parent.add_child(button)
	return button

# Soft lavender secondary button — the mockup's Cancel / "Back to Levels" pill:
# 10% purple fill, purple bold text, no border.
static func soft_button(button: Button, radius: int = CORNER) -> void:
	var normal := StyleBoxFlat.new()
	# Mockup secondary: light = 10% purple fill + #5B32C4 text; dark = 8% white
	# fill + #C4B5FD text.
	normal.bg_color = Color(1, 1, 1, 0.08) if is_dark() else Color(PURPLE.r, PURPLE.g, PURPLE.b, 0.10)
	_set_radius(normal, radius)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal.duplicate())
	button.add_theme_stylebox_override("pressed", normal.duplicate())
	button.add_theme_stylebox_override("disabled", normal.duplicate())
	var text_color := Color("#C4B5FD") if is_dark() else PURPLE_DARK
	apply_font(button, FONT_BOLD, int(button.get_theme_font_size("font_size")), text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	add_press_animation(button, radius)

# Soft (tinted) danger button — pale red fill + red text, matching the Reset
# Progress pill in the mockup (not the solid gradient used for confirm dialogs).
static func danger_soft_button(button: Button, radius: int = CORNER) -> void:
	# Mockup: pale coral fill + coral border. Text stays crimson.
	var tint := DANGER_TEXT if is_dark() else Color(0.941, 0.392, 0.372)  # coral #F0645F
	var normal := smooth_panel(
		Color(tint.r, tint.g, tint.b, 0.14),
		Color(tint.r, tint.g, tint.b, 0.30),
		radius,
		PANEL_BORDER_WIDTH
	)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal.duplicate())
	button.add_theme_stylebox_override("pressed", normal.duplicate())
	button.add_theme_stylebox_override("disabled", normal.duplicate())
	apply_font(button, FONT_BOLD, int(button.get_theme_font_size("font_size")), DANGER_TEXT)
	button.add_theme_color_override("font_hover_color", DANGER_TEXT)
	button.add_theme_color_override("font_pressed_color", DANGER_TEXT)
	add_press_animation(button, radius)

static func back_button(parent: Node, position: Vector2 = Vector2(67, 74)) -> Button:
	var button := circle_button(parent, position, 127.0)
	var tex: Texture2D = load_icon(CARET_LEFT_PATH)
	if tex == null:
		tex = ICON_BACK
	icon(tex, button, Vector2(34, 34), Vector2(60, 60), TEXT)
	return button

static func pop_scale(control: Control, peak: float, out_duration: float = 0.10, in_duration: float = 0.14) -> void:
	if control == null:
		return
	if control.has_meta("pop_scale_tween"):
		var previous := control.get_meta("pop_scale_tween") as Tween
		if previous != null and previous.is_valid():
			previous.kill()
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween()
	control.set_meta("pop_scale_tween", tween)
	tween.tween_property(control, "scale", Vector2(peak, peak), out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, in_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		if is_instance_valid(control):
			control.remove_meta("pop_scale_tween")
	)

static func attention_glow_extent(level: float) -> float:
	return lerpf(ATTENTION_GLOW_MIN_EXTENT, ATTENTION_GLOW_MAX_EXTENT, clampf(level, 0.0, 1.0))

static func attention_glow_alpha(level: float) -> float:
	return lerpf(ATTENTION_GLOW_MIN_ALPHA, ATTENTION_GLOW_MAX_ALPHA, clampf(level, 0.0, 1.0))

# Hover overlay opacity at full hover. Dark theme lightens (white overlay), light
# theme darkens (black overlay) — a soft tint that reads on either surface. Kept
# per-theme because black reads a touch heavier than white at equal opacity.
const HOVER_LIGHTEN_ALPHA := 0.04   # dark theme: white overlay
const HOVER_DARKEN_ALPHA := 0.04    # light theme: black overlay
# Press feedback scale (held-down size); springs back to 1.0 on release.
const PRESS_SCALE := 0.95

# Hover feedback = a soft tint overlay (darken in light theme / lighten in dark),
# NOT a scale-up; press feedback stays a small scale-down. `highlight_radius`
# sets the overlay corner radius for gradient-textured buttons (whose baked fill
# has no readable StyleBoxFlat radius); StyleBoxFlat buttons auto-match theirs.
static func add_press_animation(button: Button, highlight_radius: int = -1) -> void:
	button.pivot_offset = button.size * 0.5
	if highlight_radius >= 0:
		button.set_meta("hover_radius", highlight_radius)
	button.mouse_entered.connect(func() -> void: _hover_highlight(button, true))
	button.mouse_exited.connect(func() -> void: _hover_highlight(button, false))
	# Press = a hold: shrink on button-down, spring back on button-up (not a
	# one-shot bounce on click), so a held button stays shrunk.
	button.button_down.connect(func() -> void:
		AudioManagerScript.play_ui_tap()
		press_hold(button, true)
	)
	button.button_up.connect(func() -> void: press_hold(button, false))

# Press-hold feedback: the control shrinks while held (pressed=true) and springs
# smoothly back to full size on release (pressed=false). Smooth ease-out with no
# overshoot, so it doesn't read as jerky. Scales around the control's current
# pivot_offset — callers set a custom pivot for off-center shapes; buttons
# default to their own center.
static func press_hold(control: Control, pressed: bool) -> void:
	if not is_instance_valid(control):
		return
	var tween := control.create_tween()
	if pressed:
		tween.tween_property(control, "scale", Vector2(PRESS_SCALE, PRESS_SCALE), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(control, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

static func _hover_highlight(button: Button, entering: bool) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	fade_hover_tint(_ensure_hover_highlight(button), entering)

# Fade a tint overlay for a hover interaction: on enter it takes the CURRENT
# theme's tint (dark = lighten / white, light = darken / black) and fades to the
# hover opacity; on exit it fades back out. Resolving per-hover keeps a cached
# overlay correct after a theme switch. Reused by buttons and by bespoke hover
# targets (e.g. the LEVEL / MOVES status halves).
static func fade_hover_tint(overlay: Control, entering: bool) -> void:
	if not is_instance_valid(overlay):
		return
	var target := 0.0
	if entering:
		var sb := overlay.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).bg_color = Color(1, 1, 1) if is_dark() else Color(0, 0, 0)
		target = HOVER_LIGHTEN_ALPHA if is_dark() else HOVER_DARKEN_ALPHA
	var tween := overlay.create_tween()
	tween.tween_property(overlay, "modulate:a", target, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Wire hover on `source` to fade the tint `overlay` in/out — for non-button hover
# targets. `overlay` must already be a child, shaped/positioned as desired, with a
# StyleBoxFlat "panel" and modulate.a = 0.
static func attach_hover_tint(source: Control, overlay: Control) -> void:
	source.mouse_entered.connect(func() -> void: fade_hover_tint(overlay, true))
	source.mouse_exited.connect(func() -> void: fade_hover_tint(overlay, false))

# Lazily create (once) the white highlight overlay that fades in on hover. Shaped
# to the button: matches a StyleBoxFlat button's corner radius, or a supplied
# `hover_radius` for gradient-textured buttons, clamped to a valid rounded rect.
static func _ensure_hover_highlight(button: Button) -> Panel:
	var existing := button.get_node_or_null("HoverHighlight")
	if existing is Panel:
		return existing as Panel
	var hl := Panel.new()
	hl.name = "HoverHighlight"
	hl.set_anchors_preset(Control.PRESET_FULL_RECT)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Some scroll surfaces apply their edge mask through inherited materials.
	# This overlay is created lazily after those surfaces have propagated the
	# material flag, so mirror the button's flag instead of bypassing the mask.
	# Outside such a surface the flag remains false and behavior is unchanged.
	hl.use_parent_material = button.use_parent_material
	hl.modulate.a = 0.0
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1) if is_dark() else Color(0, 0, 0)
	s.anti_aliasing = true
	_set_radius(s, _hover_radius_for(button))
	hl.add_theme_stylebox_override("panel", s)
	button.add_child(hl)
	return hl

static func _hover_radius_for(button: Button) -> int:
	var max_radius := int(minf(button.size.x, button.size.y) * 0.5)
	if button.has_meta("hover_radius"):
		return mini(int(button.get_meta("hover_radius")), max_radius)
	var base := button.get_theme_stylebox("normal")
	if base is StyleBoxFlat:
		return mini(int((base as StyleBoxFlat).corner_radius_top_left), max_radius)
	return max_radius

# Diagonal (135°) gradient FILL for label text — matches the primary button. The
# label must be sized to its text (VERTEX is normalized by rect_size).
static func gradient_text_material(top: Color, bottom: Color, rect_size: Vector2) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 top_color : source_color;
uniform vec4 bottom_color : source_color;
uniform vec2 rect_size = vec2(1.0, 1.0);
varying vec2 vpos;
void vertex() { vpos = VERTEX; }
void fragment() {
	float t = clamp((vpos.x / max(rect_size.x, 1.0) + vpos.y / max(rect_size.y, 1.0)) * 0.5, 0.0, 1.0);
	vec4 grad = mix(top_color, bottom_color, t);
	COLOR = vec4(grad.rgb, texture(TEXTURE, UV).a * grad.a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("top_color", top)
	mat.set_shader_parameter("bottom_color", bottom)
	mat.set_shader_parameter("rect_size", rect_size)
	return mat
