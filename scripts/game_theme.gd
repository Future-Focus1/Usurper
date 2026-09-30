class_name GameTheme
extends RefCounted

const INK := Color("101820")
const PANEL := Color("1a2733")
const PANEL_RAISED := Color("243646")
const PANEL_SUNKEN := Color("0e161e")
const LINE := Color("6d8eab")
const LINE_DIM := Color("314556")
const GOLD := Color("d5e6f2")
const CREAM := Color("e7eef5")
const MUTED := Color("93a4b5")
const GOOD := Color("7dcea0")
const BAD := Color("e07a86")
const CLAIM := Color("7eb6d9")
const COLD := Color("d4a3b0")

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

	var panel := _box(PANEL, LINE, 2, 4, 12)
	var panel_flat := _box(PANEL_SUNKEN, LINE_DIM, 1, 2, 10)
	var button := _box(Color("1e3142"), LINE, 1, 3, 8)
	var hover := _box(Color("2c4a63"), GOLD, 1, 3, 8)
	var pressed := _box(Color("14202b"), GOLD, 1, 3, 8)
	var disabled := _box(Color("172029"), LINE_DIM, 1, 3, 8)

	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("normal", "Button", button)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", hover)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", Color("6d7d8c"))
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
	box.content_margin_top = 6
	box.content_margin_bottom = 6
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
