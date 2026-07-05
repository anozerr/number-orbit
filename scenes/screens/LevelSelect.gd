class_name LevelSelectScreen
extends Control

signal back_pressed
signal settings_pressed
signal level_selected(level_number: int)
signal unlock_with_ad_requested(level_number: int)

var locked_popup: Control
var locked_popup_body: Label
var locked_popup_ad_button: Button
var locked_popup_close_button: Button
var locked_popup_level_number: int = -1
var last_scroll: ScrollContainer
var content_width := 940.0

# Horizontal breathing room INSIDE the scroll viewport so the hover-scale (1.018)
# on the How-to card / edge tiles isn't clipped by the ScrollContainer's edges.
# The visual tile grid still spans `content_width`; the scroll is just wider and
# the grid is offset by GRID_PAD. TOP_PAD gives the first row vertical room.
const GRID_PAD := 30.0
const TOP_PAD := 16.0
# Length of the top/bottom dissolve. The scroll viewport extends this far BELOW
# the unified bottom line so a row is still fully opaque AT the line and only
# fades past it (fade completing on the line made the page look shorter).
const SCROLL_FADE_PX := 100.0

# Cached args so a viewport resize can re-lay out.
var _star_ratings: Array = []
var _max_unlocked := 1
var _tutorial_completed: Array = []
var _has_data := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	if visible and _has_data:
		rebuild_level_difficulties(_star_ratings, _max_unlocked, _tutorial_completed)

func rebuild_level_difficulties(star_ratings: Array, max_unlocked_level: int, tutorial_completed: Array = []) -> void:
	_star_ratings = star_ratings
	_max_unlocked = max_unlocked_level
	_tutorial_completed = tutorial_completed
	_has_data = true

	for child in get_children():
		child.queue_free()
	last_scroll = null

	var col := Layout.content_column(self)
	content_width = col.size.x
	var top := Layout.content_top(self)

	# --- Header ---
	var back := UIStyles.back_button(self, Vector2(maxf(Layout.SIDE_MARGIN, col.position.x), top + 74.0))
	back.pressed.connect(func(): back_pressed.emit())

	var settings_btn := UIStyles.circle_button(self, Vector2(col.position.x + content_width - 127.0, top + 74.0), 127.0)
	settings_btn.pressed.connect(func(): settings_pressed.emit())
	UIStyles.icon(UIStyles.ICON_GEAR, settings_btn, Vector2(33, 33), Vector2(60, 60), UIStyles.TEXT)

	var title := Label.new()
	title.text = Locale.t("levels.title", "Levels")
	title.position = Vector2(col.position.x, top)
	title.size = Vector2(content_width, 275)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_EXTRABOLD, 54, UIStyles.TEXT)
	add_child(title)

	# --- Scroll region: starts just below the header row (was top+322, which left
	# a big empty gap between the back/settings buttons and the fade). ---
	# Scroll ends on the unified bottom line so the bottom fade sits where the
	# operator chips end on the game screen (same bottom edge on every screen).
	var scroll_top := top + 236.0
	# Bottom of the visible scroll = the unified line plus HALF a fade length, so
	# the dissolve is centred on the line (≈50% opacity there): a row is still
	# clearly present at the line but already dissolving — a middle ground between
	# "fully gone at the line" (page looked short) and "fully solid at the line"
	# (page looked long).
	var scroll_bottom := Layout.content_bottom_line(self) + SCROLL_FADE_PX * 0.5
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(col.position.x - GRID_PAD, scroll_top)
	scroll.size = Vector2(content_width + GRID_PAD * 2.0, scroll_bottom - scroll_top)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	scroll.get_v_scroll_bar().modulate = Color(0, 0, 0, 0)
	last_scroll = scroll

	var content := Control.new()
	content.custom_minimum_size = Vector2(content_width + GRID_PAD * 2.0, 0)
	scroll.add_child(content)

	var y := TOP_PAD
	y = add_tutorials_section(content, y, tutorial_completed)
	y += 67.0
	var tutorials_done := are_all_tutorials_completed(tutorial_completed)
	for difficulty_index in range(LevelData.DIFFICULTIES.size()):
		y = add_difficulty_section(content, difficulty_index, y, star_ratings, max_unlocked_level, tutorials_done)
		y += 108.0
	content.custom_minimum_size = Vector2(content_width + GRID_PAD * 2.0, y - 108.0 + 60.0)

	apply_scroll_fade(scroll)

	build_locked_level_popup()
	# Auto-scroll to the last unlocked level was removed — it got in the way.

# Alpha-fade the scroll content near the scroll region's top/bottom edges.
# The fade shader sits on the ScrollContainer and every descendant opts into it
# via use_parent_material, so the CONTENT dissolves per-fragment in screen
# space — any gradient background shows through with no color bands (a flat
# fade strip is visible over a non-uniform bg).
func apply_scroll_fade(scroll: ScrollContainer) -> void:
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float band_top = 0.0;
uniform float band_bottom = 1.0;
uniform float fade_px = 100.0;
uniform float viewport_h = 1920.0;
uniform float scroll_offset = 0.0;
uniform float max_scroll = 100000.0;

void fragment() {
	float y = SCREEN_UV.y * viewport_h;
	float top_fade = smoothstep(band_top, band_top + fade_px, y);
	float bottom_fade = smoothstep(band_bottom, band_bottom - fade_px, y);
	// Only fade an edge once content is actually scrolled past it, so the first
	// row (How-to) is fully opaque at the very top and the last row at the bottom.
	float top_gate = clamp(scroll_offset / fade_px, 0.0, 1.0);
	float bottom_gate = clamp((max_scroll - scroll_offset) / fade_px, 0.0, 1.0);
	top_fade = mix(1.0, top_fade, top_gate);
	bottom_fade = mix(1.0, bottom_fade, bottom_gate);
	COLOR.a *= top_fade * bottom_fade;
}
"""
	mat.shader = shader
	var vp := Layout.viewport_size(self)
	mat.set_shader_parameter("band_top", scroll.position.y)
	mat.set_shader_parameter("band_bottom", scroll.position.y + scroll.size.y)
	mat.set_shader_parameter("fade_px", SCROLL_FADE_PX)
	mat.set_shader_parameter("viewport_h", vp.y)
	mat.set_shader_parameter("scroll_offset", 0.0)
	mat.set_shader_parameter("max_scroll", 100000.0)
	scroll.material = mat
	_use_parent_material_recursive(scroll)
	# Drive the edge gates from the live scroll position.
	var vbar := scroll.get_v_scroll_bar()
	var refresh_fade := func(_v: float = 0.0) -> void:
		if not is_instance_valid(scroll) or scroll.material == null:
			return
		var m := scroll.material as ShaderMaterial
		m.set_shader_parameter("scroll_offset", float(scroll.scroll_vertical))
		m.set_shader_parameter("max_scroll", maxf(1.0, vbar.max_value - vbar.page))
	vbar.value_changed.connect(refresh_fade)
	refresh_fade.call_deferred()

func _use_parent_material_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			(child as CanvasItem).use_parent_material = true
		_use_parent_material_recursive(child)

# ---------------------------------------------------------------------------
# Tutorial "How to Play" row
# ---------------------------------------------------------------------------

func add_tutorials_section(parent: Control, y: float, tutorial_completed: Array) -> float:
	var completed := are_all_tutorials_completed(tutorial_completed)
	var row_h := 268.0
	var btn := Button.new()
	btn.size = Vector2(content_width, row_h)
	btn.position = Vector2(GRID_PAD, y)
	UIStyles.menu_button(btn)
	UIStyles.add_press_animation(btn)
	btn.pressed.connect(_on_level_button_pressed.bind(-1))
	parent.add_child(btn)

	# Circular gradient icon badge.
	var badge := Panel.new()
	badge.size = Vector2(147, 147)
	badge.position = Vector2(67, (row_h - 147) * 0.5)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", UIStyles.card(UIStyles.PURPLE, UIStyles.RING, 74))
	btn.add_child(badge)
	# Always the lightbulb (matches the mockup), regardless of tutorial completion.
	var icon_texture: Texture2D = UIStyles.ICON_BULB
	UIStyles.icon(icon_texture, badge, Vector2(37, 37), Vector2(74, 74), Color.WHITE)

	var name_lbl := Label.new()
	name_lbl.text = Locale.t("levels.howto.title", "How to Play")
	name_lbl.position = Vector2(261, 76)
	name_lbl.size = Vector2(content_width - 320, 60)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyles.apply_font(name_lbl, UIStyles.FONT_BOLD, 50, UIStyles.TEXT)
	btn.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = Locale.t("levels.howto.sub", "Tutorial · order, hints, operators")
	desc_lbl.position = Vector2(261, 148)
	desc_lbl.size = Vector2(content_width - 320, 50)
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyles.apply_font(desc_lbl, UIStyles.FONT_MEDIUM, 39, UIStyles.MUTED)
	btn.add_child(desc_lbl)

	return y + row_h

# ---------------------------------------------------------------------------
# Difficulty section with level chips
# ---------------------------------------------------------------------------

func add_difficulty_section(parent: Control, difficulty_index: int, y: float, star_ratings: Array, max_unlocked_level: int, tutorials_done: bool = true) -> float:
	var diff_color := section_color(difficulty_index)
	var diff_name := str(LevelData.DIFFICULTIES[difficulty_index])
	var title := Label.new()
	title.text = Locale.t("difficulty.%s" % diff_name.to_lower(), diff_name).to_upper()
	title.position = Vector2(GRID_PAD, y)
	title.size = Vector2(content_width, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 0)
	UIStyles.apply_font(title, UIStyles.FONT_EXTRABOLD, 47, diff_color)
	parent.add_child(title)

	var m := chip_metrics()
	var pad: float = m["pad"]
	var gutter: float = m["gutter"]
	var chip: float = m["chip"]
	var row_gap: float = m["row_gap"]
	var start_y := y + 93.0

	for i in range(LevelData.LEVELS_PER_DIFFICULTY):
		var local_level: int = i + 1
		var global_level: int = difficulty_index * LevelData.LEVELS_PER_DIFFICULTY + local_level
		var unlocked: bool = tutorials_done and global_level <= max_unlocked_level
		var rating: int = int(star_ratings[global_level - 1]) if global_level - 1 < star_ratings.size() else 0
		var completed: bool = rating > 0
		var col_i := i % 3
		var row_i := int(float(i) / 3.0)
		var cx := pad + col_i * (chip + gutter)
		var cy := start_y + row_i * row_gap
		build_level_chip(parent, Vector2(cx, cy), Vector2(chip, chip), global_level, rating, completed, unlocked, diff_color, tutorials_done, max_unlocked_level)

	var rows := int(ceil(float(LevelData.LEVELS_PER_DIFFICULTY) / 3.0))
	return start_y + float(rows) * row_gap - (row_gap - chip)

# Shared chip grid metrics (inset by GRID_PAD so card shadows aren't clipped by
# the scroll container at the left/right edges).
func chip_metrics() -> Dictionary:
	var gutter := 53.0
	var chip := (content_width - gutter * 2.0) / 3.0
	return {"pad": GRID_PAD, "gutter": gutter, "chip": chip, "row_gap": chip + 40.0}

func build_level_chip(parent: Control, pos: Vector2, chip_size: Vector2, global_level: int, rating: int, completed: bool, unlocked: bool, diff_color: Color, tutorials_done: bool, max_unlocked_level: int) -> void:
	var btn := Button.new()
	btn.text = ""
	btn.size = chip_size
	btn.position = pos
	UIStyles.add_press_animation(btn)
	style_level_chip(btn, completed, unlocked, diff_color)
	if unlocked:
		btn.pressed.connect(_on_level_button_pressed.bind(global_level))
	else:
		var can_watch_ad := tutorials_done and global_level == max_unlocked_level + 1
		btn.pressed.connect(show_locked_level_popup.bind(global_level, can_watch_ad))
	parent.add_child(btn)

	var num := Label.new()
	num.text = str(global_level)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	num.position = Vector2(0, chip_size.y * 0.22)
	num.size = Vector2(chip_size.x, chip_size.y * 0.42)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var num_color := diff_color if completed else (UIStyles.TEXT if unlocked else UIStyles.DISABLED)
	UIStyles.apply_font(num, UIStyles.FONT_EXTRABOLD, int(chip_size.y * 0.27), num_color)
	btn.add_child(num)

	if unlocked:
		var stars := Control.new()
		stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars.position = Vector2(0, chip_size.y * 0.66)
		stars.size = Vector2(chip_size.x, 34)
		btn.add_child(stars)
		add_star_icons(stars, rating)
	else:
		var caption := Label.new()
		caption.text = Locale.t("levels.locked", "LOCKED")
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.position = Vector2(0, chip_size.y * 0.64)
		caption.size = Vector2(chip_size.x, 34)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_font(caption, UIStyles.FONT_BOLD, 34, UIStyles.DISABLED)
		btn.add_child(caption)

func style_level_chip(button: Button, completed: bool, unlocked: bool, diff_color: Color) -> void:
	var normal: StyleBoxFlat
	if not unlocked:
		normal = UIStyles.locked_panel()
		button.modulate = Color(1, 1, 1, 0.72)
	elif completed:
		var tint := Color(diff_color.r, diff_color.g, diff_color.b, 0.16)
		normal = UIStyles.card(tint, Color(diff_color.r, diff_color.g, diff_color.b, 0.4))
		button.modulate = Color.WHITE
	else:
		normal = UIStyles.glass_panel()
		button.modulate = Color.WHITE
	# Level tiles are flat in the mockup (both themes) — drop any panel shadow.
	normal.shadow_size = 0
	normal.shadow_color = Color(0, 0, 0, 0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal.duplicate())
	button.add_theme_stylebox_override("pressed", normal.duplicate())
	button.add_theme_stylebox_override("disabled", normal.duplicate())

func add_star_icons(parent: Control, count: int) -> void:
	var icon_size := Vector2(30, 30)
	var spacing := 8.0
	var step := icon_size.x + spacing
	var start_x: float = (parent.size.x - icon_size.x * 3.0 - spacing * 2.0) * 0.5
	for i in range(3):
		var texture: Texture2D = UIStyles.ICON_LEVEL_STAR if i < count else UIStyles.ICON_LEVEL_STAR_EMPTY
		var color: Color = UIStyles.GOLD if i < count else UIStyles.STAR_EMPTY
		UIStyles.icon(texture, parent, Vector2(start_x + i * step, 2), icon_size, color)

func section_color(index: int) -> Color:
	if index >= 0 and index < LevelData.DIFFICULTIES.size():
		return UIStyles.difficulty_color(str(LevelData.DIFFICULTIES[index]))
	return UIStyles.PURPLE

func are_all_tutorials_completed(tutorial_completed: Array) -> bool:
	if tutorial_completed.is_empty():
		return false
	for completed in tutorial_completed:
		if not bool(completed):
			return false
	return true

func _on_level_button_pressed(level_number: int) -> void:
	level_selected.emit(level_number)

# ---------------------------------------------------------------------------
# Scroll centering
# ---------------------------------------------------------------------------

func center_on_level_row(level_number: int) -> void:
	if last_scroll == null or level_number <= 0:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var row_center_y := row_center_for_level(level_number)
	var desired := int(maxf(0.0, row_center_y - last_scroll.size.y * 0.5))
	last_scroll.scroll_vertical = desired

func row_center_for_level(level_number: int) -> float:
	var m := chip_metrics()
	var chip: float = m["chip"]
	var row_gap: float = m["row_gap"]
	var tutorials_height := 8.0 + 150.0
	var section_gap := 70.0
	var rows := int(ceil(float(LevelData.LEVELS_PER_DIFFICULTY) / 3.0))
	var difficulty_height := 82.0 + float(rows) * row_gap - (row_gap - chip)
	var difficulty_index := LevelData.difficulty_index_for_level(level_number)
	var local_index := LevelData.local_level_number(level_number) - 1
	var section_y := tutorials_height + section_gap + float(difficulty_index) * (difficulty_height + section_gap)
	var start_y := section_y + 82.0
	var row := int(float(local_index) / 3.0)
	return start_y + float(row) * row_gap + chip * 0.5

# ---------------------------------------------------------------------------
# Locked level popup (shared glass shell)
# ---------------------------------------------------------------------------

func build_locked_level_popup() -> void:
	if is_instance_valid(locked_popup):
		locked_popup.queue_free()

	locked_popup = Control.new()
	# Explicit size — anchored presets collapse to zero under this screen.
	locked_popup.position = Vector2.ZERO
	locked_popup.size = Layout.viewport_size(self)
	locked_popup.z_index = 100
	locked_popup.visible = false
	add_child(locked_popup)

	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = locked_popup.size
	overlay.color = Color(0.03, 0.02, 0.08, 0.55)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(func(event: InputEvent):
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed:
			hide_locked_level_popup()
	)
	locked_popup.add_child(overlay)

	var vp := Layout.viewport_size(self)
	var pw := UIStyles.popup_width(vp.x)
	var ph := 983.0
	var panel := Panel.new()
	panel.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	panel.size = Vector2(pw, ph)
	panel.add_theme_stylebox_override("panel", UIStyles.popup_panel_style())
	locked_popup.add_child(panel)

	UIStyles.popup_badge(panel, pw, Color("#B79CFF"), Color("#5B32C4"), UIStyles.ICON_LOCK, 87.0)
	UIStyles.popup_title(panel, pw, Locale.t("levels.locked.title", "Locked Level"))

	locked_popup_body = UIStyles.popup_body(panel, pw, "", 268.0)

	locked_popup_ad_button = UIStyles.popup_primary_button(Locale.t("levels.locked.watch_ad", "Watch Ad"), pw, 500.0)
	locked_popup_ad_button.pressed.connect(func(): unlock_with_ad_requested.emit(locked_popup_level_number))
	panel.add_child(locked_popup_ad_button)

	locked_popup_close_button = UIStyles.popup_secondary_button(Locale.t("common.cancel", "Cancel"), pw, 735.0)
	locked_popup_close_button.pressed.connect(hide_locked_level_popup)
	panel.add_child(locked_popup_close_button)

func show_locked_level_popup(level_number: int, can_watch_ad: bool) -> void:
	if not is_instance_valid(locked_popup):
		build_locked_level_popup()
	locked_popup_level_number = level_number
	locked_popup_body.text = Locale.t("levels.locked.body", "Complete the previous level%s to open it.") % (Locale.t("levels.locked.or_ad", " or watch an ad") if can_watch_ad else "")
	locked_popup_ad_button.visible = can_watch_ad
	locked_popup.visible = true

func hide_locked_level_popup() -> void:
	if is_instance_valid(locked_popup):
		locked_popup.visible = false
