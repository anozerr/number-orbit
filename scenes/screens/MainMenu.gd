class_name MainMenuScreen
extends Control

signal play_pressed
signal levels_pressed
signal settings_pressed

const BUTTON_HEIGHT := 194.0
const BUTTON_GAP := 40.0

var play_button: Button
var levels_button: Button
var levels_icon: TextureRect
var logo_center := Vector2.ZERO
var logo_time := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_on_viewport_resized)
	build()

func _on_viewport_resized() -> void:
	if visible:
		build()

func build() -> void:
	for child in get_children():
		child.queue_free()

	var col := Layout.content_column(self)
	var button_w := col.size.x
	var button_x := col.position.x
	var center_x := Layout.center_x(self)

	# Button block anchored so the Settings (3rd) button's bottom lands on the
	# unified bottom line (= operator-chips bottom), shared across all screens.
	var block_h := BUTTON_HEIGHT * 3.0 + BUTTON_GAP * 2.0
	var play_y := Layout.content_bottom_line(self) - block_h

	# Logo + wordmark block centered in the free space above the buttons
	# (mockup: ring box 308 + NUMBER/ORBIT at font 90 ≈ 540 tall block).
	var upper_mid := (Layout.content_top(self, 186.0) + play_y) * 0.5
	logo_center = Vector2(center_x, upper_mid - 116.0)
	var wordmark_top := logo_center.y + 174.0
	_wordmark("NUMBER", wordmark_top, UIStyles.TEXT, 90)
	_wordmark("ORBIT", wordmark_top + 100.0, UIStyles.PURPLE, 90, true)

	play_button = Button.new()
	play_button.text = Locale.t("menu.play", "Play")
	play_button.position = Vector2(button_x, play_y)
	play_button.size = Vector2(button_w, BUTTON_HEIGHT)
	play_button.add_theme_font_size_override("font_size", 57)
	UIStyles.primary_button(play_button)
	play_button.pressed.connect(func(): play_pressed.emit())
	add_child(play_button)

	levels_button = Button.new()
	levels_button.text = Locale.t("menu.levels", "Levels")
	levels_button.position = Vector2(button_x, play_y + BUTTON_HEIGHT + BUTTON_GAP)
	levels_button.size = Vector2(button_w, BUTTON_HEIGHT)
	levels_button.add_theme_font_size_override("font_size", 54)
	UIStyles.menu_button(levels_button)
	levels_button.pressed.connect(func(): levels_pressed.emit())
	add_child(levels_button)

	var settings_btn := Button.new()
	settings_btn.text = Locale.t("menu.settings", "Settings")
	settings_btn.position = Vector2(button_x, play_y + (BUTTON_HEIGHT + BUTTON_GAP) * 2.0)
	settings_btn.size = Vector2(button_w, BUTTON_HEIGHT)
	settings_btn.add_theme_font_size_override("font_size", 54)
	UIStyles.menu_button(settings_btn)
	settings_btn.pressed.connect(func(): settings_pressed.emit())
	add_child(settings_btn)

	set_continue_mode_labels()
	queue_redraw()

func _wordmark(text: String, y: float, color: Color, size: int, gradient: bool = false) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_constant_override("line_spacing", 0)
	label.add_theme_constant_override("outline_size", 0)
	if gradient:
		# ORBIT carries the primary-button diagonal gradient (sized to the text so
		# the shader normalizes across the word, not the full-width label).
		var tw: float = UIStyles.FONT_EXTRABOLD.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		label.position = Vector2((Layout.viewport_size(self).x - tw) * 0.5, y)
		label.size = Vector2(tw, size + 20)
		UIStyles.apply_font(label, UIStyles.FONT_EXTRABOLD, size, Color.WHITE)
		label.material = UIStyles.gradient_text_material(UIStyles.PRIMARY_TOP, UIStyles.PRIMARY_BOTTOM, label.size)
	else:
		label.position = Vector2(0, y)
		label.size = Vector2(Layout.viewport_size(self).x, size + 20)
		UIStyles.apply_font(label, UIStyles.FONT_EXTRABOLD, size, color)
	add_child(label)

var _has_played := false
var _current_level := 1
var _tutorials_complete := true

func set_continue_mode(has_played: bool, current_level: int, tutorials_complete: bool = true) -> void:
	_has_played = has_played
	_current_level = current_level
	_tutorials_complete = tutorials_complete
	set_continue_mode_labels()

func set_continue_mode_labels() -> void:
	if play_button == null:
		return
	play_button.text = Locale.t("menu.continue", "Continue") if _has_played and _current_level > 1 else Locale.t("menu.play", "Play")
	set_levels_enabled(_tutorials_complete)

func set_levels_enabled(enabled: bool) -> void:
	if levels_button == null:
		return
	levels_button.disabled = not enabled
	var color := UIStyles.TEXT if enabled else UIStyles.DISABLED
	var style := UIStyles.glass_panel() if enabled else UIStyles.locked_panel()
	var hover := style.duplicate() as StyleBoxFlat
	var pressed := style.duplicate() as StyleBoxFlat
	levels_button.add_theme_stylebox_override("normal", style)
	levels_button.add_theme_stylebox_override("hover", hover)
	levels_button.add_theme_stylebox_override("pressed", pressed)
	levels_button.add_theme_stylebox_override("disabled", style)
	levels_button.add_theme_color_override("font_color", color)
	levels_button.add_theme_color_override("font_hover_color", color)
	levels_button.add_theme_color_override("font_pressed_color", color)
	levels_button.add_theme_color_override("font_disabled_color", UIStyles.DISABLED)

func _process(delta: float) -> void:
	if not visible:
		return
	logo_time += delta
	queue_redraw()

func _draw() -> void:
	if logo_center == Vector2.ZERO:
		return
	var bob := sin(logo_time * 1.1) * 6.0
	var c := logo_center + Vector2(0, bob)
	var radius := 98.0
	# Thinner ring (was 23) — the mockup logo is not as heavy.
	var stroke := 16.0
	# Open ring with a gap in the top-right; dot sits inside the gap.
	var gap_center := -PI * 0.25          # top-right
	var gap_half := 0.42
	draw_arc(c, radius, gap_center + gap_half, gap_center - gap_half + TAU, 96, UIStyles.PURPLE, stroke, true)
	# End caps (round) — small filled circles at the arc ends.
	var a0 := gap_center + gap_half
	var a1 := gap_center - gap_half + TAU
	draw_circle(c + Vector2(cos(a0), sin(a0)) * radius, stroke * 0.5, UIStyles.PURPLE)
	draw_circle(c + Vector2(cos(a1), sin(a1)) * radius, stroke * 0.5, UIStyles.PURPLE)
	# Dot inside the gap.
	var dot_pos := c + Vector2(cos(gap_center), sin(gap_center)) * radius
	draw_circle(dot_pos, 22.0, UIStyles.PURPLE_DARK)
