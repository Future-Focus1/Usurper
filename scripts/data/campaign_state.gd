class_name CampaignState
extends RefCounted

## Mutable campaign. Static lore stays in ContentDB. This object is what saves.

var version := 2
var campaign_id := ""
var ending_data := {}
var claimant_id := ""
var turn := 1
var gold := 0
var rations := 0
var forces := 0
var claim := 0
var fear := 0
var reputation := 0
var stability := 50
var foreign := 0
var army_morale := 68
var blocs := {"nobility": 0, "people": 0, "flame": 0, "military": 0, "court": 0}
var flags := {}
var news: Array = []
var log: Array = []
var week_report: Array = []
var week_title := ""
var banner := ""
var territories := {}
var npcs := {}
var rivals := {}
var ledger: Array = []
var ledger_archive: Array = []
var houses := {}
var elites: Array = []
var commanders: Array = []
var wounded := {}
var scheduled: Array = []
var modifiers: Array = []
var forced_events: Array = []
var seen_events := {}
var event_queue: Array = []
var event_index := 0
var phase := "overview"
var action_taken := ""
var pending_battle := {}
var pending_throne_route := ""
var post_battle := ""
var defeat_reason := ""
var location := ""
var decisions: Array = []
var chronicle_this_run: Array = []
var last_battle := {}
var rng := RandomNumberGenerator.new()


func setup(id: String, db: ContentDB) -> void:
	version = 2
	ending_data = {}
	news = []
	log = []
	ledger_archive = []
	wounded = {}
	scheduled = []
	modifiers = []
	forced_events = []
	seen_events = {}
	event_queue = []
	event_index = 0
	action_taken = ""
	pending_battle = {}
	pending_throne_route = ""
	post_battle = ""
	defeat_reason = ""
	banner = ""
	decisions = []
	chronicle_this_run = []
	last_battle = {}
	claimant_id = id
	var claimant: Dictionary = db.claimants[id]
	var start: Dictionary = claimant.get("start", {})
	turn = 1
	gold = int(start.get("gold", 0))
	rations = int(start.get("rations", 0))
	forces = int(start.get("forces", 0))
	claim = int(start.get("claim", 0))
	fear = int(start.get("fear", 0))
	reputation = int(start.get("reputation", 0))
	stability = int(start.get("stability", 50))
	foreign = int(start.get("foreign", 2))
	army_morale = int(start.get("morale", 68))
	location = str(start.get("location", ""))
	phase = "overview"
	blocs = {"nobility": 0, "people": 0, "flame": 0, "military": 0, "court": 0}
	for key in start.get("blocs", {}):
		blocs[str(key)] = int(start["blocs"][key])
	flags = {}
	for key in start.get("flags", {}):
		flags[str(key)] = bool(start["flags"][key])
	_copy_world(db)
	for tid in start.get("territories", []):
		var key := str(tid)
		if territories.has(key):
			territories[key]["controller"] = "player"
	_copy_people(db, start)
	ledger = []
	for entry in start.get("ledger", []):
		_add_ledger_id(str(entry))
	for entry in start.get("secrets", []):
		_add_ledger_id(str(entry))
	for entry in start.get("evidence", []):
		_add_ledger_id(str(entry))
	elites = []
	for entry in start.get("elites", []):
		elites.append(str(entry))
	commanders = []
	for entry in start.get("commanders", []):
		commanders.append(str(entry))
	week_report = []
	for line in start.get("opening_news", []):
		week_report.append(str(line))
	week_title = "The bells have already rung"
	rng.randomize()
	campaign_id = "%s_%d_%d" % [id, Time.get_unix_time_from_system(), rng.randi()]
	clamp_resources()


func _copy_world(db: ContentDB) -> void:
	territories = {}
	for tid in db.territory_order:
		var data: Dictionary = db.territories[tid]
		var controller := str(data.get("controller", "neutral"))
		if controller == claimant_id:
			controller = "player"
		territories[tid] = {
			"controller": controller,
			"loyalty": int(data.get("loyalty", 50)),
			"unrest": int(data.get("unrest", 10)),
			"fort": int(data.get("fort", 0)),
		}
	houses = {}
	for hid in db.houses:
		var house: Dictionary = db.houses[hid]
		var declared := str(house.get("start_declared", ""))
		if declared == claimant_id:
			declared = "player"
		houses[hid] = {"opinion": int(house.get("opinion", 0)), "declared": declared}


func _copy_people(db: ContentDB, start: Dictionary) -> void:
	npcs = {}
	for nid in db.characters:
		var who: Dictionary = db.characters[nid]
		var mode := str(who.get("start_state", "free"))
		npcs[nid] = {
			"alive": mode != "dead",
			"state": mode,
			"personal": int(who.get("personal", 0)),
			"political": int(who.get("political", 0)),
			"memories": [],
			"grudges": [],
			"promises": [],
			"broken": [],
		}
	for nid in start.get("relations", {}):
		if not npcs.has(str(nid)):
			continue
		var rel: Dictionary = start["relations"][nid]
		npcs[str(nid)]["personal"] = int(rel.get("personal", npcs[str(nid)]["personal"]))
		npcs[str(nid)]["political"] = int(rel.get("political", npcs[str(nid)]["political"]))
	for hid in start.get("house_opinion", {}):
		if houses.has(str(hid)):
			houses[str(hid)]["opinion"] = int(start["house_opinion"][hid])
	rivals = {}
	for rid in db.claimant_order:
		if rid == claimant_id:
			continue
		var other: Dictionary = db.claimants[rid]
		var other_start: Dictionary = other.get("start", {})
		var political := -10
		if npcs.has(rid):
			political = int(npcs[rid]["political"])
		rivals[rid] = {
			"gold": int(other_start.get("gold", 0)),
			"rations": int(other_start.get("rations", 0)),
			"forces": int(other_start.get("forces", 0)),
			"claim": int(other_start.get("claim", 0)),
			"fear": int(other_start.get("fear", 0)),
			"alive": true,
			"hostility": clampi(-political, 5, 100),
			"strategy": str(other.get("ai", {}).get("strategy", "mixed")),
			"cooldown": 1,
			"bid": false,
			"temper": 0,
		}


func _add_ledger_id(id: String) -> void:
	if id != "" and not ledger.has(id):
		ledger.append(id)


func has_ledger(id: String) -> bool:
	return ledger.has(id)


func has_proof(id: String) -> bool:
	# A document formally read into the public record remains evidence even
	# after it leaves the private ledger. Selling or burning a secret does not.
	return has_ledger(id) or (ledger_archive.has(id) and bool(flags.get("REVEALED_" + id.to_upper(), false)))


func remove_ledger(id: String) -> void:
	if ledger.has(id):
		ledger.erase(id)
	if id != "" and not ledger_archive.has(id):
		ledger_archive.append(id)


func npc_alive(id: String) -> bool:
	return npcs.has(id) and bool(npcs[id].get("alive", false))


func player_territories() -> Array:
	var owned: Array = []
	for tid in territories:
		if str(territories[tid].get("controller", "")) == "player":
			owned.append(tid)
	return owned


func houses_declared_for_player() -> int:
	var count := 0
	for hid in houses:
		if str(houses[hid].get("declared", "")) == "player":
			count += 1
	return count


func broken_promise_count() -> int:
	var count := 0
	for nid in npcs:
		count += npcs[nid].get("broken", []).size()
	return count


func add_log(line: String) -> void:
	if line.strip_edges() == "":
		return
	log.append(line)
	while log.size() > 120:
		log.pop_front()


func add_decision(entry: Dictionary) -> void:
	decisions.append(entry)
	while decisions.size() > 80:
		decisions.pop_front()


func clamp_resources() -> void:
	gold = maxi(0, gold)
	rations = maxi(0, rations)
	forces = maxi(0, forces)
	claim = clampi(claim, 0, 100)
	fear = clampi(fear, 0, 100)
	reputation = clampi(reputation, -100, 100)
	stability = clampi(stability, 0, 100)
	foreign = maxi(0, foreign)
	army_morale = clampi(army_morale, 0, 100)
	for key in blocs.keys():
		blocs[key] = clampi(int(blocs[key]), -100, 100)
	for id in territories:
		territories[id]["loyalty"] = clampi(int(territories[id].get("loyalty", 50)), 0, 100)
		territories[id]["unrest"] = clampi(int(territories[id].get("unrest", 0)), 0, 100)
		territories[id]["fort"] = clampi(int(territories[id].get("fort", 0)), 0, 12)
	for id in npcs:
		npcs[id]["personal"] = clampi(int(npcs[id].get("personal", 0)), -100, 100)
		npcs[id]["political"] = clampi(int(npcs[id].get("political", 0)), -100, 100)
		if str(npcs[id].get("state", "")) == "dead":
			npcs[id]["alive"] = false
		if not bool(npcs[id].get("alive", false)):
			npcs[id]["state"] = "dead"
			commanders.erase(id)
			if rivals.has(id):
				rivals[id]["alive"] = false
				rivals[id]["forces"] = 0
	for id in rivals:
		for field in ["gold", "rations", "forces", "cooldown", "temper"]:
			rivals[id][field] = maxi(0, int(rivals[id].get(field, 0)))
		for field in ["claim", "fear", "hostility"]:
			rivals[id][field] = clampi(int(rivals[id].get(field, 0)), 0, 100)


func to_dict() -> Dictionary:
	return {
		"version": version,
		"campaign_id": campaign_id,
		"ending_data": ending_data.duplicate(true),
		"claimant_id": claimant_id,
		"turn": turn,
		"gold": gold,
		"rations": rations,
		"forces": forces,
		"claim": claim,
		"fear": fear,
		"reputation": reputation,
		"stability": stability,
		"foreign": foreign,
		"army_morale": army_morale,
		"blocs": blocs.duplicate(true),
		"flags": flags.duplicate(true),
		"news": news.duplicate(),
		"log": log.duplicate(),
		"week_report": week_report.duplicate(),
		"week_title": week_title,
		"banner": banner,
		"territories": territories.duplicate(true),
		"npcs": npcs.duplicate(true),
		"rivals": rivals.duplicate(true),
		"ledger": ledger.duplicate(),
		"ledger_archive": ledger_archive.duplicate(),
		"houses": houses.duplicate(true),
		"elites": elites.duplicate(),
		"commanders": commanders.duplicate(),
		"wounded": wounded.duplicate(true),
		"scheduled": scheduled.duplicate(true),
		"modifiers": modifiers.duplicate(true),
		"forced_events": forced_events.duplicate(),
		"seen_events": seen_events.duplicate(true),
		"event_queue": event_queue.duplicate(),
		"event_index": event_index,
		"phase": phase,
		"action_taken": action_taken,
		"pending_battle": pending_battle.duplicate(true),
		"pending_throne_route": pending_throne_route,
		"post_battle": post_battle,
		"defeat_reason": defeat_reason,
		"location": location,
		"decisions": decisions.duplicate(true),
		"chronicle_this_run": chronicle_this_run.duplicate(),
		"last_battle": last_battle.duplicate(true),
		# JSON numbers cannot preserve the RNG's full 64-bit state.
		"rng_seed": str(rng.seed),
		"rng_state": str(rng.state),
	}


static func from_dict(data: Dictionary, db: ContentDB) -> CampaignState:
	var state := CampaignState.new()
	state.claimant_id = str(data.get("claimant_id", "mira"))
	if not db.claimants.has(state.claimant_id):
		state.claimant_id = "mira"
	state.setup(state.claimant_id, db)
	state.version = 2
	state.campaign_id = str(data.get("campaign_id", "%s_legacy_%s" % [state.claimant_id, str(data.get("rng_seed", "1"))]))
	var saved_ending = data.get("ending_data", {})
	state.ending_data = saved_ending.duplicate(true) if typeof(saved_ending) == TYPE_DICTIONARY else {}
	state.turn = maxi(1, int(data.get("turn", 1)))
	state.gold = int(data.get("gold", 0))
	state.rations = int(data.get("rations", 0))
	state.forces = int(data.get("forces", 0))
	state.claim = int(data.get("claim", 0))
	state.fear = int(data.get("fear", 0))
	state.reputation = int(data.get("reputation", 0))
	state.stability = int(data.get("stability", 50))
	state.foreign = int(data.get("foreign", 0))
	state.army_morale = int(data.get("army_morale", 68))
	state.blocs = _int_map(data.get("blocs", {}))
	for key in Balance.BLOCS:
		if not state.blocs.has(key):
			state.blocs[key] = 0
	state.flags = {}
	var raw_flags = data.get("flags", {})
	if typeof(raw_flags) == TYPE_DICTIONARY:
		for key in raw_flags:
			state.flags[str(key)] = bool(raw_flags[key])
	state.news = _string_list(data.get("news", []))
	state.log = _string_list(data.get("log", []))
	state.week_report = _string_list(data.get("week_report", []))
	state.week_title = str(data.get("week_title", ""))
	state.banner = str(data.get("banner", ""))
	state.territories = _merge_territories(data.get("territories", {}), state.territories)
	state.npcs = _merge_npcs(data.get("npcs", {}), state.npcs)
	state.rivals = _merge_rivals(data.get("rivals", {}), state.rivals)
	state.ledger = _string_list(data.get("ledger", []))
	state.ledger = state.ledger.filter(func(id): return db.ledger.has(str(id)))
	state.ledger_archive = _string_list(data.get("ledger_archive", []))
	state.ledger_archive = state.ledger_archive.filter(func(id): return db.ledger.has(str(id)))
	state.houses = _merge_houses(data.get("houses", {}), state.houses)
	state.elites = _string_list(data.get("elites", []))
	state.elites = state.elites.filter(func(id): return db.units.has(str(id)))
	state.commanders = _string_list(data.get("commanders", []))
	state.commanders = state.commanders.filter(func(id): return db.characters.has(str(id)))
	state.wounded = _int_map(data.get("wounded", {}))
	state.scheduled = _dict_list(data.get("scheduled", []))
	state.modifiers = _dict_list(data.get("modifiers", []))
	state.forced_events = _string_list(data.get("forced_events", []))
	state.seen_events = _int_map(data.get("seen_events", {}))
	state.event_queue = _string_list(data.get("event_queue", []))
	state.event_queue = state.event_queue.filter(func(id): return db.events_by_id.has(str(id)))
	state.event_index = clampi(int(data.get("event_index", 0)), 0, state.event_queue.size())
	state.phase = str(data.get("phase", "overview"))
	if not ["overview", "event", "action", "response", "ending"].has(state.phase):
		state.phase = "overview"
	state.action_taken = str(data.get("action_taken", ""))
	var pending = data.get("pending_battle", {})
	state.pending_battle = pending.duplicate(true) if typeof(pending) == TYPE_DICTIONARY else {}
	if not state.pending_battle.is_empty() and not db.battles.has(str(state.pending_battle.get("battle_id", ""))):
		state.pending_battle = {}
	state.pending_throne_route = str(data.get("pending_throne_route", ""))
	state.post_battle = str(data.get("post_battle", ""))
	state.defeat_reason = str(data.get("defeat_reason", ""))
	state.location = str(data.get("location", ""))
	state.decisions = _dict_list(data.get("decisions", []))
	state.chronicle_this_run = _string_list(data.get("chronicle_this_run", []))
	var last = data.get("last_battle", {})
	state.last_battle = last.duplicate(true) if typeof(last) == TYPE_DICTIONARY else {}
	var seed := int(data.get("rng_seed", 1))
	state.rng.seed = seed if seed != 0 else 1
	var rng_state := int(data.get("rng_state", 0))
	if rng_state != 0:
		state.rng.state = rng_state
	state.clamp_resources()
	return state


static func _int_map(raw) -> Dictionary:
	var out := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key in raw:
		out[str(key)] = int(raw[key])
	return out


static func _string_list(raw) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item in raw:
		out.append(str(item))
	return out


static func _dict_list(raw) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item in raw:
		if typeof(item) == TYPE_DICTIONARY:
			out.append(item.duplicate(true))
	return out


static func _merge_territories(raw, fallback: Dictionary) -> Dictionary:
	var out: Dictionary = fallback.duplicate(true)
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key in raw:
		if typeof(raw[key]) != TYPE_DICTIONARY or not out.has(str(key)):
			continue
		var row: Dictionary = raw[key]
		out[str(key)] = {
			"controller": str(row.get("controller", "neutral")),
			"loyalty": int(row.get("loyalty", 50)),
			"unrest": int(row.get("unrest", 0)),
			"fort": int(row.get("fort", 0)),
		}
	return out


static func _merge_npcs(raw, fallback: Dictionary) -> Dictionary:
	var out: Dictionary = fallback.duplicate(true)
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key in raw:
		if typeof(raw[key]) != TYPE_DICTIONARY or not out.has(str(key)):
			continue
		var row: Dictionary = raw[key]
		out[str(key)] = {
			"alive": bool(row.get("alive", true)),
			"state": str(row.get("state", "free")),
			"personal": int(row.get("personal", 0)),
			"political": int(row.get("political", 0)),
			"memories": _string_list(row.get("memories", [])),
			"grudges": _string_list(row.get("grudges", [])),
			"promises": _string_list(row.get("promises", [])),
			"broken": _string_list(row.get("broken", [])),
		}
	return out


static func _merge_rivals(raw, fallback: Dictionary) -> Dictionary:
	var out: Dictionary = fallback.duplicate(true)
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key in raw:
		if typeof(raw[key]) != TYPE_DICTIONARY or not out.has(str(key)):
			continue
		var row: Dictionary = raw[key]
		out[str(key)] = {
			"gold": int(row.get("gold", 0)),
			"rations": int(row.get("rations", 0)),
			"forces": int(row.get("forces", 0)),
			"claim": int(row.get("claim", 0)),
			"fear": int(row.get("fear", 0)),
			"alive": bool(row.get("alive", true)),
			"hostility": int(row.get("hostility", 0)),
			"strategy": str(row.get("strategy", "mixed")),
			"cooldown": int(row.get("cooldown", 0)),
			"bid": bool(row.get("bid", false)),
			"temper": int(row.get("temper", 0)),
		}
	return out


static func _merge_houses(raw, fallback: Dictionary) -> Dictionary:
	var out: Dictionary = fallback.duplicate(true)
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key in raw:
		if typeof(raw[key]) != TYPE_DICTIONARY or not out.has(str(key)):
			continue
		var row: Dictionary = raw[key]
		out[str(key)] = {
			"opinion": int(row.get("opinion", 0)),
			"declared": str(row.get("declared", "")),
		}
	return out
