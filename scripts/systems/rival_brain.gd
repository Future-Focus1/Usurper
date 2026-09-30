class_name RivalBrain
extends RefCounted

## Abstract rival campaigns. They do not play every system. They act like people with habits.


static func act(state: CampaignState, db: ContentDB) -> Array:
	var lines: Array = []
	for rid in state.rivals.keys():
		lines.append_array(_one(str(rid), state, db))
	return lines


static func _one(id: String, state: CampaignState, db: ContentDB) -> Array:
	var lines: Array = []
	var rival: Dictionary = state.rivals[id]
	if not bool(rival.get("alive", false)):
		return lines
	if str(state.npcs.get(id, {}).get("state", "free")) != "free":
		return lines
	var bound_by_pact := bool(state.flags.get("COUNCIL_OF_FOUR", false))
	bound_by_pact = bound_by_pact or bool(state.flags.get("ALLY_" + id.to_upper(), false))
	bound_by_pact = bound_by_pact or (bool(state.flags.get("BROTHERS_PACT", false)) and id in ["ethan", "arlo"])
	bound_by_pact = bound_by_pact or (bool(state.flags.get("MARRIAGE_MIRA_ALISTAIR", false)) and id in ["mira", "alistair"])
	if bound_by_pact or bool(state.flags.get("MARRIED_" + id.to_upper(), false)):
		rival["hostility"] = mini(25, int(rival.get("hostility", 25)))
	var name := str(db.claimants[id].get("short", id))
	var need := Balance.ration_need(int(rival.get("forces", 0)))
	if int(rival.get("rations", 0)) >= need:
		rival["rations"] = int(rival["rations"]) - need
	else:
		var loss := int(int(rival.get("forces", 0)) * 0.1)
		rival["forces"] = maxi(0, int(rival["forces"]) - loss)
		rival["rations"] = 0
		if loss > 0:
			lines.append("%s's host goes hungry and sheds soldiers." % name)
	var upkeep := Balance.gold_upkeep(int(rival.get("forces", 0)))
	rival["gold"] = maxi(0, int(rival.get("gold", 0)) - upkeep)
	var lands := _lands(id, state)
	rival["gold"] = int(rival["gold"]) + 40 + lands * 50
	rival["rations"] = int(rival["rations"]) + 3 + lands * 3
	if bound_by_pact:
		if state.turn % 4 == 0:
			state.stability += 1
			lines.append("%s honours the compact: the shared road remains open." % name)
		return lines
	if int(rival.get("cooldown", 0)) > 0:
		rival["cooldown"] = int(rival["cooldown"]) - 1
	_drift(id, rival, name, lines)
	if int(rival.get("rations", 0)) < need:
		rival["gold"] = maxi(0, int(rival["gold"]) - 80)
		rival["rations"] = int(rival["rations"]) + 6
		lines.append("%s buys grain at a bad price rather than watch the host thin." % name)
		return lines
	var choice := _choose(rival, state)
	match choice:
		"recruit":
			var gain := mini(360, int(int(rival["gold"]) / 2))
			if gain > 40:
				rival["gold"] = int(rival["gold"]) - gain * 2
				rival["forces"] = int(rival["forces"]) + gain
				lines.append("%s raises more soldiers. The count is now near %s." % [name, Balance.comma(int(rival["forces"]))])
		"scandal":
			state.claim = clampi(state.claim - 1, 0, 100)
			rival["claim"] = clampi(int(rival["claim"]) + 1, 0, 100)
			lines.append("A rumour useful to %s moves through the court." % name)
		"speech":
			state.blocs["people"] = clampi(int(state.blocs["people"]) - 1, -100, 100)
			rival["claim"] = clampi(int(rival["claim"]) + 2, 0, 100)
			lines.append("%s is being spoken of in markets as if the past were a promise." % name)
		"investigate":
			rival["claim"] = clampi(int(rival["claim"]) + 2, 0, 100)
			lines.append("%s is asking questions about Erol that will not stay private." % name)
		"sway":
			lines.append(_sway(id, rival, name, state, db))
		"march":
			lines.append(_march(id, rival, name, state, db))
		"tax":
			rival["gold"] = int(rival["gold"]) + 90
			lines.append("%s squeezes the lands already in hand." % name)
		"offer":
			rival["hostility"] = clampi(int(rival["hostility"]) - 5, 0, 100)
			if state.npcs.has(id):
				state.npcs[id]["political"] = clampi(int(state.npcs[id]["political"]) + 3, -100, 100)
			lines.append("A careful letter arrives from %s. It is not quite peace." % name)
		_:
			lines.append("%s spends the week watching." % name)
	if int(rival.get("claim", 0)) >= 100 and not bool(rival.get("bid", false)):
		rival["bid"] = true
		state.flags["BID_" + id.to_upper()] = true
		var bid := "bid_" + id
		if db.events_by_id.has(bid):
			state.forced_events.append(bid)
		lines.append("%s is ready to try for the crown." % name)
	return lines


static func _drift(id: String, rival: Dictionary, name: String, lines: Array) -> void:
	var strategy := str(rival.get("strategy", "mixed"))
	if strategy == "military" and int(rival.get("forces", 0)) < 450:
		rival["temper"] = int(rival.get("temper", 0)) + 1
		if int(rival["temper"]) >= 3:
			rival["strategy"] = "intrigue"
			rival["temper"] = 0
			lines.append("%s stops threatening marches and starts buying friends." % name)
	elif strategy == "popular" and int(rival.get("hostility", 0)) >= 78:
		rival["strategy"] = "military"
		lines.append("%s is done asking. The old reputation is being hammered into a weapon." % name)
	elif strategy == "investigate" and int(rival.get("claim", 0)) >= 42:
		rival["strategy"] = "popular"
		lines.append("What %s found is now being told in the open." % name)
	elif id == "mira" and strategy == "intrigue" and int(rival.get("hostility", 0)) >= 80:
		rival["temper"] = int(rival.get("temper", 0)) + 1


static func _choose(rival: Dictionary, state: CampaignState) -> String:
	var strategy := str(rival.get("strategy", "mixed"))
	var bag: Array = []
	match strategy:
		"intrigue":
			bag = [["scandal", 4], ["sway", 3], ["recruit", 2], ["tax", 2], ["offer", 1]]
		"popular":
			bag = [["speech", 4], ["sway", 2], ["recruit", 2], ["investigate", 1]]
		"investigate":
			bag = [["investigate", 4], ["sway", 3], ["speech", 2], ["offer", 1]]
		"military":
			bag = [["march", 4], ["recruit", 3], ["sway", 2], ["tax", 2], ["scandal", 1]]
		_:
			bag = [["recruit", 2], ["sway", 2], ["tax", 2], ["speech", 1]]
	if int(rival.get("gold", 0)) < 200:
		bag = bag.filter(func(row): return row[0] != "recruit")
	if int(rival.get("cooldown", 0)) > 0 or int(rival.get("hostility", 0)) < 28 or int(rival.get("forces", 0)) < 700:
		bag = bag.filter(func(row): return row[0] != "march")
	if bag.is_empty():
		return "tax"
	var total := 0
	for row in bag:
		total += int(row[1])
	var roll := state.rng.randi_range(1, maxi(1, total))
	var cursor := 0
	for row in bag:
		cursor += int(row[1])
		if roll <= cursor:
			return str(row[0])
	return str(bag[0][0])


static func _lands(id: String, state: CampaignState) -> int:
	var count := 0
	for tid in state.territories:
		if str(state.territories[tid].get("controller", "")) == id:
			count += 1
	return count


static func _sway(id: String, rival: Dictionary, name: String, state: CampaignState, db: ContentDB) -> String:
	var options: Array = []
	for tid in state.territories:
		var owner := str(state.territories[tid].get("controller", ""))
		if owner == id or owner == "player":
			continue
		if owner == "neutral" or db.houses.has(owner):
			options.append(tid)
	if options.is_empty():
		return "%s finds no lord willing to move this week." % name
	var tid := str(options[state.rng.randi_range(0, options.size() - 1)])
	var chance := 0.22 + float(int(rival.get("claim", 0))) / 350.0
	var house_id := str(db.territories[tid].get("house", ""))
	if house_id != "" and str(state.houses.get(house_id, {}).get("declared", "")) == "player":
		return "%s's overture to %s is rejected: the house keeps its oath to you." % [name, db.territories[tid].get("name", tid)]
	if state.rng.randf() > chance:
		return "%s courts %s and is told to wait." % [name, db.territories[tid].get("name", tid)]
	state.territories[tid]["controller"] = id
	state.territories[tid]["loyalty"] = clampi(int(state.territories[tid]["loyalty"]) - 8, 0, 100)
	return "%s gains %s without a battle." % [name, db.territories[tid].get("name", tid)]


static func _march(id: String, rival: Dictionary, name: String, state: CampaignState, db: ContentDB) -> String:
	rival["cooldown"] = 6
	rival["hostility"] = clampi(int(rival.get("hostility", 0)) + 6, 0, 100)
	var event_id := "clash_" + id
	if db.events_by_id.has(event_id) and not state.forced_events.has(event_id):
		state.forced_events.append(event_id)
		state.flags["CLASH_" + id.to_upper()] = true
	return "%s's banners are on the road. A clash is coming." % name
