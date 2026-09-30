extends Control


func _ready() -> void:
	GameTheme.mount(self)
	_build()


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = GameTheme.INK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var column := UiFactory.vbox(8)
	margin.add_child(column)
	var header := UiFactory.hbox()
	header.add_child(UiFactory.title("Chronicle of Nezrel", 26))
	header.add_child(UiFactory.filler())
	var back := UiFactory.chip("Back")
	back.pressed.connect(func(): GameManager.close_extra())
	header.add_child(back)
	column.add_child(header)
	var chronicle: Dictionary = GameManager.db.chronicle
	var total := 0
	var found := 0
	for category in chronicle.get("categories", []):
		for entry in category.get("entries", []):
			total += 1
			if MetaProgress.has(str(entry.get("id", ""))):
				found += 1
	column.add_child(UiFactory.muted("%d of %d discoveries. What you learn here does not enter the next claimant's head. It only opens doors the world can justify." % [found, total]))
	var completed := MetaProgress.completed_claimants()
	if completed.is_empty():
		column.add_child(UiFactory.muted("No campaign has been finished on this machine."))
	else:
		column.add_child(UiFactory.muted("Campaigns finished: " + ", ".join(completed)))
	var list := UiFactory.vbox(10)
	column.add_child(UiFactory.scroll(list))
	for category in chronicle.get("categories", []):
		var entries: Array = category.get("entries", [])
		var have := 0
		for entry in entries:
			if MetaProgress.has(str(entry.get("id", ""))):
				have += 1
		list.add_child(UiFactory.title("%s  —  %d / %d" % [category.get("title", ""), have, entries.size()], 22))
		for entry in entries:
			var known := MetaProgress.has(str(entry.get("id", "")))
			if known:
				list.add_child(UiFactory.label(str(entry.get("title", "")), 16, GameTheme.GOLD))
				list.add_child(UiFactory.label(str(entry.get("text", "")), 15))
			else:
				list.add_child(UiFactory.muted("Undiscovered"))
		list.add_child(UiFactory.rule())
