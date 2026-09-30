class_name CampaignRules
extends RefCounted

## Week economy, battle handoff, and the consequences that come back from the field.


static func close_week(state: CampaignState, db: ContentDB) -> Array:
	if not state.ending_data.is_empty() or state.defeat_reason != "":
		return []
	var closing_turn := state.turn
	var report: Array = []
	report.append_array(_upkeep(state, db))
	report.append_array(_modifiers(state))
	_tick_wounds(state)
	_tick_schedules(state)
	report.append_array(RivalBrain.act(state, db))
	report.append_array(NewsWeaver.ambient(state, db))
	if _fractured(state):
		state.foreign += 1
		report.append("Word of the fracture reaches Varos. Foreign interest rises.")
	elif state.stability >= 60 and state.foreign > 0 and state.turn % 2 == 0:
		state.foreign -= 1
		report.append("The steady courts and open roads make foreign agents less welcome. Varos's influence recedes.")
	if int(state.blocs.get("people", 0)) < -20:
		state.stability -= 1
	elif int(state.blocs.get("people", 0)) > 40:
		state.stability += 1
	if state.fear > 65:
		state.stability -= 1
	state.turn += 1
	if state.turn == 36:
		report.append("The Council calls for a final settlement by the end of the first year. Seventeen weeks remain to make your claim.")
	if state.turn == 44 or state.turn == 48:
		report.append("The Council's deadline draws close. You have %d weeks before the surviving houses settle the throne without you." % (53 - state.turn))
	if state.turn > 52:
		state.defeat_reason = "council_settlement"
		report.append("The year of succession ends. The Council seals a settlement before another winter can begin.")
	state.event_queue = []
	state.event_index = 0
	state.action_taken = ""
	state.phase = "response"
	state.week_title = "Close of " + Balance.date_line(closing_turn)
	state.week_report = report.duplicate()
	for line in report:
		state.add_log(str(line))
	state.clamp_resources()
	if state.claim >= 100 and not bool(state.flags.get("CLAIM_ANNOUNCED", false)):
		state.flags["CLAIM_ANNOUNCED"] = true
		state.week_report.append("Your claim is whole enough to attempt the throne.")
	SaveManager.save_campaign(state, 0, "Autosave")
	return report


static func build_battle(state: CampaignState, db: ContentDB) -> Dictionary:
	var pending: Dictionary = state.pending_battle
	var battle_id := str(pending.get("battle_id", ""))
	var definition: Dictionary = db.battles.get(battle_id, {})
	var enemy_forces := int(definition.get("enemy_forces", 700))
	var enemy_name := str(definition.get("enemy_name", "Enemy Host"))
	var morale := int(definition.get("enemy_morale", 60))
	var types = definition.get("enemy_types", ["infantry", "spears", "archers", "cavalry"])
	var elites: Array = []
	if str(definition.get("enemy_elite", "")) != "":
		elites.append(str(definition.get("enemy_elite", "")))
	var rival_id := str(definition.get("use_rival", ""))
	var battle_title := str(definition.get("title", "Battle"))
	if battle_id == "throne_conquest" and str(state.territories.get("caerlyn", {}).get("controller", "")) == "player":
		battle_title = "The Last Siege of Caerlyn"
		enemy_name = "Coalition outside the Crown Gate"
		state.pending_battle["defending_capital"] = true
	if rival_id != "" and state.rivals.has(rival_id) and bool(state.rivals[rival_id].get("alive", false)):
		enemy_forces = maxi(180, int(state.rivals[rival_id].get("forces", enemy_forces)))
		enemy_name = str(db.claimants[rival_id].get("name", enemy_name))
		morale = clampi(48 + int(state.rivals[rival_id].get("fear", 0)) / 6, 40, 92)
		var bias = db.claimants[rival_id].get("army_bias", types)
		types = bias
		for elite in db.claimants[rival_id].get("start", {}).get("elites", []):
			if not elites.has(str(elite)):
				elites.append(str(elite))
	var player_morale := clampi(state.army_morale + int(state.reputation / 12) - (10 if state.rations <= 0 else 0), 20, 96)
	if not state.pending_battle.has("seed"):
		state.pending_battle["seed"] = str(state.rng.randi())
	return {
		"battle_id": battle_id,
		"title": battle_title,
		"enemy_name": enemy_name,
		"player_name": str(db.claimants.get(state.claimant_id, {}).get("name", "You")),
		"player_units": ArmyComposer.compose_player(state, db),
		"enemy_units": ArmyComposer.compose_custom(db, enemy_forces, types, elites, enemy_name),
		"player_morale": player_morale,
		"enemy_morale": morale,
		"player_forces": state.forces,
		"enemy_forces": enemy_forces,
		"rival_id": rival_id,
		"seed": int(state.pending_battle["seed"]),
	}


static func apply_battle_return(state: CampaignState, db: ContentDB, battle_result: Dictionary) -> void:
	# The pending handoff is consumed once. Duplicate UI callbacks cannot spend
	# the same soldiers twice or grant another victory.
	if state.pending_battle.is_empty():
		return
	var outcome := str(battle_result.get("outcome", "stalemate"))
	var lost := maxi(0, int(battle_result.get("forces_lost", 0)))
	state.forces = maxi(0, state.forces - lost)
	var battle_id := str(state.pending_battle.get("battle_id", battle_result.get("battle_id", "")))
	var definition: Dictionary = db.battles.get(battle_id, {})
	var claim_delta := 0
	match outcome:
		"victory":
			claim_delta = int(definition.get("claim_win", 3))
		"defeat":
			claim_delta = int(definition.get("claim_loss", -4))
		"retreat":
			claim_delta = int(definition.get("claim_retreat", -2))
		_:
			claim_delta = int(definition.get("claim_stalemate", 0))
	state.claim += claim_delta
	state.army_morale = clampi(int(battle_result.get("player_morale", state.army_morale)), 0, 100)
	var rival_id := str(battle_result.get("rival_id", ""))
	if rival_id != "" and state.rivals.has(rival_id):
		var enemy_lost := maxi(0, int(battle_result.get("enemy_lost", 0)))
		state.rivals[rival_id]["forces"] = maxi(0, int(state.rivals[rival_id]["forces"]) - enemy_lost)
		if outcome == "victory":
			state.rivals[rival_id]["hostility"] = clampi(int(state.rivals[rival_id]["hostility"]) + 8, 0, 100)
			state.rivals[rival_id]["claim"] = clampi(int(state.rivals[rival_id]["claim"]) - 3, 0, 100)
		elif outcome == "defeat":
			state.rivals[rival_id]["claim"] = clampi(int(state.rivals[rival_id]["claim"]) + 4, 0, 100)
	for elite_id in battle_result.get("elites_lost", []):
		state.elites.erase(str(elite_id))
	for fate in battle_result.get("commanders", []):
		_commander_fate(state, db, fate)
	var title := str(battle_result.get("title", definition.get("title", "Battle")))
	var line := "%s — %s. Lost %s soldiers. Claim %s." % [title, outcome, Balance.comma(lost), Balance.signed(claim_delta)]
	state.last_battle = {"outcome": outcome, "forces_lost": lost, "title": title, "battle_id": battle_id, "defending_capital": bool(state.pending_battle.get("defending_capital", false))}
	state.banner = line
	state.add_log(line)
	for entry in battle_result.get("log", []):
		if state.log.size() < 120:
			state.add_log(str(entry))
	var follow: Array = []
	match outcome:
		"victory":
			follow = state.pending_battle.get("on_victory", [])
		"defeat":
			follow = state.pending_battle.get("on_defeat", [])
		_:
			follow = state.pending_battle.get("on_retreat", [])
	state.pending_battle = {}
	if typeof(follow) == TYPE_ARRAY and not follow.is_empty():
		EffectResolver.apply(state, follow, db)
	if state.post_battle == "throne" and outcome == "retreat":
		state.post_battle = ""
		state.pending_throne_route = ""
		state.claim = clampi(state.claim - 4, 0, 100)
		state.add_log("You step back from the throne. The court will call it fear or patience.")
	state.clamp_resources()


static func _commander_fate(state: CampaignState, db: ContentDB, fate: Dictionary) -> void:
	var id := str(fate.get("id", ""))
	var kind := str(fate.get("fate", "ok"))
	if id == "" or kind == "ok":
		return
	if id == state.claimant_id:
		if kind == "dead":
			state.defeat_reason = "battle_death"
			state.add_log("Your banner falls. You do not leave the field.")
		elif kind == "wounded":
			state.army_morale = clampi(state.army_morale - 8, 0, 100)
			state.wounded[id] = 3
			state.add_log("You are carried off the field wounded.")
		elif kind == "captured":
			state.defeat_reason = "captured"
			state.add_log("You are taken alive.")
		return
	var name := str(db.characters.get(id, {}).get("name", id))
	match kind:
		"dead":
			EffectResolver.apply(state, [{"op": "kill", "id": id}], db)
		"captured":
			state.npcs[id]["state"] = "captured"
			state.commanders.erase(id)
			state.add_log("%s is captured." % name)
		"wounded":
			state.wounded[id] = 2
			state.army_morale = clampi(state.army_morale - 4, 0, 100)
			if state.npcs.has(id):
				var memories: Array = state.npcs[id]["memories"]
				memories.append("Wounded in your service.")
			state.add_log("%s is wounded." % name)


static func _upkeep(state: CampaignState, db: ContentDB) -> Array:
	var report: Array = []
	var gold_in := 0
	var food_in := 0
	for tid in state.player_territories():
		var data: Dictionary = db.territories.get(tid, {})
		var loyalty := int(state.territories[tid].get("loyalty", 50))
		gold_in += Balance.scaled_yield(int(data.get("gold", 0)), loyalty)
		food_in += Balance.scaled_yield(int(data.get("rations", 0)), loyalty)
		var unrest := int(state.territories[tid].get("unrest", 0))
		if unrest > 30:
			state.territories[tid]["loyalty"] = clampi(loyalty - 2, 0, 100)
			report.append("%s is restless, and its loyalty slips." % str(data.get("name", tid)))
		elif unrest > 0:
			state.territories[tid]["unrest"] = unrest - 1
	state.gold += gold_in
	state.rations += food_in
	if gold_in > 0 or food_in > 0:
		report.append("Your holdings yield %s gold and %d rations." % [Balance.comma(gold_in), food_in])
	var food_need := Balance.ration_need(state.forces)
	if state.rations >= food_need:
		state.rations -= food_need
		state.flags.erase("STARVING")
		if food_need > 0:
			report.append("The host eats %d rations." % food_need)
	elif state.forces > 0:
		var short := food_need - state.rations
		state.rations = 0
		var loss := mini(state.forces, int(float(state.forces) * min(0.22, float(short) * 0.045)) + short * 8)
		state.forces -= loss
		state.army_morale = clampi(state.army_morale - 8, 0, 100)
		state.blocs["military"] = clampi(int(state.blocs["military"]) - 4, -100, 100)
		state.claim = clampi(state.claim - 1, 0, 100)
		report.append("The stores fail. %s soldiers desert or die." % Balance.comma(loss))
		if short >= 3:
			state.flags["STARVING"] = true
			state.flags["HAD_STARVATION"] = true
	var cost := Balance.gold_upkeep(state.forces)
	if state.gold >= cost:
		state.gold -= cost
		state.flags.erase("UNPAID")
		if cost > 0:
			report.append("Pay and steel cost %s gold." % Balance.comma(cost))
	elif cost > 0:
		state.gold = 0
		state.flags["UNPAID"] = true
		state.army_morale = clampi(state.army_morale - 6, 0, 100)
		state.blocs["military"] = clampi(int(state.blocs["military"]) - 5, -100, 100)
		report.append("You cannot pay the host. Discipline thins.")
	return report


static func _modifiers(state: CampaignState) -> Array:
	var report: Array = []
	var kept: Array = []
	for raw in state.modifiers:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var modifier: Dictionary = raw
		state.gold += int(modifier.get("gold", 0))
		state.rations += int(modifier.get("rations", 0))
		state.claim += int(modifier.get("claim", 0))
		state.fear += int(modifier.get("fear", 0))
		state.army_morale += int(modifier.get("morale", 0))
		var blocs = modifier.get("blocs", {})
		if typeof(blocs) == TYPE_DICTIONARY:
			for key in blocs:
				if state.blocs.has(str(key)):
					state.blocs[str(key)] = int(state.blocs[str(key)]) + int(blocs[key])
		modifier["turns"] = int(modifier.get("turns", 1)) - 1
		if int(modifier["turns"]) > 0:
			kept.append(modifier)
		else:
			report.append("%s has run its course." % str(modifier.get("name", "A pressure")))
	state.modifiers = kept
	return report


static func _tick_wounds(state: CampaignState) -> void:
	var kept := {}
	for key in state.wounded:
		var left := int(state.wounded[key]) - 1
		if left > 0:
			kept[str(key)] = left
	state.wounded = kept


static func _fractured(state: CampaignState) -> bool:
	if state.fear >= 55 or state.stability <= 40:
		return true
	for rid in state.rivals:
		var rival: Dictionary = state.rivals[rid]
		if bool(state.flags.get("ALLY_" + str(rid).to_upper(), false)) or bool(state.flags.get("COUNCIL_OF_FOUR", false)):
			continue
		if bool(rival.get("alive", false)) and int(rival.get("claim", 0)) >= state.claim + 8:
			return true
	return false


static func _tick_schedules(state: CampaignState) -> void:
	var kept: Array = []
	for raw in state.scheduled:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = raw
		row["delay"] = int(row.get("delay", 1)) - 1
		if int(row["delay"]) <= 0:
			var event_id := str(row.get("event", ""))
			if event_id != "" and not state.forced_events.has(event_id):
				state.forced_events.append(event_id)
		else:
			kept.append(row)
	state.scheduled = kept
