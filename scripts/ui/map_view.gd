class_name MapView
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
	header.add_child(UiFactory.title("Nezrel", 26))
	header.add_child(UiFactory.filler())
	var close := UiFactory.chip("Close")
	close.pressed.connect(func(): dismissed.emit())
	header.add_child(close)
	column.add_child(header)
	column.add_child(UiFactory.muted("A political map, not a battlefield. Click a land to read it."))
	var body := UiFactory.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var board := Control.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.size_flags_stretch_ratio = 1.7
	board.custom_minimum_size = Vector2(420, 280)
	board.clip_contents = false
	body.add_child(board)
	var detail := UiFactory.vbox(6)
	var detail_scroll := UiFactory.scroll(detail)
	detail_scroll.custom_minimum_size = Vector2(220, 0)
	detail_scroll.size_flags_stretch_ratio = 0.85
	body.add_child(detail_scroll)
	detail.add_child(UiFactory.muted("Select a territory."))
	for tid in db.territory_order:
		var data: Dictionary = db.territories[tid]
		var spot: Dictionary = state.territories.get(tid, {})
		var button := Button.new()
		button.text = str(data.get("name", tid))
		button.tooltip_text = db.controller_name(str(spot.get("controller", "")), state.claimant_id)
		var point := Vector2(float(data.get("x", 0.5)), float(data.get("y", 0.5)))
		var x := lerpf(0.16, 0.84, clampf(point.x, 0.0, 1.0))
		var y := lerpf(0.16, 0.84, clampf(point.y, 0.0, 1.0))
		button.anchor_left = x
		button.anchor_top = y
		button.anchor_right = x
		button.anchor_bottom = y
		button.offset_left = -74
		button.offset_top = -22
		button.offset_right = 74
		button.offset_bottom = 22
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = false
		button.add_theme_font_size_override("font_size", 13)
		_tint(button, str(spot.get("controller", "")), state)
		var territory_id := str(tid)
		button.pressed.connect(func(): _show_detail(detail, state, db, territory_id))
		board.add_child(button)


func _show_detail(detail: VBoxContainer, state: CampaignState, db: ContentDB, tid: String) -> void:
	UiFactory.clear(detail)
	var data: Dictionary = db.territories[tid]
	var spot: Dictionary = state.territories[tid]
	detail.add_child(UiFactory.title(str(data.get("name", tid)), 24))
	detail.add_child(UiFactory.muted(str(data.get("blurb", ""))))
	detail.add_child(UiFactory.label("Held by %s" % db.controller_name(str(spot.get("controller", "")), state.claimant_id)))
	detail.add_child(UiFactory.label("Loyalty %d    Unrest %d    Fort %d" % [int(spot.get("loyalty", 0)), int(spot.get("unrest", 0)), int(spot.get("fort", 0))]))
	detail.add_child(UiFactory.label("Gold %s    Rations %s    Recruits %s" % [
		str(data.get("gold", 0)), str(data.get("rations", 0)), str(data.get("recruit", 0))
	], 15, GameTheme.GOLD))
	detail.add_child(UiFactory.muted("Special: %s" % str(data.get("special", "none"))))
	var house_id := str(data.get("house", ""))
	if db.houses.has(house_id):
		var house: Dictionary = db.houses[house_id]
		detail.add_child(UiFactory.muted("%s — \"%s\"" % [house.get("name", ""), house.get("motto", "")]))
	detail.add_child(UiFactory.muted("Worth %s to whoever holds the roads." % str(data.get("strategic", ""))))


func _tint(button: Button, controller: String, state: CampaignState) -> void:
	var color := GameTheme.PANEL_RAISED
	if controller == "player" or controller == state.claimant_id:
		color = Color("2c5d82")
	elif state.rivals.has(controller):
		color = Color("6d3a4a")
	elif controller == "neutral":
		color = Color("2a3542")
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = GameTheme.LINE
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = 6
	box.content_margin_right = 6
	button.add_theme_stylebox_override("normal", box)
