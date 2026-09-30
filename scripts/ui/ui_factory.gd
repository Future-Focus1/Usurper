class_name UiFactory
extends RefCounted


static func clear(node: Node) -> void:
	while node.get_child_count() > 0:
		var child := node.get_child(0)
		node.remove_child(child)
		child.queue_free()


static func label(text: String, size := 16, color: Color = Color(0, 0, 0, 0)) -> Label:
	var node := Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size", size)
	if color.a > 0.0:
		node.add_theme_color_override("font_color", color)
	return node


static func single(text: String, size := 16, color: Color = Color(0, 0, 0, 0)) -> Label:
	var node := label(text, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.clip_text = true
	return node


static func title(text: String, size := 28) -> Label:
	var node := label(text, size, GameTheme.GOLD)
	if GameTheme.display_font == null:
		GameTheme.get_theme()
	if GameTheme.display_font != null:
		node.add_theme_font_override("font", GameTheme.display_font)
	return node


static func support_color(word: String) -> Color:
	match word:
		"Devoted", "Loyal", "Beloved":
			return GameTheme.CLAIM
		"Supportive", "Warm":
			return GameTheme.GOOD
		"Opposed", "Cold":
			return GameTheme.COLD
		"Hostile", "Feared", "Dreaded", "Tyrant's Shadow":
			return GameTheme.BAD
		_:
			return GameTheme.MUTED


static func muted(text: String, size := 14) -> Label:
	return label(text, size, GameTheme.MUTED)


static func button(text: String) -> Button:
	var node := Button.new()
	node.text = text
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func chip(text: String) -> Button:
	var node := button(text)
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.clip_text = false
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	node.custom_minimum_size = Vector2(_text_width(text, 15) + 24.0, 0)
	return node


static func _text_width(text: String, size: int) -> float:
	if GameTheme.body_font == null:
		GameTheme.get_theme()
	if GameTheme.body_font == null:
		return float(text.length() * size)
	return GameTheme.body_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func flow(sep := 8) -> HFlowContainer:
	var node := HFlowContainer.new()
	node.add_theme_constant_override("h_separation", sep)
	node.add_theme_constant_override("v_separation", sep)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func vbox(sep := 8) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", sep)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func hbox(sep := 8) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", sep)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func panel() -> PanelContainer:
	var node := PanelContainer.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func scroll(child: Control) -> ScrollContainer:
	var node := ScrollContainer.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_child(child)
	return node


static func rule() -> ColorRect:
	var node := ColorRect.new()
	node.color = GameTheme.LINE_DIM
	node.custom_minimum_size = Vector2(0, 1)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func expand(node: Control) -> Control:
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


static func filler() -> Control:
	var node := Control.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func rich(text: String, size := 17) -> RichTextLabel:
	var node := RichTextLabel.new()
	node.bbcode_enabled = true
	node.fit_content = true
	node.scroll_active = false
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("normal_font_size", size)
	node.add_theme_color_override("default_color", GameTheme.CREAM)
	node.text = text
	return node


static func artwork(id: String, height: float, width: float = 0) -> TextureRect:
	var node := TextureRect.new()
	node.texture = ArtLibrary.texture(id)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.custom_minimum_size = Vector2(width, height)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.clip_contents = true
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func backdrop(root: Control, id := "throne", darkness := 0.5) -> void:
	var art := artwork(id, 0)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(art)
	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.04, 0.035, darkness)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)


static func primary(text: String) -> Button:
	var node := button(text)
	node.custom_minimum_size.y = 44
	var box := StyleBoxFlat.new()
	box.bg_color = Color("54462d")
	box.border_color = GameTheme.GOLD
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	node.add_theme_stylebox_override("normal", box)
	node.add_theme_color_override("font_color", GameTheme.CREAM)
	return node


static func portrait(id: String, height: float, width: float = 0) -> PortraitFrame:
	var node := PortraitFrame.new()
	node.texture = ArtLibrary.texture(id)
	node.custom_minimum_size = Vector2(width, height)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node
