extends Control


func _ready() -> void:
	GameTheme.mount(self)
	_build()


func _build() -> void:
	UiFactory.backdrop(self, "throne", 0.78)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var column := UiFactory.vbox(10)
	margin.add_child(column)
	var header := UiFactory.hbox(12)
	column.add_child(header)
	header.add_child(UiFactory.title("Choose a Claimant", 32))
	header.add_child(UiFactory.filler())
	var back := UiFactory.chip("Back")
	back.pressed.connect(func(): GameManager.to_menu())
	header.add_child(back)
	column.add_child(UiFactory.muted("Experience. Honour. Blood. Steel. Four answers to what makes a ruler rightful."))
	var row := UiFactory.flow(12)
	column.add_child(UiFactory.scroll(row))
	for id in GameManager.db.claimant_order:
		row.add_child(_card(GameManager.db.claimants[id]))


func _card(claimant: Dictionary) -> Control:
	var panel := UiFactory.panel()
	panel.custom_minimum_size = Vector2(290, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := UiFactory.vbox(6)
	panel.add_child(column)
	var band := ColorRect.new()
	band.custom_minimum_size = Vector2(0, 8)
	band.color = Color(str(claimant.get("color", "#5d7c99")))
	column.add_child(band)
	var portrait := UiFactory.portrait(str(claimant.get("id", "")), 178)
	column.add_child(portrait)
	column.add_child(UiFactory.title(str(claimant.get("name", "")), 22))
	column.add_child(UiFactory.muted("Age %d  ·  %s" % [int(claimant.get("age", 0)), str(claimant.get("difficulty", ""))]))
	column.add_child(UiFactory.label(str(claimant.get("summary", "")), 15))
	column.add_child(UiFactory.muted(str(claimant.get("playstyle", ""))))
	var start: Dictionary = claimant.get("start", {})
	column.add_child(UiFactory.label("Gold %s   Rations %d   Forces %s   Claim %d" % [
		Balance.comma(int(start.get("gold", 0))),
		int(start.get("rations", 0)),
		Balance.comma(int(start.get("forces", 0))),
		int(start.get("claim", 0)),
	], 14, GameTheme.GOLD))
	for strength in claimant.get("strengths", []):
		column.add_child(UiFactory.muted("· " + str(strength)))
	column.add_child(UiFactory.filler())
	var begin := UiFactory.primary("Begin as %s" % str(claimant.get("short", "them")))
	begin.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var claimant_id := str(claimant.get("id", ""))
	begin.pressed.connect(func():
		AudioManager.click()
		GameManager.start_new(claimant_id)
	)
	column.add_child(begin)
	return panel
