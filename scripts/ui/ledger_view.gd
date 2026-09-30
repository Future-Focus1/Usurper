class_name LedgerView
extends Control

signal dismissed
signal use_action(action: Dictionary)


func present(state: CampaignState, db: ContentDB, allow_use: bool) -> void:
	UiFactory.clear(self)
	var backdrop := ColorRect.new()
	backdrop.color = Color(GameTheme.INK, 0.96)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var column := UiFactory.vbox(8)
	margin.add_child(column)
	var header := UiFactory.hbox()
	header.add_child(UiFactory.title("Ledger", 26))
	header.add_child(UiFactory.filler())
	var close := UiFactory.chip("Close")
	close.pressed.connect(func(): dismissed.emit())
	header.add_child(close)
	column.add_child(header)
	if allow_use:
		column.add_child(UiFactory.muted("Using a secret, favour, or document spends your action for the week."))
	else:
		column.add_child(UiFactory.muted("The ledger is read here. It is spent when you choose the week's action."))
	var list := UiFactory.vbox(8)
	column.add_child(UiFactory.scroll(list))
	if state.ledger.is_empty():
		list.add_child(UiFactory.label("Nothing is written down yet. Rumours are not proof."))
		return
	for kind in ["secret", "evidence", "document", "favour", "debt", "rumour"]:
		var rows: Array = []
		for id in state.ledger:
			var item: Dictionary = db.ledger.get(str(id), {})
			if str(item.get("kind", "")) == kind:
				rows.append(item)
		if rows.is_empty():
			continue
		list.add_child(UiFactory.title(kind.capitalize(), 20))
		for item in rows:
			var card := UiFactory.panel()
			var inner := UiFactory.vbox(4)
			card.add_child(inner)
			inner.add_child(UiFactory.label(str(item.get("title", "")), 18, GameTheme.GOLD))
			inner.add_child(UiFactory.label(str(item.get("text", ""))))
			list.add_child(card)
	if not state.ledger_archive.is_empty():
		list.add_child(UiFactory.title("Spent", 20))
		for id in state.ledger_archive:
			var item: Dictionary = db.ledger.get(str(id), {})
			list.add_child(UiFactory.muted(str(item.get("title", id))))
