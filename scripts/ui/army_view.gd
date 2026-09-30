class_name ArmyView
extends Control

signal dismissed


func present(state: CampaignState, db: ContentDB) -> void:
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
	header.add_child(UiFactory.title("Army", 26))
	header.add_child(UiFactory.filler())
	var close := UiFactory.chip("Close")
	close.pressed.connect(func(): dismissed.emit())
	header.add_child(close)
	column.add_child(header)
	column.add_child(UiFactory.label("Forces %s    Morale %d" % [Balance.comma(state.forces), state.army_morale], 16, GameTheme.GOLD))
	column.add_child(UiFactory.label("Eats %d rations a week    Pay %s gold" % [
		Balance.ration_need(state.forces),
		Balance.comma(Balance.gold_upkeep(state.forces)),
	], 16, GameTheme.GOLD))
	column.add_child(UiFactory.muted("Battle tokens stand for companies. The number above is the host itself."))
	var list := UiFactory.vbox(6)
	column.add_child(UiFactory.scroll(list))
	if state.forces < 40:
		list.add_child(UiFactory.label("You do not have enough soldiers to offer battle."))
	for unit in ArmyComposer.compose_player(state, db):
		var card := UiFactory.panel()
		var inner := UiFactory.vbox(2)
		card.add_child(inner)
		var name := str(unit.get("name", "Company"))
		if bool(unit.get("elite", false)):
			name += "  ·  elite"
		inner.add_child(UiFactory.label("%s    %s" % [name, Balance.comma(int(unit.get("strength", 0)))]))
		inner.add_child(UiFactory.muted("Attack %s   Defence %s   %s" % [
			str(unit.get("attack", 0)),
			str(unit.get("defense", 0)),
			"ranged" if bool(unit.get("ranged", false)) else "close",
		]))
		if str(unit.get("commander_id", "")) != "":
			var commander := str(unit.get("commander_name", unit.get("commander_id", "")))
			if db.characters.has(str(unit.get("commander_id", ""))):
				commander = str(db.characters[str(unit.get("commander_id", ""))].get("name", commander))
			inner.add_child(UiFactory.muted("Commander: " + commander))
		list.add_child(card)
	if not state.modifiers.is_empty():
		list.add_child(UiFactory.title("Pressures", 20))
		for modifier in state.modifiers:
			list.add_child(UiFactory.label("%s — %d weeks left" % [modifier.get("name", ""), int(modifier.get("turns", 0))]))
