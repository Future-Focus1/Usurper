class_name NewsWeaver
extends RefCounted


static func ambient(state: CampaignState, db: ContentDB) -> Array:
	var lines: Array = []
	var pool: Array = []
	for rumour in db.rumours:
		if typeof(rumour) != TYPE_DICTIONARY:
			continue
		if ConditionChecker.met(rumour.get("requires", {}), state, db):
			var text := str(rumour.get("text", ""))
			if not state.news.has(text):
				pool.append(text)
	_shuffle(pool, state.rng)
	for text in pool:
		if lines.size() >= 2:
			break
		if text != "":
			lines.append(text)
			state.news.append(text)
			while state.news.size() > 8:
				state.news.pop_front()
	if state.foreign >= 8:
		lines.append("Merchants from Varos are pricing grain as if Nezrel will not finish the year intact.")
	if state.fear >= 55:
		lines.append("People lower their eyes when your name is spoken, and then they speak it anyway.")
	var strongest := ""
	var best := -1
	for rid in state.rivals:
		if not bool(state.rivals[rid].get("alive", false)) or str(state.npcs.get(rid, {}).get("state", "free")) != "free":
			continue
		var claim := int(state.rivals[rid].get("claim", 0))
		if claim > best:
			best = claim
			strongest = str(db.claimants[rid].get("short", rid))
	if strongest != "" and best > state.claim:
		lines.append("%s's claim is being repeated in rooms that used to wait on yours." % strongest)
	return lines.slice(0, mini(3, lines.size()))


static func _shuffle(rows: Array, rng: RandomNumberGenerator) -> void:
	for index in range(rows.size() - 1, 0, -1):
		var swap := rng.randi_range(0, index)
		var tmp = rows[index]
		rows[index] = rows[swap]
		rows[swap] = tmp
