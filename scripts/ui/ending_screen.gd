extends Control


func _ready() -> void:
	GameTheme.mount(self)
	_build()


func _build() -> void:
	var ending: Dictionary = GameManager.ending
	UiFactory.backdrop(self, "throne", 0.8)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var column := UiFactory.vbox(10)
	margin.add_child(column)
	column.add_child(UiFactory.muted(str(ending.get("headline", "YOUR CLAIM ENDS • NEZREL REMEMBERS" if bool(ending.get("defeat", false)) else "THE CROWN IS YOURS • NEZREL REMEMBERS"))))
	column.add_child(UiFactory.title(str(ending.get("title", "The Crown")), 32))
	column.add_child(UiFactory.label(str(ending.get("subtitle", "")), 16, GameTheme.GOLD))
	var spread := UiFactory.hbox(28)
	column.add_child(UiFactory.scroll(spread))
	if GameManager.state != null:
		var sidebar := UiFactory.vbox(8)
		sidebar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		sidebar.custom_minimum_size.x = 180
		spread.add_child(sidebar)
		sidebar.add_child(UiFactory.portrait(GameManager.state.claimant_id, 232, 180))
		sidebar.add_child(UiFactory.title(str(GameManager.db.claimants[GameManager.state.claimant_id].get("short", "")), 22))
		sidebar.add_child(UiFactory.muted("%s\n%s" % [ending.get("legacy", ""), ending.get("kingdom", "")]))
	var body := UiFactory.vbox(12)
	spread.add_child(body)
	for paragraph in ending.get("paragraphs", []):
		body.add_child(UiFactory.label(str(paragraph), 17))
		body.add_child(UiFactory.rule())
	var row := UiFactory.flow(8)
	column.add_child(row)
	var menu := UiFactory.button("Main Menu")
	menu.pressed.connect(func(): GameManager.to_menu())
	row.add_child(menu)
	var chronicle := UiFactory.button("Chronicle of Nezrel")
	chronicle.pressed.connect(func(): GameManager.open_chronicle())
	row.add_child(chronicle)
	var again := UiFactory.button("Play Another Claimant")
	again.pressed.connect(func(): GameManager.to_select())
	row.add_child(again)
