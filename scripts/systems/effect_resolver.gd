class_name EffectResolver
extends RefCounted

## Every consequence in the game passes through here, including debug tools.


static func apply(state: CampaignState, effects: Array, db: ContentDB) -> Dictionary:
	var result := {"log": [], "battle": {}, "defeat": ""}
	if not state.ending_data.is_empty():
		return result
	_apply_list(state, effects, db, result)
	state.clamp_resources()
	_announce_claim(state, result)
	return result


static func preview(effects: Array, db: ContentDB) -> String:
	var parts: PackedStringArray = []
	var remembered := false
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var op := str(effect.get("op", ""))
		match op:
			"gold":
				parts.append("Gold %s" % Balance.signed(int(effect.get("amount", 0))))
			"rations":
				parts.append("Rations %s" % Balance.signed(int(effect.get("amount", 0))))
			"forces":
				parts.append("Forces %s" % Balance.signed(int(effect.get("amount", 0))))
			"claim":
				parts.append("Claim %s" % Balance.signed(int(effect.get("amount", 0))))
			"fear":
				parts.append("Fear %s" % Balance.signed(int(effect.get("amount", 0))))
			"reputation":
				parts.append("Reputation %s" % Balance.signed(int(effect.get("amount", 0))))
			"stability":
				parts.append("Stability %s" % Balance.signed(int(effect.get("amount", 0))))
			"foreign":
				parts.append("Foreign pressure %s" % Balance.signed(int(effect.get("amount", 0))))
			"morale":
				parts.append("Morale %s" % Balance.signed(int(effect.get("amount", 0))))
			"political":
				var name := str(db.characters.get(str(effect.get("id", "")), {}).get("name", effect.get("id", "")))
				parts.append("%s's recognition %s" % [name, Balance.signed(int(effect.get("amount", 0)))])
			"house_opinion":
				var name := str(db.houses.get(str(effect.get("id", "")), {}).get("name", effect.get("id", "")))
				parts.append("%s %s" % [name, Balance.signed(int(effect.get("amount", 0)))])
			"bloc":
				parts.append("%s %s" % [Balance.bloc_title(str(effect.get("bloc", ""))), Balance.signed(int(effect.get("amount", 0)))])
			"relation":
				var who := str(db.characters.get(str(effect.get("id", "")), {}).get("name", effect.get("id", "")))
				parts.append("%s %s" % [who, Balance.signed(int(effect.get("amount", 0)))])
			"recruit":
				parts.append("Up to %d soldiers at %d gold each" % [int(effect.get("amount", 0)), int(effect.get("gold_each", 2))])
			"buy_rations":
				parts.append("Up to %d rations at %d gold each" % [int(effect.get("amount", 0)), int(effect.get("gold_each", 4))])
			"battle":
				parts.append("A battle follows")
			"chance", "assassinate":
				var pct := int(round(float(effect.get("p", effect.get("chance", 0.5))) * 100.0))
				parts.append("Uncertain (%d%%)" % pct)
			"ledger_add":
				var title := str(db.ledger.get(str(effect.get("id", "")), {}).get("title", "a document"))
				parts.append("Gain " + title)
			"defeat":
				parts.append("This can end your campaign")
			"flag", "clear_flag", "schedule", "chronicle", "kill", "capture", "memory", "promise", "clear_promise", "break_promise":
				remembered = true
			_:
				if op in ["territory", "house_declare", "elite_add", "prove_blood"]:
					remembered = true
	if remembered:
		parts.append("This will be remembered")
	return " · ".join(parts)


static func _apply_list(state: CampaignState, effects: Array, db: ContentDB, result: Dictionary) -> void:
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		if _apply_one(state, effect, db, result):
			return


static func _apply_one(state: CampaignState, effect: Dictionary, db: ContentDB, result: Dictionary) -> bool:
	var op := str(effect.get("op", ""))
	match op:
		"gold":
			state.gold += int(effect.get("amount", 0))
			_note(state, result, "Gold %s." % Balance.signed(int(effect.get("amount", 0))))
		"rations":
			state.rations += int(effect.get("amount", 0))
			_note(state, result, "Rations %s." % Balance.signed(int(effect.get("amount", 0))))
		"forces":
			state.forces += int(effect.get("amount", 0))
			_note(state, result, "Forces %s." % Balance.signed(int(effect.get("amount", 0))))
		"claim":
			state.claim += int(effect.get("amount", 0))
			_note(state, result, "Claim %s." % Balance.signed(int(effect.get("amount", 0))))
		"fear":
			state.fear += int(effect.get("amount", 0))
			_note(state, result, "Fear %s." % Balance.signed(int(effect.get("amount", 0))))
		"reputation":
			state.reputation += int(effect.get("amount", 0))
		"stability":
			state.stability += int(effect.get("amount", 0))
		"foreign":
			state.foreign += int(effect.get("amount", 0))
		"morale":
			state.army_morale += int(effect.get("amount", 0))
		"bloc":
			var bloc := str(effect.get("bloc", ""))
			if state.blocs.has(bloc):
				state.blocs[bloc] = int(state.blocs[bloc]) + int(effect.get("amount", 0))
				_note(state, result, "%s %s." % [Balance.bloc_title(bloc), Balance.signed(int(effect.get("amount", 0)))])
		"relation":
			_shift_relation(state, db, result, str(effect.get("id", "")), int(effect.get("amount", 0)), int(effect.get("political", 0)))
		"political":
			_shift_relation(state, db, result, str(effect.get("id", "")), 0, int(effect.get("amount", 0)))
		"memory":
			_append_npc_list(state, str(effect.get("id", "")), "memories", str(effect.get("text", "")))
		"grudge":
			_append_npc_list(state, str(effect.get("id", "")), "grudges", str(effect.get("text", "")))
		"promise":
			_append_npc_list(state, str(effect.get("id", "")), "promises", str(effect.get("text", "")))
			_note(state, result, "A promise is made.")
		"clear_promise":
			var id := str(effect.get("id", ""))
			var text := str(effect.get("text", ""))
			if state.npcs.has(id) and state.npcs[id]["promises"].has(text):
				state.npcs[id]["promises"].erase(text)
				_note(state, result, "You keep your word to %s." % str(db.characters.get(id, {}).get("name", id)))
		"break_promise":
			_break_promise(state, db, result, str(effect.get("id", "")), str(effect.get("text", "")))
		"flag":
			state.flags[str(effect.get("flag", ""))] = effect.get("value", true)
		"clear_flag":
			state.flags.erase(str(effect.get("flag", "")))
		"ledger_add":
			_ledger_add(state, db, result, str(effect.get("id", "")))
		"ledger_remove":
			state.remove_ledger(str(effect.get("id", "")))
		"grant_first_missing":
			_grant_first(state, db, result, effect.get("ids", []))
		"prove_blood":
			_prove_blood(state, db, result, effect)
		"territory":
			_set_territory(state, db, result, str(effect.get("id", "")), str(effect.get("controller", "player")))
		"loyalty":
			_shift_territory(state, str(effect.get("id", "")), "loyalty", int(effect.get("amount", 0)))
		"unrest":
			_shift_territory(state, str(effect.get("id", "")), "unrest", int(effect.get("amount", 0)))
		"fort":
			_shift_territory(state, str(effect.get("id", "")), "fort", int(effect.get("amount", 0)))
		"kill":
			_kill(state, db, result, str(effect.get("id", "")))
		"capture":
			_set_npc_mode(state, db, result, str(effect.get("id", "")), "captured", true)
		"free_npc":
			_set_npc_mode(state, db, result, str(effect.get("id", "")), "free", true)
		"npc_state":
			_set_npc_mode(state, db, result, str(effect.get("id", "")), str(effect.get("state", "free")), str(effect.get("state", "")) != "dead")
		"schedule":
			state.scheduled.append({"event": str(effect.get("event", "")), "delay": maxi(1, int(effect.get("delay", 1)))})
		"modifier":
			_add_modifier(state, effect)
			_note(state, result, str(effect.get("name", "A change")) + " takes hold.")
		"battle":
			return _battle(state, db, result, effect)
		"news":
			_note(state, result, str(effect.get("text", "")))
		"chronicle":
			_chronicle(state, db, result, str(effect.get("id", "")))
		"rival":
			_shift_rival(state, db, str(effect.get("id", "")), str(effect.get("field", "hostility")), int(effect.get("amount", 0)))
		"house_opinion":
			_shift_house(state, str(effect.get("id", "")), int(effect.get("amount", 0)))
		"house_declare":
			_declare_house(state, db, result, str(effect.get("id", "")), str(effect.get("declared", "player")))
		"elite_add":
			var elite := str(effect.get("id", ""))
			if elite != "" and not state.elites.has(elite):
				state.elites.append(elite)
				_note(state, result, str(db.units.get(elite, {}).get("name", elite)) + " will fight under your banner.")
		"elite_remove":
			state.elites.erase(str(effect.get("id", "")))
		"commander_add":
			var cid := str(effect.get("id", ""))
			if cid != "" and not state.commanders.has(cid):
				state.commanders.append(cid)
		"recruit":
			_recruit(state, result, int(effect.get("amount", 0)), int(effect.get("gold_each", 2)))
		"buy_rations":
			_buy(state, result, int(effect.get("amount", 0)), int(effect.get("gold_each", 4)))
		"chance":
			var roll := state.rng.randf()
			var chance := clampf(float(effect.get("p", 0.5)), 0.0, 1.0)
			if roll < chance:
				_note(state, result, str(effect.get("success_text", "Fortune favours the attempt.")))
				_apply_list(state, effect.get("success", []), db, result)
			else:
				_note(state, result, str(effect.get("fail_text", "The attempt fails.")))
				_apply_list(state, effect.get("fail", []), db, result)
		"assassinate":
			_assassinate(state, db, result, effect)
		"defeat":
			state.defeat_reason = str(effect.get("reason", "collapse"))
			result.defeat = state.defeat_reason
			_note(state, result, str(effect.get("text", "Your claim comes apart.")))
		_:
			_note(state, result, "")
	# A nested chance branch can open a battle or end the campaign.
	state.clamp_resources()
	return not result.battle.is_empty() or str(result.defeat) != ""


static func _battle(state: CampaignState, db: ContentDB, result: Dictionary, effect: Dictionary) -> bool:
	if state.forces < 40:
		_note(state, result, "You cannot put a host in the field.")
		_apply_list(state, effect.get("on_defeat", []), db, result)
		return false
	state.pending_battle = {
		"battle_id": str(effect.get("battle_id", "")),
		"on_victory": effect.get("on_victory", []),
		"on_defeat": effect.get("on_defeat", []),
		"on_retreat": effect.get("on_retreat", []),
	}
	result.battle = state.pending_battle.duplicate(true)
	_note(state, result, "Steel is drawn.")
	return true


static func _announce_claim(state: CampaignState, result: Dictionary) -> void:
	if state.claim >= 100 and not bool(state.flags.get("CLAIM_ANNOUNCED", false)):
		state.flags["CLAIM_ANNOUNCED"] = true
		_note(state, result, "Your claim is whole enough to attempt the throne.")


static func _note(state: CampaignState, result: Dictionary, line: String) -> void:
	if line.strip_edges() == "":
		return
	state.add_log(line)
	result.log.append(line)


static func _shift_relation(state: CampaignState, db: ContentDB, result: Dictionary, id: String, personal: int, political: int) -> void:
	if not state.npc_alive(id):
		return
	state.npcs[id]["personal"] = clampi(int(state.npcs[id]["personal"]) + personal, -100, 100)
	state.npcs[id]["political"] = clampi(int(state.npcs[id]["political"]) + political, -100, 100)
	if personal != 0:
		var name := str(db.characters.get(id, {}).get("name", id))
		_note(state, result, "%s %s." % [name, Balance.signed(personal)])


static func _append_npc_list(state: CampaignState, id: String, key: String, text: String) -> void:
	if text == "" or not state.npcs.has(id):
		return
	var items: Array = state.npcs[id][key]
	if not items.has(text):
		items.append(text)


static func _break_promise(state: CampaignState, db: ContentDB, result: Dictionary, id: String, text: String) -> void:
	if not state.npcs.has(id):
		return
	var promises: Array = state.npcs[id]["promises"]
	if text == "" and not promises.is_empty():
		text = str(promises[0])
	if text != "" and promises.has(text):
		promises.erase(text)
	if text != "":
		_append_npc_list(state, id, "broken", text)
	state.npcs[id]["personal"] = clampi(int(state.npcs[id]["personal"]) - 12, -100, 100)
	state.reputation -= 6
	var name := str(db.characters.get(id, {}).get("name", id))
	_note(state, result, "You break your word to %s." % name)


static func _ledger_add(state: CampaignState, db: ContentDB, result: Dictionary, id: String) -> void:
	if id == "" or not db.ledger.has(id):
		return
	if state.has_ledger(id) or state.ledger_archive.has(id):
		return
	state.ledger.append(id)
	_note(state, result, "Ledger: %s." % str(db.ledger[id].get("title", id)))


static func _grant_first(state: CampaignState, db: ContentDB, result: Dictionary, ids) -> void:
	if typeof(ids) != TYPE_ARRAY:
		return
	for raw in ids:
		var id := str(raw)
		if not state.has_ledger(id) and not state.ledger_archive.has(id):
			_ledger_add(state, db, result, id)
			return
	_note(state, result, "The archives yield nothing new.")


static func _prove_blood(state: CampaignState, db: ContentDB, result: Dictionary, effect: Dictionary) -> void:
	var ids = effect.get("ids", [])
	var need := int(effect.get("need", 2))
	var held := 0
	if typeof(ids) == TYPE_ARRAY:
		for raw in ids:
			if state.has_proof(str(raw)):
				held += 1
	if held < need:
		_note(state, result, "The proofs are too thin. You hold %d of %d." % [held, need])
		return
	if bool(state.flags.get("BLOOD_PROVEN", false)):
		_note(state, result, "The court has already heard this.")
		return
	state.flags["BLOOD_PROVEN"] = true
	state.claim += int(effect.get("claim", 12))
	state.blocs["nobility"] = int(state.blocs["nobility"]) + 8
	state.blocs["people"] = int(state.blocs["people"]) + 6
	_note(state, result, "Laid in order, the proofs change what Arlo is allowed to be.")
	_chronicle(state, db, result, "ab_legitimization")


static func _set_territory(state: CampaignState, db: ContentDB, result: Dictionary, id: String, controller: String) -> void:
	if not state.territories.has(id):
		return
	if controller == state.claimant_id:
		controller = "player"
	state.territories[id]["controller"] = controller
	var name := str(db.territories.get(id, {}).get("name", id))
	_note(state, result, "%s is now held by %s." % [name, db.controller_name(controller, state.claimant_id)])


static func _shift_territory(state: CampaignState, id: String, key: String, amount: int) -> void:
	if not state.territories.has(id):
		return
	var value := int(state.territories[id].get(key, 0)) + amount
	if key == "loyalty":
		value = clampi(value, 0, 100)
	else:
		value = maxi(0, value)
	state.territories[id][key] = value


static func _kill(state: CampaignState, db: ContentDB, result: Dictionary, id: String) -> void:
	if id == state.claimant_id:
		state.defeat_reason = "assassination"
		result.defeat = "assassination"
		_note(state, result, "You do not survive it.")
		return
	if not state.npcs.has(id):
		return
	if not state.npc_alive(id):
		return
	state.npcs[id]["alive"] = false
	state.npcs[id]["state"] = "dead"
	state.commanders.erase(id)
	if state.rivals.has(id):
		state.rivals[id]["alive"] = false
		state.rivals[id]["forces"] = 0
	var who: Dictionary = db.characters.get(id, {})
	var death_flag := str(who.get("death_flag", ""))
	if death_flag != "":
		state.flags[death_flag] = true
	var death_event := str(who.get("death_event", ""))
	if death_event != "" and db.events_by_id.has(death_event):
		state.scheduled.append({"event": death_event, "delay": 1})
	_note(state, result, "%s is dead." % str(who.get("name", id)))


static func _set_npc_mode(state: CampaignState, db: ContentDB, result: Dictionary, id: String, mode: String, alive: bool) -> void:
	if id == state.claimant_id and mode == "captured":
		state.defeat_reason = "captured"
		result.defeat = "captured"
		return
	if not state.npcs.has(id):
		return
	if not state.npc_alive(id) and alive:
		return
	state.npcs[id]["alive"] = alive
	state.npcs[id]["state"] = mode
	if not alive or mode != "free":
		state.commanders.erase(id)
	if state.rivals.has(id):
		state.rivals[id]["alive"] = alive
		if not alive:
			state.rivals[id]["forces"] = 0
	var name := str(db.characters.get(id, {}).get("name", id))
	_note(state, result, "%s is now %s." % [name, mode])


static func _add_modifier(state: CampaignState, effect: Dictionary) -> void:
	var id := str(effect.get("id", "mod"))
	var contrary := "eased_tax" if id == "harsh_tax" else ("harsh_tax" if id == "eased_tax" else "")
	state.modifiers = state.modifiers.filter(func(row): return str(row.get("id", "")) != id and (contrary == "" or str(row.get("id", "")) != contrary))
	state.modifiers.append({
		"id": id,
		"name": str(effect.get("name", id)),
		"turns": maxi(1, int(effect.get("turns", 3))),
		"gold": int(effect.get("gold", 0)),
		"rations": int(effect.get("rations", 0)),
		"claim": int(effect.get("claim", 0)),
		"fear": int(effect.get("fear", 0)),
		"morale": int(effect.get("morale", 0)),
		"blocs": effect.get("blocs", {}),
	})


static func _chronicle(state: CampaignState, db: ContentDB, result: Dictionary, id: String) -> void:
	if id == "":
		return
	if not state.chronicle_this_run.has(id):
		state.chronicle_this_run.append(id)
	var fresh: bool = MetaProgress.unlock(id)
	if fresh:
		_note(state, result, "Chronicle uncovered: %s." % db.chronicle_title(id))


static func _shift_rival(state: CampaignState, db: ContentDB, id: String, field: String, amount: int) -> void:
	if not state.rivals.has(id):
		return
	if field in ["gold", "rations", "forces", "claim", "fear", "hostility", "temper", "cooldown"]:
		state.rivals[id][field] = int(state.rivals[id][field]) + amount
		if field == "claim":
			state.rivals[id][field] = clampi(int(state.rivals[id][field]), 0, 100)
		if field == "hostility":
			state.rivals[id][field] = clampi(int(state.rivals[id][field]), 0, 100)
		if field in ["gold", "rations", "forces"]:
			state.rivals[id][field] = maxi(0, int(state.rivals[id][field]))


static func _shift_house(state: CampaignState, id: String, amount: int) -> void:
	if state.houses.has(id):
		state.houses[id]["opinion"] = clampi(int(state.houses[id]["opinion"]) + amount, -100, 100)


static func _declare_house(state: CampaignState, db: ContentDB, result: Dictionary, id: String, declared: String) -> void:
	if not state.houses.has(id):
		return
	if declared == state.claimant_id:
		declared = "player"
	state.houses[id]["declared"] = declared
	var leader := str(db.houses.get(id, {}).get("leader", ""))
	if declared == "player" and state.rivals.has(leader):
		state.rivals[leader]["hostility"] = mini(20, int(state.rivals[leader].get("hostility", 20)))
		state.flags["ALLY_" + leader.to_upper()] = true
	# A house's recognition must change the world, not just an invisible counter.
	for tid in state.territories:
		var controller := str(state.territories[tid].get("controller", ""))
		if str(db.territories.get(tid, {}).get("house", "")) == id and (controller == id or (declared == "player" and controller == leader and state.rivals.has(leader))):
			state.territories[tid]["controller"] = declared
			state.territories[tid]["loyalty"] = maxi(55, int(state.territories[tid].get("loyalty", 50)))
	var name := str(db.houses.get(id, {}).get("name", id))
	_note(state, result, "%s declares for %s." % [name, db.controller_name(declared, state.claimant_id)])


static func _recruit(state: CampaignState, result: Dictionary, amount: int, gold_each: int) -> void:
	if amount <= 0:
		return
	var price := maxi(1, gold_each)
	var affordable := int(state.gold / price)
	var gain := mini(amount, affordable)
	state.gold -= gain * price
	state.forces += gain
	_note(state, result, "Recruited %s soldiers." % Balance.comma(gain))


static func _buy(state: CampaignState, result: Dictionary, amount: int, gold_each: int) -> void:
	if amount <= 0:
		return
	var price := maxi(1, gold_each)
	var affordable := int(state.gold / price)
	var gain := mini(amount, affordable)
	state.gold -= gain * price
	state.rations += gain
	_note(state, result, "Bought %d rations." % gain)


static func _assassinate(state: CampaignState, db: ContentDB, result: Dictionary, effect: Dictionary) -> void:
	var chance := clampf(float(effect.get("chance", 0.35)), 0.0, 1.0)
	var target := str(effect.get("target", ""))
	var name := str(db.characters.get(target, {}).get("name", target))
	if state.rng.randf() < chance:
		_note(state, result, str(effect.get("success_text", "The blade finds %s." % name)))
		_apply_list(state, effect.get("success", []), db, result)
	else:
		_note(state, result, str(effect.get("fail_text", "The attempt on %s fails." % name)))
		_apply_list(state, effect.get("fail", []), db, result)
