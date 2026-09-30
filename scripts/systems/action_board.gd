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
	return rows


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
	return ConditionChecker.met(action.get("requires", {}), state, db)


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
		if not bool(state.rivals[rid].get("alive", false)):
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
		if not bool(state.rivals[rid].get("alive", false)):
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
			if target == "" or state.npc_alive(target):
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


static func _play(id: String, category: String, title: String, summary: String, effects: Array, requires: Dictionary) -> Dictionary:
	return {
		"id": id,
		"category": category,
		"title": title,
		"summary": summary,
		"requires": requires,
		"effects": effects,
	}
