class_name CourtView
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
	header.add_child(UiFactory.title("Court", 26))
	header.add_child(UiFactory.filler())
	var close := UiFactory.chip("Close")
	close.pressed.connect(func(): dismissed.emit())
	header.add_child(close)
	column.add_child(header)
	var body := UiFactory.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var list := UiFactory.vbox(4)
	var scroll := UiFactory.scroll(list)
	scroll.custom_minimum_size = Vector2(220, 0)
	scroll.size_flags_stretch_ratio = 1.0
	body.add_child(scroll)
	var detail := UiFactory.vbox(6)
	var detail_scroll := UiFactory.scroll(detail)
	detail_scroll.size_flags_stretch_ratio = 1.4
	body.add_child(detail_scroll)
	detail.add_child(UiFactory.muted("People remember what you did to them. Politics is only half of that."))
	for id in db.character_order:
		if id == state.claimant_id:
			continue
		var button := UiFactory.button(_row_label(state, db, id))
		var who := str(id)
		button.pressed.connect(func(): _detail(detail, state, db, who))
		list.add_child(button)
	if db.characters.has("garran_vale"):
		_detail(detail, state, db, "garran_vale")


func _row_label(state: CampaignState, db: ContentDB, id: String) -> String:
	var name := str(db.characters[id].get("name", id))
	var row: Dictionary = state.npcs.get(id, {})
	var status := _status(row)
	return "%s  —  %s, %s" % [name, Balance.relation_label(int(row.get("personal", 0))), status]


func _detail(detail: VBoxContainer, state: CampaignState, db: ContentDB, id: String) -> void:
	UiFactory.clear(detail)
	var who: Dictionary = db.characters[id]
	var row: Dictionary = state.npcs.get(id, {})
	var portrait := UiFactory.portrait(id, 210, 180)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if not bool(row.get("alive", true)):
		portrait.modulate = Color(0.45, 0.45, 0.45)
	detail.add_child(portrait)
	detail.add_child(UiFactory.title(str(who.get("name", id)), 26))
	detail.add_child(UiFactory.muted("%s  ·  Age %d" % [who.get("role", ""), int(who.get("age", 0))]))
	detail.add_child(UiFactory.label(str(who.get("summary", ""))))
	var biography := str(who.get("biography", who.get("backstory", "")))
	if who.has("public_biography") and not ConditionChecker.met(who.get("biography_requires", {}), state, db):
		biography = str(who["public_biography"])
	if biography != "":
		detail.add_child(UiFactory.rich(biography, 16))
	if str(who.get("allegiance", "")) != "":
		detail.add_child(UiFactory.muted("Beliefs: " + str(who["allegiance"]), 15))
	var personal := Balance.relation_label(int(row.get("personal", 0)))
	var political := Balance.relation_label(int(row.get("political", 0)))
	var personal_label := UiFactory.label("Personal: %s (%d)" % [personal, int(row.get("personal", 0))])
	personal_label.add_theme_color_override("font_color", UiFactory.support_color(personal))
	detail.add_child(personal_label)
	detail.add_child(UiFactory.label("Political: %s (%d)" % [political, int(row.get("political", 0))]))
	detail.add_child(UiFactory.label("Status: %s" % _status(row)))
	if state.rivals.has(id):
		var rival: Dictionary = state.rivals[id]
		detail.add_child(UiFactory.muted("Rival claim %d · forces %s · %s" % [
			int(rival.get("claim", 0)), Balance.comma(int(rival.get("forces", 0))), "alive" if bool(rival.get("alive", false)) else "gone"
		]))
	_list(detail, "Memories", row.get("memories", []))
	_list(detail, "Grudges", row.get("grudges", []))
	_list(detail, "Promises", row.get("promises", []))
	_list(detail, "Broken", row.get("broken", []))


func _list(detail: VBoxContainer, title: String, rows) -> void:
	if typeof(rows) != TYPE_ARRAY or rows.is_empty():
		return
	detail.add_child(UiFactory.muted(title))
	for line in rows:
		detail.add_child(UiFactory.label("· " + str(line), 14))


func _status(row: Dictionary) -> String:
	if not bool(row.get("alive", true)):
		return "Dead"
	return str(row.get("state", "free")).capitalize()
