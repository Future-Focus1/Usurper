extends Node

## Headless campaign proof. Launch res://tests/smoke_runner.tscn.


func _ready() -> void:
	var code := 0
	if not _prove():
		code = 1
	get_tree().quit(code)


func _prove() -> bool:
	var db: ContentDB = get_node("/root/GameManager").db
	var errors := db.validate()
	if not errors.is_empty():
		for err in errors:
			push_error(err)
		return false
	if db.events.size() < 40:
		push_error("Not enough events")
		return false
	for claimant_id in db.claimant_order:
		if not _campaign(db, claimant_id):
			return false
	if not _battle(db):
		return false
	if not _ending(db):
		return false
	if not _chronicle():
		return false
	print("USURPER_SMOKE_OK events=%d claimants=%d" % [db.events.size(), db.claimant_order.size()])
	return true


func _campaign(db: ContentDB, claimant_id: String) -> bool:
	var state := CampaignState.new()
	state.setup(claimant_id, db)
	state.rng.seed = 424242
	EventDirector.pick_audience(state, db)
	if state.event_queue.is_empty():
		push_error("%s opened with no audience" % claimant_id)
		return false
	var openings := {
		"mira": "morning_of_bells",
		"ethan": "news_on_the_road",
		"arlo": "letter_on_the_table",
		"alistair": "stormhold_messengers",
	}
	if str(state.event_queue[0]) != str(openings[claimant_id]):
		push_error("%s opening was %s" % [claimant_id, state.event_queue[0]])
		return false
	var weeks := 0
	while weeks < 12 and state.defeat_reason == "":
		if state.event_queue.is_empty():
			EventDirector.pick_audience(state, db)
		while state.event_index < state.event_queue.size() and state.defeat_reason == "":
			if not _choose(state, db):
				push_error("%s stuck on %s" % [claimant_id, state.event_queue[state.event_index]])
				return false
			state.event_index += 1
		if state.defeat_reason != "":
			break
		var action := _action(state, db)
		if action.is_empty():
			push_error("%s had no strategic action" % claimant_id)
			return false
		if not _apply(state, db, action.get("effects", [])):
			return false
		if state.defeat_reason != "":
			break
		CampaignRules.close_week(state, db)
		state.event_queue = []
		state.event_index = 0
		weeks += 1
	if weeks < 4 and state.defeat_reason == "":
		push_error("%s only survived %d weeks" % [claimant_id, weeks])
		return false
	var saves = get_node("/root/SaveManager")
	if not saves.save_campaign(state, 2, "Smoke"):
		push_error("Save failed for %s" % claimant_id)
		return false
	var loaded: CampaignState = saves.load_campaign(2)
	if loaded == null or loaded.claimant_id != claimant_id or loaded.turn != state.turn or loaded.claim != state.claim:
		push_error("Reload mismatch for %s" % claimant_id)
		return false
	if loaded.gold != state.gold or loaded.forces != state.forces or loaded.ledger.size() != state.ledger.size():
		push_error("Reload resources mismatch for %s" % claimant_id)
		return false
	print("%s played %d weeks, turn %d, claim %d, defeat %s" % [claimant_id, weeks, state.turn, state.claim, state.defeat_reason])
	return true


func _choose(state: CampaignState, db: ContentDB) -> bool:
	var event := EventDirector.current(state, db)
	for choice in event.get("choices", []):
		if not ConditionChecker.met(choice.get("requires", {}), state, db):
			continue
		return _apply(state, db, choice.get("effects", []))
	return true


func _apply(state: CampaignState, db: ContentDB, effects: Array) -> bool:
	var result := EffectResolver.apply(state, effects, db)
	if str(result.get("defeat", "")) != "":
		return true
	if result.get("battle", {}).is_empty():
		return true
	state.post_battle = "advance_event"
	return _resolve_pending(state, db)


func _resolve_pending(state: CampaignState, db: ContentDB) -> bool:
	var setup := CampaignRules.build_battle(state, db)
	if setup.get("player_units", []).is_empty():
		CampaignRules.apply_battle_return(state, db, {"outcome": "retreat", "forces_lost": 0, "enemy_lost": 0, "player_morale": state.army_morale, "commanders": [], "elites_lost": [], "log": []})
		return true
	var resolved: Dictionary = BattleResolver.auto_resolve(setup)
	if str(resolved.get("outcome", "")) == "":
		push_error("Battle returned no outcome")
		return false
	CampaignRules.apply_battle_return(state, db, resolved)
	return true


func _action(state: CampaignState, db: ContentDB) -> Dictionary:
	var preferred := ["wait_listen", "address_troops", "public_audience", "train_forces", "lower_taxes", "seek_flame"]
	var rows := ActionBoard.available(state, db)
	for wanted in preferred:
		for action in rows:
			if str(action.get("id", "")) == wanted and ConditionChecker.met(action.get("requires", {}), state, db):
				return action
	for action in rows:
		if ConditionChecker.met(action.get("requires", {}), state, db):
			var effects = action.get("effects", [])
			if typeof(effects) == TYPE_ARRAY and not effects.is_empty():
				return action
	return {}


func _battle(db: ContentDB) -> bool:
	var state := CampaignState.new()
	state.setup("mira", db)
	state.forces = 1200
	state.pending_battle = {"battle_id": "road_bandits", "on_victory": [{"op": "claim", "amount": 1}], "on_defeat": [], "on_retreat": []}
	var setup := CampaignRules.build_battle(state, db)
	var resolved: Dictionary = BattleResolver.auto_resolve(setup)
	var outcome := str(resolved.get("outcome", ""))
	if not ["victory", "defeat", "retreat", "stalemate"].has(outcome):
		push_error("Unexpected battle outcome %s" % outcome)
		return false
	CampaignRules.apply_battle_return(state, db, resolved)
	if state.last_battle.is_empty():
		push_error("Battle was not recorded")
		return false
	print("battle %s" % outcome)
	return true


func _ending(db: ContentDB) -> bool:
	var state := CampaignState.new()
	state.setup("mira", db)
	state.claim = 100
	state.forces = 2600
	state.fear = 12
	state.blocs["military"] = 30
	state.blocs["nobility"] = 40
	state.blocs["court"] = 30
	state.blocs["people"] = 20
	state.blocs["flame"] = 10
	state.flags["COUNCIL_OF_FOUR"] = true
	var open_four := false
	for row in EndingDirector.list_routes(state, db):
		if str(row.get("route", {}).get("id", "")) == "four_banners" and bool(row.get("open", false)):
			open_four = true
	if not open_four:
		push_error("Four Banners did not open for a living player")
		for row in EndingDirector.list_routes(state, db):
			if str(row.get("route", {}).get("id", "")) == "four_banners":
				push_error(str(row.get("reason", "")))
		return false
	var ending := EndingDirector.resolve(state, db, "conquest", {"outcome": "victory"}, "triumph")
	if str(ending.get("title", "")) == "" or ending.get("paragraphs", []).is_empty():
		push_error("Ending text was empty")
		return false
	var defeat := EndingDirector.resolve_defeat(state, db, "exile")
	if str(defeat.get("title", "")) == "":
		push_error("Defeat text was empty")
		return false
	print("ending %s" % ending.get("title", ""))
	return true


func _chronicle() -> bool:
	var meta = get_node("/root/MetaProgress")
	var fresh: bool = meta.unlock("kd_illness")
	if not meta.has("kd_illness"):
		push_error("Chronicle did not keep a discovery")
		return false
	if fresh:
		print("chronicle unlocked kd_illness")
	else:
		print("chronicle already knew kd_illness")
	return true
