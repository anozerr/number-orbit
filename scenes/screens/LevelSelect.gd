class_name LevelSelectScreen
extends Control

const PopupFactoryScript = preload("res://scripts/ui/PopupFactory.gd")
const AudioManagerScript = preload("res://scripts/audio/AudioManager.gd")

signal back_pressed
signal settings_pressed
signal level_selected(level_number: int)
signal skip_level_requested(level_number: int)
signal ad_reward_requested(level_number: int)

var locked_popup: Control
var locked_popup_panel: Panel
var locked_popup_body: Label
var locked_popup_balance: Label
var locked_popup_unlock_button: Button
var locked_popup_ad_button: Button
var locked_popup_close_button: Button
var locked_popup_level_number: int = -1
var locked_popup_skippable := false
var locked_popup_insufficient := false
var last_scroll: ScrollContainer
var content_width := 940.0

# Horizontal breathing room INSIDE the scroll viewport so edge tiles / the
# How-to card aren't clipped by the ScrollContainer's edges. The visual tile
# grid still spans `content_width`; the scroll is just wider and the grid is
# offset by GRID_PAD. The top pad is a transparent scroll runway: it keeps the
# first card below the live fade at rest, then lets it dissolve gradually as the
# user scrolls instead of switching a shader gate over a few pixels.
const GRID_PAD := 30.0
const EDGE_FADE_PX := 56.0
const TOP_PAD := EDGE_FADE_PX
const LEVEL_STAR_SIZE := 42.0
const LEVEL_STAR_SPACING := 7.0
const LEVEL_STAR_Y_RATIO := 0.65
# The scroll viewport extends half the shared edge dissolve BELOW
# the unified bottom line so a row is still fully opaque AT the line and only
# fades past it (fade completing on the line made the page look shorter).
const LOCKED_POPUP_HEIGHT := 650.0
# Cancel ends at y=888 in the actionable layout; 968 leaves the same deliberate
# 80px bottom breathing room used by the popup's horizontal padding.
const UNLOCK_POPUP_HEIGHT := 968.0

# Cached args so a viewport resize can re-lay out.
var _star_ratings: Array = []
var _max_unlocked := 1
var _tutorial_completed: Array = []
var _lumens := 0
var _has_data := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	if visible and _has_data:
		var previous_scroll := last_scroll.scroll_vertical if is_instance_valid(last_scroll) else 0
		var reopen_popup := is_instance_valid(locked_popup) and locked_popup.visible
		var reopen_level := locked_popup_level_number
		var reopen_skippable := locked_popup_skippable
		rebuild_level_difficulties(_star_ratings, _max_unlocked, _tutorial_completed, _lumens)
		if is_instance_valid(last_scroll):
			last_scroll.set_deferred("scroll_vertical", previous_scroll)
		if reopen_popup:
			show_locked_level_popup(reopen_level, reopen_skippable, true)

func set_lumens(value: int) -> void:
	_lumens = value

func rebuild_level_difficulties(star_ratings: Array, max_unlocked_level: int, tutorial_completed: Array = [], lumens: int = 0) -> void:
	_star_ratings = star_ratings
	_max_unlocked = max_unlocked_level
	_tutorial_completed = tutorial_completed
	_lumens = lumens
	_has_data = true

	Layout.clear_children_for_rebuild(self)
	last_scroll = null

	var col := Layout.content_column(self)
	content_width = col.size.x
	var top := Layout.content_top(self)

	# --- Header ---
	var back := UIStyles.back_button(self, Vector2(maxf(Layout.SIDE_MARGIN, col.position.x), top + 74.0))
	back.set_meta(&"screen_transition_role", &"back")
	back.pressed.connect(func(): back_pressed.emit())

	var settings_btn := UIStyles.circle_button(self, Vector2(col.position.x + content_width - 127.0, top + 74.0), 127.0)
	settings_btn.set_meta(&"screen_transition_role", &"settings")
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

	# --- Scroll region: starts 55px below the 127px header circles (top+74..201),
	# giving the header deliberate breathing room. Its 56px transparent runway
	# keeps How-to fully outside the live fade at rest. ---
	# Scroll ends on the unified bottom line so the bottom fade sits where the
	# operator chips end on the game screen (same bottom edge on every screen).
	var scroll_top := top + 256.0
	# Bottom of the visible scroll = the unified line plus HALF a fade length, so
	# the dissolve is spatially centred on the line (≈50% opacity there): clearly
	# present but already dissolving.
	var scroll_bottom := Layout.content_bottom_line(self) + EDGE_FADE_PX * 0.5
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
	# Match the bottom runway to the top one: at maximum scroll the final card
	# stops exactly where the bottom fade begins, fully opaque and unclipped.
	content.custom_minimum_size = Vector2(content_width + GRID_PAD * 2.0, y - 108.0 + EDGE_FADE_PX)

	apply_scroll_fade(scroll)

	build_locked_level_popup()
	# Auto-scroll to the last unlocked level was removed — it got in the way.

# Alpha-fade the scroll content near the scroll region's top/bottom edges.
# The fade shader sits on the ScrollContainer and every descendant opts into it
# via use_parent_material, so the CONTENT dissolves per-fragment in screen
# space — any gradient background shows through with no color bands (a flat
# fade strip is visible over a non-uniform bg). Both masks stay active and use
# the exact same EDGE_FADE_PX curve. TOP_PAD is one fade long, so How-to rests
# fully below the mask and traverses the whole gradient before the hard clip.
func apply_scroll_fade(scroll: ScrollContainer) -> void:
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float band_top = 0.0;
uniform float band_bottom = 1.0;
uniform float edge_fade_px = 56.0;
uniform float viewport_h = 1920.0;

void fragment() {
	float y = SCREEN_UV.y * viewport_h;
	float safe_fade_px = max(edge_fade_px, 1.0);
	float top_progress = clamp((y - band_top) / safe_fade_px, 0.0, 1.0);
	float bottom_progress = clamp((band_bottom - y) / safe_fade_px, 0.0, 1.0);
	// Cubic smoothstep has zero slope at both ends, so neither the transparent
	// edge nor the return to fully opaque content reads as a horizontal seam.
	float top_fade = smoothstep(0.0, 1.0, top_progress);
	float bottom_fade = smoothstep(0.0, 1.0, bottom_progress);
	COLOR.a *= top_fade * bottom_fade;
}
"""
	mat.shader = shader
	var vp := Layout.viewport_size(self)
	mat.set_shader_parameter("band_top", scroll.position.y)
	mat.set_shader_parameter("band_bottom", scroll.position.y + scroll.size.y)
	mat.set_shader_parameter("edge_fade_px", EDGE_FADE_PX)
	mat.set_shader_parameter("viewport_h", vp.y)
	scroll.material = mat
	_use_parent_material_recursive(scroll)

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
	btn.pressed.connect(_on_level_button_pressed.bind(-1))
	parent.add_child(btn)

	# Circular gradient icon badge.
	var badge := TextureRect.new()
	badge.size = Vector2(147, 147)
	badge.position = Vector2(67, (row_h - 147) * 0.5)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.texture = UIStyles.circle_gradient_texture(147, UIStyles.PRIMARY_TOP, UIStyles.PRIMARY_BOTTOM)
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
	desc_lbl.text = Locale.t("levels.howto.sub", "Tutorial · operations and order")
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

	var count := LevelData.difficulty_level_count(difficulty_index)
	var start_offset := LevelData.difficulty_start_offset(difficulty_index)
	# Any single-level band is rendered as one full-width tile.
	var wide := count == 1

	for i in range(count):
		var global_level: int = start_offset + i + 1
		var unlocked: bool = tutorials_done and global_level <= max_unlocked_level
		var rating: int = int(star_ratings[global_level - 1]) if global_level - 1 < star_ratings.size() else 0
		var completed: bool = rating > 0
		var cx := pad
		var cy := start_y
		var chip_w := content_width
		if not wide:
			var col_i := i % 3
			var row_i := int(float(i) / 3.0)
			cx = pad + col_i * (chip + gutter)
			cy = start_y + row_i * row_gap
			chip_w = chip
		build_level_chip(parent, Vector2(cx, cy), Vector2(chip_w, chip), global_level, rating, completed, unlocked, diff_color, tutorials_done, max_unlocked_level)

	var rows := 1 if wide else int(ceil(float(count) / 3.0))
	return start_y + float(rows) * row_gap - (row_gap - chip)

# Shared chip grid metrics (inset by GRID_PAD so chips aren't clipped by the
# scroll container at the left/right edges).
func chip_metrics() -> Dictionary:
	var gutter := 53.0
	var chip := (content_width - gutter * 2.0) / 3.0
	return {"pad": GRID_PAD, "gutter": gutter, "chip": chip, "row_gap": chip + 40.0}

func build_level_chip(parent: Control, pos: Vector2, chip_size: Vector2, global_level: int, rating: int, completed: bool, unlocked: bool, diff_color: Color, tutorials_done: bool, max_unlocked_level: int) -> void:
	var btn := Button.new()
	btn.text = ""
	btn.size = chip_size
	btn.position = pos
	style_level_chip(btn, completed, unlocked, diff_color)
	if unlocked:
		# Exception: locked levels give no hover/press feedback (they only open the
		# unlock popup on tap), so the highlight is attached to unlocked chips only.
		UIStyles.add_press_animation(btn, UIStyles.CORNER)
		btn.pressed.connect(_on_level_button_pressed.bind(global_level))
	else:
		var skippable := tutorials_done and global_level == max_unlocked_level + 1
		btn.pressed.connect(show_locked_level_popup.bind(global_level, skippable))
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
		stars.position = Vector2(0, chip_size.y * LEVEL_STAR_Y_RATIO)
		stars.size = Vector2(chip_size.x, LEVEL_STAR_SIZE)
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
	var normal: StyleBox
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
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal.duplicate())
	button.add_theme_stylebox_override("pressed", normal.duplicate())
	button.add_theme_stylebox_override("disabled", normal.duplicate())

func add_star_icons(parent: Control, count: int) -> void:
	var icon_size := Vector2(LEVEL_STAR_SIZE, LEVEL_STAR_SIZE)
	var spacing := LEVEL_STAR_SPACING
	var step := icon_size.x + spacing
	var start_x: float = (parent.size.x - icon_size.x * 3.0 - spacing * 2.0) * 0.5
	var y := (parent.size.y - icon_size.y) * 0.5
	for i in range(3):
		var texture: Texture2D = UIStyles.ICON_LEVEL_STAR if i < count else UIStyles.ICON_LEVEL_STAR_EMPTY
		var color: Color = UIStyles.GOLD if i < count else UIStyles.STAR_EMPTY
		UIStyles.icon(texture, parent, Vector2(start_x + i * step, y), icon_size, color)

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
	var difficulty_index := LevelData.difficulty_index_for_level(level_number)
	var local_index := LevelData.local_level_number(level_number) - 1
	# Mirror the actual builder geometry: top runway + How-to (268) + its gap
	# (67), then each previous section's grid and 108px trailing gap.
	var section_y := TOP_PAD + 268.0 + 67.0
	for i in range(difficulty_index):
		var rows_i := int(ceil(float(LevelData.difficulty_level_count(i)) / 3.0))
		var height_i := 93.0 + float(rows_i) * row_gap - (row_gap - chip)
		section_y += height_i + 108.0
	var start_y := section_y + 93.0
	var row := int(float(local_index) / 3.0)
	return start_y + float(row) * row_gap + chip * 0.5

# ---------------------------------------------------------------------------
# Locked level popup (shared glass shell)
# ---------------------------------------------------------------------------

func build_locked_level_popup() -> void:
	if is_instance_valid(locked_popup):
		locked_popup.queue_free()
	locked_popup_panel = null

	locked_popup = Control.new()
	# Explicit size — anchored presets collapse to zero under this screen.
	locked_popup.position = Vector2.ZERO
	locked_popup.size = Layout.viewport_size(self)
	locked_popup.z_index = 100
	locked_popup.visible = false
	add_child(locked_popup)

	var overlay := PopupFactoryScript.scrim(locked_popup.size, func() -> void: hide_locked_level_popup())
	locked_popup.add_child(overlay)

	var vp := Layout.viewport_size(self)
	var pw := PopupFactoryScript.popup_width(vp.x)
	var ph := LOCKED_POPUP_HEIGHT
	var panel := Panel.new()
	panel.name = "PopupPanel"
	panel.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	panel.size = Vector2(pw, ph)
	PopupFactoryScript.apply_panel_glass(panel)
	PopupFactoryScript.register_sheet_panel(panel)
	locked_popup_panel = panel
	locked_popup.add_child(panel)

	PopupFactoryScript.badge(panel, pw, Color("#B79CFF"), Color("#5B32C4"), UIStyles.ICON_LOCK, 87.0)
	PopupFactoryScript.title(panel, pw, Locale.t("levels.locked.title", "Locked Level"))

	locked_popup_body = PopupFactoryScript.body(panel, pw, "", 268.0)

	locked_popup_balance = Label.new()
	locked_popup_balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locked_popup_balance.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(locked_popup_balance, UIStyles.FONT_SEMIBOLD, 40, UIStyles.MUTED)
	panel.add_child(locked_popup_balance)

	# One primary slot with two mutually-exclusive states: Unlock when the player
	# can afford it, or Watch Ad when the balance is insufficient.
	locked_popup_unlock_button = PopupFactoryScript.primary_button(Locale.t("levels.locked.unlock", "Unlock"), pw, 500.0)
	locked_popup_unlock_button.pressed.connect(_on_locked_popup_unlock_pressed)
	panel.add_child(locked_popup_unlock_button)

	locked_popup_ad_button = PopupFactoryScript.primary_button(Locale.t("levels.locked.watch_ad", "Watch Ad"), pw, 500.0)
	locked_popup_ad_button.pressed.connect(func(): ad_reward_requested.emit(locked_popup_level_number))
	panel.add_child(locked_popup_ad_button)

	locked_popup_close_button = PopupFactoryScript.secondary_button(Locale.t("common.cancel", "Cancel"), pw, 735.0)
	locked_popup_close_button.pressed.connect(hide_locked_level_popup)
	panel.add_child(locked_popup_close_button)

func show_locked_level_popup(level_number: int, skippable: bool, immediate: bool = false) -> void:
	if not is_instance_valid(locked_popup):
		build_locked_level_popup()
	if not immediate:
		AudioManagerScript.play_locked_level_haptic()
	locked_popup_level_number = level_number
	locked_popup_skippable = skippable
	locked_popup_insufficient = skippable and _lumens < skip_cost_for(level_number)
	layout_locked_level_popup(skippable)
	update_locked_level_popup_content()
	var overlay := PopupFactoryScript.find_scrim(locked_popup)
	if immediate:
		PopupFactoryScript.show_sheet_immediate(locked_popup, locked_popup_panel, overlay)
	else:
		PopupFactoryScript.show_sheet(locked_popup, locked_popup_panel, overlay)

func _on_locked_popup_unlock_pressed() -> void:
	if not locked_popup_skippable:
		return
	if _lumens >= skip_cost_for(locked_popup_level_number):
		skip_level_requested.emit(locked_popup_level_number)
		return
	locked_popup_insufficient = true
	AudioManagerScript.play_invalid()
	update_locked_level_popup_content()

func update_locked_level_popup_content() -> void:
	var cost := skip_cost_for(locked_popup_level_number)
	var affordable := _lumens >= cost
	# Reset the body typography/layout before selecting a state; the insufficient
	# explanation uses a slightly smaller font and more vertical room.
	locked_popup_body.position = Vector2(PopupFactoryScript.POPUP_PAD, 268.0)
	locked_popup_body.size = Vector2(locked_popup_panel.size.x - PopupFactoryScript.POPUP_PAD * 2.0, 120.0)
	locked_popup_balance.position.y = 420.0
	UIStyles.apply_font(locked_popup_body, UIStyles.FONT_SEMIBOLD, 45, UIStyles.MUTED)
	if not locked_popup_skippable:
		locked_popup_body.text = Locale.t("levels.locked.body", "Complete the previous level to open it.")
		locked_popup_balance.visible = false
		locked_popup_unlock_button.visible = false
		locked_popup_ad_button.visible = false
	elif locked_popup_insufficient and not affordable:
		locked_popup_body.position.y = 246.0
		locked_popup_body.size.y = 180.0
		UIStyles.apply_font(locked_popup_body, UIStyles.FONT_SEMIBOLD, 40, UIStyles.MUTED)
		locked_popup_body.text = Locale.t(
			"levels.locked.insufficient",
			"Unlocking this level costs %d Lumens. You don't have enough — watch an ad to get %d Lumens."
		) % [cost, GameState.AD_REWARD_LUMENS]
		locked_popup_balance.text = Locale.t("hint.balance_short", "Balance: %d / %d Lumens") % [_lumens, cost]
		locked_popup_balance.position.y = 436.0
		locked_popup_balance.visible = true
		locked_popup_unlock_button.visible = false
		locked_popup_ad_button.text = Locale.t("levels.locked.watch_ad", "Watch Ad")
		locked_popup_ad_button.visible = true
	else:
		locked_popup_insufficient = false
		locked_popup_body.position.y = 274.0
		locked_popup_body.size.y = 180.0
		UIStyles.apply_font(locked_popup_body, UIStyles.FONT_SEMIBOLD, 42, UIStyles.MUTED)
		locked_popup_body.text = Locale.t(
			"levels.locked.body_unlock",
			"Beat the previous level to open it — or unlock it now for %d Lumens.",
		) % cost
		locked_popup_balance.text = Locale.t("hint.balance_short", "Balance: %d / %d Lumens") % [_lumens, cost]
		locked_popup_balance.visible = false
		locked_popup_unlock_button.text = Locale.t("levels.locked.unlock", "Unlock")
		locked_popup_unlock_button.visible = true
		locked_popup_ad_button.visible = false

func skip_cost_for(level_number: int) -> int:
	var band := LevelData.difficulty_index_for_level(level_number)
	if band < 0 or band >= GameState.BAND_SKIP_COST.size():
		return 0
	return int(GameState.BAND_SKIP_COST[band])

func layout_locked_level_popup(skippable: bool) -> void:
	if not is_instance_valid(locked_popup_panel):
		return
	var panel_height := UNLOCK_POPUP_HEIGHT if skippable else LOCKED_POPUP_HEIGHT
	var viewport_size := Layout.viewport_size(self)
	locked_popup_panel.size.y = panel_height
	locked_popup_panel.position = (viewport_size - locked_popup_panel.size) * 0.5
	var pw := locked_popup_panel.size.x
	locked_popup_body.position = Vector2(PopupFactoryScript.POPUP_PAD, 268.0)
	locked_popup_body.size = Vector2(pw - PopupFactoryScript.POPUP_PAD * 2.0, 120.0)
	if skippable:
		locked_popup_balance.position = Vector2(0, 420.0)
		locked_popup_balance.size = Vector2(pw, 58.0)
		locked_popup_unlock_button.position.y = 510.0
		locked_popup_ad_button.position.y = 510.0
		locked_popup_close_button.position.y = 720.0
	else:
		locked_popup_close_button.position.y = 430.0
	PopupFactoryScript.register_sheet_panel(locked_popup_panel)

func hide_locked_level_popup() -> void:
	if is_instance_valid(locked_popup) and is_instance_valid(locked_popup_panel):
		PopupFactoryScript.hide_sheet(locked_popup, locked_popup_panel, PopupFactoryScript.find_scrim(locked_popup))
