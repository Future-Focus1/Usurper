class_name ActionBoard
extends RefCounted

## Builds the week's strategic actions from static data plus generators.


static func available(state: CampaignState, db: ContentDB) -> Array:
	var rows: Array = []
	for action in db.actions:
		if action.has("generator"):
			rows.append_array(_generate(action, state, db))
		elif _allowed(action, state, db):
			rows.append(action)
	rows.append_array(_ledger_plays(state, db))
	return rows.filter(func(action): return ConditionChecker.choice_failures(action, state, db).is_empty())


static func column(state: CampaignState, db: ContentDB, category: String) -> Array:
	var rows: Array = []
	for action in available(state, db):
		if str(action.get("category", "Personal")) == category:
			rows.append({"action": action, "open": true, "reason": ""})
	for action in db.actions:
		if str(action.get("category", "Personal")) != category:
			continue
		if not _for_claimant(action, state):
			continue
		var fails := ConditionChecker.failures(action.get("requires", {}), state, db)
		if fails.is_empty():
			continue
		if not _situation_allows(action, state, db):
			continue
		rows.append({
			"action": {
				"id": "locked_" + str(action.get("id", category)),
				"title": str(action.get("title", "Action")),
				"summary": str(action.get("summary", "")),
				"effects": [],
			},
			"open": false,
			"reason": str(fails[0]),
		})
	return rows


static func _situation_allows(action: Dictionary, state: CampaignState, db: ContentDB) -> bool:
	var requires = action.get("requires", {})
	if typeof(requires) != TYPE_DICTIONARY:
		return true
	var structural := {}
	for key in ["min_forces", "max_forces", "min_player_territories", "max_player_territories", "min_turn", "max_turn", "min_claim", "max_claim", "flags", "not_flags", "controls", "controls_any", "not_controls", "claimant", "not_claimant", "acts", "elite", "min_bloc", "max_bloc"]:
		if requires.has(key):
			structural[key] = requires[key]
	if structural.is_empty():
		return true
	return ConditionChecker.met(structural, state, db)


static func _for_claimant(action: Dictionary, state: CampaignState) -> bool:
	var claimants = action.get("claimants", [])
	if typeof(claimants) != TYPE_ARRAY or claimants.is_empty():
		return true
	for entry in claimants:
		if str(entry) == state.claimant_id:
			return true
	return false


static func _allowed(action: Dictionary, state: CampaignState, db: ContentDB) -> bool:
	if not _for_claimant(action, state):
		return false
	var id := str(action.get("id", ""))
	if id in ["spread_word", "spread_word_ethan", "appeal_people"] and state.claim >= 100 and int(state.blocs.get("people", 0)) >= 100:
		return false
	if id == "public_audience" and state.reputation >= 100 and int(state.blocs.get("people", 0)) >= 100:
		return false
	if id in ["train_forces", "address_troops"] and state.army_morale >= 100 and int(state.blocs.get("military", 0)) >= 100 and (id == "train_forces" or state.claim >= 100):
		return false
	if id in ["seek_flame", "seek_flame_ethan", "seek_flame_arlo"] and int(state.blocs.get("flame", 0)) >= 100 and int(state.npcs.get("aldren_veil", {}).get("personal", 0)) >= 100 and int(state.npcs.get("aldren_veil", {}).get("political", 0)) >= 100:
		return false
	if id == "summon_official" and state.claim >= 100 and int(state.blocs.get("court", 0)) >= 100 and int(state.npcs.get("lucan_rook", {}).get("personal", 0)) >= 100 and int(state.npcs.get("lucan_rook", {}).get("political", 0)) >= 100:
		return false
	for effect in action.get("effects", []):
		if str(effect.get("op", "")) == "grant_first_missing":
			var has_new := false
			for proof_id in effect.get("ids", []):
				if not state.has_ledger(str(proof_id)) and not state.ledger_archive.has(str(proof_id)):
					has_new = true
			if not has_new:
				return false
	return ConditionChecker.choice_failures(action, state, db).is_empty()


static func _generate(template: Dictionary, state: CampaignState, db: ContentDB) -> Array:
	var kind := str(template.get("generator", ""))
	match kind:
		"raid_territory":
			return _raid(template, state, db)
		"spy_rival":
			return _spy(template, state, db)
		"envoy_house":
			return _envoy(template, state, db)
		"assassinate_rival":
			return _assassinate(template, state, db)
		"fortify_territory":
			return _fortify(template, state, db)
		"occupy_territory":
			return _occupy(template, state, db)
		"charter_territory":
			return _charter(template, state, db)
		"reconcile_rival":
			return _reconcile(template, state, db)
		"prisoner_settlement":
			return _prisoners(template, state, db)
		_:
			return []


static func _raid(template: Dictionary, state: CampaignState, db: ContentDB) -> Array:
	if not _allowed(template, state, db):
		return []
	var rows: Array = []
	for tid in db.territory_order:
		var owner := str(state.territories[tid].get("controller", ""))
		if owner == "player":
			continue
		var name := str(db.territories[tid].get("name", tid))
		rows.append({
			"id": "raid_" + tid,
			"category": "Military",
			"title": "Raid %s" % name,
			"summary": "Strike %s for grain and coin. %s holds it now." % [name, db.controller_name(owner, state.claimant_id)],
			"requires": template.get("requires", {}),
			"effects": [
				{"op": "fear", "amount": 2},
				{"op": "battle", "battle_id": "raid_skirmish",
					"on_victory": [
						{"op": "gold", "amount": int(db.territories[tid].get("gold", 40)) + 40},
						{"op": "rations", "amount": 4},
						{"op": "loyalty", "id": tid, "amount": -12},
						{"op": "claim", "amount": 1},
					],
					"on_defeat": [{"op": "claim", "amount": -2}, {"op": "reputation", "amount": -3}],
					"on_retreat": [{"op": "fear", "amount": -1}],
				},
			],
		})
	return rows


static func _spy(template: Dictionary, state: CampaignState, db: ContentDB) -> Array:
	if not _allowed(template, state, db):
		return []
	var rows: Array = []
	for rid in state.rivals:
		if not bool(state.rivals[rid].get("alive", false)) or str(state.npcs.get(rid, {}).get("state", "free")) != "free":
			continue
		var name := str(db.claimants[rid].get("short", rid))
		rows.append({
			"id": "spy_" + rid,
			"category": "Intrigue",
			"title": "Spy on %s" % name,
			"summary": "Pay for eyes inside %s's camp. If they are caught, the story that comes back will be the one %s prefers." % [name, name],
			"requires": template.get("requires", {}),
			"effects": [
				{"op": "gold", "amount": -80 if state.claimant_id == "mira" else -120},
				{"op": "chance", "p": 0.72 if state.claimant_id == "mira" else 0.55,
					"success_text": "The report arrives sealed.",
					"fail_text": "Your agent is found. The story that returns is the one they wanted told.",
					"success": [
						{"op": "rival", "id": rid, "field": "hostility", "amount": 4},
						{"op": "news", "text": "Spies place %s's strength near %s soldiers." % [name, Balance.comma(int(state.rivals[rid].get("forces", 0)))]},
						{"op": "claim", "amount": 1},
					],
					"fail": [
						{"op": "rival", "id": rid, "field": "hostility", "amount": 10},
						{"op": "reputation", "amount": -2},
					],
				},
			],
		})
	return rows


static func _envoy(template: Dictionary, state: CampaignState, db: ContentDB) -> Array:
	if not _allowed(template, state, db):
		return []
	var rows: Array = []
	for hid in db.house_order:
		if str(state.houses[hid].get("declared", "")) == "player":
			continue
		var house: Dictionary = db.houses[hid]
		var name := str(house.get("name", hid))
		var leader := str(house.get("leader", ""))
		if leader != "" and (not state.npc_alive(leader) or str(state.npcs.get(leader, {}).get("state", "free")) != "free"):
			continue
		if state.rivals.has(leader) and (int(state.rivals[leader].get("hostility", 100)) >= 35 or int(state.npcs[leader].get("personal", 0)) < 35):
			continue
		if int(state.houses[hid].get("opinion", 0)) >= 25:
			rows.append({
				"id": "recognition_" + str(hid), "category": "Diplomacy",
				"title": "Accept %s's recognition" % name,
				"summary": "%s trusts your conduct. Confirm its local rights in exchange for a public oath and its unoccupied estates." % name,
				"requires": {"min_gold": 150, "house_opinion_min": {hid: 25}},
				"effects": [{"op": "gold", "amount": -150}, {"op": "house_declare", "id": hid}, {"op": "claim", "amount": 6}, {"op": "bloc", "bloc": "nobility", "amount": 5}, {"op": "stability", "amount": 4}, {"op": "flag", "flag": "RIGHTS_" + str(hid).to_upper()}],
			})
			continue
		rows.append({
			"id": "envoy_" + hid,
			"category": "Diplomacy",
			"title": "Envoy to %s" % name,
			"summary": "Ride to %s with a gift and ask where the house will stand." % name,
			"requires": {"min_gold": 150},
			"effects": [
				{"op": "gold", "amount": -150},
				{"op": "house_opinion", "id": hid, "amount": 8},
				{"op": "chance", "p": 0.45,
					"success_text": "%s receives you with more warmth than the gift deserved." % name,
					"fail_text": "%s keeps the gift and the old answer." % name,
					"success": [
						{"op": "house_opinion", "id": hid, "amount": 6},
						{"op": "bloc", "bloc": "nobility", "amount": 3},
						{"op": "flag", "flag": "ENVOY_" + hid.to_upper()},
					],
					"fail": [{"op": "news", "text": "%s delays." % name}],
				},
			],
		})
	return rows


static func _assassinate(template: Dictionary, state: CampaignState, db: ContentDB) -> Array:
	if not _allowed(template, state, db):
		return []
	var rows: Array = []
	for rid in state.rivals:
		if not bool(state.rivals[rid].get("alive", false)) or str(state.npcs.get(rid, {}).get("state", "free")) != "free":
			continue
		var name := str(db.claimants[rid].get("name", rid))
		rows.append({
			"id": "kill_" + rid,
			"category": "Intrigue",
			"title": "Attempt on %s" % name,
			"summary": "A knife is cheaper than a war and harder to wash off.",
			"requires": {"min_gold": 400},
			"effects": [
				{"op": "gold", "amount": -400},
				{"op": "fear", "amount": 6},
				{"op": "reputation", "amount": -8},
				{"op": "assassinate", "target": rid, "chance": 0.32,
					"success": [
						{"op": "kill", "id": rid},
						{"op": "claim", "amount": 6},
						{"op": "bloc", "bloc": "people", "amount": -8},
						{"op": "bloc", "bloc": "flame", "amount": -6},
						{"op": "flag", "flag": "ASSASSINATED_" + rid.to_upper()},
					],
					"fail": [
						{"op": "claim", "amount": -6},
						{"op": "rival", "id": rid, "field": "hostility", "amount": 20},
						{"op": "bloc", "bloc": "court", "amount": -6},
						{"op": "schedule", "event": "knife_in_yard", "delay": 2},
					],
				},
			],
		})
	return rows


static func _fortify(template: Dictionary, state: CampaignState, db: ContentDB) -> Array:
	if not _allowed(template, state, db):
		return []
	var rows: Array = []
	for tid in state.player_territories():
		if int(state.territories[tid].get("fort", 0)) >= 12:
			continue
		var name := str(db.territories[tid].get("name", tid))
		rows.append({
			"id": "fortify_" + tid,
			"category": "Military",
			"title": "Fortify %s" % name,
			"summary": "Walls, ditches, and a garrison that will still be here next month.",
			"requires": {"min_gold": 200},
			"effects": [
				{"op": "gold", "amount": -200},
				{"op": "fort", "id": tid, "amount": 2},
				{"op": "loyalty", "id": tid, "amount": 4},
				{"op": "bloc", "bloc": "military", "amount": 2},
			],
		})
	return rows


static func _occupy(template: Dictionary, state: CampaignState, db: ContentDB) -> Array:
	if state.claimant_id != "alistair" and int(state.blocs.get("military", 0)) < 40:
		return []
	if not _allowed(template, state, db):
		return []
	var rows: Array = []
	for tid in db.territory_order:
		var owner := str(state.territories[tid].get("controller", ""))
		if owner == "player":
			continue
		var name := str(db.territories[tid].get("name", tid))
		var effects: Array = [
			{"op": "fear", "amount": 4},
			{"op": "claim", "amount": 2},
			{"op": "bloc", "bloc": "military", "amount": 2},
			{"op": "bloc", "bloc": "people", "amount": -3},
		]
		if state.rivals.has(owner) and int(state.rivals[owner].get("forces", 0)) >= 500:
			effects.append({
				"op": "battle",
				"battle_id": "rival_" + owner,
				"on_victory": [
					{"op": "territory", "id": tid, "controller": "player"},
					{"op": "loyalty", "id": tid, "amount": -18},
					{"op": "claim", "amount": 3},
				],
				"on_defeat": [{"op": "claim", "amount": -4}],
				"on_retreat": [{"op": "fear", "amount": -2}],
			})
		else:
			effects.append({"op": "territory", "id": tid, "controller": "player"})
			effects.append({"op": "loyalty", "id": tid, "amount": -15})
		rows.append({
			"id": "occupy_" + tid,
			"category": "Military",
			"title": "Occupy %s" % name,
			"summary": "Plant banners and call it order. %s will call it something else." % db.controller_name(owner, state.claimant_id),
			"requires": {"min_forces": 800},
			"effects": effects,
		})
	return rows


static func _ledger_plays(state: CampaignState, db: ContentDB) -> Array:
	var rows: Array = []
	for id in state.ledger:
		var item: Dictionary = db.ledger.get(str(id), {})
		if item.is_empty():
			continue
		var title := str(item.get("title", id))
		var kind := str(item.get("kind", "secret"))
		if kind in ["secret", "evidence", "document"] and item.has("reveal"):
			var reveal_effects: Array = [
				{"op": "flag", "flag": "REVEALED_" + str(id).to_upper()},
				{"op": "ledger_remove", "id": str(id)},
			]
			reveal_effects.append_array(item.get("reveal", []))
			if not bool(state.flags.get("REVEALED_" + str(id).to_upper(), false)):
				rows.append(_play("reveal_" + str(id), "Intrigue", "Reveal: " + title, str(item.get("text", "")), reveal_effects, {"not_flags": ["REVEALED_" + str(id).to_upper()]}))
		if int(item.get("sell_gold", 0)) > 0:
			rows.append({
				"id": "sell_" + str(id),
				"category": "Intrigue",
				"title": "Sell: " + title,
				"summary": "A buyer in the riverside will pay and then own you a little.",
				"effects": [
					{"op": "gold", "amount": int(item.get("sell_gold", 0))},
					{"op": "ledger_remove", "id": str(id)},
					{"op": "reputation", "amount": -3},
					{"op": "news", "text": "A secret changes hands for coin."},
				],
			})
		if typeof(item.get("blackmail", null)) == TYPE_ARRAY:
			var target := str(item.get("target", ""))
			if not bool(state.flags.get("BLACKMAIL_" + str(id).to_upper(), false)) and (target == "" or (state.npc_alive(target) and str(state.npcs.get(target, {}).get("state", "free")) == "free")):
				var effects: Array = [{"op": "flag", "flag": "BLACKMAIL_" + str(id).to_upper()}]
				effects.append_array(item.get("blackmail", []))
				rows.append(_play(
					"blackmail_" + str(id),
					"Intrigue",
					"Blackmail with: " + title,
					"Use it once, quietly. They will remember the hand, not the words.",
					effects,
					{"not_flags": ["BLACKMAIL_" + str(id).to_upper()]},
				))
		if kind == "favour":
			var benefactor := str(item.get("target", ""))
			if benefactor != "" and not state.npc_alive(benefactor):
				continue
			var call_effects: Array = [{"op": "ledger_remove", "id": str(id)}]
			call_effects.append_array(item.get("call", []))
			rows.append({
				"id": "call_" + str(id),
				"category": "Diplomacy",
				"title": "Call in: " + title,
				"summary": str(item.get("text", "A favour is only real when it is spent.")),
				"effects": call_effects,
			})
		if kind in ["secret", "evidence", "document", "rumour"]:
			rows.append({
				"id": "destroy_" + str(id),
				"category": "Intrigue",
				"title": "Destroy: " + title,
				"summary": "Burn it. Some truths are more dangerous in your hands than in the fire.",
				"effects": [
					{"op": "ledger_remove", "id": str(id)},
					{"op": "news", "text": title + " is ash."},
				],
			})
	return rows


static func _charter(template: Dictionary, state: CampaignState, db: ContentDB) -> Array:
	if not _allowed(template, state, db):
		return []
	var rows: Array = []
	for tid in db.territory_order:
		if str(state.territories[tid].get("controller", "")) != "neutral":
			continue
		var name := str(db.territories[tid].get("name", tid))
		rows.append({
			"id": "charter_" + str(tid), "category": "Diplomacy", "title": "Charter for %s" % name,
			"summary": "Guarantee the councils of %s their local courts and pay for their roads. They will collect grain and taxes in your name; the lords will resent the precedent." % name,
			"requires": template.get("requires", {}),
			"effects": [{"op": "gold", "amount": -100}, {"op": "territory", "id": tid}, {"op": "loyalty", "id": tid, "amount": 12}, {"op": "unrest", "id": tid, "amount": -10}, {"op": "claim", "amount": 3}, {"op": "bloc", "bloc": "people", "amount": 3}, {"op": "bloc", "bloc": "nobility", "amount": -2}, {"op": "stability", "amount": 3}, {"op": "flag", "flag": "CHARTER_" + str(tid).to_upper()}],
		})
	return rows


static func _reconcile(template: Dictionary, state: CampaignState, db: ContentDB) -> Array:
	if not _allowed(template, state, db):
		return []
	var rows: Array = []
	for rid in state.rivals:
		if not state.npc_alive(rid) or str(state.npcs.get(rid, {}).get("state", "free")) != "free":
			continue
		if int(state.rivals[rid].get("hostility", 0)) <= 10 and int(state.npcs[rid].get("personal", 0)) >= 35:
			continue
		var name := str(db.claimants[rid].get("short", rid))
		rows.append({
			"id": "reconcile_" + str(rid), "category": "Diplomacy", "title": "Parley with %s" % name,
			"summary": "Offer safe passage, exchange prisoners and fund grain for %s's camp. Trust returns slowly. An army kept alive today may stand beside you tomorrow." % name,
			"requires": template.get("requires", {}),
			"effects": [{"op": "gold", "amount": -90}, {"op": "rations", "amount": -2}, {"op": "relation", "id": rid, "amount": 6, "political": 4}, {"op": "rival", "id": rid, "field": "hostility", "amount": -12}, {"op": "rival", "id": rid, "field": "rations", "amount": 2}, {"op": "stability", "amount": 3}, {"op": "fear", "amount": -1}, {"op": "flag", "flag": "PARLEY_" + str(rid).to_upper()}],
		})
	return rows


static func _prisoners(_template: Dictionary, state: CampaignState, db: ContentDB) -> Array:
	var rows: Array = []
	for id in db.character_order:
		if id == state.claimant_id or not state.npc_alive(id) or str(state.npcs[id].get("state", "")) != "captured":
			continue
		var name := str(db.characters[id].get("name", id))
		var condition := {"npc_alive": [id], "npc_state": {id: "captured"}}
		var release_condition: Dictionary = condition.duplicate(true)
		release_condition["min_gold"] = 30
		rows.append({
			"id": "release_" + str(id), "category": "Diplomacy", "title": "Release %s under oath" % name,
			"summary": "Pay for safe passage and record the terms before witnesses. The prisoner returns to public life; gratitude offers no guarantee against a renewed claim.",
			"requires": release_condition,
			"effects": [{"op": "gold", "amount": -30}, {"op": "free_npc", "id": id}, {"op": "relation", "id": id, "amount": 8, "political": 5}, {"op": "rival", "id": id, "field": "hostility", "amount": -20}, {"op": "reputation", "amount": 2}, {"op": "fear", "amount": -3}, {"op": "memory", "id": id, "text": "You released me under a witnessed oath."}],
		})
		rows.append({
			"id": "ransom_" + str(id), "category": "Economy", "title": "Ransom %s" % name,
			"summary": "The household pays to recover its own. Your treasury gains a purse and your reputation gains a price.",
			"requires": condition,
			"effects": [{"op": "gold", "amount": 150}, {"op": "free_npc", "id": id}, {"op": "relation", "id": id, "amount": -8, "political": -4}, {"op": "rival", "id": id, "field": "hostility", "amount": 10}, {"op": "reputation", "amount": -3}, {"op": "flag", "flag": "RANSOMED_" + str(id).to_upper()}],
		})
		rows.append({
			"id": "execute_" + str(id), "category": "Intrigue", "title": "Condemn %s" % name,
			"summary": "Use the power of confinement to impose a death sentence. Their household, the Flame and the public will remember that the verdict came from your seal.",
			"requires": condition,
			"effects": [{"op": "fear", "amount": 5}, {"op": "reputation", "amount": -8}, {"op": "bloc", "bloc": "people", "amount": -5}, {"op": "bloc", "bloc": "flame", "amount": -5}, {"op": "flag", "flag": "EXECUTED_" + str(id).to_upper()}, {"op": "kill", "id": id}],
		})
	for row in rows:
		row["effects"] = row["effects"].filter(func(effect): return str(effect.get("op", "")) != "rival" or state.rivals.has(str(effect.get("id", ""))))
	return rows


static func _play(id: String, category: String, title: String, summary: String, effects: Array, requires: Dictionary) -> Dictionary:
	return {
		"id": id,
		"category": category,
		"title": title,
		"summary": summary,
		"requires": requires,
		"effects": effects,
	}
