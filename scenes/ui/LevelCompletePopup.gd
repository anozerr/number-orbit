class_name LevelCompletePopup
extends Control

signal next_pressed
signal levels_pressed

var panel: Panel
var title_label: Label
var stars_label: Label
var moves_label: Label
var next_button: Button

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
	panel.position = Vector2(120, 570)
	panel.size = Vector2(840, 760)
	panel.add_theme_stylebox_override("panel", UIStyles.soft_panel(Color.WHITE, 36))
	add_child(panel)

	var badge := Panel.new()
	badge.position = Vector2(365, -45)
	badge.size = Vector2(110, 110)
	badge.add_theme_stylebox_override("panel", UIStyles.card(Color("#51C46B"), Color.WHITE, 55))
	panel.add_child(badge)
	UIStyles.icon(UIStyles.ICON_CHECK, badge, Vector2(28, 28), Vector2(54, 54), Color.WHITE)

	title_label = Label.new()
	title_label.position = Vector2(0, 105)
	title_label.size = Vector2(840, 110)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(title_label, UIStyles.FONT_BOLD, 42, UIStyles.TEXT)
	panel.add_child(title_label)

	stars_label = Label.new()
	stars_label.position = Vector2(0, 255)
	stars_label.size = Vector2(840, 90)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(stars_label)

	moves_label = Label.new()
	moves_label.position = Vector2(0, 370)
	moves_label.size = Vector2(840, 60)
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_font(moves_label, UIStyles.FONT_MEDIUM, 28, UIStyles.TEXT)
	panel.add_child(moves_label)

	next_button = Button.new()
	next_button.position = Vector2(130, 520)
	next_button.size = Vector2(580, 100)
	next_button.add_theme_font_size_override("font_size", 34)
	UIStyles.primary_button(next_button)
	next_button.pressed.connect(func(): next_pressed.emit())
	panel.add_child(next_button)

	var levels_btn := Button.new()
	levels_btn.text = "Back to Levels"
	levels_btn.position = Vector2(130, 650)
	levels_btn.size = Vector2(580, 80)
	levels_btn.add_theme_font_size_override("font_size", 28)
	UIStyles.menu_button(levels_btn)
	levels_btn.pressed.connect(func(): levels_pressed.emit())
	panel.add_child(levels_btn)

func show_result(level_number: int, stars: int, moves: int, has_next: bool) -> void:
	title_label.text = "LEVEL %d\nCOMPLETE!" % level_number
	draw_star_row(stars)
	moves_label.text = "Moves: %d" % moves
	next_button.text = "Next Level"
	next_button.visible = has_next
	visible = true

func hide_popup() -> void:
	visible = false

func draw_star_row(count: int) -> void:
	stars_label.text = ""
	for child in stars_label.get_children():
		child.queue_free()
	for i in range(3):
		var texture: Texture2D = UIStyles.ICON_STAR if i < count else UIStyles.ICON_STAR_EMPTY
		var color: Color = UIStyles.GOLD if i < count else Color("#DADDE4")
		UIStyles.icon(texture, stars_label, Vector2(245 + i * 116, 6), Vector2(78, 78), color)
