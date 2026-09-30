extends Node

## Meaningful release checks. Always launch through run_qa.ps1: campaign systems
## intentionally autosave and uncover Chronicle entries during these tests.

const CONDITION_KEYS := ["claimant", "not_claimant", "min_turn", "max_turn", "acts", "flags", "not_flags", "min_gold", "min_rations", "min_forces", "max_forces", "min_claim", "max_claim", "min_fear", "max_fear", "min_reputation", "max_reputation", "min_stability", "min_foreign", "max_foreign", "min_bloc", "max_bloc", "min_player_territories", "max_player_territories", "controls", "controls_any", "not_controls", "relation_min", "political_min", "npc_alive", "npc_dead", "npc_state", "has_ledger", "missing_ledger", "has_ledger_any", "house_declared", "house_opinion_min", "min_houses_player", "chronicle", "not_chronicle", "chronicle_any", "rival_alive", "rival_dead", "any_rival_weak", "elite"]
const EFFECT_OPS := ["gold", "rations", "forces", "claim", "fear", "reputation", "stability", "foreign", "morale", "bloc", "relation", "political", "memory", "grudge", "promise", "break_promise", "flag", "clear_flag", "ledger_add", "ledger_remove", "grant_first_missing", "prove_blood", "territory", "loyalty", "unrest", "fort", "kill", "capture", "free_npc", "npc_state", "schedule", "modifier", "battle", "news", "chronicle", "rival", "house_opinion", "house_declare", "elite_add", "elite_remove", "commander_add", "recruit", "buy_rations", "chance", "assassinate", "defeat"]
const POLICIES := ["random", "legitimacy", "benevolent", "ruthless", "diplomacy", "military"]
const BANDS := ["triumph", "brittle", "pyrrhic", "failure", "disaster"]

var db: ContentDB
var errors: Array[String] = []
var checks := 0
var branches := 0
var choices := 0
var simulations := 0
var visited_events := {}
var visited_choices := {}
var ending_counts := {}
var ending_routes := {}
var ending_fixtures := {}
var policy_counts := {}
var winning_replays := {}
var personal_prose_counts := {}
var producer_deliveries := {}
var report := {}


func _ready() -> void:
	if not _isolated():
		get_tree().quit(2)
		return
	db = GameManager.db
	for message in db.validate():
		_fail("database: " + message)
	_schema()
	_schedule_graph()
	_epilogue_schema()
	_condition_boundaries()
	_resolver_regressions()
	_producer_deliveries()
	_all_choices()
	_routes()
	_save_roundtrip()
	_continuity()
	_prisoner_and_house_payoffs()
	_battle_commands()
	_army_and_capital()
	var seeds := 24
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("seeds="):
			seeds = maxi(1, int(argument.trim_prefix("seeds=")))
	for claimant in db.claimant_order:
		for policy in POLICIES:
			for seed_index in seeds:
				_simulate(str(claimant), str(policy), seed_index + 20260930)
		print("CAMPAIGNS %s %s" % [claimant, JSON.stringify(ending_counts.get(claimant, {}))])
	_report(seeds)
	if errors.is_empty():
		print("RELEASE_AUDIT_OK checks=%d choices=%d branches=%d campaigns=%d events_seen=%d" % [checks, choices, branches, simulations, visited_events.size()])
		get_tree().quit(0)
	else:
		for message in errors:
			print("AUDIT_FAIL ", message)
		print("RELEASE_AUDIT_FAILED count=%d" % errors.size())
		get_tree().quit(1)


func _isolated() -> bool:
	var expected := OS.get_environment("USURPER_QA_USER_ROOT").replace("\\", "/").to_lower()
	var actual := OS.get_user_data_dir().replace("\\", "/").to_lower()
	if expected == "" or not actual.begins_with(expected + "/"):
		push_error("Refusing to run write-producing QA against real saves. Use tests/run_qa.ps1. actual=" + actual)
		return false
	print("QA_ISOLATED_USER_DATA ", actual)
	return true


func _schema() -> void:
	_unique(db.actions, "action")
	_unique(db.routes, "route")
	for event in db.events:
		var context := "event " + str(event.get("id", ""))
		_expect(str(event.get("title", "")).strip_edges() != "", context + " has no title")
		_expect(str(event.get("text", "")).strip_edges() != "", context + " has no narrative")
		_expect(not event.get("choices", []).is_empty(), context + " has no choices")
		_conditions(event.get("requires", {}), context)
		_unique(event.get("choices", []), context + " choice")
		for choice in event.get("choices", []):
			var choice_context := context + "/" + str(choice.get("id", ""))
			_expect(str(choice.get("text", "")).strip_edges() != "", choice_context + " has no text")
			_conditions(choice.get("requires", {}), choice_context)
			_effects(choice.get("effects", []), choice_context)
	for action in db.actions:
		var context := "action " + str(action.get("id", ""))
		_conditions(action.get("requires", {}), context)
		if not action.has("generator"):
			_effects(action.get("effects", []), context)
	for id in db.ledger:
		for field in ["reveal", "blackmail", "call"]:
			if db.ledger[id].has(field):
				_effects(db.ledger[id][field], "ledger " + str(id) + "/" + field)
	for route in db.routes:
		_conditions(route.get("requires", {}), "route " + str(route.get("id", "")))
		if route.has("battle_id"):
			_expect(db.battles.has(str(route.battle_id)), "route references unknown battle " + str(route.battle_id))
		for band in BANDS:
			_expect(str(route.get("prose", {}).get(band, "")).length() > 20, "route %s missing %s prose" % [route.get("id", ""), band])
	for claimant in db.claimant_order:
		var start: Dictionary = db.claimants[claimant].get("start", {})
		for field in ["ledger", "secrets", "evidence"]:
			for id in start.get(field, []):
				_expect(db.ledger.has(str(id)), "%s starts with unknown ledger %s" % [claimant, id])
		for id in start.get("commanders", []):
			_expect(db.characters.has(str(id)), "%s starts with unknown commander %s" % [claimant, id])
		for id in start.get("elites", []):
			_expect(db.units.has(str(id)), "%s starts with unknown formation %s" % [claimant, id])
	for id in db.characters:
		_expect(str(db.characters[id].get("biography", "")).length() >= 200, "character lacks full biography " + str(id))
	var lore_ids := {}
	for category in db.lore.get("categories", []):
		for entry in category.get("entries", []):
			var id := str(entry.get("id", ""))
			_expect(id != "" and not lore_ids.has(id), "world atlas duplicate/empty id " + id)
			lore_ids[id] = true
			_expect(str(entry.get("title", "")).length() > 1 and str(entry.get("text", "")).length() >= 80, "world atlas incomplete entry " + id)


func _unique(rows: Array, context: String) -> void:
	var seen := {}
	for row in rows:
		var id := str(row.get("id", ""))
		_expect(id != "" and not seen.has(id), context + " duplicate/empty id " + id)
		seen[id] = true


func _epilogue_schema() -> void:
	for claimant in db.epilogues.get("claimants", {}):
		_expect(db.claimants.has(str(claimant)), "epilogue unknown claimant " + str(claimant))
		for route_id in db.epilogues.claimants[claimant].get("routes", {}):
			var found := false
			for route in db.routes:
				if str(route.id) == str(route_id):
					found = true
			_expect(found, "epilogue unknown route " + str(route_id))
			for band in BANDS:
				_expect(str(db.epilogues.claimants[claimant].routes[route_id].get(band, "")).length() > 20, "personal epilogue incomplete %s/%s/%s" % [claimant, route_id, band])
	for category in ["milestones", "world", "npc_rules"]:
		for row in db.epilogues.get(category, []):
			_conditions(row.get("requires", {}), "epilogue " + category)
			_expect(_witness(row.get("requires", {})) != null, "epilogue condition impossible " + str(row.get("id", "")))
			if category == "npc_rules":
				_expect(db.characters.has(str(row.get("npc", ""))), "epilogue rule references unknown character")


func _conditions(raw, context: String) -> void:
	_expect(typeof(raw) == TYPE_DICTIONARY, context + " condition is not a dictionary")
	if typeof(raw) != TYPE_DICTIONARY:
		return
	if raw.has("min_turn"):
		_expect(int(raw.min_turn) <= 52, context + " begins after campaign deadline")
	for key in raw:
		_expect(CONDITION_KEYS.has(str(key)) or str(key) in ["all", "any", "ledger_count", "min_ledger_count", "ledger_count_ids"], context + " unsupported condition " + str(key))
		if str(key) in ["all", "any"]:
			for child in raw[key]:
				_conditions(child, context + "/" + str(key))


func _effects(raw, context: String) -> void:
	_expect(typeof(raw) == TYPE_ARRAY, context + " effects are not an array")
	if typeof(raw) != TYPE_ARRAY:
		return
	for effect in raw:
		_expect(typeof(effect) == TYPE_DICTIONARY, context + " malformed effect")
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var op := str(effect.get("op", ""))
		_expect(EFFECT_OPS.has(op) or op == "clear_promise", context + " unsupported op " + op)
		if op == "chance" or op == "assassinate":
			var p := float(effect.get("p", effect.get("chance", 0.5)))
			_expect(p >= 0.0 and p <= 1.0, context + " invalid probability")
			_effects(effect.get("success", []), context + "/success")
			_effects(effect.get("fail", []), context + "/fail")
		elif op == "battle":
			for branch in ["on_victory", "on_defeat", "on_retreat"]:
				_effects(effect.get(branch, []), context + "/" + branch)
		elif op == "npc_state":
			_expect(db.characters.has(str(effect.get("id", ""))), context + " unknown npc_state target")


func _fresh(claimant := "mira") -> CampaignState:
	var state := CampaignState.new()
	state.setup(claimant, db)
	state.rng.seed = 20260930
	return state


func _schedule_graph() -> void:
	var inbound := {}
	for event in db.events:
		for choice in event.get("choices", []):
			_schedule_edges(choice.get("effects", []), str(event.id), inbound)
	for action in db.actions:
		_schedule_edges(action.get("effects", []), "action " + str(action.get("id", "")), inbound)
	# Generators author their concrete effect lists at runtime (not in actions.json).
	for claimant in db.claimant_order:
		var state := _fresh(str(claimant))
		state.gold = 10000
		state.rations = 200
		state.forces = 4000
		state.ledger = db.ledger.keys()
		for action in ActionBoard.available(state, db):
			_schedule_edges(action.get("effects", []), "generated " + str(action.get("id", "")), inbound)
	for id in db.characters:
		var death_event := str(db.characters[id].get("death_event", ""))
		if death_event != "":
			inbound[death_event] = true
	for event in db.events:
		if bool(event.get("scheduled_only", false)):
			_expect(inbound.has(str(event.id)), "scheduled-only event has no producer " + str(event.id))


func _schedule_edges(effects: Array, source: String, inbound: Dictionary) -> void:
	for effect in effects:
		var op := str(effect.get("op", ""))
		if op == "schedule":
			inbound[str(effect.get("event", ""))] = source
		elif op in ["chance", "assassinate"]:
			_schedule_edges(effect.get("success", []), source, inbound)
			_schedule_edges(effect.get("fail", []), source, inbound)
		elif op == "battle":
			for branch in ["on_victory", "on_defeat", "on_retreat"]:
				_schedule_edges(effect.get(branch, []), source, inbound)


func _condition_boundaries() -> void:
	var state := _fresh()
	for pair in [["min_gold", "gold"], ["min_rations", "rations"], ["min_forces", "forces"], ["min_claim", "claim"], ["min_fear", "fear"], ["min_reputation", "reputation"], ["min_stability", "stability"], ["min_foreign", "foreign"]]:
		state.set(pair[1], 19)
		_expect(not ConditionChecker.met({pair[0]: 20}, state, db), "condition lower boundary " + pair[0])
		state.set(pair[1], 20)
		_expect(ConditionChecker.met({pair[0]: 20}, state, db), "condition inclusive boundary " + pair[0])
	for pair in [["max_forces", "forces"], ["max_claim", "claim"], ["max_fear", "fear"], ["max_reputation", "reputation"], ["max_foreign", "foreign"]]:
		state.set(pair[1], 21)
		_expect(not ConditionChecker.met({pair[0]: 20}, state, db), "condition upper boundary " + pair[0])
		state.set(pair[1], 20)
		_expect(ConditionChecker.met({pair[0]: 20}, state, db), "condition upper inclusive " + pair[0])
	state.flags["QA_FLAG"] = true
	_expect(ConditionChecker.met({"flags": ["QA_FLAG"]}, state, db), "true flag unavailable")
	_expect(not ConditionChecker.met({"not_flags": ["QA_FLAG"]}, state, db), "negative flag accepted")
	state.npcs["garran_vale"]["alive"] = false
	state.npcs["garran_vale"]["state"] = "dead"
	_expect(not ConditionChecker.met({"npc_alive": ["garran_vale"]}, state, db), "dead npc passes alive condition")
	_expect(ConditionChecker.met({"npc_dead": ["garran_vale"]}, state, db), "dead npc fails dead condition")


func _all_choices() -> void:
	for event in db.events:
		for choice in event.get("choices", []):
			choices += 1
			var context := "%s/%s" % [event.get("id", ""), choice.get("id", "")]
			var state := _witness(event.get("requires", {}), choice.get("requires", {}))
			if state == null:
				_fail("unreachable conditions for " + context)
				continue
			_expect(ConditionChecker.met(event.get("requires", {}), state, db), context + " event witness fails")
			_expect(ConditionChecker.met(choice.get("requires", {}), state, db), context + " choice witness fails")
			_expect(ConditionChecker.choice_failures(choice, state, db).is_empty(), context + " witness cannot afford choice")
			var expanded := _expand(choice.get("effects", []))
			for effects in expanded:
				var trial := CampaignState.from_dict(state.to_dict(), db)
				EffectResolver.apply(trial, effects, db)
				branches += 1
				_invariants(trial, context)
	for claimant in db.claimant_order:
		var state := _fresh(str(claimant))
		state.gold = 10000
		state.rations = 200
		state.forces = 4000
		state.claim = 100
		state.ledger = db.ledger.keys()
		for action in ActionBoard.available(state, db):
			_effects(action.get("effects", []), "generated " + str(action.get("id", "")))
			for effects in _expand(action.get("effects", [])):
				var trial := CampaignState.from_dict(state.to_dict(), db)
				EffectResolver.apply(trial, effects, db)
				branches += 1
				_invariants(trial, "generated " + str(action.get("id", "")))


## Branch expansion executes every success/failure and battle-return effect list
## in a valid contextual state, including nested branches. Battle mechanics are
## independently exercised below; this does not claim every gameplay sequence.
func _expand(effects: Array) -> Array:
	var paths: Array = [[]]
	for effect in effects:
		var alternatives: Array = [[effect]]
		var op := str(effect.get("op", ""))
		if op in ["chance", "assassinate"]:
			alternatives = _expand(effect.get("success", [])) + _expand(effect.get("fail", []))
		elif op == "battle":
			alternatives = _expand(effect.get("on_victory", [])) + _expand(effect.get("on_defeat", [])) + _expand(effect.get("on_retreat", []))
		var next: Array = []
		for path in paths:
			for branch in alternatives:
				next.append(path + branch)
		paths = next
	return paths


func _witness(first: Dictionary, second: Dictionary = {}) -> CampaignState:
	for first_variant in _requirement_variants(first):
		for second_variant in _requirement_variants(second):
			for claimant in db.claimant_order:
				var state := _fresh(str(claimant))
				state.gold = 2000
				state.rations = 100
				state.forces = 1200
				for requirement in first_variant + second_variant:
					_satisfy(state, requirement)
				if ConditionChecker.met(first, state, db) and ConditionChecker.met(second, state, db):
					return state
	return null


func _requirement_variants(requirement: Dictionary) -> Array:
	var base := requirement.duplicate(true)
	base.erase("all")
	base.erase("any")
	var paths: Array = [[base]]
	for child in requirement.get("all", []):
		var next: Array = []
		for path in paths:
			for variant in _requirement_variants(child):
				next.append(path + variant)
		paths = next
	if requirement.has("any"):
		var next: Array = []
		for child in requirement["any"]:
			for path in paths:
				for variant in _requirement_variants(child):
					next.append(path + variant)
		paths = next
	return paths


func _resolver_regressions() -> void:
	var state := _fresh()
	state.gold = 5
	_expect(not ConditionChecker.choice_failures({"effects": [{"op": "gold", "amount": -10}]}, state, db).is_empty(), "unaffordable direct payment is selectable")
	var original_forces := state.forces
	var original_rations := state.rations
	EffectResolver.apply(state, [{"op": "gold", "amount": -10}, {"op": "recruit", "amount": 20, "gold_each": 2}, {"op": "buy_rations", "amount": 20, "gold_each": 2}], db)
	_expect(state.forces >= original_forces and state.rations >= original_rations, "negative treasury makes recruitment or purchase subtract stock")
	state = _fresh()
	var gold_before := state.gold
	EffectResolver.apply(state, [{"op": "chance", "p": 1.0, "success": [{"op": "gold", "amount": 7}], "fail": [{"op": "gold", "amount": -9}]}], db)
	_expect(state.gold == gold_before + 7, "certain success executes wrong branch")
	EffectResolver.apply(state, [{"op": "chance", "p": 0.0, "success": [{"op": "gold", "amount": 7}], "fail": [{"op": "gold", "amount": -9}]}], db)
	_expect(state.gold == gold_before - 2, "certain failure executes wrong branch")
	state = _fresh()
	EffectResolver.apply(state, [{"op": "defeat", "reason": "exile"}, {"op": "flag", "flag": "QA_AFTER_DEATH"}], db)
	_expect(not bool(state.flags.get("QA_AFTER_DEATH", false)), "effects continue after terminal defeat")
	state = _fresh()
	state.event_queue = ["pell_private"]
	state.seen_events["pell_private"] = 1
	EffectResolver.apply(state, [{"op": "kill", "id": "oren_pell"}], db)
	_expect(EventDirector.current(state, db).is_empty(), "queued event remains valid after speaker dies")
	state = _fresh()
	state.flags["STARVING"] = true
	state.rations = 100
	CampaignRules._upkeep(state, db)
	_expect(not bool(state.flags.get("STARVING", false)), "fed host remains starving")
	state = _fresh()
	state.turn = 52
	CampaignRules.close_week(state, db)
	_expect(state.turn == 53 and state.defeat_reason != "", "unresolved campaign fails to reach finite settlement")
	state = _fresh()
	state.pending_battle = {"battle_id": "road_bandits", "on_victory": [{"op": "flag", "flag": "QA_RETURNED"}], "on_defeat": [], "on_retreat": []}
	var result := {"outcome": "victory", "forces_lost": 10, "enemy_lost": 10, "player_morale": 60, "commanders": [], "elites_lost": [], "log": [], "battle_id": "road_bandits"}
	CampaignRules.apply_battle_return(state, db, result)
	var once := state.to_dict()
	CampaignRules.apply_battle_return(state, db, result)
	_expect(JSON.stringify(state.to_dict()) == JSON.stringify(once), "battle outcome applied twice")


func _producer_deliveries() -> void:
	# Execute the authored producer effects, then the actual schedule ticker and
	# EventDirector delivery. Do not inject the target's required flags.
	for event in db.events:
		for choice in event.get("choices", []):
			var initial: CampaignState = _witness(event.get("requires", {}), choice.get("requires", {}))
			if initial == null:
				continue
			for branch in _expand(choice.get("effects", [])):
				var targets := _scheduled_targets(branch)
				if not targets.is_empty():
					var state := CampaignState.from_dict(initial.to_dict(), db)
					EffectResolver.apply(state, branch, db)
					_deliver_targets(state, targets, "%s/%s" % [event.id, choice.id])
	for claimant in db.claimant_order:
		var initial := _fresh(str(claimant))
		initial.gold = 10000
		initial.rations = 200
		initial.forces = 4000
		initial.claim = 100
		initial.ledger = db.ledger.keys()
		for action in ActionBoard.available(initial, db):
			for branch in _expand(action.get("effects", [])):
				var targets := _scheduled_targets(branch)
				if not targets.is_empty():
					var state := CampaignState.from_dict(initial.to_dict(), db)
					EffectResolver.apply(state, branch, db)
					_deliver_targets(state, targets, "generated/" + str(action.id))
	for character in db.character_order:
		var target := str(db.characters[character].get("death_event", ""))
		if target != "":
			var state := _fresh("arlo" if character == "mira" else "mira")
			EffectResolver.apply(state, [{"op": "kill", "id": character}], db)
			_deliver_targets(state, [target], "death/" + str(character))
	for event in db.events:
		if bool(event.get("scheduled_only", false)):
			_expect(producer_deliveries.has(str(event.id)), "scheduled scene has no delivered producer " + str(event.id))
	# Every rival march and coronation bid must set its own flag and reach the
	# current scene, then vanish if that rival dies or enters custody first.
	for rival in db.claimant_order:
		for kind in ["clash", "bid"]:
			var state := _fresh("ethan" if rival == "mira" else "mira")
			var id := "%s_%s" % [kind, rival]
			if kind == "clash":
				RivalBrain._march(str(rival), state.rivals[rival], str(rival), state, db)
			else:
				state.rivals[rival]["claim"] = 100
				state.rivals[rival]["rations"] = 500
				state.rivals[rival]["gold"] = 10000
				RivalBrain._one(str(rival), state, db)
			_expect(state.forced_events.has(id), "rival producer never queues " + id)
			var death := CampaignState.from_dict(state.to_dict(), db)
			var custody := CampaignState.from_dict(state.to_dict(), db)
			EffectResolver.apply(death, [{"op": "kill", "id": rival}], db)
			EffectResolver.apply(custody, [{"op": "capture", "id": rival}], db)
			EventDirector.pick_audience(death, db)
			EventDirector.pick_audience(custody, db)
			_expect(not death.event_queue.has(id), "dead rival scene delivered " + id)
			_expect(not custody.event_queue.has(id), "captured rival scene delivered " + id)
			_deliver_targets(state, [id], "RivalBrain/" + kind)
			_expect(producer_deliveries.has(id), "rival producer not delivered " + id)
	# The optional family promise scene is pooled rather than scheduled.
	var promise_event := db.event_by_id("evelyne_afraid")
	var family: CampaignState = _witness(promise_event.get("requires", {}), {"claimant": "arlo"})
	for choice in promise_event.get("choices", []):
		if str(choice.id) == "promise":
			EffectResolver.apply(family, choice.get("effects", []), db)
	family.turn = 14
	_expect(ConditionChecker.met(db.event_by_id("arlo_mother_heard").get("requires", {}), family, db), "Evelyne promise cannot unlock hearing")
	_expect(EventDirector._available(family, db).has(db.event_by_id("arlo_mother_heard")), "Evelyne hearing absent from real event pool")
	_deliver_targets(family, ["arlo_mother_heard"], "evelyne_afraid/promise")
	_expect(producer_deliveries.has("arlo_mother_heard"), "Evelyne hearing never delivered from event pool")
	var quiet := _fresh()
	for event in db.events:
		if bool(event.get("one_time", true)):
			quiet.seen_events[str(event.id)] = 1
	EventDirector.pick_audience(quiet, db)
	_expect(str(EventDirector.current(quiet, db).get("id", "")) == "quiet_week", "empty audience does not deliver quiet fallback")
	producer_deliveries["quiet_week"] = {"source": "EventDirector/fallback", "week": quiet.turn}
	var failed := _fresh("alistair")
	failed.gold = 10000
	failed.claim = 30
	var failure_applied := false
	for action in ActionBoard.available(failed, db):
		if str(action.id) != "kill_ethan":
			continue
		var guaranteed_failure: Array = action.get("effects", []).duplicate(true)
		for effect in guaranteed_failure:
			if str(effect.get("op", "")) == "assassinate":
				effect["chance"] = 0.0
		EffectResolver.apply(failed, guaranteed_failure, db)
		failure_applied = true
		_expect(failed.scheduled.any(func(row): return str(row.get("event", "")) == "knife_in_yard"), "failed assassination does not schedule its consequence")
		_deliver_targets(failed, ["knife_in_yard"], "actual failed assassination")
	_expect(failure_applied and failed.npc_alive("ethan") and str(producer_deliveries.get("knife_in_yard", {}).get("source", "")) == "actual failed assassination", "failed assassination consequence never delivered")


func _scheduled_targets(effects: Array) -> Array:
	var targets: Array = []
	for effect in effects:
		if str(effect.get("op", "")) == "schedule" and not targets.has(str(effect.get("event", ""))):
			targets.append(str(effect.get("event", "")))
	return targets


func _deliver_targets(state: CampaignState, targets: Array, source: String) -> void:
	var remaining := targets.duplicate()
	while state.turn < 52 and not remaining.is_empty() and state.defeat_reason == "":
		CampaignRules._tick_schedules(state)
		state.turn += 1
		EventDirector.pick_audience(state, db)
		for index in state.event_queue.size():
			state.event_index = index
			var event := EventDirector.current(state, db)
			var id := str(event.get("id", ""))
			if remaining.has(id):
				producer_deliveries[id] = {"source": source, "week": state.turn}
				remaining.erase(id)


func _satisfy(state: CampaignState, requirement: Dictionary) -> void:
	for pair in [["min_turn", "turn"], ["min_gold", "gold"], ["min_rations", "rations"], ["min_forces", "forces"], ["min_claim", "claim"], ["min_fear", "fear"], ["min_reputation", "reputation"], ["min_stability", "stability"], ["min_foreign", "foreign"]]:
		if requirement.has(pair[0]):
			state.set(pair[1], maxi(int(state.get(pair[1])), int(requirement[pair[0]])))
	for pair in [["max_turn", "turn"], ["max_forces", "forces"], ["max_claim", "claim"], ["max_fear", "fear"], ["max_reputation", "reputation"], ["max_foreign", "foreign"]]:
		if requirement.has(pair[0]):
			state.set(pair[1], mini(int(state.get(pair[1])), int(requirement[pair[0]])))
	if requirement.has("acts") and not requirement.acts.has(Balance.act_of(state.turn)):
		var act := int(requirement.acts[0])
		state.turn = [0, 1, 9, 19, 29][act]
	for flag in requirement.get("flags", []):
		state.flags[str(flag)] = true
	for flag in requirement.get("not_flags", []):
		state.flags.erase(str(flag))
	for id in requirement.get("min_bloc", {}):
		state.blocs[id] = maxi(int(state.blocs[id]), int(requirement.min_bloc[id]))
	for id in requirement.get("max_bloc", {}):
		state.blocs[id] = mini(int(state.blocs[id]), int(requirement.max_bloc[id]))
	for id in requirement.get("controls", []):
		state.territories[id]["controller"] = "player"
	if requirement.has("controls_any") and not requirement.controls_any.is_empty():
		state.territories[requirement.controls_any[0]]["controller"] = "player"
	for id in requirement.get("not_controls", []):
		state.territories[id]["controller"] = "neutral"
	if requirement.has("min_player_territories"):
		for id in db.territory_order:
			if state.player_territories().size() >= int(requirement.min_player_territories):
				break
			if not requirement.get("not_controls", []).has(id):
				state.territories[id]["controller"] = "player"
	if requirement.has("max_player_territories"):
		for id in db.territory_order:
			if state.player_territories().size() <= int(requirement.max_player_territories):
				break
			if not requirement.get("controls", []).has(id):
				state.territories[id]["controller"] = "neutral"
	for field in ["relation_min", "political_min"]:
		for id in requirement.get(field, {}):
			state.npcs[id]["personal" if field == "relation_min" else "political"] = int(requirement[field][id])
	for field in ["npc_alive", "npc_dead"]:
		for id in requirement.get(field, []):
			state.npcs[id]["alive"] = field == "npc_alive"
			state.npcs[id]["state"] = "free" if field == "npc_alive" else "dead"
			if state.rivals.has(id):
				state.rivals[id]["alive"] = field == "npc_alive"
				if field == "npc_dead":
					state.rivals[id]["forces"] = 0
	for id in requirement.get("npc_state", {}):
		state.npcs[id]["state"] = requirement.npc_state[id]
		state.npcs[id]["alive"] = str(requirement.npc_state[id]) != "dead"
	for field in ["rival_alive", "rival_dead"]:
		for id in requirement.get(field, []):
			if state.rivals.has(id):
				state.rivals[id]["alive"] = field == "rival_alive"
				if field == "rival_dead":
					state.rivals[id]["forces"] = 0
					state.npcs[id]["alive"] = false
					state.npcs[id]["state"] = "dead"
	for id in requirement.get("has_ledger", []):
		if not state.ledger.has(id):
			state.ledger.append(id)
	for id in requirement.get("missing_ledger", []):
		state.ledger.erase(id)
	if requirement.has("has_ledger_any") and not requirement.has_ledger_any.is_empty():
		state.ledger.append(requirement.has_ledger_any[0])
	if requirement.has("ledger_count"):
		var proof: Dictionary = requirement.ledger_count
		var obtained := 0
		for id in proof.get("ids", []):
			if obtained >= int(proof.get("min", 1)):
				break
			if not state.ledger.has(id):
				state.ledger.append(id)
			obtained += 1
	if requirement.has("min_ledger_count"):
		var obtained := 0
		for id in requirement.get("ledger_count_ids", []):
			if obtained >= int(requirement.min_ledger_count):
				break
			if not state.ledger.has(id):
				state.ledger.append(id)
			obtained += 1
	for id in requirement.get("house_declared", {}):
		state.houses[id]["declared"] = requirement.house_declared[id]
	for id in requirement.get("house_opinion_min", {}):
		state.houses[id]["opinion"] = int(requirement.house_opinion_min[id])
	if requirement.has("min_houses_player"):
		for id in db.house_order:
			if state.houses_declared_for_player() >= int(requirement.min_houses_player):
				break
			state.houses[id]["declared"] = "player"
	if requirement.has("chronicle"):
		MetaProgress.unlocked[str(requirement.chronicle)] = true
	if requirement.has("not_chronicle"):
		MetaProgress.unlocked.erase(str(requirement.not_chronicle))
	if requirement.has("chronicle_any") and not requirement.chronicle_any.is_empty():
		MetaProgress.unlocked[str(requirement.chronicle_any[0])] = true
	for id in requirement.get("elite", []):
		if not state.elites.has(id):
			state.elites.append(id)
	if bool(requirement.get("any_rival_weak", false)) and not state.rivals.is_empty():
		state.rivals[state.rivals.keys()[0]]["claim"] = 0
		state.rivals[state.rivals.keys()[0]]["forces"] = 100


func _routes() -> void:
	for claimant in db.claimant_order:
		var count := 0
		var paragraph_count := 0
		var distinct := {}
		for route in db.routes:
			var witness := _witness(route.get("requires", {}), {"claimant": claimant})
			if witness == null:
				continue
			count += 1
			for band in BANDS:
				var personal: Dictionary = db.epilogues.get("claimants", {}).get(claimant, {}).get("routes", {}).get(str(route.id), {})
				var prose := str(personal.get(band, ""))
				_expect(prose.length() > 20, "eligible route missing personal prose %s/%s/%s" % [claimant, route.id, band])
				paragraph_count += 1
				distinct[prose] = true
				var ending := EndingDirector.resolve(witness, db, str(route.id), {"outcome": "victory"}, band)
				ending_fixtures[str(ending.get("ending_id", ""))] = true
				_expect(str(ending.get("title", "")) != "", "%s/%s/%s empty title" % [claimant, route.id, band])
				_expect(ending.get("paragraphs", []).size() >= 4, "%s/%s/%s incomplete epilogue" % [claimant, route.id, band])
				_expect(bool(ending.get("defeat", false)) == (band in ["failure", "disaster"]), "ending band victory mismatch")
				for paragraph in ending.get("paragraphs", []):
					_expect(str(paragraph).strip_edges() != "", "ending contains blank paragraph")
		for reason in db.defeats:
			var ending := EndingDirector.resolve_defeat(_fresh(str(claimant)), db, str(reason))
			_expect(str(ending.get("title", "")) != "" and bool(ending.get("defeat", false)), "defeat missing " + str(reason))
		print("ROUTE_WITNESSES %s %d routes × %d bands" % [claimant, count, BANDS.size()])
		personal_prose_counts[claimant] = {"eligible_routes": count, "route_band_paragraphs": paragraph_count, "distinct_route_band_paragraphs": distinct.size()}


func _save_roundtrip() -> void:
	for claimant in db.claimant_order:
		var state := _fresh(str(claimant))
		state.rng.seed = 1234567
		state.rng.randf()
		state.flags["QA_FLAG"] = true
		state.scheduled.append({"event": "quiet_week", "delay": 3})
		state.pending_battle = {"battle_id": "road_bandits", "on_victory": [{"op": "claim", "amount": 3}], "on_defeat": [], "on_retreat": []}
		state.post_battle = "advance_event"
		state.add_decision({"event": "quiet_week", "choice": "QA"})
		_expect(SaveManager.save_campaign(state, 3, "QA isolated roundtrip"), "save failed " + str(claimant))
		var loaded: CampaignState = SaveManager.load_campaign(3)
		_expect(loaded != null, "load failed " + str(claimant))
		if loaded == null:
			continue
		var original := state.to_dict()
		var restored := loaded.to_dict()
		for key in original:
			if key not in ["rng_seed", "rng_state"]:
				_expect(_same(original[key], restored.get(key)), "save field differs %s/%s" % [claimant, key])
		for index in 8:
			_expect(state.rng.randi() == loaded.rng.randi(), "save RNG continuity mismatch %s draw %d" % [claimant, index])
		_expect(SaveManager.save_campaign(loaded, 3, "QA backup fixture"), "backup fixture save failed")
		var corrupt := FileAccess.open(SaveManager.slot_path(3), FileAccess.WRITE)
		corrupt.store_string("{not-json")
		corrupt.close()
		var recovered: CampaignState = SaveManager.load_campaign(3)
		_expect(recovered != null and recovered.claimant_id == claimant, "corrupt save does not recover from backup")
	var malformed_path: String = SaveManager.slot_path(2)
	var file := FileAccess.open(malformed_path, FileAccess.WRITE)
	file.store_string("{\"broken\": true}")
	file.close()
	_expect(SaveManager.load_campaign(2) == null, "malformed save accepted")
	var rapid := _fresh()
	var previous_timestamp := 0
	for slot in [1, 3, 2, 0]:
		rapid.turn += 1
		_expect(SaveManager.save_campaign(rapid, slot, "QA rapid sequence"), "rapid save fails")
		_expect(SaveManager.latest_slot() == slot, "rapid save ordering selects older slot after " + str(slot))
		var metadata := SaveManager.read_json(SaveManager.slot_path(slot))
		_expect(typeof(metadata.get("saved_at_unix_usec", null)) == TYPE_STRING, "save timestamp loses integer precision in JSON")
		var timestamp := int(str(metadata.get("saved_at_unix_usec", "0")))
		_expect(timestamp > previous_timestamp, "precise save timestamp does not advance")
		previous_timestamp = timestamp
	var second := 0
	for slot in [1, 3, 2, 0]:
		var legacy := SaveManager.read_json(SaveManager.slot_path(slot))
		legacy.erase("saved_at_unix_usec")
		legacy["saved_at"] = "2024-01-01T00:00:0" + str(second)
		SaveManager.write_json(SaveManager.slot_path(slot), legacy)
		second += 1
	_expect(SaveManager.latest_slot() == 0, "legacy timestamp ordering ignores most recent save")


func _continuity() -> void:
	for id in db.characters:
		if id == "mira":
			continue
		var state := _fresh()
		EffectResolver.apply(state, [{"op": "kill", "id": str(id)}], db)
		_expect(not state.npc_alive(str(id)), "kill leaves living character " + str(id))
		_expect(not state.commanders.has(id), "dead commander retained " + str(id))
		EffectResolver.apply(state, [{"op": "free_npc", "id": str(id)}], db)
		_expect(not state.npc_alive(str(id)), "free_npc resurrects " + str(id))
		EffectResolver.apply(state, [{"op": "capture", "id": str(id)}], db)
		_expect(not state.npc_alive(str(id)), "capture resurrects " + str(id))
		var available := EventDirector._available(state, db)
		for event in available:
			_expect(ConditionChecker.met(event.get("requires", {}), state, db), "dead NPC event still available " + str(event.id))
	var state := _fresh()
	state.forced_events = ["pell_private"]
	EffectResolver.apply(state, [{"op": "kill", "id": "oren_pell"}], db)
	EventDirector.pick_audience(state, db)
	_expect(not state.event_queue.has("pell_private"), "scheduled meeting retained after Pell dies")


func _battle_commands() -> void:
	for claimant in db.claimant_order:
		for battle_id in db.battles:
			var state := _fresh(str(claimant))
			state.forces = 2000
			state.pending_battle = {"battle_id": battle_id, "on_victory": [{"op": "flag", "flag": "QA_VICTORY"}], "on_defeat": [{"op": "flag", "flag": "QA_DEFEAT"}], "on_retreat": [{"op": "flag", "flag": "QA_RETREAT"}]}
			var setup := CampaignRules.build_battle(state, db)
			var result := BattleResolver.auto_resolve(setup)
			_expect(str(result.get("outcome", "")) in ["victory", "defeat", "retreat", "stalemate"], "invalid battle outcome")
			_expect(int(result.get("forces_lost", -1)) >= 0 and int(result.get("forces_lost", -1)) <= state.forces, "battle loses impossible number")
			var again := BattleResolver.auto_resolve(setup)
			_expect(JSON.stringify(result) == JSON.stringify(again), "same battle seed yields different outcome")
			CampaignRules.apply_battle_return(state, db, result)
			_expect(state.pending_battle.is_empty(), "pending battle not consumed")
			_invariants(state, "battle " + str(battle_id))
	var state := _fresh()
	state.pending_battle = {"battle_id": "road_bandits", "on_victory": [], "on_defeat": [], "on_retreat": []}
	for command in BattleResolver.COMMANDS:
		var battle := BattleResolver.new()
		battle.setup(CampaignRules.build_battle(state, db))
		for index in 12:
			battle.resolve_round({"left": command, "center": command, "right": command})
			if battle.finished:
				break
		_expect(battle.finished, "battle command fails to terminate " + command)


func _simulate(claimant: String, policy: String, seed_value: int) -> void:
	simulations += 1
	var state := _fresh(claimant)
	state.rng.seed = seed_value
	var selector := RandomNumberGenerator.new()
	selector.seed = seed_value + 97
	var conclusion := "week_limit"
	var won := false
	var reached_route := ""
	var replay: Array = []
	for week in 80:
		if state.defeat_reason != "":
			conclusion = "defeat_" + state.defeat_reason
			break
		EventDirector.pick_audience(state, db)
		while state.event_index < state.event_queue.size() and state.defeat_reason == "":
			var event := EventDirector.current(state, db)
			if event.is_empty():
				state.event_index += 1
				continue
			var event_id := str(event.id)
			visited_events[event_id] = true
			var legal: Array = []
			for choice in event.get("choices", []):
				if ConditionChecker.choice_failures(choice, state, db).is_empty():
					legal.append(choice)
			if legal.is_empty():
				_fail("no legal choice claimant=%s seed=%d week=%d event=%s" % [claimant, seed_value, state.turn, event_id])
				state.event_index += 1
				continue
			var selected := _select(legal, state, policy, selector)
			visited_choices[event_id + "/" + str(selected.get("id", ""))] = true
			replay.append({"week": state.turn, "kind": "petition", "event": event_id, "choice": str(selected.get("id", "")), "claim_before": state.claim})
			_apply_campaign(state, selected.get("effects", []), "%s seed=%d event=%s" % [claimant, seed_value, event_id])
			state.add_decision({"event": event_id, "choice": str(selected.get("id", ""))})
			state.event_index += 1
		if state.defeat_reason != "":
			conclusion = "defeat_" + state.defeat_reason
			break
		var legal_routes: Array = []
		for row in EndingDirector.list_routes(state, db):
			if bool(row.open):
				legal_routes.append(row.route)
		if not legal_routes.is_empty():
			var route: Dictionary = legal_routes[selector.randi_range(0, legal_routes.size() - 1)]
			var battle_result := {}
			if route.has("battle_id"):
				state.pending_battle = {"battle_id": route.battle_id, "on_victory": [], "on_defeat": [], "on_retreat": []}
				battle_result = BattleResolver.auto_resolve(CampaignRules.build_battle(state, db))
				CampaignRules.apply_battle_return(state, db, battle_result)
			if state.defeat_reason != "":
				conclusion = "defeat_" + state.defeat_reason
				break
			var ending := EndingDirector.resolve(state, db, str(route.id), battle_result)
			conclusion = str(ending.ending_id)
			won = not bool(ending.get("defeat", true))
			reached_route = str(route.id)
			replay.append({"week": state.turn, "kind": "throne", "route": reached_route, "ending": conclusion, "claim": state.claim, "stability": state.stability, "rations": state.rations, "forces": state.forces, "blocs": state.blocs.duplicate()})
			ending_routes[claimant + "/" + str(route.id)] = true
			break
		var legal: Array = []
		for action in ActionBoard.available(state, db):
			if ConditionChecker.met(action.get("requires", {}), state, db):
				legal.append(action)
		if legal.is_empty():
			_fail("no strategic action claimant=%s seed=%d week=%d" % [claimant, seed_value, state.turn])
			break
		var selected := _select(legal, state, policy, selector)
		replay.append({"week": state.turn, "kind": "decree", "action": str(selected.get("id", "")), "claim_before": state.claim})
		_apply_campaign(state, selected.get("effects", []), "%s seed=%d action=%s" % [claimant, seed_value, selected.get("id", "")])
		if state.defeat_reason != "":
			conclusion = "defeat_" + state.defeat_reason
			break
		CampaignRules.close_week(state, db)
		_invariants(state, "%s seed=%d week=%d" % [claimant, seed_value, state.turn])
	if not ending_counts.has(claimant):
		ending_counts[claimant] = {}
	ending_counts[claimant][conclusion] = int(ending_counts[claimant].get(conclusion, 0)) + 1
	_expect(conclusion != "week_limit", "campaign failed to reach a conclusion %s/%s seed=%d" % [claimant, policy, seed_value])
	if not policy_counts.has(claimant):
		policy_counts[claimant] = {}
	if not policy_counts[claimant].has(policy):
		policy_counts[claimant][policy] = {"campaigns": 0, "victories": 0, "defeats": 0, "total_weeks": 0, "routes": []}
	var totals: Dictionary = policy_counts[claimant][policy]
	totals["campaigns"] += 1
	totals["victories" if won else "defeats"] += 1
	totals["total_weeks"] += state.turn
	if reached_route != "" and not totals.routes.has(reached_route):
		totals.routes.append(reached_route)
	if won and (not winning_replays.has(claimant) or (policy == "legitimacy" and str(winning_replays[claimant].get("policy", "")) != "legitimacy")):
		winning_replays[claimant] = {"claimant": claimant, "seed": seed_value, "policy": policy, "ending": conclusion, "weeks": state.turn, "steps": replay}


func _army_and_capital() -> void:
	for claimant in db.claimant_order:
		var state := _fresh(str(claimant))
		for forces in [0, 1, 8, 28, 48, 99, 100, 250, 900, 980, 4000]:
			state.forces = forces
			var total := 0
			for unit in ArmyComposer.compose_player(state, db):
				total += int(unit.strength)
				if str(unit.get("elite_id", "")) == "queens_guard":
					_expect(int(unit.strength) <= 48, "Queen's Guard formation exceeds canonical48 at host size%d" % forces)
			_expect(total == forces, "army composition creates/loses soldiers %s force=%d total=%d" % [claimant, forces, total])
	var state := _fresh()
	state.pending_battle = {"battle_id": "throne_conquest", "on_victory": [], "on_defeat": [], "on_retreat": []}
	state.territories["caerlyn"]["controller"] = "player"
	var defending := CampaignRules.build_battle(state, db)
	_expect(bool(state.pending_battle.get("defending_capital", false)), "capital holder is sent to assault own city")
	_expect(str(defending.title).contains("Siege"), "capital defence has assault battle title")
	var preserved := CampaignState.from_dict(state.to_dict(), db)
	_expect(CampaignRules.build_battle(preserved, db).seed == defending.seed, "battle seed changes after pending save roundtrip")
	state.last_battle = {"defending_capital": true}
	var defender_ending := EndingDirector.resolve(state, db, "conquest", {"outcome": "victory"}, "triumph")
	_expect(str(defender_ending.paragraphs[0]).contains("already held Caerlyn"), "defended capital ending claims player conquered own city")
	state = _fresh("ethan")
	state.pending_battle = {"battle_id": "throne_conquest", "on_victory": [], "on_defeat": [], "on_retreat": []}
	CampaignRules.build_battle(state, db)
	_expect(not bool(state.pending_battle.get("defending_capital", false)), "unlanded claimant labelled capital defender")


func _select(rows: Array, state: CampaignState, policy: String, selector: RandomNumberGenerator) -> Dictionary:
	if policy == "random":
		return rows[selector.randi_range(0, rows.size() - 1)]
	var winner: Dictionary = rows[0]
	var best := -INF
	for row in rows:
		var value := _score(row.get("effects", []), state, policy) + selector.randf_range(0.0, 0.2)
		if value > best:
			best = value
			winner = row
	return winner


func _score(effects: Array, state: CampaignState, policy: String) -> float:
	var value := 0.0
	for effect in effects:
		var amount := float(effect.get("amount", 0))
		var op := str(effect.get("op", ""))
		match op:
			"claim": value += amount * (5.0 if policy == "legitimacy" else 2.0)
			"gold": value += amount * (0.07 if state.gold < 250 else 0.008)
			"rations": value += amount * (5.0 if state.rations < Balance.ration_need(state.forces) * 3 else 0.4)
			"buy_rations": value += mini(amount, float(state.gold / maxi(1, int(effect.get("gold_each", 1))))) * (4.0 if state.rations < Balance.ration_need(state.forces) * 3 else -0.2)
			"forces", "recruit": value += amount * (0.03 if policy == "military" else 0.004)
			"stability": value += amount * 1.5
			"reputation": value += amount * (2.0 if policy == "benevolent" else 0.5)
			"fear": value += amount * (1.2 if policy == "ruthless" else -0.8)
			"foreign": value -= amount * 1.5
			"morale": value += amount * (0.8 if policy == "military" else 0.2)
			"bloc":
				var bloc := str(effect.get("bloc", ""))
				var weight := 1.0
				if policy == "benevolent" and bloc == "people": weight = 3.0
				if policy == "diplomacy" and bloc in ["court", "nobility", "flame"]: weight = 2.0
				if policy == "military" and bloc == "military": weight = 3.0
				value += amount * weight
			"relation", "house_opinion": value += amount * (1.0 if policy == "diplomacy" else 0.2)
			"territory": value += 25.0 if str(effect.get("controller", "player")) == "player" else -25.0
			"house_declare": value += 18.0 if str(effect.get("declared", "player")) == "player" else -8.0
			"kill": value += 8.0 if policy == "ruthless" and str(effect.get("id", "")) != state.claimant_id else -15.0
			"defeat": value -= 500.0
			"prove_blood": value += 20.0 if not bool(state.flags.get("BLOOD_PROVEN", false)) and state.ledger.size() >= 2 else 0.0
			"ledger_add": value += 4.0 if not state.has_ledger(str(effect.get("id", ""))) else 0.0
			"chance", "assassinate":
				var p := float(effect.get("p", effect.get("chance", 0.5)))
				value += p * _score(effect.get("success", []), state, policy) + (1.0 - p) * _score(effect.get("fail", []), state, policy)
			"battle": value += _score(effect.get("on_victory", []), state, policy) * (0.8 if state.forces >= 1800 else 0.4) - 5.0
	return value


func _apply_campaign(state: CampaignState, effects: Array, context: String) -> void:
	EffectResolver.apply(state, effects, db)
	if not state.pending_battle.is_empty() and state.defeat_reason == "":
		var result := BattleResolver.auto_resolve(CampaignRules.build_battle(state, db))
		CampaignRules.apply_battle_return(state, db, result)
	_invariants(state, context)


func _prisoner_and_house_payoffs() -> void:
	var state := _fresh()
	EffectResolver.apply(state, [{"op": "capture", "id": "oren_pell"}], db)
	for prefix in ["release_", "ransom_", "execute_"]:
		var matching := {}
		for action in ActionBoard.available(state, db):
			if str(action.get("id", "")) == prefix + "oren_pell":
				matching = action
		_expect(not matching.is_empty(), "captured Pell has no " + prefix + " action")
		if matching.is_empty():
			continue
		var trial := CampaignState.from_dict(state.to_dict(), db)
		EffectResolver.apply(trial, matching.get("effects", []), db)
		_expect(str(trial.npcs.oren_pell.state) != "captured", "prisoner settlement leaves custody active")
		_expect(trial.npc_alive("oren_pell") == (prefix != "execute_"), "prisoner settlement has wrong mortality")
		for action in ActionBoard.available(trial, db):
			_expect(str(action.get("id", "")) != prefix + "oren_pell", "settlement can be repeated")
	for house_id in db.house_order:
		state = _fresh()
		var estate := ""
		for territory_id in db.territory_order:
			if str(db.territories[territory_id].get("house", "")) == str(house_id):
				estate = str(territory_id)
				break
		if estate == "":
			continue
		state.territories[estate]["controller"] = house_id
		EffectResolver.apply(state, [{"op": "house_declare", "id": house_id, "declared": "player"}], db)
		_expect(str(state.territories[estate].controller) == "player", "declared house estate fails to join player " + str(house_id))
		var leader := str(db.houses[house_id].get("leader", ""))
		# A declaring claimant may bring his own household estates into the pact.
		# An occupation by another claimant must survive that declaration.
		var occupier := "ethan" if leader == "alistair" else "alistair"
		state.territories[estate]["controller"] = occupier
		EffectResolver.apply(state, [{"op": "house_declare", "id": house_id, "declared": "player"}], db)
		_expect(str(state.territories[estate].controller) == occupier, "declaration seizes rival-held estate " + estate)


func _invariants(state: CampaignState, context: String) -> void:
	_expect(state.gold >= 0 and state.rations >= 0 and state.forces >= 0, context + " negative resource")
	for pair in [["claim", state.claim], ["fear", state.fear], ["stability", state.stability], ["morale", state.army_morale]]:
		_expect(int(pair[1]) >= 0 and int(pair[1]) <= 100, context + " out of range " + str(pair[0]))
	for id in state.blocs:
		_expect(int(state.blocs[id]) >= -100 and int(state.blocs[id]) <= 100, context + " bloc outside range")
	for id in state.commanders:
		_expect(id == state.claimant_id or state.npc_alive(str(id)), context + " dead commander " + str(id))
	for id in state.ledger:
		_expect(db.ledger.has(str(id)), context + " unknown ledger " + str(id))
	for id in state.rivals:
		if not bool(state.rivals[id].get("alive", false)):
			_expect(int(state.rivals[id].get("forces", 0)) == 0, context + " dead rival has soldiers " + str(id))


func _expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		_fail(message)


func _same(left, right) -> bool:
	if typeof(left) in [TYPE_INT, TYPE_FLOAT] and typeof(right) in [TYPE_INT, TYPE_FLOAT]:
		return float(left) == float(right)
	if typeof(left) != typeof(right):
		return false
	if typeof(left) == TYPE_DICTIONARY:
		if left.size() != right.size():
			return false
		for key in left:
			if not right.has(key) or not _same(left[key], right[key]):
				return false
		return true
	if typeof(left) == TYPE_ARRAY:
		if left.size() != right.size():
			return false
		for index in left.size():
			if not _same(left[index], right[index]):
				return false
		return true
	return left == right


func _fail(message: String) -> void:
	if errors.size() < 200 and not errors.has(message):
		errors.append(message)


func _report(seeds: int) -> void:
	var unseen: Array = []
	for event in db.events:
		if not visited_events.has(str(event.id)):
			unseen.append(str(event.id))
	report = {
		"engine": Engine.get_version_info().string,
		"checked_at_utc": Time.get_datetime_string_from_system(true),
		"checks": checks,
		"catalogue_events": db.events.size(),
		"catalogue_choices": choices,
		"effect_branches_executed": branches,
		"ending_fixture_variants": ending_fixtures.size(),
		"personal_prose_counts": personal_prose_counts,
		"producer_deliveries": producer_deliveries,
		"seeded_campaigns": simulations,
		"seeds_per_policy_per_claimant": seeds,
		"policies": POLICIES,
		"campaign_week_limit": 80,
		"events_seen_in_campaigns": visited_events.size(),
		"choices_seen_in_campaigns": visited_choices.size(),
		"unseen_campaign_events": unseen,
		"ending_counts": ending_counts,
		"policy_counts": policy_counts,
		"routes_reached_in_campaigns": ending_routes.keys(),
		"failures": errors,
		"coverage_note": "Every authored choice receives a valid contextual condition witness, and every success/failure/battle-return effect branch is executed independently. Seeded campaign policies explore connected play. This does not prove all combinatorial decision sequences or validate prose meaning automatically.",
	}
	DirAccess.make_dir_recursive_absolute("res://tests/.artifacts")
	var file := FileAccess.open("res://tests/.artifacts/release_audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	var replay_file := FileAccess.open("res://tests/.artifacts/winning_replays.json", FileAccess.WRITE)
	replay_file.store_string(JSON.stringify(winning_replays, "\t"))
