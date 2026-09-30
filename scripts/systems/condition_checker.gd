class_name ConditionChecker
extends RefCounted


static func met(requires, state: CampaignState, db: ContentDB) -> bool:
	return failures(requires, state, db).is_empty()


static func failures(requires, state: CampaignState, db: ContentDB) -> PackedStringArray:
	var out := PackedStringArray()
	if typeof(requires) != TYPE_DICTIONARY or requires.is_empty():
		return out
	_claimant(requires, state, out)
	if requires.has("min_turn") and state.turn < int(requires["min_turn"]):
		out.append("Too early")
	if requires.has("max_turn") and state.turn > int(requires["max_turn"]):
		out.append("The moment has passed")
	if requires.has("acts"):
		var act := Balance.act_of(state.turn)
		var ok := false
		for entry in requires["acts"]:
			if int(entry) == act:
				ok = true
		if not ok:
			out.append("Wrong season of the war")
	_flags(requires.get("flags", null), state, true, out)
	_flags(requires.get("not_flags", null), state, false, out)
	_at_least("min_gold", state.gold, "gold", requires, out)
	_at_least("min_rations", state.rations, "rations", requires, out)
	_at_least("min_forces", state.forces, "forces", requires, out)
	_at_least("min_claim", state.claim, "claim", requires, out)
	_at_most("max_claim", state.claim, "claim", requires, out)
	_at_least("min_fear", state.fear, "fear", requires, out)
	_at_most("max_fear", state.fear, "fear", requires, out)
	_at_least("min_reputation", state.reputation, "reputation", requires, out)
	_at_most("max_reputation", state.reputation, "reputation", requires, out)
	_at_least("min_stability", state.stability, "stability", requires, out)
	_at_least("min_foreign", state.foreign, "foreign pressure", requires, out)
	_at_most("max_foreign", state.foreign, "foreign pressure", requires, out)
	if requires.has("max_forces") and state.forces > int(requires["max_forces"]):
		out.append("Army is too large")
	_bloc_bounds(requires.get("min_bloc", {}), state, true, out)
	_bloc_bounds(requires.get("max_bloc", {}), state, false, out)
	var owned := state.player_territories()
	if requires.has("min_player_territories") and owned.size() < int(requires["min_player_territories"]):
		out.append("Need more territory")
	if requires.has("max_player_territories") and owned.size() > int(requires["max_player_territories"]):
		out.append("Hold too much land")
	_owns(requires.get("controls", null), owned, true, db, out)
	_owns_any(requires.get("controls_any", null), owned, db, out)
	_owns(requires.get("not_controls", null), owned, false, db, out)
	_relations(requires.get("relation_min", {}), state, "personal", out, db)
	_relations(requires.get("political_min", {}), state, "political", out, db)
	_people(requires.get("npc_alive", null), state, true, out, db)
	_people(requires.get("npc_dead", null), state, false, out, db)
	_npc_modes(requires.get("npc_state", {}), state, out)
	_ledger_all(requires.get("has_ledger", null), state, db, out)
	_ledger_missing(requires.get("missing_ledger", null), state, db, out)
	_ledger_any(requires.get("has_ledger_any", null), state, db, out)
	_houses(requires.get("house_declared", {}), state, out, db)
	_house_opinion(requires.get("house_opinion_min", {}), state, out, db)
	if requires.has("min_houses_player") and state.houses_declared_for_player() < int(requires["min_houses_player"]):
		out.append("Need %d houses declared" % int(requires["min_houses_player"]))
	if requires.has("chronicle") and not MetaProgress.has(str(requires["chronicle"])):
		out.append("Not yet known to history")
	if requires.has("not_chronicle") and MetaProgress.has(str(requires["not_chronicle"])):
		out.append("Already known")
	_chronicle_any(requires.get("chronicle_any", null), out)
	_rivals(requires.get("rival_alive", null), state, true, out, db)
	_rivals(requires.get("rival_dead", null), state, false, out, db)
	if bool(requires.get("any_rival_weak", false)) and not _any_rival_weak(state):
		out.append("No rival is weak enough")
	if requires.has("elite"):
		for elite in requires["elite"]:
			if not state.elites.has(str(elite)):
				out.append("Missing a formation")
	return out


static func _claimant(requires: Dictionary, state: CampaignState, out: PackedStringArray) -> void:
	if requires.has("claimant") and not _id_match(requires["claimant"], state.claimant_id):
		out.append("Another claimant's path")
	if requires.has("not_claimant") and _id_match(requires["not_claimant"], state.claimant_id):
		out.append("Closed to you")


static func _id_match(raw, id: String) -> bool:
	if typeof(raw) == TYPE_ARRAY:
		for entry in raw:
			if str(entry) == id:
				return true
		return false
	return str(raw) == id


static func _flags(raw, state: CampaignState, must: bool, out: PackedStringArray) -> void:
	if typeof(raw) != TYPE_ARRAY:
		return
	for flag in raw:
		var present := bool(state.flags.get(str(flag), false))
		if must and not present:
			out.append("Requires " + Balance.human_flag(str(flag)))
		if not must and present:
			out.append("Blocked by " + Balance.human_flag(str(flag)))


static func _at_least(key: String, value: int, label: String, requires: Dictionary, out: PackedStringArray) -> void:
	if requires.has(key) and value < int(requires[key]):
		out.append("Need %s %s" % [Balance.comma(int(requires[key])), label])


static func _at_most(key: String, value: int, label: String, requires: Dictionary, out: PackedStringArray) -> void:
	if requires.has(key) and value > int(requires[key]):
		out.append("%s is too high" % label.capitalize())


static func _bloc_bounds(raw, state: CampaignState, minimum: bool, out: PackedStringArray) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	for key in raw:
		var have := int(state.blocs.get(str(key), 0))
		var need := int(raw[key])
		if minimum and have < need:
			out.append("%s support too low" % Balance.bloc_title(str(key)))
		if not minimum and have > need:
			out.append("%s support too high" % Balance.bloc_title(str(key)))


static func _owns(raw, owned: Array, must: bool, db: ContentDB, out: PackedStringArray) -> void:
	if typeof(raw) != TYPE_ARRAY:
		return
	for tid in raw:
		var has := owned.has(str(tid))
		var name := str(db.territories.get(str(tid), {}).get("name", tid))
		if must and not has:
			out.append("Need " + name)
		if not must and has:
			out.append("Must not hold " + name)


static func _owns_any(raw, owned: Array, db: ContentDB, out: PackedStringArray) -> void:
	if typeof(raw) != TYPE_ARRAY:
		return
	for tid in raw:
		if owned.has(str(tid)):
			return
	out.append("Need a foothold")


static func _relations(raw, state: CampaignState, field: String, out: PackedStringArray, db: ContentDB) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	for key in raw:
		var have := -100
		if state.npcs.has(str(key)):
			have = int(state.npcs[str(key)].get(field, 0))
		if have < int(raw[key]):
			var name := str(db.characters.get(str(key), {}).get("name", key))
			out.append("%s is not close enough" % name)


static func _people(raw, state: CampaignState, alive: bool, out: PackedStringArray, db: ContentDB) -> void:
	if typeof(raw) != TYPE_ARRAY:
		return
	for key in raw:
		var living := state.npc_alive(str(key))
		var name := str(db.characters.get(str(key), {}).get("name", key))
		if alive and not living:
			out.append("%s is gone" % name)
		if not alive and living:
			out.append("%s still lives" % name)


static func _npc_modes(raw, state: CampaignState, out: PackedStringArray) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	for key in raw:
		var mode := ""
		if state.npcs.has(str(key)):
			mode = str(state.npcs[str(key)].get("state", ""))
		if mode != str(raw[key]):
			out.append("Someone is not where they must be")


static func _ledger_all(raw, state: CampaignState, db: ContentDB, out: PackedStringArray) -> void:
	if typeof(raw) != TYPE_ARRAY:
		return
	for key in raw:
		if not state.has_ledger(str(key)):
			var title := str(db.ledger.get(str(key), {}).get("title", key))
			out.append("Need " + title)


static func _ledger_missing(raw, state: CampaignState, db: ContentDB, out: PackedStringArray) -> void:
	if typeof(raw) != TYPE_ARRAY:
		return
	for key in raw:
		if state.has_ledger(str(key)):
			out.append("Already in the ledger")


static func _ledger_any(raw, state: CampaignState, db: ContentDB, out: PackedStringArray) -> void:
	if typeof(raw) != TYPE_ARRAY:
		return
	for key in raw:
		if state.has_ledger(str(key)):
			return
	out.append("Need some proof")


static func _houses(raw, state: CampaignState, out: PackedStringArray, db: ContentDB) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	for key in raw:
		var declared := ""
		if state.houses.has(str(key)):
			declared = str(state.houses[str(key)].get("declared", ""))
		if declared != str(raw[key]):
			var name := str(db.houses.get(str(key), {}).get("name", key))
			out.append("%s has not declared" % name)


static func _house_opinion(raw, state: CampaignState, out: PackedStringArray, db: ContentDB) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	for key in raw:
		var opinion := -100
		if state.houses.has(str(key)):
			opinion = int(state.houses[str(key)].get("opinion", 0))
		if opinion < int(raw[key]):
			var name := str(db.houses.get(str(key), {}).get("name", key))
			out.append("%s is unconvinced" % name)


static func _chronicle_any(raw, out: PackedStringArray) -> void:
	if typeof(raw) != TYPE_ARRAY:
		return
	for key in raw:
		if MetaProgress.has(str(key)):
			return
	out.append("History has not opened this door")


static func _rivals(raw, state: CampaignState, alive: bool, out: PackedStringArray, db: ContentDB) -> void:
	if typeof(raw) != TYPE_ARRAY:
		return
	for key in raw:
		var id := str(key)
		var living := false
		if id == state.claimant_id:
			living = state.defeat_reason == ""
		else:
			living = state.rivals.has(id) and bool(state.rivals[id].get("alive", false))
		var name := str(db.claimants.get(id, {}).get("short", key))
		if alive and not living:
			out.append("%s is gone" % name)
		if not alive and living:
			out.append("%s still lives" % name)


static func _any_rival_weak(state: CampaignState) -> bool:
	for id in state.rivals:
		var rival: Dictionary = state.rivals[id]
		if not bool(rival.get("alive", false)):
			continue
		if int(rival.get("claim", 100)) <= 24 and int(rival.get("forces", 9999)) <= 700:
			return true
	return false
