class_name ContentDB
extends RefCounted

## Loads every JSON catalogue. Gameplay code reads these tables; it does not own the prose.

var claimants := {}
var claimant_order: Array = []
var characters := {}
var character_order: Array = []
var houses := {}
var house_order: Array = []
var territories := {}
var territory_order: Array = []
var events: Array = []
var events_by_id := {}
var actions: Array = []
var ledger := {}
var ledger_order: Array = []
var units := {}
var battles := {}
var routes: Array = []
var chronicle := {}
var chronicle_entries := {}
var defeats := {}
var rumours: Array = []
var load_errors: PackedStringArray = []


func load_all() -> void:
	claimants.clear()
	claimant_order.clear()
	characters.clear()
	character_order.clear()
	houses.clear()
	house_order.clear()
	territories.clear()
	territory_order.clear()
	events.clear()
	events_by_id.clear()
	actions.clear()
	ledger.clear()
	ledger_order.clear()
	units.clear()
	battles.clear()
	routes.clear()
	chronicle_entries.clear()
	defeats.clear()
	rumours.clear()
	load_errors = PackedStringArray()

	for row in _array("res://data/claimants.json"):
		var id := str(row.get("id", ""))
		claimants[id] = row
		claimant_order.append(id)
	for row in _array("res://data/characters.json"):
		var id := str(row.get("id", ""))
		characters[id] = row
		character_order.append(id)
	for row in _array("res://data/houses.json"):
		var id := str(row.get("id", ""))
		houses[id] = row
		house_order.append(id)
	for row in _array("res://data/territories.json"):
		var id := str(row.get("id", ""))
		territories[id] = row
		territory_order.append(id)
	for row in _array("res://data/ledger.json"):
		var id := str(row.get("id", ""))
		ledger[id] = row
		ledger_order.append(id)
	var unit_rows = _read("res://data/units.json")
	if typeof(unit_rows) == TYPE_DICTIONARY:
		units = unit_rows
	for row in _array("res://data/battles.json"):
		battles[str(row.get("id", ""))] = row
	routes = _array("res://data/routes.json")
	var chronicle_raw = _read("res://data/chronicle.json")
	chronicle = chronicle_raw if typeof(chronicle_raw) == TYPE_DICTIONARY else {}
	_index_chronicle()
	var defeat_raw = _read("res://data/defeats.json")
	defeats = defeat_raw if typeof(defeat_raw) == TYPE_DICTIONARY else {}
	rumours = _array("res://data/rumours.json")
	actions = _array("res://data/actions.json")
	_load_events()


func _load_events() -> void:
	var dir := DirAccess.open("res://data/events")
	if dir == null:
		load_errors.append("Missing res://data/events")
		return
	var names: Array = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	for event_file in names:
		for row in _array("res://data/events/" + str(event_file)):
			var id := str(row.get("id", ""))
			if id == "":
				load_errors.append("%s has an event without an id" % event_file)
				continue
			if events_by_id.has(id):
				load_errors.append("Duplicate event id %s" % id)
			events.append(row)
			events_by_id[id] = row


func _index_chronicle() -> void:
	for category in chronicle.get("categories", []):
		if typeof(category) != TYPE_DICTIONARY:
			continue
		for entry in category.get("entries", []):
			if typeof(entry) == TYPE_DICTIONARY:
				chronicle_entries[str(entry.get("id", ""))] = entry


func event_by_id(id: String) -> Dictionary:
	return events_by_id.get(id, {})


func chronicle_title(id: String) -> String:
	var entry: Dictionary = chronicle_entries.get(id, {})
	return str(entry.get("title", id))


func controller_name(controller: String, state_claimant := "") -> String:
	if controller == "player":
		if state_claimant != "" and claimants.has(state_claimant):
			return "You (" + str(claimants[state_claimant].get("short", "You")) + ")"
		return "Your control"
	if controller == "neutral":
		return "Unaligned"
	if controller == "varos":
		return "Varos"
	if controller == "rebels":
		return "Rebels"
	if claimants.has(controller):
		return str(claimants[controller].get("short", controller))
	if houses.has(controller):
		return str(houses[controller].get("name", controller))
	return controller.capitalize()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = load_errors.duplicate()
	if claimant_order.size() != 4:
		errors.append("Expected 4 claimants, found %d" % claimant_order.size())
	if events.size() < 40:
		errors.append("Expected at least 40 events, found %d" % events.size())
	for event in events:
		_validate_event(event, errors)
	for action in actions:
		if str(action.get("id", "")) == "":
			errors.append("Action missing id")
		if not action.has("generator"):
			_walk_effects(action.get("effects", []), errors, "action " + str(action.get("id", "?")))
	for route in routes:
		if str(route.get("id", "")) == "":
			errors.append("Route missing id")
		var battle_id := str(route.get("battle_id", ""))
		if battle_id != "" and not battles.has(battle_id):
			errors.append("Route %s missing battle %s" % [route.get("id", ""), battle_id])
	for id in ledger:
		var kind := str(ledger[id].get("kind", ""))
		if not ["secret", "evidence", "favour", "document", "rumour", "debt"].has(kind):
			errors.append("Ledger %s has unknown kind %s" % [id, kind])
	return errors


func _validate_event(event: Dictionary, errors: PackedStringArray) -> void:
	var id := str(event.get("id", ""))
	var choices = event.get("choices", [])
	if typeof(choices) != TYPE_ARRAY or choices.is_empty():
		errors.append("Event %s has no choices" % id)
		return
	_check_requires(event.get("requires", {}), errors, "event " + id)
	var index := 0
	for choice in choices:
		index += 1
		if typeof(choice) != TYPE_DICTIONARY or str(choice.get("text", "")) == "":
			errors.append("Event %s choice %d missing text" % [id, index])
			continue
		_check_requires(choice.get("requires", {}), errors, "event %s choice %d" % [id, index])
		_walk_effects(choice.get("effects", []), errors, "event %s choice %d" % [id, index])


func _check_requires(requires, errors: PackedStringArray, context: String) -> void:
	if typeof(requires) != TYPE_DICTIONARY:
		return
	_check_id_list(requires.get("claimant", null), claimants, errors, context, "claimant", true)
	_check_id_list(requires.get("not_claimant", null), claimants, errors, context, "claimant", true)
	_check_id_list(requires.get("controls", null), territories, errors, context, "territory", false)
	_check_id_list(requires.get("controls_any", null), territories, errors, context, "territory", false)
	_check_id_list(requires.get("not_controls", null), territories, errors, context, "territory", false)
	_check_id_list(requires.get("npc_alive", null), characters, errors, context, "npc", false)
	_check_id_list(requires.get("npc_dead", null), characters, errors, context, "npc", false)
	_check_id_list(requires.get("has_ledger", null), ledger, errors, context, "ledger", false)
	_check_id_list(requires.get("missing_ledger", null), ledger, errors, context, "ledger", false)
	_check_id_list(requires.get("has_ledger_any", null), ledger, errors, context, "ledger", false)
	_check_id_list(requires.get("rival_alive", null), claimants, errors, context, "rival", false)
	_check_map_keys(requires.get("relation_min", {}), characters, errors, context, "npc")
	_check_map_keys(requires.get("political_min", {}), characters, errors, context, "npc")
	_check_map_keys(requires.get("min_bloc", {}), _bloc_set(), errors, context, "bloc")
	_check_map_keys(requires.get("max_bloc", {}), _bloc_set(), errors, context, "bloc")
	_check_map_keys(requires.get("house_declared", {}), houses, errors, context, "house")
	_check_map_keys(requires.get("house_opinion_min", {}), houses, errors, context, "house")
	_check_map_keys(requires.get("npc_state", {}), characters, errors, context, "npc")
	if requires.has("chronicle") and not chronicle_entries.has(str(requires["chronicle"])):
		errors.append("%s unknown chronicle %s" % [context, requires["chronicle"]])
	_check_id_list(requires.get("chronicle_any", null), chronicle_entries, errors, context, "chronicle", false)


func _walk_effects(effects, errors: PackedStringArray, context: String) -> void:
	if typeof(effects) != TYPE_ARRAY:
		errors.append("%s effects are not a list" % context)
		return
	var seen_battle := false
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			errors.append("%s has a broken effect" % context)
			continue
		var op := str(effect.get("op", ""))
		if op == "":
			errors.append("%s effect missing op" % context)
			continue
		if seen_battle:
			errors.append("%s has an effect after battle" % context)
		if op == "battle":
			seen_battle = true
			var battle_id := str(effect.get("battle_id", ""))
			if not battles.has(battle_id):
				errors.append("%s missing battle %s" % [context, battle_id])
			_walk_effects(effect.get("on_victory", []), errors, context + " victory")
			_walk_effects(effect.get("on_defeat", []), errors, context + " defeat")
			_walk_effects(effect.get("on_retreat", []), errors, context + " retreat")
		elif op == "chance" or op == "assassinate":
			_walk_effects(effect.get("success", []), errors, context + " success")
			_walk_effects(effect.get("fail", []), errors, context + " fail")
			if op == "assassinate" and not characters.has(str(effect.get("target", ""))):
				errors.append("%s assassination target missing" % context)
		elif op == "schedule":
			if not events_by_id.has(str(effect.get("event", ""))):
				errors.append("%s schedules missing event %s" % [context, effect.get("event", "")])
		elif op == "ledger_add" or op == "ledger_remove":
			if not ledger.has(str(effect.get("id", ""))):
				errors.append("%s ledger id missing %s" % [context, effect.get("id", "")])
		elif op == "grant_first_missing" or op == "prove_blood":
			_check_id_list(effect.get("ids", []), ledger, errors, context, "ledger", false)
		elif op == "territory" or op == "loyalty" or op == "unrest" or op == "fort":
			if not territories.has(str(effect.get("id", ""))):
				errors.append("%s territory missing %s" % [context, effect.get("id", "")])
		elif op in ["kill", "capture", "free_npc", "memory", "grudge", "promise", "break_promise", "relation", "political", "commander_add"]:
			if not characters.has(str(effect.get("id", ""))):
				errors.append("%s npc missing %s" % [context, effect.get("id", "")])
		elif op == "chronicle":
			if not chronicle_entries.has(str(effect.get("id", ""))):
				errors.append("%s chronicle missing %s" % [context, effect.get("id", "")])
		elif op == "house_opinion" or op == "house_declare":
			if not houses.has(str(effect.get("id", ""))):
				errors.append("%s house missing %s" % [context, effect.get("id", "")])
		elif op == "bloc":
			if not Balance.BLOCS.has(str(effect.get("bloc", ""))):
				errors.append("%s bad bloc %s" % [context, effect.get("bloc", "")])
		elif op == "elite_add" or op == "elite_remove":
			if not units.has(str(effect.get("id", ""))):
				errors.append("%s elite missing %s" % [context, effect.get("id", "")])
		elif op == "rival":
			if not claimants.has(str(effect.get("id", ""))):
				errors.append("%s rival missing %s" % [context, effect.get("id", "")])
		elif op == "defeat":
			pass


func _check_id_list(raw, table: Dictionary, errors: PackedStringArray, context: String, label: String, allow_string: bool) -> void:
	if raw == null:
		return
	if allow_string and (typeof(raw) == TYPE_STRING or typeof(raw) == TYPE_STRING_NAME):
		if not table.has(str(raw)):
			errors.append("%s unknown %s %s" % [context, label, raw])
		return
	if typeof(raw) != TYPE_ARRAY:
		if allow_string:
			if not table.has(str(raw)):
				errors.append("%s unknown %s %s" % [context, label, raw])
		return
	for item in raw:
		if not table.has(str(item)):
			errors.append("%s unknown %s %s" % [context, label, item])


func _check_map_keys(raw, table: Dictionary, errors: PackedStringArray, context: String, label: String) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	for key in raw:
		if not table.has(str(key)):
			errors.append("%s unknown %s %s" % [context, label, key])


func _bloc_set() -> Dictionary:
	var table := {}
	for id in Balance.BLOCS:
		table[id] = true
	return table


func _array(path: String) -> Array:
	var parsed = _read(path)
	if typeof(parsed) != TYPE_ARRAY:
		load_errors.append("%s is not a list" % path)
		return []
	return parsed


func _read(path: String):
	if not FileAccess.file_exists(path):
		load_errors.append("Missing " + path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_errors.append("Unreadable " + path)
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		load_errors.append("Broken JSON " + path)
	return parsed
