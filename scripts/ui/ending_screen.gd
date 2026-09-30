extends Control


func _ready() -> void:
	GameTheme.mount(self)
	_build()


func _build() -> void:
	var ending: Dictionary = GameManager.ending
	var backdrop := ColorRect.new()
	backdrop.color = GameTheme.INK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var column := UiFactory.vbox(10)
	margin.add_child(column)
	column.add_child(UiFactory.muted("THE CHRONICLE CLOSES THIS CAMPAIGN"))
	column.add_child(UiFactory.title(str(ending.get("title", "The Crown")), 32))
	column.add_child(UiFactory.label(str(ending.get("subtitle", "")), 16, GameTheme.GOLD))
	var body := UiFactory.vbox(12)
	column.add_child(UiFactory.scroll(body))
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
