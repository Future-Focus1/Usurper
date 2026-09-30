class_name DebugPanel
extends PanelContainer

signal changed
signal launch_battle(battle_id: String)
signal force_route(route_id: String)
signal play_event(event_id: String)

var _state: CampaignState
var _db: ContentDB


func present(state: CampaignState, db: ContentDB) -> void:
	UiFactory.clear(self)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var column := UiFactory.vbox(8)
	margin.add_child(UiFactory.scroll(column))
	var header := UiFactory.hbox()
	header.add_child(UiFactory.title("Debug", 24))
	header.add_child(UiFactory.filler())
	var close := UiFactory.chip("Close")
	close.pressed.connect(func(): visible = false)
	header.add_child(close)
	column.add_child(header)
	var row := UiFactory.flow(6)
	column.add_child(row)
	row.add_child(_chip("Gold +500", func(): state.gold += 500; _touch()))
	row.add_child(_chip("Rations +20", func(): state.rations += 20; _touch()))
	row.add_child(_chip("Forces +500", func(): state.forces += 500; _touch()))
	row.add_child(_chip("Claim +10", func(): state.claim += 10; _touch()))
	row.add_child(_chip("Claim 100", func(): state.claim = 100; state.flags["CLAIM_ANNOUNCED"] = true; _touch()))
	row.add_child(_chip("Advance week", func(): CampaignRules.close_week(state, db); _touch()))
	_state = state
	_db = db
	var blocs := UiFactory.flow(6)
	column.add_child(blocs)
	for bloc in Balance.BLOCS:
		blocs.add_child(_chip(Balance.bloc_title(str(bloc)) + " +15", _bump_bloc.bind(str(bloc))))
	var event_row := UiFactory.flow(6)
	column.add_child(event_row)
	var event_id := LineEdit.new()
	event_id.placeholder_text = "Event id"
	event_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_row.add_child(event_id)
	var play := _chip("Trigger event", func(): play_event.emit(event_id.text.strip_edges()))
	event_row.add_child(play)
	var battle_row := UiFactory.flow(6)
	column.add_child(battle_row)
	var battle_id := LineEdit.new()
	battle_id.text = "road_bandits"
	battle_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_row.add_child(battle_id)
	battle_row.add_child(_chip("Start battle", func(): launch_battle.emit(battle_id.text.strip_edges())))
	var territory := _option()
	var owner := _option()
	for tid in db.territory_order:
		territory.add_item(str(db.territories[tid].get("name", tid)))
		territory.set_item_metadata(territory.item_count - 1, tid)
	for controller in ["player", "neutral", "mira", "ethan", "arlo", "alistair", "maren", "veyne", "harrow", "edevane"]:
		owner.add_item(controller)
	var land_row := UiFactory.flow(6)
	column.add_child(land_row)
	land_row.add_child(territory)
	land_row.add_child(owner)
	land_row.add_child(_chip("Set owner", func():
		var tid := str(territory.get_item_metadata(territory.selected))
		state.territories[tid]["controller"] = owner.get_item_text(owner.selected)
		_touch()
	))
	var secret := _option()
	for id in db.ledger_order:
		secret.add_item(str(db.ledger[id].get("title", id)))
		secret.set_item_metadata(secret.item_count - 1, id)
	var secret_row := UiFactory.flow(6)
	column.add_child(secret_row)
	secret_row.add_child(secret)
	secret_row.add_child(_chip("Unlock ledger", func():
		var id := str(secret.get_item_metadata(secret.selected))
		if not state.ledger.has(id):
			state.ledger.append(id)
		_touch()
	))
	var npc := _option()
	for id in db.character_order:
		npc.add_item(str(db.characters[id].get("name", id)))
		npc.set_item_metadata(npc.item_count - 1, id)
	var npc_row := UiFactory.flow(6)
	column.add_child(npc_row)
	npc_row.add_child(npc)
	npc_row.add_child(_chip("Kill", func():
		EffectResolver.apply(state, [{"op": "kill", "id": str(npc.get_item_metadata(npc.selected))}], db)
		_touch()
	))
	npc_row.add_child(_chip("Revive", func():
		var id := str(npc.get_item_metadata(npc.selected))
		if state.npcs.has(id):
			state.npcs[id]["alive"] = true
			state.npcs[id]["state"] = "free"
		if state.rivals.has(id):
			state.rivals[id]["alive"] = true
		_touch()
	))
	var route := _option()
	for item in db.routes:
		route.add_item(str(item.get("title", item.get("id", ""))))
		route.set_item_metadata(route.item_count - 1, str(item.get("id", "")))
	var route_row := UiFactory.flow(6)
	column.add_child(route_row)
	route_row.add_child(route)
	route_row.add_child(_chip("Force triumph", func(): force_route.emit(str(route.get_item_metadata(route.selected)))))
	column.add_child(UiFactory.muted("Debug stays in the build until Balance.DEBUG_ENABLED is turned off."))


func _option() -> OptionButton:
	var node := OptionButton.new()
	node.fit_to_longest_item = false
	node.clip_text = true
	node.custom_minimum_size = Vector2(180, 0)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


func _chip(text: String, callback: Callable) -> Button:
	var button := UiFactory.chip(text)
	button.pressed.connect(callback)
	return button


func _bump_bloc(id: String) -> void:
	if _state == null:
		return
	_state.blocs[id] = clampi(int(_state.blocs.get(id, 0)) + 15, -100, 100)
	_touch()


func _touch() -> void:
	changed.emit()
