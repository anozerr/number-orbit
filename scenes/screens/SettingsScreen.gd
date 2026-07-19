class_name SettingsScreen
extends Control

const PopupFactoryScript = preload("res://scripts/ui/PopupFactory.gd")
const AudioManagerScript = preload("res://scripts/audio/AudioManager.gd")

signal back_pressed
signal volumes_changed(music_value: int, sound_value: int)
signal haptics_changed(enabled: bool)
signal reset_progress_requested
signal theme_selected(theme_name: String)
signal language_changed(language_code: String)

var music_volume := 80
var sound_volume := 80
var haptics_enabled := true
var current_theme := "light"
var current_language := "en"
var reset_popup: Control
var reset_popup_panel: Panel
var language_popup: Control
var language_popup_panel: Panel

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_on_viewport_resized)
	build()

func _on_viewport_resized() -> void:
	if visible:
		var reopen_language := is_language_popup_open()
		var reopen_reset := is_reset_popup_open()
		build()
		if reopen_language:
			show_language_popup(true)
		elif reopen_reset:
			show_reset_popup(true)

func configure(music_value: int, sound_value: int, theme_name: String = "light", language_code: String = "en", enable_haptics: bool = true) -> void:
	var keep_language_popup_open := is_language_popup_open()
	music_volume = int(clamp(music_value, 0, 100))
	sound_volume = int(clamp(sound_value, 0, 100))
	haptics_enabled = enable_haptics
	current_theme = "dark" if theme_name == "dark" else "light"
	current_language = language_code
	build()
	if keep_language_popup_open:
		show_language_popup(true)

func build() -> void:
	Layout.clear_children_for_rebuild(self)
	reset_popup = null
	reset_popup_panel = null
	language_popup = null
	language_popup_panel = null

	var col := Layout.content_column(self)
	var cx := col.position.x
	var cw := col.size.x
	var t := Layout.content_top(self)

	# --- Header (mockup: 275-tall row, circle centered at t+74) ---
	var back_btn := UIStyles.back_button(self, Vector2(maxf(Layout.SIDE_MARGIN, cx), t + 74.0))
	back_btn.set_meta(&"screen_transition_role", &"back")
	back_btn.pressed.connect(func(): back_pressed.emit())

	var title := Label.new()
	title.text = Locale.t("settings.title", "Settings")
	title.position = Vector2(cx, t)
	title.size = Vector2(cw, 275)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title, UIStyles.FONT_EXTRABOLD, 54, UIStyles.TEXT)
	add_child(title)

	# --- Sliders card. Keep the Settings mockup's own t+252 placement; Level
	# Select reserves extra vertical space for its symmetric scroll-edge fade. ---
	var card_h := 503.0
	var sound_card := Panel.new()
	sound_card.position = Vector2(cx, t + 252.0)
	sound_card.size = Vector2(cw, card_h)
	sound_card.add_theme_stylebox_override("panel", UIStyles.glass_panel())
	add_child(sound_card)

	add_slider_block(sound_card, Locale.t("settings.music", "Music"), UIStyles.ICON_MUSIC, music_volume, 80.0, "music")
	var divider := ColorRect.new()
	divider.position = Vector2(67, 250.0)
	divider.size = Vector2(cw - 134, 3)
	divider.color = Color(UIStyles.TEXT.r, UIStyles.TEXT.g, UIStyles.TEXT.b, 0.08)
	sound_card.add_child(divider)
	add_slider_block(sound_card, Locale.t("settings.sound", "Sound"), UIStyles.ICON_SPEAKER, sound_volume, 313.0, "sound")

	build_haptics_row(cx, t + 805.0, cw)

	# --- Appearance + Language tiles: 194 tall = main-menu button height. ---
	add_section_label(cx, t + 1069.0, cw, Locale.t("settings.appearance", "APPEARANCE"))
	build_theme_toggle(cx, t + 1150.0, cw)

	add_section_label(cx, t + 1414.0, cw, Locale.t("settings.language", "LANGUAGE"))
	build_language_row(cx, t + 1495.0, cw)

	# --- Reset: 194 tall, its bottom on the unified bottom line (= the main-menu
	# Settings button's bottom and the operator-chips bottom). ---
	var reset_btn := Button.new()
	reset_btn.text = Locale.t("settings.reset", "Reset Progress")
	reset_btn.position = Vector2(cx, Layout.content_bottom_line(self) - 194.0)
	reset_btn.size = Vector2(cw, 194.0)
	reset_btn.add_theme_font_size_override("font_size", 50)
	UIStyles.danger_soft_button(reset_btn)
	reset_btn.pressed.connect(show_reset_popup)
	add_child(reset_btn)

	build_reset_popup()
	build_language_popup()

func add_section_label(x: float, y: float, w: float, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(x + 6, y)
	label.size = Vector2(w - 12, 60)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(label, UIStyles.FONT_BOLD, 44, UIStyles.MUTED)
	add_child(label)

# ---------------------------------------------------------------------------
# Haptics
# ---------------------------------------------------------------------------

func build_haptics_row(x: float, y: float, w: float) -> void:
	var row_h := 194.0
	var row := Button.new()
	row.position = Vector2(x, y)
	row.size = Vector2(w, row_h)
	row.toggle_mode = true
	row.button_pressed = haptics_enabled
	_apply_static_glass_button(row)
	add_child(row)

	var label_row := HBoxContainer.new()
	label_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_row.position = Vector2(67, 0)
	label_row.size = Vector2(w - 300, row_h)
	row.add_child(label_row)

	var label_text := Locale.t("settings.haptics", "Haptic Feedback")
	var label := Label.new()
	label.text = label_text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size.y = row_h
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(label, UIStyles.FONT_BOLD, 50, UIStyles.TEXT)
	label_row.add_child(label)

	var track_x := w - 67.0 - 140.0

	var track := Control.new()
	track.position = Vector2(track_x, (row_h - 78.0) * 0.5)
	track.size = Vector2(140, 78)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(track)

	var off_layer := Panel.new()
	off_layer.size = track.size
	off_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var off_style := StyleBoxFlat.new()
	off_style.bg_color = Color(1, 1, 1, 0.10) if UIStyles.is_dark() else Color(UIStyles.PURPLE.r, UIStyles.PURPLE.g, UIStyles.PURPLE.b, 0.15)
	UIStyles._set_radius(off_style, 39)
	off_layer.add_theme_stylebox_override("panel", off_style)
	track.add_child(off_layer)

	var on_layer := Panel.new()
	on_layer.size = track.size
	on_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	on_layer.add_theme_stylebox_override("panel", UIStyles.gradient_style(
		UIStyles.PRIMARY_TOP,
		UIStyles.PRIMARY_BOTTOM,
		39,
		Vector2i(140, 78)
	))
	track.add_child(on_layer)

	var knob := Panel.new()
	knob.size = Vector2(66, 66)
	knob.position.y = 6.0
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color.WHITE
	UIStyles._set_radius(knob_style, 33)
	knob.add_theme_stylebox_override("panel", knob_style)
	track.add_child(knob)
	_apply_haptics_switch_visual(on_layer, knob, haptics_enabled, false)

	row.toggled.connect(func(enabled: bool) -> void:
		haptics_enabled = enabled
		_apply_haptics_switch_visual(on_layer, knob, enabled, true)
		haptics_changed.emit(enabled)
		if enabled:
			AudioManagerScript.confirm_haptics_enabled()
	)

func _apply_haptics_switch_visual(on_layer: Panel, knob: Panel, enabled: bool, animate: bool) -> void:
	var target_x := 68.0 if enabled else 6.0
	var target_alpha := 1.0 if enabled else 0.0
	if animate:
		if knob.has_meta("haptics_tween"):
			var previous := knob.get_meta("haptics_tween") as Tween
			if previous != null and previous.is_valid():
				previous.kill()
		var tween := knob.create_tween()
		knob.set_meta("haptics_tween", tween)
		tween.set_parallel(true)
		tween.tween_method(_set_haptics_knob_progress.bind(knob, knob.position.x, target_x), 0.0, 1.0, 0.25)
		tween.tween_property(on_layer, "modulate:a", target_alpha, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		knob.position.x = target_x
		on_layer.modulate.a = target_alpha

func _set_haptics_knob_progress(progress: float, knob: Panel, from_x: float, to_x: float) -> void:
	knob.position.x = lerpf(from_x, to_x, _haptics_slide_ease(progress))

func _haptics_slide_ease(progress: float) -> float:
	var t := clampf(progress, 0.0, 1.0)
	for _iteration in range(6):
		var x := _cubic_bezier_axis(t, 0.32, 0.35)
		var derivative := _cubic_bezier_derivative(t, 0.32, 0.35)
		if absf(derivative) < 0.0001:
			break
		t = clampf(t - (x - progress) / derivative, 0.0, 1.0)
	return _cubic_bezier_axis(t, 0.72, 1.0)

func _cubic_bezier_axis(t: float, first: float, second: float) -> float:
	var inverse := 1.0 - t
	return 3.0 * inverse * inverse * t * first + 3.0 * inverse * t * t * second + t * t * t

func _cubic_bezier_derivative(t: float, first: float, second: float) -> float:
	var inverse := 1.0 - t
	return 3.0 * inverse * inverse * first + 6.0 * inverse * t * (second - first) + 3.0 * t * t * (1.0 - second)

func _apply_static_glass_button(button: Button) -> void:
	var style := UIStyles.glass_panel(67, false)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style.duplicate())
	button.add_theme_stylebox_override("pressed", style.duplicate())
	button.add_theme_stylebox_override("disabled", style.duplicate())
	UIStyles.apply_font(button, UIStyles.FONT_SEMIBOLD, int(button.get_theme_font_size("font_size")), UIStyles.TEXT)
	button.add_theme_color_override("font_hover_color", UIStyles.TEXT)
	button.add_theme_color_override("font_pressed_color", UIStyles.TEXT)
	button.add_theme_color_override("font_focus_color", UIStyles.TEXT)
	button.set_meta("hover_radius", 67)
	button.mouse_entered.connect(func() -> void: UIStyles._hover_highlight(button, true))
	button.mouse_exited.connect(func() -> void: UIStyles._hover_highlight(button, false))
	# 5.6: тумблер (строка вибро) молчал при нажатии — добавляем клик как у других кнопок.
	button.button_down.connect(func() -> void: AudioManagerScript.play_ui_tap())

# ---------------------------------------------------------------------------
# Appearance toggle
# ---------------------------------------------------------------------------

func build_theme_toggle(x: float, y: float, w: float) -> void:
	var toggle_h := 194.0
	var container := Panel.new()
	container.position = Vector2(x, y)
	container.size = Vector2(w, toggle_h)
	container.add_theme_stylebox_override("panel", UIStyles.appearance_toggle_bg())
	add_child(container)

	var seg_w := (w - 39.0) * 0.5
	_theme_segment(container, Locale.t("settings.light", "Light"), "light", 13.0, seg_w, toggle_h)
	_theme_segment(container, Locale.t("settings.dark", "Dark"), "dark", 13.0 + seg_w + 13.0, seg_w, toggle_h)

func _theme_segment(parent: Node, text: String, value: String, x: float, w: float, h: float) -> void:
	var active := current_theme == value
	var tab_size := Vector2(w, h - 26.0)
	var seg := Button.new()
	seg.text = text
	seg.position = Vector2(x, 13.0)
	seg.size = tab_size
	seg.focus_mode = Control.FOCUS_NONE
	seg.add_theme_font_size_override("font_size", 47)
	if active:
		var seg_text_color := UIStyles.ON_ACCENT
		if UIStyles.is_dark():
			var style := UIStyles.gradient_style(UIStyles.PRIMARY_TOP, UIStyles.PRIMARY_BOTTOM, 54, Vector2i(tab_size))
			seg.add_theme_stylebox_override("normal", style)
			seg.add_theme_stylebox_override("hover", style.duplicate())
			seg.add_theme_stylebox_override("pressed", style.duplicate())
		else:
			var white := StyleBoxFlat.new()
			white.bg_color = Color.WHITE
			UIStyles._set_radius(white, 54)
			seg.add_theme_stylebox_override("normal", white)
			seg.add_theme_stylebox_override("hover", white.duplicate())
			seg.add_theme_stylebox_override("pressed", white.duplicate())
			seg_text_color = UIStyles.TEXT
		UIStyles.apply_font(seg, UIStyles.FONT_BOLD, 47, seg_text_color)
		seg.add_theme_color_override("font_hover_color", seg_text_color)
		seg.add_theme_color_override("font_pressed_color", seg_text_color)
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0, 0, 0, 0)
		UIStyles._set_radius(flat, 54)
		seg.add_theme_stylebox_override("normal", flat)
		seg.add_theme_stylebox_override("hover", flat.duplicate())
		seg.add_theme_stylebox_override("pressed", flat.duplicate())
		UIStyles.apply_font(seg, UIStyles.FONT_SEMIBOLD, 47, UIStyles.MUTED)
		seg.add_theme_color_override("font_hover_color", UIStyles.MUTED)
		seg.add_theme_color_override("font_pressed_color", UIStyles.MUTED)
		seg.set_meta("hover_radius", 54)
		seg.mouse_entered.connect(func() -> void: UIStyles._hover_highlight(seg, true))
		seg.mouse_exited.connect(func() -> void: UIStyles._hover_highlight(seg, false))
	# 5.6: сегменты темы молчали при нажатии — клик как у других кнопок.
	seg.button_down.connect(func() -> void: AudioManagerScript.play_ui_tap())
	seg.pressed.connect(func(): theme_selected.emit(value))
	parent.add_child(seg)

# ---------------------------------------------------------------------------
# Language row + picker
# ---------------------------------------------------------------------------

func build_language_row(x: float, y: float, w: float) -> void:
	var row_h := 194.0
	var row := Button.new()
	row.position = Vector2(x, y)
	row.size = Vector2(w, row_h)
	row.add_theme_font_size_override("font_size", 50)
	UIStyles.menu_button(row)
	row.pressed.connect(show_language_popup)
	add_child(row)

	var label := Label.new()
	label.text = Locale.label_for(current_language)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(67, 0)
	label.size = Vector2(w - 160, row_h)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(label, UIStyles.FONT_BOLD, 50, UIStyles.TEXT)
	row.add_child(label)

	var caret: Texture2D = UIStyles.load_icon(UIStyles.CARET_RIGHT_PATH)
	if caret != null:
		UIStyles.icon(caret, row, Vector2(w - 100, row_h * 0.5 - 24), Vector2(48, 48), UIStyles.MUTED)
	else:
		var chev := Label.new()
		chev.text = "›"
		chev.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chev.position = Vector2(w - 80, 0)
		chev.size = Vector2(60, row_h)
		chev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chev.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_font(chev, UIStyles.FONT_BOLD, 40, UIStyles.MUTED)
		row.add_child(chev)

func build_language_popup() -> void:
	language_popup = _make_scrim_popup(func() -> void: hide_language_popup())
	var vp := Layout.viewport_size(self)
	var pw := PopupFactoryScript.popup_width(vp.x)
	var langs: Array = Locale.available()
	var opt_h := 188.0
	var opt_gap := 34.0
	var options_top := 290.0
	var cancel_y := options_top + float(langs.size()) * (opt_h + opt_gap) - opt_gap + 74.0
	var ph := cancel_y + PopupFactoryScript.POPUP_SECONDARY_H + 80.0
	var panel := Panel.new()
	panel.name = "PopupPanel"
	panel.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	panel.size = Vector2(pw, ph)
	PopupFactoryScript.apply_panel_glass(panel)
	PopupFactoryScript.register_sheet_panel(panel)
	language_popup_panel = panel
	language_popup.add_child(panel)

	var globe: Texture2D = UIStyles.load_icon(UIStyles.GLOBE_PATH)
	PopupFactoryScript.badge(panel, pw, UIStyles.PRIMARY_TOP, UIStyles.PRIMARY_BOTTOM, globe if globe != null else UIStyles.ICON_INFO, 94.0)
	PopupFactoryScript.title(panel, pw, Locale.t("settings.language", "LANGUAGE"))

	var ry := options_top
	for entry in langs:
		var code := str(entry["code"])
		var selected := code == current_language
		var opt := Button.new()
		opt.position = Vector2(PopupFactoryScript.POPUP_PAD, ry)
		opt.size = Vector2(pw - PopupFactoryScript.POPUP_PAD * 2.0, opt_h)
		var style := _language_row_style(selected)
		opt.add_theme_stylebox_override("normal", style)
		opt.add_theme_stylebox_override("hover", style.duplicate())
		opt.add_theme_stylebox_override("pressed", style.duplicate())
		UIStyles.add_press_animation(opt, 60)
		opt.pressed.connect(func():
			language_changed.emit(code)
		)
		panel.add_child(opt)

		var label := Label.new()
		label.text = str(entry["label"])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.position = Vector2(67, 0)
		label.size = Vector2(opt.size.x - 200, opt_h)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_font(label, UIStyles.FONT_BOLD, 50, UIStyles.TEXT)
		opt.add_child(label)

		if selected:
			var check_color: Color = Color("#C4B5FD") if UIStyles.is_dark() else UIStyles.PURPLE_DARK
			UIStyles.icon(UIStyles.ICON_CHECK, opt, Vector2(opt.size.x - 127, opt_h * 0.5 - 30), Vector2(60, 60), check_color)
		ry += opt_h + opt_gap

	var cancel := PopupFactoryScript.secondary_button(Locale.t("common.cancel", "Cancel"), pw, cancel_y)
	cancel.pressed.connect(func(): hide_language_popup())
	panel.add_child(cancel)

func _language_row_style(selected: bool) -> StyleBoxTexture:
	var bg: Color
	var border: Color
	if selected:
		if UIStyles.is_dark():
			bg = Color(0.655, 0.545, 0.980, 0.16)
			border = Color(0.769, 0.710, 0.992, 0.40)
		else:
			bg = Color(0.545, 0.361, 0.965, 0.10)
			border = Color(0.357, 0.196, 0.768, 0.30)
	else:
		if UIStyles.is_dark():
			bg = Color(1, 1, 1, 0.05)
			border = Color(1, 1, 1, 0.10)
		else:
			bg = Color(0.106, 0.071, 0.2, 0.04)
			border = Color(0.106, 0.071, 0.2, 0.08)
	return UIStyles.smooth_panel(bg, border, 60, UIStyles.PANEL_BORDER_WIDTH)

func is_language_popup_open() -> bool:
	return is_instance_valid(language_popup) and language_popup.visible

func show_language_popup(immediate: bool = false) -> void:
	if language_popup != null and language_popup_panel != null:
		var overlay := PopupFactoryScript.find_scrim(language_popup)
		if immediate:
			PopupFactoryScript.show_sheet_immediate(language_popup, language_popup_panel, overlay)
		else:
			PopupFactoryScript.show_sheet(language_popup, language_popup_panel, overlay)

func hide_language_popup(after_hidden: Callable = Callable()) -> void:
	if language_popup != null and language_popup_panel != null:
		PopupFactoryScript.hide_sheet(language_popup, language_popup_panel, PopupFactoryScript.find_scrim(language_popup), after_hidden)
	else:
		if language_popup != null:
			language_popup.visible = false
		if after_hidden.is_valid():
			after_hidden.call()

# ---------------------------------------------------------------------------
# Reset popup
# ---------------------------------------------------------------------------

func _make_scrim_popup(close_callback: Callable = Callable()) -> Control:
	var popup := Control.new()
	# Explicit size: anchor presets resolve against this screen's own rect,
	# which is not full-rect sized, so an anchored overlay collapses to zero.
	popup.position = Vector2.ZERO
	popup.size = Layout.viewport_size(self)
	popup.visible = false
	popup.z_index = 100
	add_child(popup)
	var overlay := PopupFactoryScript.scrim(popup.size, close_callback)
	popup.add_child(overlay)
	return popup

func build_reset_popup() -> void:
	reset_popup = _make_scrim_popup(func() -> void: hide_reset_popup())
	var vp := Layout.viewport_size(self)
	var pw := PopupFactoryScript.popup_width(vp.x)
	var ph := 983.0
	var panel := Panel.new()
	panel.name = "PopupPanel"
	panel.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	panel.size = Vector2(pw, ph)
	PopupFactoryScript.apply_panel_glass(panel)
	PopupFactoryScript.register_sheet_panel(panel)
	reset_popup_panel = panel
	reset_popup.add_child(panel)

	var warn: Texture2D = UIStyles.load_icon(UIStyles.WARNING_CIRCLE_PATH)
	PopupFactoryScript.badge(panel, pw, Color("#FF9B96"), Color("#E0453F"), warn if warn != null else UIStyles.ICON_INFO, 94.0)
	PopupFactoryScript.title(panel, pw, Locale.t("settings.reset.title", "Reset Progress"))
	PopupFactoryScript.body(panel, pw, Locale.t("settings.reset.body", "This will erase your progress, stars, lumens and unlocked levels."), 268.0)

	var confirm_btn := PopupFactoryScript.primary_button(Locale.t("settings.reset.confirm", "Reset Progress"), pw, 500.0, true)
	confirm_btn.pressed.connect(func():
		hide_reset_popup(func() -> void:
			reset_progress_requested.emit()
		)
	)
	panel.add_child(confirm_btn)

	var cancel_btn := PopupFactoryScript.secondary_button(Locale.t("common.cancel", "Cancel"), pw, 735.0)
	cancel_btn.pressed.connect(func(): hide_reset_popup())
	panel.add_child(cancel_btn)

func is_reset_popup_open() -> bool:
	return is_instance_valid(reset_popup) and reset_popup.visible

func show_reset_popup(immediate: bool = false) -> void:
	if reset_popup != null and reset_popup_panel != null:
		var overlay := PopupFactoryScript.find_scrim(reset_popup)
		if immediate:
			PopupFactoryScript.show_sheet_immediate(reset_popup, reset_popup_panel, overlay)
		else:
			AudioManagerScript.play_reset_progress_haptic()
			PopupFactoryScript.show_sheet(reset_popup, reset_popup_panel, overlay)

func hide_reset_popup(after_hidden: Callable = Callable()) -> void:
	if reset_popup != null and reset_popup_panel != null:
		PopupFactoryScript.hide_sheet(reset_popup, reset_popup_panel, PopupFactoryScript.find_scrim(reset_popup), after_hidden)
	else:
		if reset_popup != null:
			reset_popup.visible = false
		if after_hidden.is_valid():
			after_hidden.call()

# ---------------------------------------------------------------------------
# Sliders
# ---------------------------------------------------------------------------

func add_slider_block(parent: Control, text: String, _icon_texture: Texture2D, value: int, y: float, key: String) -> void:
	var pad := 67.0
	var inner_w: float = parent.size.x - pad * 2.0

	var label := Label.new()
	label.text = text
	label.position = Vector2(pad, y)
	label.size = Vector2(inner_w - 200, 62)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(label, UIStyles.FONT_BOLD, 50, UIStyles.TEXT)
	parent.add_child(label)

	var value_lbl := Label.new()
	value_lbl.text = "%d%%" % value
	value_lbl.position = Vector2(parent.size.x - pad - 200, y)
	value_lbl.size = Vector2(200, 62)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(value_lbl, UIStyles.FONT_SEMIBOLD, 50, UIStyles.MUTED)
	parent.add_child(value_lbl)

	var track_x := pad
	var track_width := inner_w
	var track_y := y + 102.0

	var track_bg := Panel.new()
	track_bg.position = Vector2(track_x, track_y)
	track_bg.size = Vector2(track_width, 20)
	track_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track_bg_color := Color(1, 1, 1, 0.10) if UIStyles.is_dark() else Color(UIStyles.PURPLE.r, UIStyles.PURPLE.g, UIStyles.PURPLE.b, 0.15)
	track_bg.add_theme_stylebox_override("panel", slider_track_style(track_bg_color, 10))
	parent.add_child(track_bg)

	var track_fill := Panel.new()
	track_fill.position = Vector2(track_x, track_y)
	track_fill.size = Vector2(track_width * float(value) / 100.0, 20)
	track_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track_fill.add_theme_stylebox_override("panel", slider_gradient_track_style(Vector2i(int(track_width), 20), 10))
	parent.add_child(track_fill)

	var knob := Panel.new()
	knob.size = Vector2(80, 80)
	knob.position = Vector2(track_x + track_fill.size.x - knob.size.x * 0.5, track_y - 30)
	knob.pivot_offset = knob.size * 0.5
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.add_theme_stylebox_override("panel", slider_knob_style())
	parent.add_child(knob)
	var knob_hover := slider_knob_hover()
	knob.add_child(knob_hover)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = value
	slider.position = Vector2(track_x - 10, track_y - 30)
	slider.size = Vector2(track_width + 20, 68)
	slider.modulate = Color(1, 1, 1, 0)
	parent.add_child(slider)
	slider.value_changed.connect(_on_slider_value_changed.bind(value_lbl, track_fill, knob, track_width, key))
	slider.gui_input.connect(_on_slider_input.bind(knob))
	UIStyles.attach_hover_tint(slider, knob_hover)
	slider.drag_started.connect(func() -> void: _set_slider_press_state(knob, true, true))
	slider.drag_ended.connect(func(_value_changed: bool) -> void: _set_slider_press_state(knob, false, false))

func slider_track_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	UIStyles._set_radius(style, radius)
	return style

func slider_gradient_track_style(texture_size: Vector2i, radius: int) -> StyleBoxTexture:
	var safe_size := Vector2i(maxi(1, texture_size.x), maxi(1, texture_size.y))
	return UIStyles.gradient_style(UIStyles.PRIMARY_TOP, UIStyles.PRIMARY_BOTTOM, radius, safe_size)

func slider_knob_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	UIStyles._set_radius(style, 40)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style

func slider_knob_hover() -> Panel:
	var overlay := Panel.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(80, 80)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.modulate.a = 0.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1) if UIStyles.is_dark() else Color(0, 0, 0)
	UIStyles._set_radius(style, 40)
	overlay.add_theme_stylebox_override("panel", style)
	return overlay

func _on_slider_input(event: InputEvent, knob: Panel) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button != null and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		_set_slider_press_state(knob, mouse_button.pressed, false)
		return

	var motion := event as InputEventMouseMotion
	if motion != null and bool(knob.get_meta("slider_pressed", false)):
		knob.set_meta("slider_dragging", true)

func _set_slider_press_state(knob: Panel, pressed: bool, dragging: bool) -> void:
	if knob == null or not is_instance_valid(knob):
		return
	var was_pressed := bool(knob.get_meta("slider_pressed", false))
	knob.set_meta("slider_pressed", pressed)
	knob.set_meta("slider_dragging", dragging if pressed else false)
	if was_pressed != pressed:
		UIStyles.press_hold(knob, pressed)

func _on_slider_value_changed(value: float, value_label: Label, fill: Panel, knob: Panel, track_width: float, key: String) -> void:
	value_label.text = "%d%%" % int(round(value))
	var fill_width: float = track_width * clamp(value, 0.0, 100.0) / 100.0
	animate_slider_visual(fill, knob, fill_width)
	if key == "music":
		music_volume = int(round(value))
	else:
		sound_volume = int(round(value))
	volumes_changed.emit(music_volume, sound_volume)

func animate_slider_visual(fill: Panel, knob: Panel, fill_width: float) -> void:
	var duration := 0.07 if bool(knob.get_meta("slider_dragging", false)) else 0.16
	var target_fill_size := Vector2(fill_width, fill.size.y)
	var target_knob_x := fill.position.x + fill_width - knob.size.x * 0.5
	if knob.has_meta("slider_visual_tween"):
		var current_tween := knob.get_meta("slider_visual_tween") as Tween
		if current_tween != null and current_tween.is_valid():
			current_tween.kill()
	var tween := knob.create_tween()
	knob.set_meta("slider_visual_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(fill, "size", target_fill_size, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(knob, "position:x", target_knob_x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
