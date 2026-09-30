class_name EndingDirector
extends RefCounted

## Endings are assembled from the method, the rivals, the kingdom, and the people who lived.


static func list_routes(state: CampaignState, db: ContentDB) -> Array:
	var rows: Array = []
	for route in db.routes:
		var open := ConditionChecker.met(route.get("requires", {}), state, db)
		var reason := ""
		if not open:
			reason = "\n".join(ConditionChecker.failures(route.get("requires", {}), state, db))
		rows.append({"route": route, "open": open, "reason": reason})
	return rows


static func resolve(state: CampaignState, db: ContentDB, route_id: String, battle_result: Dictionary = {}, force_band := "") -> Dictionary:
	var route := _route(db, route_id)
	var band := force_band if force_band != "" else _band(state, route, battle_result)
	var victory := band in ["triumph", "brittle", "pyrrhic"]
	var kingdom := _kingdom(state)
	var legacy := _legacy(state, victory)
	var paragraphs: Array = []
	paragraphs.append(_method_text(route, band, state, db))
	paragraphs.append(kingdom["text"])
	paragraphs.append(legacy["text"])
	for line in _rival_lines(state, db, band, victory):
		paragraphs.append(line)
	for line in _npc_lines(state, db):
		paragraphs.append(line)
	if state.broken_promise_count() > 0:
		paragraphs.append("Broken promises outlived the coronation. %d of them are still being counted by people who do not forget." % state.broken_promise_count())
	var title := str(route.get("title", "The Crown"))
	if not victory:
		title = str(route.get("failure_title", "The Crown Refuses"))
	return {
		"title": title,
		"subtitle": "%s — %s" % [str(route.get("method", title)), legacy["name"]],
		"paragraphs": paragraphs,
		"legacy": legacy["name"],
		"kingdom": kingdom["name"],
		"method": str(route.get("method", route_id)),
		"band": band,
		"defeat": not victory,
		"ending_id": "%s_%s" % [route_id, band],
		"chronicle": route.get("chronicle", []),
	}


static func resolve_defeat(state: CampaignState, db: ContentDB, reason: String) -> Dictionary:
	var table: Dictionary = db.defeats.get(reason, {})
	var specific: Dictionary = table.get(state.claimant_id, table.get("default", {}))
	var title := str(specific.get("title", "The Claim Ends"))
	var lead := str(specific.get("text", "Nezrel continues without you."))
	var paragraphs: Array = [lead, _kingdom(state)["text"]]
	var legacy := _legacy(state, false)
	paragraphs.append(legacy["text"])
	for line in _npc_lines(state, db):
		paragraphs.append(line)
	return {
		"title": title,
		"subtitle": legacy["name"],
		"paragraphs": paragraphs,
		"legacy": legacy["name"],
		"kingdom": _kingdom(state)["name"],
		"method": reason,
		"band": "defeat",
		"defeat": true,
		"ending_id": "defeat_%s_%s" % [reason, state.claimant_id],
		"chronicle": [],
	}


static func _route(db: ContentDB, route_id: String) -> Dictionary:
	for route in db.routes:
		if str(route.get("id", "")) == route_id:
			return route
	return {"id": route_id, "title": "The Throne", "method": "Improvised", "difficulty": 60, "prose": {}}


static func _band(state: CampaignState, route: Dictionary, battle_result: Dictionary) -> String:
	var score := float(state.claim) * 0.34
	score += float(state.stability) * 0.28
	score += float(state.player_territories().size()) * 3.0
	score -= float(state.fear) * 0.14
	score -= float(state.broken_promise_count()) * 4.0
	score -= float(state.foreign) * 0.45
	var support := 0
	for bloc in Balance.BLOCS:
		support += int(state.blocs.get(bloc, 0))
	score += float(support) * 0.1
	var hostile := 0
	for id in state.rivals:
		if bool(state.rivals[id].get("alive", false)) and int(state.rivals[id].get("hostility", 0)) >= 55:
			hostile += 1
	score -= float(hostile) * 7.0
	if not battle_result.is_empty():
		match str(battle_result.get("outcome", "")):
			"victory":
				score += 18.0
			"defeat":
				score -= 30.0
			"retreat":
				score -= 10.0
	var margin := score - float(int(route.get("difficulty", 58)))
	if margin >= 28.0:
		return "triumph"
	if margin >= 8.0:
		return "brittle"
	if margin >= -10.0:
		return "pyrrhic"
	if margin >= -30.0:
		return "failure"
	return "disaster"


static func _method_text(route: Dictionary, band: String, state: CampaignState, db: ContentDB) -> String:
	var prose: Dictionary = route.get("prose", {})
	if prose.has(band):
		return str(prose[band])
	var name := str(db.claimants.get(state.claimant_id, {}).get("name", "The claimant"))
	return "%s reaches for the crown by %s, and the realm answers with %s." % [name, str(route.get("method", "force")), band]


static func _kingdom(state: CampaignState) -> Dictionary:
	if state.stability >= 70 and state.rations > 8 and state.foreign < 16 and state.fear < 50:
		return {"name": "Prosperous", "text": "Nezrel eats. The roads are not safe, but they are used. For a little while the kingdom looks like a place that expects a next year."}
	if state.rations <= 0 or bool(state.flags.get("STARVING", false)):
		return {"name": "Starving", "text": "The crown is a story people tell while they count grain. Hunger does more ruling than the throne."}
	if state.foreign >= 26:
		return {"name": "Under Shadow", "text": "Varos and the border wolves have learned the price of Nezrel's attention. Foreign coin sits in too many purses."}
	if state.fear >= 72:
		return {"name": "Rebellious", "text": "Order holds where soldiers stand and nowhere else. Plots replace petitions."}
	if state.stability >= 52:
		return {"name": "Stable", "text": "The kingdom is bruised and governed. Most people can say whose law they live under."}
	if state.stability >= 36:
		return {"name": "Recovering", "text": "Nezrel is not at peace. It is, carefully, still one kingdom."}
	return {"name": "War-torn", "text": "Fields are camps. The river roads belong to whoever reached them last. The crown is a claim, not a shelter."}


static func _legacy(state: CampaignState, victory: bool) -> Dictionary:
	var people := int(state.blocs.get("people", 0))
	var nobles := int(state.blocs.get("nobility", 0))
	var flame := int(state.blocs.get("flame", 0))
	var military := int(state.blocs.get("military", 0))
	var name := "Controversial"
	var text := "History will argue about you, which is a kind of survival."
	if not victory and state.claim < 25:
		name = "Forgotten"
		text = "Your name becomes a caution told badly in kitchens, then not told at all."
	elif people >= 55 and state.fear < 36 and state.reputation > 8:
		name = "Beloved"
		text = "People speak your name without checking who is listening. That is rarer than a crown."
	elif state.fear >= 62:
		name = "Feared"
		text = "They will obey. They will not mourn. Fear kept the peace you were willing to buy."
	elif state.broken_promise_count() >= 3:
		name = "Despised"
		text = "Every oath you broke found a witness. The reign, if it lasts, lasts inside a reputation that rots."
	elif nobles >= 40 and int(state.blocs.get("court", 0)) >= 15:
		name = "Respected"
		text = "The lords will not love you. Enough of them will stand when your name is read."
	elif people >= 35 and military >= 25 and state.claim >= 70:
		name = "Legendary"
		text = "The story grows cleaner than the weeks that made it. You become the ruler the songs can stand."
	elif not victory:
		name = "Tragic"
		text = "You are remembered for how close the crown came, and for what it cost to reach."
	elif state.fear < 20 and people < 15 and nobles < 15:
		name = "Weak"
		text = "You wear the crown like a borrowed coat. Everyone can see the sleeves."
	else:
		name = "Mysterious"
		text = "The chronicle will not agree on what you wanted. It will agree that you took the chance."
	if flame >= 50 and name == "Beloved":
		text += " The Flame calls you Keeper of the Hearth without choking on the words."
	return {"name": name, "text": "Legacy: %s. %s" % [name, text]}


static func _rival_lines(state: CampaignState, db: ContentDB, band: String, victory: bool) -> Array:
	var lines: Array = []
	for id in state.rivals:
		var rival: Dictionary = state.rivals[id]
		var full := str(db.claimants.get(id, {}).get("name", id))
		var personal := int(state.npcs.get(id, {}).get("personal", 0))
		if not bool(rival.get("alive", false)) or (state.npcs.has(id) and not bool(state.npcs[id].get("alive", true))):
			lines.append("%s is dead. The claim they carried is a story other people will try to inherit." % full)
			continue
		var married := bool(state.flags.get("MARRIED_" + id.to_upper(), false))
		var fate := "missing"
		if married:
			fate = "bound to you by marriage"
		elif str(state.npcs.get(id, {}).get("state", "")) == "captured" or bool(state.flags.get("IMPRISONED_" + id.to_upper(), false)):
			fate = "imprisoned"
		elif personal >= 35 and int(rival.get("hostility", 100)) < 40:
			fate = "kept close, a rival turned servant of the reign"
		elif int(rival.get("hostility", 0)) >= 65 and victory and state.fear >= 48:
			fate = "executed so the reign can sleep"
		elif int(rival.get("hostility", 0)) >= 65 and victory:
			fate = "exiled beyond the border they once threatened to cross"
		elif int(rival.get("hostility", 0)) >= 40:
			fate = "still in the field, a rebel with a familiar face"
		elif victory and state.reputation >= 0:
			fate = "pardoned, which is not the same as trusted"
		else:
			fate = "gone from court, alive somewhere the chronicle cannot yet see"
		if not victory and int(rival.get("hostility", 0)) >= 40:
			fate = "among those who pick through what you dropped"
		lines.append("%s is %s." % [full, fate])
		if band == "disaster" and int(rival.get("claim", 0)) > state.claim:
			lines.append("Already the streets are trying %s's title in a whisper." % str(db.claimants[id].get("short", id)))
	return lines


static func _npc_lines(state: CampaignState, db: ContentDB) -> Array:
	var lines: Array = []
	var important := ["garran_vale", "celene_veyne", "oren_pell", "nessa_grey", "bren_tal", "tomas_maren", "evelyne_maren", "edric_edevane", "aldren_veil", "osric_harrow", "lucan_rook"]
	for id in important:
		if not db.characters.has(id) or not state.npcs.has(id):
			continue
		var who: Dictionary = db.characters[id]
		var row: Dictionary = state.npcs[id]
		var epilogue: Dictionary = who.get("epilogue", {})
		var key := "cold"
		if not bool(row.get("alive", false)):
			key = "dead"
		elif str(row.get("state", "")) == "missing":
			key = "missing"
		elif str(row.get("state", "")) == "captured":
			key = "captured"
		elif int(row.get("personal", 0)) >= 55:
			key = "loyal"
		elif int(row.get("personal", 0)) >= 15:
			key = "warm"
		var line := str(epilogue.get(key, ""))
		if line == "":
			continue
		lines.append(line)
	return lines
