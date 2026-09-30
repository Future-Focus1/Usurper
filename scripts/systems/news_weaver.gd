class_name NewsWeaver
extends RefCounted


static func ambient(state: CampaignState, db: ContentDB) -> Array:
	var lines: Array = []
	var pool: Array = []
	for rumour in db.rumours:
		if typeof(rumour) != TYPE_DICTIONARY:
			continue
		if ConditionChecker.met(rumour.get("requires", {}), state, db):
			pool.append(str(rumour.get("text", "")))
	_shuffle(pool, state.rng)
	for text in pool:
		if lines.size() >= 2:
			break
		if text != "":
			lines.append(text)
	if state.foreign >= 8:
		lines.append("Merchants from Varos are pricing grain as if Nezrel will not finish the year intact.")
	if state.fear >= 55:
		lines.append("People lower their eyes when your name is spoken, and then they speak it anyway.")
	var strongest := ""
	var best := -1
	for rid in state.rivals:
		if not bool(state.rivals[rid].get("alive", false)):
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
