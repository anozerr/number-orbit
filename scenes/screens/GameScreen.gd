class_name GameScreen
extends Node2D

const OperationLegendScene = preload("res://scenes/ui/OperationLegend.tscn")
const HintPopupScript = preload("res://scenes/ui/HintPopup.gd")
const CoachOverlayScript = preload("res://scenes/ui/CoachOverlay.gd")
const AudioManagerScript = preload("res://scripts/audio/AudioManager.gd")
const GameViewStateScript = preload("res://scripts/game/GameViewState.gd")

signal back_pressed
signal settings_pressed
signal restart_pressed
signal orbit_pressed(value: int, op: String, item_id: String)
signal hint_requested
signal hint_ad_requested
signal coach_header_mode_changed(active: bool)

class OrbitButtonOutline:
	extends Control

	var outline_color: Color = Color.WHITE
	var outline_width := 4.0

	func _draw() -> void:
		var radius := minf(size.x, size.y) * 0.5 - outline_width * 0.5
		if radius <= 0.0:
			return
		draw_arc(size * 0.5, radius, 0.0, TAU, 192, outline_color, outline_width, true)

class LumensBadgeOutline:
	extends Control

	var outline_color: Color = Color.WHITE
	var outline_width := 3.0

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var inset := outline_width * 0.5
		var radius := maxf(0.0, size.y * 0.5 - inset)
		var left_center := Vector2(inset + radius, size.y * 0.5)
		var right_center := Vector2(size.x - inset - radius, size.y * 0.5)
		var points := PackedVector2Array([Vector2(left_center.x, inset), Vector2(right_center.x, inset)])
		for step in range(1, 49):
			var angle := -PI * 0.5 + PI * float(step) / 48.0
			points.append(right_center + Vector2(cos(angle), sin(angle)) * radius)
		points.append(Vector2(left_center.x, size.y - inset))
		for step in range(1, 49):
			var angle := PI * 0.5 + PI * float(step) / 48.0
			points.append(left_center + Vector2(cos(angle), sin(angle)) * radius)
		points.append(points[0])
		draw_polyline(points, outline_color, outline_width, true)

var screen_center := Vector2(603, 1240)
const ORBIT_RADIUS := 388
# The iPhone 17 Pro composition defines the maximum visual radius. Wider/taller
# canvases add breathing room around the game instead of enlarging the orbit.
var orbit_radius: float = float(ORBIT_RADIUS)
const EDGE_MARGIN := 67.0
const TOP_BUTTON_Y := 74.0
const TOP_STATUS_Y := 202.0
const TOP_STATUS_SIZE := Vector2(1072, 214)
const TARGET_BUBBLE_SIZE := Vector2(268, 268)
const INFO_LINE_Y := 364.0
const INFO_LINE_SIZE := Vector2(1072, 121)
# Marquee text lane (right of the info icon), rest offset, and edge-fade width.
const INFO_TEXT_LEFT := 150.0
const INFO_CLIP_RIGHT_PAD := 44.0
const INFO_REST_X := 48.0
const INFO_FADE_PX := 44.0
const INFO_TEXT_SAFE_INSET := 16.0
const INFO_TEMP_HOLD_SECONDS := 3.0
const HINT_REPEAT_GLOW_EXTENT := 42.0
const HINT_REPEAT_GLOW_ALPHA_FACTOR := 1.45
const HINT_REVEAL_RESET := 0.14
const HINT_REVEAL_GROW := 0.48
const HINT_REVEAL_SETTLE := 0.42
const ACTION_BUTTON_Y := 1518.0
const ACTION_BUTTON_HEIGHT := 174.0
const CENTER_CIRCLE_DIAMETER := 335
const CENTER_CIRCLE_RADIUS := CENTER_CIRCLE_DIAMETER * 0.5

var center_label: Label
var center_panel: Control
var center_circle: TextureRect
var center_flash: Panel
var center_flash_tween: Tween
var level_label: Label
var level_bg: Control
var moves_bg: Control
var target_panel: Control
var target_circle: TextureRect
var level_hover: Panel
var moves_hover: Panel
var goal_label: Label
var info_panel: Panel
var info_icon: TextureRect
var tutorial_help_label: Label
var moves_count_label: Label
var hint_button: Button
var hint_dim: Panel
var hint_label: Label
var lumens_badge: Panel
var lumens_badge_border: Control
var lumens_badge_icon: Control
var lumens_badge_label: Label
var restart_button: Button
var back_button: Button
var settings_button: Button
var hint_popup: HintPopup
var operation_legend: OperationLegend
var orbit: Node2D
var center_circle_texture: Texture2D
var orbit_angle := 0.0
var orbit_spin_factor := 1.0
var orbit_spin_tween: Tween
var last_coach_orbit_area := ""
var last_center_number: int = -999999
var level_failed: bool = false
var current_number_value: int = 0
var current_lumens: int = 0
var current_moves: int = 0
var current_hint_cost: int = 0
var current_target_value: int = 0
var current_star_mode := ""
var current_star_bands: Array = []
var current_is_tutorial := false
var _hint_dimmed := false
var _hint_dim_progress := 0.0
var tutorial_help_text_current := ""
var coach_overlay: CoachOverlay
var info_line_error_state: Variant = null
# --- Info-line captions: every message rests centered in the readable lane.
# Temporary captions fade in, stay briefly, then fade back to the default. ---
var info_clip: Control
var info_fade_material: ShaderMaterial
var info_default_text := ""
var info_temp_active := false
var info_caption_version := 0
var info_caption_tween: Tween
var info_line_font_size := -1
var hint_highlight_item_id := ""
var hint_highlight_tween: Tween
var hint_highlight_strength := 0.0
var skip_orbit_entrance_once := false
# Lead-in before the orbit chips pop in. Set by Main to the screen-crossfade
# duration on a fresh-level entry so the ripple starts as the screen settles,
# not on top of it. Consumed (reset to 0) each set_orbit_items.
var orbit_entrance_delay := 0.0
var pending_coach_snapshot: Dictionary = {}

func _ready() -> void:
	build()
	get_viewport().size_changed.connect(_apply_layout)

# Responsive layout: anchors the top cluster below the safe-area, the action
# row + legend above the home indicator, and centers the orbit in the viewport.
func _apply_layout() -> void:
	if level_bg == null:
		return
	var vp := Layout.viewport_size(self)
	var center_x := vp.x * 0.5
	var top := Layout.content_top(self)
	var bottom := Layout.content_bottom(self)

	var status_x := center_x - TOP_STATUS_SIZE.x * 0.5

	# Header circles at top + 74 — identical to the Levels/Settings header so the
	# Back and gear buttons sit in exactly the same spot across screens.
	if back_button != null:
		back_button.position = Vector2(status_x, top + 74.0)
	if settings_button != null:
		settings_button.position = Vector2(status_x + TOP_STATUS_SIZE.x - 127.0, top + 74.0)

	# Status pill (mockup top+255) + floating target centered on it. The two halves
	# sit side by side, meeting under the target badge.
	var status_y := top + 255.0
	level_bg.position = Vector2(status_x, status_y)
	moves_bg.position = Vector2(status_x + TOP_STATUS_SIZE.x * 0.5, status_y)
	var target_center := Vector2(center_x, status_y + TOP_STATUS_SIZE.y * 0.5)
	target_panel.position = target_center - TARGET_BUBBLE_SIZE * 0.5

	# Info line (mockup top+523).
	var info_y := top + 523.0
	info_panel.position = Vector2(center_x - INFO_LINE_SIZE.x * 0.5, info_y)
	if info_fade_material != null:
		var clip_left := info_panel.position.x + INFO_TEXT_LEFT
		info_fade_material.set_shader_parameter("clip_left", clip_left)
		info_fade_material.set_shader_parameter("clip_right", clip_left + info_clip.size.x)
		info_fade_material.set_shader_parameter("viewport_w", vp.x)

	# Legend + action row anchored to the bottom safe area (mockup offsets from
	# the content-area bottom: chips 134, action row a further 54 above).
	var legend_w := TOP_STATUS_SIZE.x
	operation_legend.set_width(legend_w)
	var legend_h := OperationLegend.CARD_HEIGHT
	var legend_y := Layout.content_bottom_line(self) - legend_h
	operation_legend.position = Vector2(center_x - legend_w * 0.5, legend_y)

	var action_y := legend_y - 54.0 - ACTION_BUTTON_HEIGHT
	hint_button.visible = true
	restart_button.visible = true
	var half := (TOP_STATUS_SIZE.x - 47.0) * 0.5
	hint_button.position = Vector2(status_x, action_y)
	hint_button.size = Vector2(half, ACTION_BUTTON_HEIGHT)
	restart_button.position = Vector2(status_x + half + 47.0, action_y)
	restart_button.size = Vector2(half, ACTION_BUTTON_HEIGHT)
	hint_button.pivot_offset = hint_button.size * 0.5
	restart_button.pivot_offset = restart_button.size * 0.5
	layout_lumens_badge()

	# Orbit centered between the info line and the action row. Its reference
	# radius stays unchanged on larger canvases, preserving the iPhone 17 Pro
	# clearances to the info line, action buttons, and floating Lumens badge.
	var orbit_top := info_y + INFO_LINE_SIZE.y + 20.0
	var orbit_bottom := action_y - 20.0
	screen_center = Vector2(center_x, (orbit_top + orbit_bottom) * 0.5)
	# Shrink only when an unusually constrained safe area cannot hold the reference
	# composition; never grow past ORBIT_RADIUS on a spacious viewport.
	var sat_half := 94.0  # satellite radius
	var max_r_w := center_x - Layout.SIDE_MARGIN - sat_half
	var max_r_v := (orbit_bottom - orbit_top) * 0.5 - sat_half
	orbit_radius = maxf(0.0, minf(float(ORBIT_RADIUS), minf(max_r_w, max_r_v)))
	center_panel.position = screen_center - Vector2(CENTER_CIRCLE_RADIUS, CENTER_CIRCLE_RADIUS)
	# Full-screen overlays cover the whole viewport.
	if hint_popup != null:
		hint_popup.layout_to_viewport(vp)
	if coach_overlay != null:
		coach_overlay.layout_to_viewport(vp)
		coach_overlay.configure_context(coach_context())
	queue_redraw()

func build() -> void:
	clear_hint_highlight()
	last_coach_orbit_area = ""
	Layout.clear_children_for_rebuild(self)
	# Same fill as the primary Play/Continue button (mockup parity): diagonal
	# PRIMARY_TOP→PRIMARY_BOTTOM gradient.
	center_circle_texture = UIStyles.circle_gradient_texture(CENTER_CIRCLE_DIAMETER, UIStyles.PRIMARY_TOP, UIStyles.PRIMARY_BOTTOM)

	center_panel = Control.new()
	center_panel.size = Vector2(CENTER_CIRCLE_DIAMETER, CENTER_CIRCLE_DIAMETER)
	center_panel.position = screen_center - Vector2(CENTER_CIRCLE_RADIUS, CENTER_CIRCLE_RADIUS)
	center_panel.pivot_offset = center_panel.size * 0.5
	center_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(center_panel)
	center_panel.gui_input.connect(_on_center_panel_input)
	center_panel.mouse_exited.connect(func() -> void: UIStyles.press_hold(center_panel, false))

	center_circle = TextureRect.new()
	center_circle.position = Vector2.ZERO
	center_circle.size = center_panel.size
	center_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_circle.texture = center_circle_texture
	center_circle.stretch_mode = TextureRect.STRETCH_SCALE
	center_panel.add_child(center_circle)

	center_flash = Panel.new()
	center_flash.position = Vector2.ZERO
	center_flash.size = center_panel.size
	center_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_flash.modulate.a = 0.0
	center_flash.visible = false
	center_panel.add_child(center_flash)

	center_label = Label.new()
	center_label.position = Vector2((CENTER_CIRCLE_DIAMETER - 490) * 0.5, (CENTER_CIRCLE_DIAMETER - 180) * 0.5)
	center_label.size = Vector2(490, 180)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyles.apply_font(center_label, UIStyles.FONT_EXTRABOLD, 101, Color.WHITE)
	center_panel.add_child(center_label)

	# Two complete glass buttons touch at the center and continue underneath the
	# target. The target sits above them and hides their shared inner seam.
	var half_size := Vector2(TOP_STATUS_SIZE.x * 0.5, TOP_STATUS_SIZE.y)
	var target_radius := TARGET_BUBBLE_SIZE.x * 0.5
	var target_cover := target_radius + 16.0
	var mid_y := TOP_STATUS_SIZE.y * 0.5
	var text_w := half_size.x - target_cover

	# Each side clips its half of the same full pill texture. At rest the halves
	# reconstruct one seamless surface; on press each half scales independently.
	level_bg = make_status_block(Vector2(EDGE_MARGIN, TOP_STATUS_Y), half_size, true)
	level_bg.pivot_offset = Vector2(text_w * 0.5, mid_y)
	add_child(level_bg)
	level_hover = make_status_hover(half_size, true)
	level_bg.add_child(level_hover)
	level_label = make_status_label()
	level_label.position = Vector2(0, 0)
	level_label.size = Vector2(text_w, TOP_STATUS_SIZE.y)
	level_bg.add_child(level_label)
	level_label.gui_input.connect(_on_level_panel_input)
	level_label.mouse_exited.connect(func() -> void: _press_status_block(level_bg, level_hover, false))
	UIStyles.attach_hover_tint(level_label, level_hover)

	# RIGHT (MOVES) — separate input/press area on the same shared surface.
	moves_bg = make_status_block(Vector2(EDGE_MARGIN + half_size.x, TOP_STATUS_Y), half_size, false)
	moves_bg.pivot_offset = Vector2(target_cover + text_w * 0.5, mid_y)
	add_child(moves_bg)
	moves_hover = make_status_hover(half_size, false)
	moves_bg.add_child(moves_hover)
	moves_count_label = make_status_label()
	moves_count_label.position = Vector2(target_cover, 0)
	moves_count_label.size = Vector2(text_w, TOP_STATUS_SIZE.y)
	moves_bg.add_child(moves_count_label)
	moves_count_label.gui_input.connect(_on_moves_panel_input)
	moves_count_label.mouse_exited.connect(func() -> void: _press_status_block(moves_bg, moves_hover, false))
	UIStyles.attach_hover_tint(moves_count_label, moves_hover)

	target_panel = Control.new()
	target_panel.position = Vector2(603, TOP_STATUS_Y + TOP_STATUS_SIZE.y * 0.5) - TARGET_BUBBLE_SIZE * 0.5
	target_panel.size = TARGET_BUBBLE_SIZE
	target_panel.pivot_offset = target_panel.size * 0.5
	target_panel.z_index = 6
	target_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(target_panel)
	target_panel.gui_input.connect(_on_goal_panel_input)
	target_panel.mouse_exited.connect(func() -> void: UIStyles.press_hold(target_panel, false))

	target_circle = TextureRect.new()
	target_circle.position = Vector2.ZERO
	target_circle.size = TARGET_BUBBLE_SIZE
	target_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_circle.texture = UIStyles.circle_gradient_texture(int(TARGET_BUBBLE_SIZE.x), UIStyles.TEAL_TOP, UIStyles.TEAL_BOTTOM)
	target_circle.stretch_mode = TextureRect.STRETCH_SCALE
	target_panel.add_child(target_circle)

	goal_label = Label.new()
	goal_label.position = Vector2.ZERO
	goal_label.size = TARGET_BUBBLE_SIZE
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Light number in BOTH themes (design review) — white reads on the teal bubble.
	UIStyles.apply_font(goal_label, UIStyles.FONT_EXTRABOLD, 74, Color.WHITE)
	target_panel.add_child(goal_label)

	info_panel = Panel.new()
	info_panel.position = Vector2(EDGE_MARGIN, INFO_LINE_Y)
	info_panel.size = INFO_LINE_SIZE
	info_panel.add_theme_stylebox_override("panel", UIStyles.glass_panel(67))
	add_child(info_panel)
	# Reset so the next apply_info_line_style() re-applies font/style: the label is
	# freshly rebuilt here, but the cached error-state would otherwise short-circuit
	# the re-style (leaving a stale font size after a theme rebuild).
	info_line_error_state = null
	info_line_font_size = -1
	# Likewise clear the caption cache: the label was just recreated
	# empty, so `set_info_default` must repopulate it even if the resting text is
	# unchanged (else a theme/language rebuild leaves the info line blank).
	info_default_text = ""
	info_temp_active = false
	info_icon = UIStyles.icon(UIStyles.ICON_INFO, info_panel, Vector2(90, 35), Vector2(50, 50), UIStyles.PURPLE)

	# Caption lane, right of the icon, with a screen-space edge fade kept as a
	# safety boundary outside the centered readable area.
	info_clip = Control.new()
	info_clip.position = Vector2(INFO_TEXT_LEFT, 0)
	info_clip.size = Vector2(INFO_LINE_SIZE.x - INFO_TEXT_LEFT - INFO_CLIP_RIGHT_PAD, INFO_LINE_SIZE.y)
	info_clip.clip_contents = true
	info_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_fade_material = ShaderMaterial.new()
	var fade_shader := Shader.new()
	fade_shader.code = """
shader_type canvas_item;
uniform float clip_left = 0.0;
uniform float clip_right = 1000.0;
uniform float fade_px = 64.0;
uniform float viewport_w = 1206.0;
void fragment() {
	float x = SCREEN_UV.x * viewport_w;
	float a = smoothstep(clip_left, clip_left + fade_px, x) * smoothstep(clip_right, clip_right - fade_px, x);
	COLOR *= texture(TEXTURE, UV);
	COLOR.a *= a;
}
"""
	info_fade_material.shader = fade_shader
	info_fade_material.set_shader_parameter("fade_px", INFO_FADE_PX)
	info_clip.material = info_fade_material
	info_panel.add_child(info_clip)

	tutorial_help_label = Label.new()
	tutorial_help_label.position = Vector2(info_clip.size.x, 0)
	tutorial_help_label.size = Vector2(info_clip.size.x, INFO_LINE_SIZE.y)
	tutorial_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tutorial_help_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_help_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	tutorial_help_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_help_label.use_parent_material = true
	UIStyles.apply_font(tutorial_help_label, UIStyles.FONT_MEDIUM, 40, UIStyles.MUTED)
	info_clip.add_child(tutorial_help_label)

	back_button = UIStyles.back_button(self, Vector2(EDGE_MARGIN, TOP_BUTTON_Y))
	back_button.set_meta(&"screen_transition_role", &"back")
	back_button.pressed.connect(func(): back_pressed.emit())

	settings_button = UIStyles.circle_button(self, Vector2(1206.0 - EDGE_MARGIN - 127.0, TOP_BUTTON_Y), 127.0)
	settings_button.set_meta(&"screen_transition_role", &"settings")
	settings_button.pressed.connect(func(): settings_pressed.emit())
	UIStyles.icon(UIStyles.ICON_GEAR, settings_button, Vector2(33, 33), Vector2(60, 60), UIStyles.TEXT)

	# Text-only Hint / Restart pills (icon-less was a deliberate revert).
	restart_button = Button.new()
	restart_button.text = Locale.t("game.restart", "Restart")
	restart_button.position = Vector2(555, ACTION_BUTTON_Y)
	restart_button.size = Vector2(455, ACTION_BUTTON_HEIGHT)
	restart_button.add_theme_font_size_override("font_size", 47)
	UIStyles.menu_button(restart_button)
	restart_button.pressed.connect(func(): restart_pressed.emit())
	add_child(restart_button)

	hint_button = Button.new()
	hint_button.text = ""
	hint_button.position = Vector2(70, ACTION_BUTTON_Y)
	hint_button.size = Vector2(455, ACTION_BUTTON_HEIGHT)
	hint_button.add_theme_font_size_override("font_size", 47)
	hint_button.clip_contents = false
	UIStyles.menu_button(hint_button)
	hint_button.pressed.connect(func():
		if current_is_tutorial:
			hint_requested.emit()
		elif hint_popup != null and hint_popup.has_cached_result():
			hint_requested.emit()
		elif current_lumens < current_hint_cost:
			hint_requested.emit()
		else:
			hint_popup.show_prompt()
	)
	add_child(hint_button)
	# Серый слой поверх стеклянного фона кнопки (ниже подписи), с той же рамкой
	# GLASS_BORDER, что у Restart. В тупике проявляется до непрозрачного, на возврате
	# просто гаснет, открывая стекло — без «включения прозрачности» в конце и без «блика».
	hint_dim = Panel.new()
	hint_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Инсет на ширину рамки (3px): слой НЕ перекрывает рамку кнопки, поэтому видна ровно
	# ОДНА рамка (родная GLASS_BORDER кнопки, как у Restart), без удвоения.
	hint_dim.offset_left = 3
	hint_dim.offset_top = 3
	hint_dim.offset_right = -3
	hint_dim.offset_bottom = -3
	hint_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_dim.modulate.a = 0.0
	hint_button.add_child(hint_dim)
	# Подпись «Hint» отдельным Label поверх слоя (встроенный текст кнопки убран, чтобы
	# слой его не перекрывал и цвет плавно лерпился).
	hint_label = Label.new()
	hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.text = Locale.t("game.hint", "Hint")
	UIStyles.apply_font(hint_label, UIStyles.FONT_SEMIBOLD, 47, UIStyles.TEXT)
	hint_button.add_child(hint_label)
	build_lumens_badge()

	operation_legend = OperationLegendScene.instantiate()
	add_child(operation_legend)
	operation_legend.operator_info.connect(func(text: String) -> void: show_temporary_help(text))

	orbit = Node2D.new()
	add_child(orbit)

	hint_popup = HintPopupScript.new()
	add_child(hint_popup)
	hint_popup.build(Layout.viewport_size(self).x)
	hint_popup.hint_requested.connect(func(): hint_requested.emit())
	hint_popup.hint_ad_requested.connect(func(): hint_ad_requested.emit())

	coach_overlay = CoachOverlayScript.new()
	add_child(coach_overlay)
	coach_overlay.build()
	coach_overlay.showing_started.connect(_on_coach_showing_started)
	coach_overlay.hiding_started.connect(_on_coach_hiding_started)
	coach_overlay.hiding_finished.connect(_on_coach_hiding_finished)
	_apply_layout()
	# После ребилда (смена темы/языка) сразу восстанавливаем «серое» состояние подсказки
	# и бейджа, если были в тупике — иначе новый оверлей бейджа рождается прозрачным и на
	# кадр показывает фиолетовый (аналог восстановления подсветки в Main.show_game).
	if _hint_dimmed:
		_apply_hint_dim(1.0)

func configure(view: GameViewStateScript) -> void:
	var previous_moves := current_moves
	if view.moves != previous_moves:
		clear_hint_highlight()
	level_failed = view.failed
	current_number_value = view.current_number
	current_lumens = view.lumens
	current_hint_cost = view.hint_cost
	current_moves = view.moves
	current_target_value = view.target_number
	current_star_mode = view.star_mode
	current_star_bands = view.star_bands.duplicate(true)
	current_is_tutorial = view.tutorial
	if hint_popup != null:
		hint_popup.configure_state(current_moves, current_lumens, current_hint_cost)
	level_label.text = view.title_text
	goal_label.text = "?" if view.placeholder else str(view.target_number)
	tutorial_help_text_current = (
		Locale.t("game.placeholder", "This level is being prepared.")
		if view.placeholder
		else fail_comment_text() if view.failed
		else view.tutorial_help if view.tutorial
		else progress_comment_text(view.moves)
	)
	# The info row carries live gameplay context and remains visible in tutorials,
	# including while the coach overlay is presenting a step.
	info_panel.visible = true
	tutorial_help_label.visible = true
	set_info_default(tutorial_help_text_current, view.failed)
	# Center number: shrink the font for big values or a runaway multiply chain
	# so the digits stay inside the circle instead of
	# spilling past its edge. Small numbers keep the full 101px.
	var center_text := "?" if view.placeholder else str(view.current_number)
	var center_font := 101
	while center_font > 44 and UIStyles.FONT_EXTRABOLD.get_string_size(center_text, HORIZONTAL_ALIGNMENT_CENTER, -1, center_font).x > CENTER_CIRCLE_DIAMETER - 50.0:
		center_font -= 3
	UIStyles.apply_font(center_label, UIStyles.FONT_EXTRABOLD, center_font, Color.WHITE)
	center_label.text = center_text
	# 4.4: pop только на реальном ходу (moves выросли), а не при ОТКРЫТИИ уровня
	# (свежая загрузка / сентинел / возврат из меню — там moves не растут).
	if last_center_number != view.current_number and view.moves > previous_moves:
		pop_center_number()
	last_center_number = view.current_number
	moves_count_label.text = Locale.t("game.moves", "MOVES %d") % view.moves
	# Tutorials still count real taps even though they award no stars. Keep the
	# MOVES half of the status pill visible so that relationship is explicit.
	moves_count_label.visible = true
	moves_bg.visible = true
	goal_label.size = TARGET_BUBBLE_SIZE
	operation_legend.configure_ops(view.allowed_ops)
	operation_legend.visible = not view.placeholder
	hint_button.visible = true
	# A hint is useless both in a dead end and in an unfinished placeholder.
	hint_button.disabled = (level_failed or view.placeholder) and not view.tutorial
	update_hint_button_label(view.lumens)
	_apply_layout()
	# Плавно гасим подсказку (с бейджем) при входе в тупик и возвращаем при рестарте.
	# Рестарт-кнопка НЕ подпрыгивает — и так очевидно, что жать её.
	var should_dim_hint := (level_failed or view.placeholder) and not current_is_tutorial
	# Анимируем затемнение ТОЛЬКО когда состояние сменилось ХОДОМ (moves изменились). На
	# ре-показе экрана (возврат из настроек/меню) — сразу, без «серения» и мигания.
	if should_dim_hint != _hint_dimmed:
		set_hint_dimmed(should_dim_hint, view.moves != previous_moves)
	elif should_dim_hint:
		set_hint_dimmed(should_dim_hint, false)
	_hint_dimmed = should_dim_hint
	set_orbit_items(view.orbit_items)
	var restored_coach := false
	if not pending_coach_snapshot.is_empty():
		var snapshot := pending_coach_snapshot.duplicate(true)
		pending_coach_snapshot.clear()
		coach_overlay.configure_context(coach_context())
		restored_coach = coach_overlay.restore_snapshot(snapshot, false)
	if not restored_coach and view.tutorial and not view.coach_hint.is_empty():
		coach_overlay.configure_context(coach_context())
		coach_overlay.show_hint(view.coach_hint)
	elif not restored_coach:
		coach_overlay.hide_hint()
	info_panel.visible = true
	queue_redraw()

func active_coach_snapshot() -> Dictionary:
	if coach_overlay == null:
		return {}
	return coach_overlay.state_snapshot()

func prepare_coach_snapshot_restore(snapshot: Dictionary) -> void:
	pending_coach_snapshot = snapshot.duplicate(true)

func prepare_coach_for_screen_navigation() -> void:
	if coach_overlay != null and coach_overlay.visible:
		coach_overlay.prepare_for_screen_navigation()

func pop_center_number() -> void:
	UIStyles.pop_scale(center_label, 1.08, 0.08, 0.14)

func flash_center(op: String) -> void:
	if center_flash == null:
		return
	if center_flash_tween != null and center_flash_tween.is_valid():
		center_flash_tween.kill()
	var style := StyleBoxFlat.new()
	style.bg_color = UIStyles.operation_border(op)
	UIStyles._set_radius(style, int(CENTER_CIRCLE_RADIUS))
	center_flash.add_theme_stylebox_override("panel", style)
	center_flash.visible = true
	center_flash.modulate.a = 0.0
	center_flash_tween = center_flash.create_tween()
	center_flash_tween.tween_property(center_flash, "modulate:a", 0.5, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	center_flash_tween.tween_property(center_flash, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	center_flash_tween.finished.connect(func() -> void:
		if center_flash != null:
			center_flash.visible = false
	)

func set_hint_dimmed(dimmed: bool, animate: bool) -> void:
	if hint_button == null:
		return
	if hint_button.has_meta("dim_tween"):
		var previous := hint_button.get_meta("dim_tween") as Tween
		if previous != null and previous.is_valid():
			previous.kill()
	var target := 1.0 if dimmed else 0.0
	if not animate:
		if dimmed:
			_apply_hint_dim(target)
		else:
			_restore_hint_enabled_look()
		return
	var tween := hint_button.create_tween()
	hint_button.set_meta("dim_tween", tween)
	tween.tween_method(_apply_hint_dim, _hint_dim_progress, target, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not dimmed:
		tween.tween_callback(_restore_hint_enabled_look)

# t: 0 = обычная стеклянная кнопка, 1 = вид плитки «Недоступно» из легенды (те же
# operation_plate / operation_text, непрозрачно, БЕЗ рамки). Бейдж гаснет вместе с кнопкой.
func _apply_hint_dim(t: float) -> void:
	if hint_button == null or hint_dim == null:
		return
	_hint_dim_progress = clampf(t, 0.0, 1.0)
	# Серый слой в цвете НЕДОСТУПНОГО спутника орбиты (по теме), БЕЗ своей рамки и
	# инсетнут на 3px — видна ровно родная рамка кнопки (GLASS_BORDER, как у Restart),
	# без удвоения. Стеклянный фон кнопки НЕ трогаем — слой просто гаснет на возврате.
	var dim_bg: Color = UIStyles.BG.lerp(Color.WHITE, 0.03) if UIStyles.is_dark() else Color("#F1F0F5")
	var style := StyleBoxFlat.new()
	style.bg_color = dim_bg
	UIStyles._set_radius(style, UIStyles.CORNER - 3)
	hint_dim.add_theme_stylebox_override("panel", style)
	hint_dim.modulate.a = _hint_dim_progress
	if hint_label != null:
		hint_label.add_theme_color_override("font_color", UIStyles.TEXT.lerp(UIStyles.DISABLED, _hint_dim_progress))
	_apply_badge_dim(_hint_dim_progress)

# Бейдж люменов: в непрозрачный серый (та же плитка «Недоступно»), плавным цвет-лерпом.
func _apply_badge_dim(t: float) -> void:
	if lumens_badge == null or lumens_badge_label == null:
		return
	var progress := clampf(t, 0.0, 1.0)
	var affordable := current_lumens >= current_hint_cost
	# ОДИН слой: bg бейджа лерпится между включённым видом (ПЛОСКИЙ фиолет / muted) и
	# серым спутником. Плоские цвета → плавно, без прыжка; один слой → бейдж НЕ мигает при
	# затемнении экрана на переходах между экранами (там modulate масштабирует альфу).
	var enabled_bg: Color = (UIStyles.PRIMARY_TOP.lerp(UIStyles.PRIMARY_BOTTOM, 0.5)) if affordable else (Color("#2E283C") if UIStyles.is_dark() else Color("#ECEBF1"))
	var enabled_text: Color = Color.WHITE if affordable else UIStyles.operation_text("unavailable")
	var dim_bg: Color = UIStyles.BG.lerp(Color.WHITE, 0.03) if UIStyles.is_dark() else Color("#F1F0F5")
	var style := StyleBoxFlat.new()
	style.bg_color = enabled_bg.lerp(dim_bg, progress)
	UIStyles._set_radius(style, int(lumens_badge.size.y * 0.5))
	lumens_badge.add_theme_stylebox_override("panel", style)
	var text_col := enabled_text.lerp(UIStyles.DISABLED, progress)
	lumens_badge_label.add_theme_color_override("font_color", text_col)
	if lumens_badge_icon != null:
		UIStyles.recolor_sparkle_mark(lumens_badge_icon, text_col)
	if lumens_badge_border != null and lumens_badge_border is LumensBadgeOutline:
		var outline := lumens_badge_border as LumensBadgeOutline
		outline.outline_color = UIStyles.GLASS_BORDER
		outline.outline_width = 3.0
		outline.queue_redraw()

func _restore_hint_enabled_look() -> void:
	_hint_dim_progress = 0.0
	# Стеклянный фон кнопки не трогали — достаточно погасить серые слои и вернуть текст.
	if hint_dim != null:
		hint_dim.modulate.a = 0.0
	if hint_label != null:
		hint_label.add_theme_color_override("font_color", UIStyles.TEXT)
	update_lumens_badge(current_lumens)

# LEVEL / MOVES shrink around the center of their visible text lane. Their inner
# edges remain fully covered by the target throughout the press animation.
func _press_status_block(panel: Control, _hover: Panel, pressed: bool) -> void:
	if panel == null:
		return
	UIStyles.press_hold(panel, pressed)

func _on_moves_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		AudioManagerScript.play_ui_tap()
		_press_status_block(moves_bg, moves_hover, true)
		if current_is_tutorial:
			show_temporary_help(Locale.t("game.tap.moves_tut", "Tutorial moves earn no stars."), false)
		else:
			show_temporary_help(star_requirements_text(), false)
	else:
		_press_status_block(moves_bg, moves_hover, false)

func _on_level_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		AudioManagerScript.play_ui_tap()
		_press_status_block(level_bg, level_hover, true)
		if current_is_tutorial:
			show_temporary_help(Locale.t("game.tap.level_tut", "One step at a time."), false)
		else:
			show_temporary_help(Locale.t("game.tap.level", "Beat this to unlock the next."), false)
	else:
		_press_status_block(level_bg, level_hover, false)

func _on_goal_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		AudioManagerScript.play_ui_tap()
		UIStyles.press_hold(target_panel, true)
		show_temporary_help(Locale.t("game.tap.target", "Reach %d using orbit numbers.") % current_target_value, false)
	else:
		UIStyles.press_hold(target_panel, false)

func _on_center_panel_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.pressed:
		AudioManagerScript.play_ui_tap()
		UIStyles.press_hold(center_panel, true)
		show_temporary_help(Locale.t("game.tap.center", "Your number. Moves change it."), false)
	else:
		UIStyles.press_hold(center_panel, false)

func star_requirements_text() -> String:
	match current_star_mode:
		LevelData.STAR_MODE_TUTORIAL:
			return ""
		LevelData.STAR_MODE_ALWAYS_THREE:
			if current_star_bands.is_empty():
				return ""
			return Locale.t(
				"game.stars.only_three",
				"This level awards ★★★ only.",
			)
		LevelData.STAR_MODE_TIERED:
			return star_band_ranges_text(current_star_bands)
	return ""

func star_band_ranges_text(bands: Array) -> String:
	# min_moves/max_moves are the authoritative emitted intervals.
	var parts: Array[String] = []
	for index in range(bands.size()):
		var raw_band: Variant = bands[index]
		var band: Dictionary = raw_band as Dictionary
		var stars := int(band.get("stars", 1))
		var lower := int(band.get("min_moves", -1))
		var upper := int(band.get("max_moves", -1))
		var moves_text := ""
		if lower == upper:
			moves_text = str(upper)
		else:
			moves_text = "%d–%d" % [lower, upper]
		if index == 0:
			parts.append(Locale.t(
				"game.stars.band_list",
				"%s moves = %s",
			) % [moves_text, star_text(stars)])
		else:
			parts.append("%s = %s" % [moves_text, star_text(stars)])
	return " · ".join(parts)

func star_text(count: int) -> String:
	match count:
		3:
			return "★★★"
		2:
			return "★★"
	return "★"

func progress_comment_text(moves: int) -> String:
	if moves == 0:
		return Locale.t("game.info", "Tap orbit numbers to reach the target.")
	if current_star_mode == LevelData.STAR_MODE_ALWAYS_THREE:
		return Locale.t("game.stars.keep3", "Reach the target — ★★★ on completion.")
	if current_star_mode == LevelData.STAR_MODE_TIERED:
		var next_move := moves + 1
		for raw_band in current_star_bands:
			var band: Dictionary = raw_band as Dictionary
			if (
				next_move >= int(band.get("min_moves", -1))
				and next_move <= int(band.get("max_moves", -1))
			):
				match int(band.get("stars", 0)):
					3:
						return Locale.t("game.progress.on3", "On track for ★★★.")
					2:
						return Locale.t("game.progress.on2", "★★ still in reach.")
					_:
						return Locale.t("game.progress.on1", "★ still in reach.")
	return Locale.t("game.progress.finish", "Reach the target.")

func fail_comment_text() -> String:
	# Автоматическое поражение наступает только когда на доске действительно не
	# осталось применимых ходов. Нерешаемую, но всё ещё активную позицию интерфейс
	# не раскрывает — её можно проверить только осознанным запросом Hint.
	return Locale.t("game.fail", "No moves left — tap Restart.")

func apply_info_line_style(error: bool = false, font_size: int = 40) -> void:
	if info_line_error_state != null and bool(info_line_error_state) == error and info_line_font_size == font_size:
		return
	if error:
		var danger_bg := Color(UIStyles.DANGER_BOTTOM.r, UIStyles.DANGER_BOTTOM.g, UIStyles.DANGER_BOTTOM.b, 0.14)
		var danger_border := Color(UIStyles.DANGER_BOTTOM.r, UIStyles.DANGER_BOTTOM.g, UIStyles.DANGER_BOTTOM.b, 0.5)
		info_panel.add_theme_stylebox_override("panel", UIStyles.card(danger_bg, danger_border, 40))
		UIStyles.apply_font(tutorial_help_label, UIStyles.FONT_SEMIBOLD, font_size, UIStyles.DANGER_TEXT)
		if info_icon != null:
			info_icon.modulate = UIStyles.DANGER_TEXT
	else:
		info_panel.add_theme_stylebox_override("panel", UIStyles.glass_panel(40))
		UIStyles.apply_font(tutorial_help_label, UIStyles.FONT_MEDIUM, font_size, UIStyles.MUTED)
		if info_icon != null:
			info_icon.modulate = UIStyles.PURPLE
	info_line_error_state = error
	info_line_font_size = font_size

func update_hint_button_label(_lumens: int) -> void:
	if hint_label != null:
		hint_label.text = Locale.t("game.hint", "Hint")
	update_lumens_badge(_lumens)

func build_lumens_badge() -> void:
	if hint_button == null:
		return
	lumens_badge = Panel.new()
	lumens_badge.name = "LumensBadge"
	lumens_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lumens_badge.z_index = 20
	hint_button.add_child(lumens_badge)

	lumens_badge_icon = UIStyles.sparkle_mark(lumens_badge, Vector2.ZERO, Vector2(30, 30), Color.WHITE)
	lumens_badge_label = Label.new()
	lumens_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lumens_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(lumens_badge_label, UIStyles.FONT_BOLD, 38, Color.WHITE)
	lumens_badge.add_child(lumens_badge_label)

	lumens_badge_border = LumensBadgeOutline.new()
	lumens_badge_border.name = "LumensBadgeBorder"
	lumens_badge_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lumens_badge.add_child(lumens_badge_border)
	layout_lumens_badge()
	update_lumens_badge(current_lumens)

func layout_lumens_badge() -> void:
	if hint_button == null or lumens_badge == null:
		return
	var badge_h := 68.0
	var min_w := 112.0
	var digits := str(max(0, current_lumens)).length()
	var badge_w := maxf(min_w, 84.0 + float(digits) * 22.0)
	var badge_size := Vector2(badge_w, badge_h)
	var badge_pos := Vector2(hint_button.size.x - badge_size.x - 27.0, -33.0)
	lumens_badge.position = badge_pos
	lumens_badge.size = badge_size
	# Tutorial hints are free, so the regular balance badge is intentionally absent.
	lumens_badge.visible = hint_button.visible and not current_is_tutorial
	if lumens_badge_border != null:
		lumens_badge_border.position = Vector2.ZERO
		lumens_badge_border.size = badge_size
	if lumens_badge_icon != null:
		lumens_badge_icon.position = Vector2(15.0, 18.0)
		lumens_badge_icon.size = Vector2(33.0, 33.0)
	if lumens_badge_label != null:
		lumens_badge_label.position = Vector2(52.0, 0.0)
		lumens_badge_label.size = Vector2(badge_size.x - 62.0, badge_size.y)

func update_lumens_badge(balance: int) -> void:
	current_lumens = balance
	if lumens_badge == null or lumens_badge_label == null or lumens_badge_icon == null:
		return
	layout_lumens_badge()
	lumens_badge_label.text = str(max(0, balance))
	# Единый источник вида бейджа — _apply_badge_dim: он лерпит цвет ОДНОГО слоя между
	# «включённым» (плоский фиолет / muted) и «серым» (спутник) по _hint_dim_progress.
	# Один слой → бейдж не мигает при затемнении экрана на переходах между экранами.
	_apply_badge_dim(_hint_dim_progress)

# A temporary caption (operator tap / panel tap) fades in, rests 3s, then the
# default caption returns.
func show_temporary_help(text: String, _error: bool = false) -> void:
	var repeats_visible_text := info_temp_active and tutorial_help_label != null and tutorial_help_label.text == text
	info_temp_active = true
	if repeats_visible_text:
		_restart_temporary_info_timer(level_failed)
	else:
		show_info_caption(text, true, level_failed)

# Repeated taps on the same source only renew the hold timeout. Keep the current
# alpha instead of resetting it to zero, so a visible caption never blinks.
func _restart_temporary_info_timer(error: bool) -> void:
	if tutorial_help_label == null:
		return
	info_caption_version += 1
	var version := info_caption_version
	if info_caption_tween != null and info_caption_tween.is_valid():
		info_caption_tween.kill()
	if info_line_error_state == null or bool(info_line_error_state) != error:
		prepare_info_caption(tutorial_help_label.text, error)
	info_caption_tween = create_tween()
	# A repeat during the initial fade or the final fade-out resumes from the
	# current opacity; it never jumps back to transparent.
	if tutorial_help_label.modulate.a < 0.999:
		info_caption_tween.tween_property(tutorial_help_label, "modulate:a", 1.0, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_queue_temporary_info_timeout(info_caption_tween, version)

# The resting caption (progress / fail text). It only transitions again when
# the text changes or a temporary message is currently occupying the line.
func set_info_default(text: String, error: bool) -> void:
	var changed := text != info_default_text
	info_default_text = text
	if current_moves == 0 or tutorial_help_label.text == "":
		info_temp_active = false
		set_info_immediate(text, error)
		return
	if changed or info_temp_active:
		info_temp_active = false
		show_info_caption(text, false, error)

func set_info_immediate(text: String, error: bool) -> void:
	if tutorial_help_label == null:
		return
	info_caption_version += 1
	if info_caption_tween != null and info_caption_tween.is_valid():
		info_caption_tween.kill()
	prepare_info_caption(text, error)
	tutorial_help_label.modulate.a = 1.0

func info_text_font_size(text: String, error: bool) -> int:
	var font: Font = UIStyles.FONT_SEMIBOLD if error else UIStyles.FONT_MEDIUM
	var size := 40
	var readable_width := info_readable_width()
	while size > 34 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > readable_width:
		size -= 1
	return size

func _info_text_width(text: String, font_size: int, error: bool) -> float:
	var font: Font = UIStyles.FONT_SEMIBOLD if error else UIStyles.FONT_MEDIUM
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

func info_readable_width() -> float:
	if info_clip == null:
		return 0.0
	return maxf(0.0, info_clip.size.x - INFO_FADE_PX * 2.0 - INFO_TEXT_SAFE_INSET * 2.0)

func prepare_info_caption(text: String, error: bool) -> void:
	if tutorial_help_label == null:
		return
	var font_size := info_text_font_size(text, error)
	apply_info_line_style(error, font_size)
	var text_width := _info_text_width(text, font_size, error)
	tutorial_help_label.text = text
	tutorial_help_label.size = Vector2(text_width, INFO_LINE_SIZE.y)
	tutorial_help_label.position.x = _info_rest_x_for_width(text_width)

func _info_rest_x_for_width(text_width: float) -> float:
	if info_clip == null:
		return INFO_REST_X
	var readable_left := INFO_FADE_PX + INFO_TEXT_SAFE_INSET
	var readable_w := info_readable_width()
	if text_width <= readable_w:
		return readable_left + (readable_w - text_width) * 0.5
	return readable_left

func show_info_caption(text: String, temp: bool, error: bool) -> void:
	if info_clip == null:
		return
	info_caption_version += 1
	var version := info_caption_version
	if info_caption_tween != null and info_caption_tween.is_valid():
		info_caption_tween.kill()
	prepare_info_caption(text, error)
	tutorial_help_label.modulate.a = 0.0
	info_caption_tween = create_tween()
	info_caption_tween.tween_property(tutorial_help_label, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if temp:
		_queue_temporary_info_timeout(info_caption_tween, version)

func _queue_temporary_info_timeout(tween: Tween, version: int) -> void:
	tween.tween_interval(INFO_TEMP_HOLD_SECONDS)
	tween.tween_property(tutorial_help_label, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if version == info_caption_version:
			info_temp_active = false
			show_info_caption(info_default_text, false, level_failed)
	)

# --- Status pill (LEVEL / MOVES) building blocks ------------------------------

# One independently scalable half of a shared full-width pill. Both sides render
# the same cached texture at the same virtual width, then clip opposite halves.
func make_status_block(pos: Vector2, size: Vector2, is_left: bool) -> Control:
	var area := Control.new()
	area.position = pos
	area.size = size
	area.clip_contents = true
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var surface := Panel.new()
	surface.name = "StatusSurface"
	surface.position = Vector2.ZERO if is_left else Vector2(-size.x, 0.0)
	surface.size = TOP_STATUS_SIZE
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_theme_stylebox_override("panel", UIStyles.glass_panel(67))
	area.add_child(surface)
	return area

# Half hover tint has only the outer corners rounded; its center edge is square.
func make_status_hover(size: Vector2, is_left: bool) -> Panel:
	var overlay := Panel.new()
	overlay.position = Vector2.ZERO
	overlay.size = size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.modulate.a = 0.0
	overlay.add_theme_stylebox_override("panel", status_hover_style(is_left))
	return overlay

func status_hover_style(is_left: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0)
	style.corner_radius_top_left = 67 if is_left else 0
	style.corner_radius_bottom_left = 67 if is_left else 0
	style.corner_radius_top_right = 0 if is_left else 67
	style.corner_radius_bottom_right = 0 if is_left else 67
	return style

# A centered status label (LEVEL / MOVES text). It also handles taps + hover, so
# it is mouse-STOP; the caller sets position/size.
func make_status_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	UIStyles.apply_font(label, UIStyles.FONT_BOLD, 44, UIStyles.STATUSBAR_TEXT)
	return label

func set_orbit_items(items: Array) -> void:
	var animate_new_items := not skip_orbit_entrance_once
	var desired_ids: Dictionary = {}
	for i in range(items.size()):
		var item: Dictionary = items[i] as Dictionary
		var value: int = int(item["value"])
		var op: String = str(item["op"])
		var item_id: String = str(item.get("id", "%s_%d_%d" % [op, value, orbit.get_child_count()]))
		var slot: int = int(item["slot"]) if item.has("slot") else orbit.get_child_count()
		var slot_count: int = int(item["slot_count"]) if item.has("slot_count") else items.size()
		desired_ids[item_id] = true
		var btn: Button = find_orbit_button(item_id)
		var is_new := false
		if btn == null:
			btn = Button.new()
			btn.size = Vector2(188, 188)
			btn.pivot_offset = btn.size * 0.5
			btn.add_theme_font_size_override("font_size", 67)
			btn.pressed.connect(_on_orbit_button_pressed.bind(btn))
			UIStyles.add_press_animation(btn)
			orbit.add_child(btn)
			is_new = true
		if is_new and animate_new_items:
			btn.modulate.a = 0.0
			btn.scale = Vector2(0.3, 0.3)
		else:
			btn.modulate.a = 1.0
			btn.scale = Vector2.ONE
		btn.set_meta("popping", false)
		btn.visible = true
		btn.text = str(value)
		btn.set_meta("id", item_id)
		btn.set_meta("value", value)
		btn.set_meta("op", op)
		btn.set_meta("slot", slot)
		btn.set_meta("slot_count", slot_count)
		var target_angle := orbit_angle_for_slot(slot, slot_count)
		if item.has("orbit_target_angle"):
			target_angle = float(item["orbit_target_angle"])
		if is_new or not btn.has_meta("orbit_display_angle"):
			btn.set_meta("orbit_display_angle", target_angle)
		if bool(item.get("orbit_snap_to_target", false)):
			btn.set_meta("orbit_display_angle", target_angle)
		btn.set_meta("orbit_target_angle", target_angle)
		btn.set_meta("orbit_force_clockwise", bool(item.get("orbit_force_clockwise", false)))
		var valid_operation := OperationLogic.can_apply(current_number_value, value, op)
		var had_validity := btn.has_meta("operation_valid")
		var previous_validity := bool(btn.get_meta("operation_valid", valid_operation))
		btn.set_meta("operation_valid", valid_operation)
		if is_new or not had_validity:
			style_operation_button(btn, op, valid_operation)
		elif previous_validity != valid_operation:
			animate_operation_availability(btn, op, previous_validity, valid_operation)
		elif not btn.has_meta("availability_tween"):
			style_operation_button(btn, op, valid_operation)
		# A grey satellite remains clickable so it can acknowledge the tap without
		# applying the operation. A failed level still blocks the whole orbit.
		btn.disabled = level_failed
		if is_new and animate_new_items:
			btn.position = orbit_target_position(btn) - btn.size * 0.5
			var pop_tween := btn.create_tween()
			pop_tween.tween_interval(orbit_entrance_delay + float(i) * 0.04)
			pop_tween.tween_property(btn, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pop_tween.parallel().tween_property(btn, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for child in orbit.get_children():
		var btn := child as Button
		if btn != null and not desired_ids.has(str(btn.get_meta("id"))):
			animate_orbit_disappear(btn)
	skip_orbit_entrance_once = false
	orbit_entrance_delay = 0.0
	update_orbit_positions(false)

func restore_orbit_without_entrance_animation() -> void:
	skip_orbit_entrance_once = true

# Тайминги исчезновения спутника при ходе. Единый источник и для анимации, и для
# синхронизации блокировки ввода (4.3) — вместо «магической» 0.22 в Main.
const ORBIT_DISAPPEAR_GROW := 0.07
const ORBIT_DISAPPEAR_FADE := 0.14
const ORBIT_AVAILABILITY_DURATION := 0.26
const ORBIT_REENABLE_PULSE := 0.03
# Per-chip stagger when the whole orbit is dismissed on level advance (ripple-out).
const ORBIT_DISMISS_STAGGER := 0.02
# Ввод разблокируется, когда убранный спутник практически исчез (он `disabled` сразу,
# так что даблтап по нему невозможен), а оставшиеся уже перетекают — «доска готова».
const ORBIT_MOVE_SETTLE_TIME := ORBIT_DISAPPEAR_FADE

func orbit_move_settle_time() -> float:
	return ORBIT_MOVE_SETTLE_TIME

func animate_orbit_disappear(button: Button) -> void:
	if button == null or button.is_queued_for_deletion():
		return
	if bool(button.get_meta("popping", false)):
		return
	finish_operation_availability(button)
	button.set_meta("popping", true)
	button.disabled = true
	button.pivot_offset = button.size * 0.5
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.16, 1.16), ORBIT_DISAPPEAR_GROW).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.72, 0.72), ORBIT_DISAPPEAR_FADE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(button, "modulate:a", 0.0, ORBIT_DISAPPEAR_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		if button == null or button.is_queued_for_deletion():
			return
		button.visible = false
		button.modulate.a = 1.0
		button.scale = Vector2.ONE
		button.set_meta("popping", false)
	)

# Gracefully shrink/fade the whole current orbit away (ripple-out), then fire
# `after_done`. Used on level advance so the old board leaves smoothly instead of
# being freed in a single frame; the chips keep spinning as they shrink (the same
# way animate_orbit_disappear coexists with the spin during a normal move).
func dismiss_orbit(after_done: Callable = Callable()) -> void:
	var buttons: Array[Button] = []
	if orbit != null:
		for child in orbit.get_children():
			var btn := child as Button
			if btn != null and not btn.is_queued_for_deletion() and btn.visible and not bool(btn.get_meta("popping", false)):
				buttons.append(btn)
	if buttons.is_empty():
		if after_done.is_valid():
			after_done.call()
		return
	var last_end := 0.0
	for i in range(buttons.size()):
		var delay := float(i) * ORBIT_DISMISS_STAGGER
		var starter := create_tween()
		starter.tween_interval(delay)
		starter.tween_callback(animate_orbit_disappear.bind(buttons[i]))
		last_end = maxf(last_end, delay + ORBIT_DISAPPEAR_GROW + ORBIT_DISAPPEAR_FADE)
	var done := create_tween()
	done.tween_interval(last_end)
	done.tween_callback(func() -> void:
		if after_done.is_valid():
			after_done.call()
	)

func find_orbit_button(item_id: String) -> Button:
	for child in orbit.get_children():
		var btn := child as Button
		if btn != null and not btn.is_queued_for_deletion() and str(btn.get_meta("id", "")) == item_id:
			return btn
	return null

func style_operation_button(button: Button, op: String, valid: bool = true) -> void:
	# Satellite matches its operator's chip: fill = plate, outline = identity color,
	# number = high-contrast semantic text color.
	var colors := operation_button_colors(op, valid)
	apply_operation_button_style(button, op, colors["bg"], colors["border"], colors["text"], valid)

func operation_button_colors(op: String, valid: bool) -> Dictionary:
	if valid:
		return {
			"bg": UIStyles.operation_plate(op),
			"border": UIStyles.operation_border(op),
			"text": UIStyles.operation_text(op),
		}
	# At rest an unavailable move is fully neutral: outline and number share the
	# same grey. Its operator color is revealed only by the rejected-tap flash.
	return {
		"bg": disabled_orbit_bg(),
		"border": UIStyles.DISABLED,
		"text": UIStyles.DISABLED,
	}

func animate_operation_availability(button: Button, op: String, from_valid: bool, to_valid: bool) -> void:
	if button == null or button.is_queued_for_deletion():
		return
	var from_colors := operation_button_colors(op, from_valid)
	if button.has_meta("availability_bg"):
		from_colors = {
			"bg": button.get_meta("availability_bg"),
			"border": button.get_meta("availability_border"),
			"text": button.get_meta("availability_text"),
		}
	_kill_operation_availability_tween(button)
	var to_colors := operation_button_colors(op, to_valid)
	button.scale = Vector2.ONE
	var tween := button.create_tween()
	button.set_meta("availability_tween", tween)
	tween.tween_method(func(amount: float) -> void:
		if button == null or button.is_queued_for_deletion():
			return
		var bg: Color = (from_colors["bg"] as Color).lerp(to_colors["bg"] as Color, amount)
		var border: Color = (from_colors["border"] as Color).lerp(to_colors["border"] as Color, amount)
		var text_color: Color = (from_colors["text"] as Color).lerp(to_colors["text"] as Color, amount)
		button.set_meta("availability_bg", bg)
		button.set_meta("availability_border", border)
		button.set_meta("availability_text", text_color)
		apply_operation_button_style(button, op, bg, border, text_color, to_valid)
		if to_valid:
			var pulse := 1.0 + sin(amount * PI) * ORBIT_REENABLE_PULSE
			button.scale = Vector2.ONE * pulse
	, 0.0, 1.0, ORBIT_AVAILABILITY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func() -> void:
		if button == null or button.is_queued_for_deletion():
			return
		if button.get_meta("availability_tween", null) != tween:
			return
		button.remove_meta("availability_tween")
		_clear_operation_availability_colors(button)
		button.scale = Vector2.ONE
		style_operation_button(button, op, bool(button.get_meta("operation_valid", to_valid)))
	)

func finish_operation_availability(button: Button) -> void:
	if button == null or button.is_queued_for_deletion():
		return
	_kill_operation_availability_tween(button)
	_clear_operation_availability_colors(button)
	button.scale = Vector2.ONE
	var op := str(button.get_meta("op", ""))
	if not op.is_empty():
		style_operation_button(button, op, bool(button.get_meta("operation_valid", true)))

func _kill_operation_availability_tween(button: Button) -> void:
	if not button.has_meta("availability_tween"):
		return
	var tween := button.get_meta("availability_tween") as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	button.remove_meta("availability_tween")

func _clear_operation_availability_colors(button: Button) -> void:
	for meta_key in [&"availability_bg", &"availability_border", &"availability_text"]:
		if button.has_meta(meta_key):
			button.remove_meta(meta_key)

func apply_operation_button_style(button: Button, op: String, bg: Color, border: Color, text_color: Color, valid: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	UIStyles._set_radius(normal, 94)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	if valid and str(button.get_meta("id", "")) == hint_highlight_item_id:
		apply_hint_shadow(normal, op, hint_highlight_strength)
		apply_hint_shadow(hover, op, hint_highlight_strength)
		apply_hint_shadow(pressed, op, hint_highlight_strength)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_font_override("font", UIStyles.FONT_BOLD)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color)
	update_orbit_button_outline(button, border)

func disabled_orbit_bg() -> Color:
	return UIStyles.BG.lerp(Color.WHITE, 0.03) if UIStyles.is_dark() else Color("#F1F0F5")

func update_orbit_button_outline(button: Button, color: Color) -> void:
	if button == null or button.is_queued_for_deletion():
		return
	var outline := button.get_node_or_null("OrbitButtonOutline") as OrbitButtonOutline
	if outline == null:
		outline = OrbitButtonOutline.new()
		outline.name = "OrbitButtonOutline"
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outline.z_index = 10
		button.add_child(outline)
	outline.position = Vector2.ZERO
	outline.size = button.size
	outline.outline_color = color
	outline.outline_width = 4.0
	outline.queue_redraw()

func apply_hint_shadow(style: StyleBoxFlat, op: String, strength: float = 1.0) -> void:
	var shadow := UIStyles.operation_border(op)
	# Reveal strength -1→0 grows the halo from the chip's center into the regular
	# breathing glow. 0→1 is the light pulse; 1→2 is the large reveal halo.
	if strength < 0.0:
		var reveal_progress := clampf(strength + 1.0, 0.0, 1.0)
		shadow.a = (0.62 if UIStyles.is_dark() else 0.48) * UIStyles.ATTENTION_GLOW_MIN_ALPHA * reveal_progress
		style.shadow_color = shadow
		style.shadow_size = roundi(UIStyles.ATTENTION_GLOW_MIN_EXTENT * reveal_progress)
		style.shadow_offset = Vector2.ZERO
		return
	var amount := clampf(strength, 0.0, 1.0)
	var boost := clampf(strength - 1.0, 0.0, 1.0)
	var alpha_factor := lerpf(UIStyles.attention_glow_alpha(amount), HINT_REPEAT_GLOW_ALPHA_FACTOR, boost)
	shadow.a = minf(1.0, (0.62 if UIStyles.is_dark() else 0.48) * alpha_factor)
	style.shadow_color = shadow
	style.shadow_size = roundi(lerpf(UIStyles.attention_glow_extent(amount), HINT_REPEAT_GLOW_EXTENT, boost))
	style.shadow_offset = Vector2.ZERO

func _on_orbit_button_pressed(button: Button) -> void:
	if button == null or button.is_queued_for_deletion() or button.disabled:
		return
	var item_id := str(button.get_meta("id", ""))
	if item_id.is_empty():
		return
	var op := str(button.get_meta("op", ""))
	if not bool(button.get_meta("operation_valid", true)):
		play_rejected_orbit_feedback(button, op)
		AudioManagerScript.play_orbit_rejected_haptic()
		return
	finish_operation_availability(button)
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.90, 0.90), 0.055).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	orbit_pressed.emit(int(button.get_meta("value")), op, item_id)

func play_rejected_orbit_feedback(button: Button, op: String, restore_valid: bool = false) -> void:
	if button == null or button.is_queued_for_deletion():
		return
	finish_operation_availability(button)
	for meta_key in [&"rejected_color_tween", &"rejected_shake_tween"]:
		if button.has_meta(meta_key):
			var previous := button.get_meta(meta_key) as Tween
			if previous != null and previous.is_valid():
				previous.kill()
	var color_tween := button.create_tween()
	button.set_meta("rejected_color_tween", color_tween)
	color_tween.tween_method(func(amount: float) -> void:
		apply_rejected_orbit_flash(button, op, amount, restore_valid), 0.0, 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	color_tween.tween_method(func(amount: float) -> void:
		apply_rejected_orbit_flash(button, op, amount, restore_valid), 1.0, 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	color_tween.finished.connect(func() -> void:
		if is_instance_valid(button):
			style_operation_button(button, op, restore_valid)
			button.remove_meta("rejected_color_tween")
	)
	var shake_tween := button.create_tween()
	button.set_meta("rejected_shake_tween", shake_tween)
	shake_tween.tween_method(func(offset: Vector2) -> void:
		set_rejected_orbit_offset(button, offset), Vector2.ZERO, Vector2(9.0, 0.0), 0.055).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	shake_tween.tween_method(func(offset: Vector2) -> void:
		set_rejected_orbit_offset(button, offset), Vector2(9.0, 0.0), Vector2(-7.0, 0.0), 0.055).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_method(func(offset: Vector2) -> void:
		set_rejected_orbit_offset(button, offset), Vector2(-7.0, 0.0), Vector2(4.0, 0.0), 0.055).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_method(func(offset: Vector2) -> void:
		set_rejected_orbit_offset(button, offset), Vector2(4.0, 0.0), Vector2.ZERO, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	shake_tween.finished.connect(func() -> void:
		if is_instance_valid(button):
			set_rejected_orbit_offset(button, Vector2.ZERO)
			button.remove_meta("rejected_shake_tween")
	)

func apply_rejected_orbit_flash(button: Button, op: String, amount: float, restore_valid: bool = false) -> void:
	if button == null or button.is_queued_for_deletion():
		return
	var t := clampf(amount, 0.0, 1.0)
	var rest_bg := UIStyles.operation_plate(op) if restore_valid else disabled_orbit_bg()
	var rest_border := UIStyles.operation_border(op) if restore_valid else UIStyles.DISABLED
	var rest_text := UIStyles.operation_text(op) if restore_valid else UIStyles.DISABLED
	var flash_bg := UIStyles.operation_plate(op).lerp(UIStyles.operation_border(op), 0.18)
	apply_operation_button_style(
		button,
		op,
		rest_bg.lerp(flash_bg, t),
		rest_border.lerp(UIStyles.operation_border(op), t),
		rest_text,
		restore_valid
	)

func reject_tutorial_orbit(item_id: String) -> void:
	var button := find_orbit_button(item_id)
	if button == null:
		return
	var op := str(button.get_meta("op", ""))
	play_rejected_orbit_feedback(button, op, true)
	AudioManagerScript.play_tutorial_wrong_move_haptic()
	show_temporary_help(
		Locale.t("tutorial.wrong_move", "Tutorial is safe. Levels have traps."),
		false
	)

func set_rejected_orbit_offset(button: Button, offset: Vector2) -> void:
	if button != null and not button.is_queued_for_deletion():
		button.set_meta("rejected_offset", offset)

func reveal_hint_result(message: String, balance: int, target: Dictionary) -> void:
	current_lumens = balance
	update_lumens_badge(balance)
	if hint_popup != null:
		hint_popup.cache_result(message, balance, target)
	var reveal := func() -> void:
		highlight_hint_target(target)
	if hint_popup != null and hint_popup.visible:
		hint_popup.hide_popup(reveal)
	else:
		reveal.call()

func restore_hint_result_cache(message: String, balance: int, target: Dictionary) -> void:
	if hint_popup != null:
		hint_popup.cache_result(message, balance, target)

func highlight_hint_target(target: Dictionary) -> void:
	if target.is_empty():
		clear_hint_highlight()
		return
	var item_id := str(target.get("id", ""))
	var button := find_orbit_button(item_id) if not item_id.is_empty() else null
	if button == null:
		button = find_orbit_button_by_move(str(target.get("op", "")), int(target.get("value", 0)))
	if button == null:
		return
	var target_item_id := str(button.get_meta("id", ""))
	var op := str(button.get_meta("op", target.get("op", "")))
	var value := int(button.get_meta("value", target.get("value", 0)))
	var valid_operation := OperationLogic.can_apply(current_number_value, value, op)
	if target_item_id == hint_highlight_item_id:
		pulse_existing_hint_highlight(button, op)
		return
	clear_hint_highlight()
	hint_highlight_item_id = target_item_id
	hint_highlight_strength = -1.0
	style_operation_button(button, op, valid_operation)
	play_hint_reveal(button, op, true)

func restore_hint_highlight(target: Dictionary) -> void:
	clear_hint_highlight()
	if target.is_empty():
		return
	var item_id := str(target.get("id", ""))
	var button := find_orbit_button(item_id) if not item_id.is_empty() else null
	if button == null:
		button = find_orbit_button_by_move(str(target.get("op", "")), int(target.get("value", 0)))
	if button == null:
		return
	var op := str(button.get_meta("op", target.get("op", "")))
	var value := int(button.get_meta("value", target.get("value", 0)))
	if not OperationLogic.can_apply(current_number_value, value, op):
		return
	hint_highlight_item_id = str(button.get_meta("id", ""))
	hint_highlight_strength = 0.0
	style_operation_button(button, op, true)
	start_hint_highlight_pulse(button, op)

func set_hint_highlight_strength(button: Button, op: String, strength: float) -> void:
	if button == null or button.is_queued_for_deletion():
		return
	hint_highlight_strength = clampf(strength, -1.0, 2.0)
	for state in [&"normal", &"hover", &"pressed"]:
		var style := button.get_theme_stylebox(state) as StyleBoxFlat
		if style != null:
			apply_hint_shadow(style, op, hint_highlight_strength)

func pulse_existing_hint_highlight(button: Button, op: String) -> void:
	play_hint_reveal(button, op, false)

func play_hint_reveal(button: Button, op: String, from_center: bool) -> void:
	if button == null or button.is_queued_for_deletion():
		return
	if hint_highlight_tween != null and hint_highlight_tween.is_valid():
		hint_highlight_tween.kill()
	var starting_strength := -1.0 if from_center else clampf(hint_highlight_strength, 0.0, 1.0)
	set_hint_highlight_strength(button, op, starting_strength)
	hint_highlight_tween = button.create_tween()
	if not from_center:
		# Repeated Hint presses smoothly gather the light back into the chip before
		# replaying the same center-out reveal instead of popping to full size.
		hint_highlight_tween.tween_method(func(strength: float) -> void:
			set_hint_highlight_strength(button, op, strength), starting_strength, -1.0, HINT_REVEAL_RESET).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	hint_highlight_tween.tween_method(func(strength: float) -> void:
		set_hint_highlight_strength(button, op, strength), -1.0, 2.0, HINT_REVEAL_GROW).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	hint_highlight_tween.tween_method(func(strength: float) -> void:
		set_hint_highlight_strength(button, op, strength), 2.0, 1.0, HINT_REVEAL_SETTLE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hint_highlight_tween.finished.connect(func() -> void:
		if is_instance_valid(button) and hint_highlight_item_id == str(button.get_meta("id", "")):
			start_hint_highlight_pulse(button, op, 1.0)
	)

func start_hint_highlight_pulse(button: Button, op: String, starting_level: float = 0.0) -> void:
	if button == null or button.is_queued_for_deletion():
		return
	if hint_highlight_tween != null and hint_highlight_tween.is_valid():
		hint_highlight_tween.kill()
	var starts_at_peak := starting_level >= 0.5
	set_hint_highlight_strength(button, op, 1.0 if starts_at_peak else 0.0)
	hint_highlight_tween = button.create_tween().set_loops()
	if starts_at_peak:
		hint_highlight_tween.tween_method(func(strength: float) -> void:
			set_hint_highlight_strength(button, op, strength), 1.0, 0.0, UIStyles.ATTENTION_PULSE_HALF_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		hint_highlight_tween.tween_method(func(strength: float) -> void:
			set_hint_highlight_strength(button, op, strength), 0.0, 1.0, UIStyles.ATTENTION_PULSE_HALF_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		hint_highlight_tween.tween_method(func(strength: float) -> void:
			set_hint_highlight_strength(button, op, strength), 0.0, 1.0, UIStyles.ATTENTION_PULSE_HALF_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		hint_highlight_tween.tween_method(func(strength: float) -> void:
			set_hint_highlight_strength(button, op, strength), 1.0, 0.0, UIStyles.ATTENTION_PULSE_HALF_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func find_orbit_button_by_move(op: String, value: int) -> Button:
	for child in orbit.get_children():
		var btn := child as Button
		if btn == null or btn.is_queued_for_deletion():
			continue
		if str(btn.get_meta("op", "")) == op and int(btn.get_meta("value", 0)) == value:
			return btn
	return null

func clear_hint_highlight() -> void:
	var previous_button := find_orbit_button(hint_highlight_item_id) if not hint_highlight_item_id.is_empty() and is_instance_valid(orbit) else null
	if hint_highlight_tween != null and hint_highlight_tween.is_valid():
		hint_highlight_tween.kill()
	hint_highlight_item_id = ""
	hint_highlight_strength = 0.0
	hint_highlight_tween = null
	if previous_button != null:
		var op := str(previous_button.get_meta("op", ""))
		var valid := bool(previous_button.get_meta("operation_valid", true))
		style_operation_button(previous_button, op, valid)

func _process(delta: float) -> void:
	if not visible:
		return
	var speed := 0.25
	orbit_angle += delta * speed * orbit_spin_factor
	var orbit_moved := update_orbit_positions(false)
	if coach_overlay != null and coach_overlay.visible:
		var moving_area := coach_overlay.moving_orbit_area()
		if not moving_area.is_empty() and (orbit_moved or moving_area != last_coach_orbit_area):
			coach_overlay.refresh_orbit_spotlight(visible_orbit_button_rects(moving_area == "invalid_orbit"))
		last_coach_orbit_area = moving_area
	else:
		last_coach_orbit_area = ""
	queue_redraw()

func _on_coach_showing_started() -> void:
	stop_orbit_spin_smoothly()
	_set_local_header_over_coach(false)
	coach_header_mode_changed.emit(true)
	if info_panel != null:
		info_panel.visible = true

func _on_coach_hiding_started() -> void:
	start_orbit_spin_ramp()
	_set_local_header_over_coach(false)
	# Keep persistent navigation blocked until the dim shader has fully faded.
	coach_header_mode_changed.emit(true)
	if info_panel != null:
		info_panel.visible = true

func _on_coach_hiding_finished() -> void:
	coach_header_mode_changed.emit(false)

func _set_local_header_over_coach(shown: bool) -> void:
	for button in [back_button, settings_button]:
		if not is_instance_valid(button):
			continue
		button.visible = shown
		button.z_index = 100 if shown else 0

func stop_orbit_spin_smoothly() -> void:
	if orbit_spin_tween != null and orbit_spin_tween.is_valid():
		orbit_spin_tween.kill()
	orbit_spin_tween = create_tween()
	orbit_spin_tween.tween_property(self, "orbit_spin_factor", 0.0, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func start_orbit_spin_ramp() -> void:
	if orbit_spin_tween != null and orbit_spin_tween.is_valid():
		orbit_spin_tween.kill()
	orbit_spin_factor = 0.0
	orbit_spin_tween = create_tween()
	orbit_spin_tween.tween_property(self, "orbit_spin_factor", 1.0, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	if not visible:
		return
	# Slightly wider ring, filled with the purple-button color (mid of the primary
	# gradient) instead of the faint neutral ring.
	var ring_color := UIStyles.PRIMARY_TOP.lerp(UIStyles.PRIMARY_BOTTOM, 0.5)
	ring_color.a = 0.55
	draw_arc(screen_center, orbit_radius, 0.0, TAU, 200, ring_color, 6.0, true)

func update_orbit_positions(snap: bool = false) -> bool:
	var moved := false
	for i in range(orbit.get_child_count()):
		var b := orbit.get_child(i) as Button
		if b == null or b.is_queued_for_deletion() or not b.visible:
			continue
		var previous_position := b.position
		var target := orbit_target_position(b) - b.size * 0.5
		if snap:
			b.set_meta("orbit_display_angle", float(b.get_meta("orbit_target_angle", orbit_angle_for_button(b))))
			b.position = target + (b.get_meta("rejected_offset", Vector2.ZERO) as Vector2)
		else:
			var current_angle := float(b.get_meta("orbit_display_angle", orbit_angle_for_button(b)))
			var target_angle := float(b.get_meta("orbit_target_angle", orbit_angle_for_button(b)))
			if bool(b.get_meta("orbit_force_clockwise", false)):
				var clockwise_delta: float = fposmod(target_angle - current_angle, TAU)
				if clockwise_delta > PI * 0.75:
					current_angle = current_angle + angle_difference(current_angle, target_angle) * 0.16
				elif clockwise_delta < 0.002:
					current_angle = target_angle
				else:
					current_angle += clockwise_delta * 0.16
			else:
				var shortest_delta := angle_difference(current_angle, target_angle)
				current_angle = target_angle if absf(shortest_delta) < 0.002 else current_angle + shortest_delta * 0.115
			b.set_meta("orbit_display_angle", current_angle)
			b.position = orbit_position_for_angle(current_angle) - b.size * 0.5 + (b.get_meta("rejected_offset", Vector2.ZERO) as Vector2)
		moved = moved or not previous_position.is_equal_approx(b.position)
	return moved

func orbit_target_position(button: Button) -> Vector2:
	return orbit_position_for_angle(orbit_angle_for_button(button))

func orbit_angle_for_button(button: Button) -> float:
	var slot: int = int(button.get_meta("slot")) if button.has_meta("slot") else 0
	var slot_count: int = max(1, int(button.get_meta("slot_count")) if button.has_meta("slot_count") else orbit.get_child_count())
	return orbit_angle_for_slot(slot, slot_count)

func orbit_angle_for_slot(slot: int, slot_count: int) -> float:
	return TAU * float(slot) / float(max(1, slot_count)) - PI / 2.0

func orbit_position_for_angle(angle_without_spin: float) -> Vector2:
	var angle := angle_without_spin + orbit_angle
	return screen_center + Vector2(cos(angle), sin(angle)) * orbit_radius

func clear_orbit_buttons() -> void:
	clear_hint_highlight()
	if orbit == null:
		return
	for child in orbit.get_children().duplicate():
		orbit.remove_child(child)
		child.free()

func show_hint_result(message: String, balance: int) -> void:
	current_lumens = balance
	update_lumens_badge(balance)
	if hint_popup != null:
		hint_popup.show_result(message, balance)

func show_insufficient_hint_balance(balance: int) -> void:
	current_lumens = balance
	update_lumens_badge(balance)
	if hint_popup != null:
		hint_popup.show_insufficient_balance(balance)

func show_hint_prompt_after_ad(balance: int) -> void:
	current_lumens = balance
	update_lumens_badge(balance)
	if hint_popup != null:
		hint_popup.configure_state(current_moves, current_lumens, current_hint_cost)
		hint_popup.show_prompt()

func clear_hint_cache() -> void:
	if hint_popup != null:
		hint_popup.clear_cache()

func coach_context() -> Dictionary:
	return {
		"screen_center": screen_center,
		"center_rect": Rect2(center_panel.position, center_panel.size) if center_panel != null else Rect2(screen_center - Vector2(CENTER_CIRCLE_RADIUS, CENTER_CIRCLE_RADIUS), Vector2.ONE * CENTER_CIRCLE_DIAMETER),
		"target_rect": Rect2(target_panel.position, target_panel.size) if target_panel != null else Rect2(Vector2(540, TOP_STATUS_Y + TOP_STATUS_SIZE.y * 0.5) - TARGET_BUBBLE_SIZE * 0.5, TARGET_BUBBLE_SIZE),
		"info_rect": Rect2(info_panel.position, info_panel.size) if info_panel != null else Rect2(Vector2(EDGE_MARGIN, INFO_LINE_Y), INFO_LINE_SIZE),
		"orbit_valid_rects": visible_orbit_button_rects(false),
		"orbit_invalid_rects": visible_orbit_button_rects(true),
		"orbit_fallback_rect": Rect2(Vector2(100, 520), Vector2(880, 880)),
		"ops_rect": Rect2(operation_legend.position, operation_legend.size),
		"op_chip_rects": op_chip_rects(),
		"hint_rect": Rect2(hint_button.position, hint_button.size) if hint_button != null else Rect2(Vector2(70, ACTION_BUTTON_Y), Vector2(455, ACTION_BUTTON_HEIGHT))
	}

# 5.3/5.4: прямоугольники чипов легенды по имени оператора (легенда показывает только
# операторы уровня, без фиксированных индексов и без чипа «Недоступно»).
func op_chip_rects() -> Dictionary:
	var result: Dictionary = {}
	if operation_legend == null:
		return result
	for op in ["add", "subtract", "multiply", "divide"]:
		var idx: int = operation_legend.op_index(op)
		if idx >= 0:
			result[op] = operation_card_rect(idx)
	return result

func visible_orbit_button_rects(only_invalid: bool) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if orbit == null:
		return rects
	for child in orbit.get_children():
		var btn := child as Button
		if btn == null or not btn.visible:
			continue
		if bool(btn.get_meta("popping", false)):
			continue
		var is_invalid := not bool(btn.get_meta("operation_valid", true))
		if only_invalid and not is_invalid:
			continue
		if not only_invalid and is_invalid:
			continue
		rects.append(Rect2(btn.position, btn.size))
	return rects

func operation_card_rect(index: int) -> Rect2:
	if operation_legend != null:
		var local_rect: Rect2 = operation_legend.card_rect(index)
		return Rect2(operation_legend.position + local_rect.position, local_rect.size)
	return Rect2(operation_legend.position, Vector2(304, 74))
