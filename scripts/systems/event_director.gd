class_name EventDirector
extends RefCounted

## Picks the week's audience from data. Forced consequences lead. Quiet weeks are the fallback.


static func pick_audience(state: CampaignState, db: ContentDB) -> Array:
	var chosen: Array = []
	var forced := _take_forced(state, db)
	var pool := _available(state, db)
	var high: Array = []
	var consequences: Array = []
	var normal: Array = []
	for event in pool:
		if _contains(forced, event) or _contains(chosen, event):
			continue
		var priority := int(event.get("priority", 0))
		if priority >= 90:
			high.append(event)
		elif priority >= 70:
			consequences.append(event)
		else:
			normal.append(event)
	if not high.is_empty():
		high.sort_custom(func(a, b): return int(a.get("priority", 0)) > int(b.get("priority", 0)))
		for event in forced:
			if chosen.size() >= 1:
				break
			chosen.append(event)
		for event in high:
			if chosen.size() >= 3:
				break
			if _contains(chosen, event):
				continue
			chosen.append(event)
	else:
		for event in forced:
			if chosen.size() >= 3:
				break
			chosen.append(event)
		consequences.sort_custom(func(a, b): return int(a.get("priority", 0)) > int(b.get("priority", 0)))
		for event in consequences:
			if chosen.size() >= 3:
				break
			chosen.append(event)
		while chosen.size() < 3 and not normal.is_empty():
			var pick := _weighted(normal, state)
			chosen.append(pick)
			normal.erase(pick)
	if chosen.is_empty():
		var fallback: Dictionary = db.event_by_id("quiet_week")
		if not fallback.is_empty():
			chosen.append(fallback)
	state.event_queue = []
	for event in chosen:
		var id := str(event.get("id", ""))
		state.event_queue.append(id)
		state.seen_events[id] = int(state.seen_events.get(id, 0)) + 1
	state.event_index = 0
	return chosen


static func current(state: CampaignState, db: ContentDB) -> Dictionary:
	if state.event_index < 0 or state.event_index >= state.event_queue.size():
		return {}
	return db.event_by_id(str(state.event_queue[state.event_index]))


static func _take_forced(state: CampaignState, db: ContentDB) -> Array:
	var found: Array = []
	var pending: Array = state.forced_events.duplicate()
	state.forced_events.clear()
	for raw in pending:
		var event := db.event_by_id(str(raw))
		if event.is_empty():
			continue
		var id := str(event.get("id", ""))
		if bool(event.get("one_time", true)) and int(state.seen_events.get(id, 0)) > 0:
			continue
		found.append(event)
	return found


static func _available(state: CampaignState, db: ContentDB) -> Array:
	var pool: Array = []
	for event in db.events:
		if bool(event.get("fallback", false)):
			continue
		var id := str(event.get("id", ""))
		if bool(event.get("one_time", true)) and int(state.seen_events.get(id, 0)) > 0:
			continue
		if not ConditionChecker.met(event.get("requires", {}), state, db):
			continue
		pool.append(event)
	return pool


static func _contains(rows: Array, event: Dictionary) -> bool:
	var id := str(event.get("id", ""))
	for row in rows:
		if str(row.get("id", "")) == id:
			return true
	return false


static func _weighted(pool: Array, state: CampaignState) -> Dictionary:
	var total := 0
	var weights: Array = []
	for event in pool:
		var weight := _boost(event, state)
		weights.append(weight)
		total += weight
	var roll := state.rng.randi_range(1, maxi(1, total))
	var cursor := 0
	for index in pool.size():
		cursor += int(weights[index])
		if roll <= cursor:
			return pool[index]
	return pool[0]


static func _boost(event: Dictionary, state: CampaignState) -> int:
	var weight := maxi(1, int(event.get("weight", 10)))
	var tags = event.get("tags", [])
	if typeof(tags) != TYPE_ARRAY:
		return weight
	if state.rations < Balance.ration_need(state.forces) * 2 and tags.has("food"):
		weight *= 3
	if state.fear >= 50 and tags.has("fear"):
		weight *= 2
	if state.foreign >= 10 and tags.has("foreign"):
		weight *= 3
	if state.forces >= 2500 and tags.has("army"):
		weight *= 2
	return weight
