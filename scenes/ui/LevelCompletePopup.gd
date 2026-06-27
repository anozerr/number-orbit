class_name LevelCompletePopup
extends Control

signal next_pressed
signal levels_pressed

var panel: Panel
var title_label: Label
var stars_label: Label
var moves_label: Label
var reward_label: Label
var next_button: Button
var levels_button: Button

func _ready() -> void:
	size = Vector2(1080, 1920)
	visible = false
	build()

func build() -> void:
	for child in get_children():
		child.queue_free()

	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1080, 1920)
	overlay.color = Color(0.05, 0.06, 0.10, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	panel = Panel.new()
	panel.position = Vector2(90, 560)
	panel.size = Vector2(900, 790)
	panel.add_theme_stylebox_override("panel", UIStyles.soft_panel(Color.WHITE, 36))
	add_child(panel)

	var badge := Panel.new()
	badge.position = Vector2(395, -45)
	badge.size = Vector2(110, 110)
	badge.add_theme_stylebox_override("panel", UIStyles.card(Color("#51C46B"), Color.WHITE, 55))
	panel.add_child(badge)
	UIStyles.icon(UIStyles.ICON_CHECK, badge, Vector2(28, 28), Vector2(54, 54), Color.WHITE)

	title_label = Label.new()
	title_label.position = Vector2(0, 105)
	title_label.size = Vector2(900, 110)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title_label, UIStyles.FONT_BOLD, 42, UIStyles.TEXT)
	panel.add_child(title_label)

	stars_label = Label.new()
	stars_label.position = Vector2(0, 255)
	stars_label.size = Vector2(900, 90)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(stars_label)

	moves_label = Label.new()
	moves_label.position = Vector2(0, 370)
	moves_label.size = Vector2(900, 60)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(moves_label, UIStyles.FONT_MEDIUM, 28, UIStyles.TEXT)
	panel.add_child(moves_label)

	reward_label = Label.new()
	reward_label.position = Vector2(0, 425)
	reward_label.size = Vector2(900, 50)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_font(reward_label, UIStyles.FONT_SEMIBOLD, 24, UIStyles.MUTED)
	panel.add_child(reward_label)

	next_button = Button.new()
	next_button.position = Vector2(145, 525)
	next_button.size = Vector2(610, 100)
	next_button.add_theme_font_size_override("font_size", 34)
	UIStyles.primary_button(next_button)
	next_button.pressed.connect(func(): next_pressed.emit())
	panel.add_child(next_button)

	levels_button = Button.new()
	levels_button.text = "Back to Levels"
	levels_button.position = Vector2(145, 665)
	levels_button.size = Vector2(610, 82)
	levels_button.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(levels_button)
	levels_button.pressed.connect(func(): levels_pressed.emit())
	panel.add_child(levels_button)

func show_result(title_text: String, stars: int, moves: int, has_next: bool, reward: int = 0, hint_points: int = 0, show_details: bool = true) -> void:
	title_label.text = "%s\nCOMPLETE!" % title_text
	stars_label.visible = show_details
	moves_label.visible = true
	reward_label.visible = true
	if show_details:
		title_label.position = Vector2(0, 105)
		title_label.size = Vector2(900, 110)
		moves_label.position = Vector2(0, 370)
		reward_label.position = Vector2(0, 425)
		reward_label.size = Vector2(900, 72)
		next_button.position = Vector2(145, 525)
		next_button.size = Vector2(610, 100)
		levels_button.position = Vector2(145, 665)
		levels_button.size = Vector2(610, 82)
		draw_star_row(stars)
		moves_label.text = "Moves: %d" % moves
		if reward > 0:
			reward_label.text = "New reward: +%d bulbs\nBalance: %d" % [reward, hint_points]
		else:
			reward_label.text = "Best reward already claimed\nBalance: %d" % hint_points
	else:
		title_label.position = Vector2(0, 95)
		title_label.size = Vector2(900, 118)
		draw_star_row(0)
		moves_label.position = Vector2(0, 275)
		moves_label.text = "Moves: %d" % moves
		reward_label.position = Vector2(90, 340)
		reward_label.size = Vector2(720, 76)
		reward_label.text = "Tutorials teach the operators.\nNo bulb reward is given here."
		next_button.position = Vector2(145, 525)
		next_button.size = Vector2(610, 100)
		levels_button.position = Vector2(145, 665)
		levels_button.size = Vector2(610, 82)
	next_button.text = "Next Level" if show_details else "Next Tutorial"
	levels_button.text = "Back to Levels" if show_details else "Back to All Levels"
	next_button.visible = has_next
	visible = true
	animate_open()

func animate_open() -> void:
	panel.scale = Vector2(0.94, 0.94)
	panel.pivot_offset = panel.size * 0.5
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_popup() -> void:
	visible = false

func draw_star_row(count: int) -> void:
	stars_label.text = ""
	for child in stars_label.get_children():
		child.queue_free()
	for i in range(3):
		var texture: Texture2D = UIStyles.ICON_STAR if i < count else UIStyles.ICON_STAR_EMPTY
		var color: Color = UIStyles.GOLD if i < count else Color("#DADDE4")
		UIStyles.icon(texture, stars_label, Vector2(275 + i * 116, 6), Vector2(78, 78), color)
