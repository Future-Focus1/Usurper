class_name GameTheme
extends RefCounted

const INK := Color("10100f")
const PANEL := Color("1c1c19")
const PANEL_RAISED := Color("292923")
const PANEL_SUNKEN := Color("141513")
const LINE := Color("716044")
const LINE_DIM := Color("393a31")
const GOLD := Color("dfbf7d")
const CREAM := Color("eee5d3")
const MUTED := Color("b4b2a3")
const GOOD := Color("9bc7a4")
const BAD := Color("e19b8e")
const CLAIM := Color("dfbf7d")
const COLD := Color("c7a3aa")

static var theme: Theme
static var display_font: Font
static var body_font: Font


static func get_theme() -> Theme:
	if theme != null:
		return theme
	theme = Theme.new()
	_load_fonts()
	if body_font != null:
		theme.default_font = body_font
	theme.default_font_size = 16

	var panel := _box(Color(PANEL, 0.96), LINE_DIM, 1, 3, 16)
	var panel_flat := _box(PANEL_SUNKEN, LINE_DIM, 1, 2, 10)
	var button := _box(Color("26271f"), LINE, 1, 2, 14)
	var hover := _box(Color("39392b"), GOLD, 1, 2, 14)
	var pressed := _box(Color("1c1d17"), GOLD, 1, 2, 14)
	var disabled := _box(Color("1a1b18"), LINE_DIM, 1, 2, 14)

	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("normal", "Button", button)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", hover)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", Color("9b9b8b"))
	theme.set_font_size("font_size", "Button", 15)

	theme.set_color("font_color", "Label", CREAM)
	theme.set_font_size("font_size", "Label", 16)
	theme.set_color("default_color", "RichTextLabel", CREAM)
	theme.set_font_size("normal_font_size", "RichTextLabel", 17)

	var line_normal := _box(PANEL_SUNKEN, LINE, 1, 2, 8)
	var line_focus := _box(PANEL_SUNKEN, GOLD, 1, 2, 8)
	theme.set_stylebox("normal", "LineEdit", line_normal)
	theme.set_stylebox("focus", "LineEdit", line_focus)
	theme.set_color("font_color", "LineEdit", CREAM)
	theme.set_color("caret_color", "LineEdit", GOLD)
	theme.set_font_size("font_size", "LineEdit", 16)

	theme.set_stylebox("normal", "OptionButton", button)
	theme.set_stylebox("hover", "OptionButton", hover)
	theme.set_stylebox("pressed", "OptionButton", pressed)
	theme.set_stylebox("disabled", "OptionButton", disabled)
	theme.set_color("font_color", "OptionButton", CREAM)
	theme.set_color("font_disabled_color", "OptionButton", Color("6d7d8c"))
	theme.set_font_size("font_size", "OptionButton", 15)

	var bg := _box(PANEL_SUNKEN, LINE_DIM, 1, 2, 2)
	var fill := _box(CLAIM, CLAIM, 0, 2, 2)
	theme.set_stylebox("background", "ProgressBar", bg)
	theme.set_stylebox("fill", "ProgressBar", fill)
	theme.set_color("font_color", "ProgressBar", CREAM)

	theme.set_stylebox("slider", "HSlider", bg)
	theme.set_stylebox("grabber_area", "HSlider", fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
	theme.set_icon("grabber", "HSlider", _dot(GOLD))
	theme.set_icon("grabber_highlight", "HSlider", _dot(CREAM))
	theme.set_constant("grabber_offset", "HSlider", 0)

	theme.set_color("font_color", "CheckButton", CREAM)
	theme.set_stylebox("panel", "TooltipPanel", panel_flat)
	theme.set_color("font_color", "TooltipLabel", CREAM)
	return theme


static func mount(root: Control) -> void:
	root.theme = get_theme()
	root.clip_contents = true


static func _load_fonts() -> void:
	if ResourceLoader.exists("res://assets/fonts/SourceSans3-Regular.ttf"):
		body_font = load("res://assets/fonts/SourceSans3-Regular.ttf")
	if ResourceLoader.exists("res://assets/fonts/Cinzel-Bold.ttf"):
		display_font = load("res://assets/fonts/Cinzel-Bold.ttf")
	elif ResourceLoader.exists("res://assets/fonts/Cinzel-Regular.ttf"):
		display_font = load("res://assets/fonts/Cinzel-Regular.ttf")


static func _box(fill: Color, border: Color, border_w: int, radius: int, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_w)
	box.set_corner_radius_all(radius)
	box.content_margin_left = margin
	box.content_margin_right = margin
	box.content_margin_top = mini(margin, 10)
	box.content_margin_bottom = mini(margin, 10)
	return box


static func _dot(color: Color) -> ImageTexture:
	var image := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in 14:
		for x in 14:
			var d := Vector2(x - 6.5, y - 6.5).length()
			if d <= 6.0:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
