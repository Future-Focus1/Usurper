class_name ArmyComposer
extends RefCounted

## Turns an abstract force count into a handful of battle tokens.


static func compose_player(state: CampaignState, db: ContentDB) -> Array:
	var claimant: Dictionary = db.claimants.get(state.claimant_id, {})
	var bias = claimant.get("army_bias", ["infantry", "spears", "archers", "cavalry"])
	var short := str(claimant.get("short", "Your"))
	return _compose(db, state.forces, bias, state.elites, state.commanders, state.claimant_id, short)


static func compose_custom(db: ContentDB, forces: int, types, elites: Array, label: String) -> Array:
	return _compose(db, forces, types, elites, [], "", label)


static func _compose(db: ContentDB, forces: int, types, elites: Array, commanders: Array, banner_id: String, label: String) -> Array:
	forces = maxi(0, forces)
	if forces <= 0:
		return []
	var type_list: Array = types if typeof(types) == TYPE_ARRAY and not types.is_empty() else ["infantry", "spears", "archers"]
	var units: Array = []
	var used := 0
	if banner_id != "":
		var banner_size := clampi(int(float(forces) * 0.16), 30, mini(420, forces))
		var banner := _make(db, "infantry", banner_size, "%s's Banner" % label, "banner")
		banner["commander_id"] = banner_id
		banner["commander_name"] = label
		banner["attack"] = int(banner["attack"]) + 1
		units.append(banner)
		used += banner_size
	for elite_id in elites:
		if used >= forces - 20:
			break
		var data: Dictionary = db.units.get(str(elite_id), {})
		if data.is_empty():
			continue
		var size := mini(int(data.get("company", 400)), forces - used)
		if size < 30:
			continue
		var elite := _from_data(data, size, str(elite_id))
		elite["elite"] = true
		elite["elite_id"] = str(elite_id)
		units.append(elite)
		used += size
	var remaining := forces - used
	var generic_count := 3 if forces >= 900 else (2 if forces >= 250 else 1)
	if units.size() >= 5:
		generic_count = 1
	if remaining > 0:
		var each := int(remaining / generic_count)
		var spare := remaining - each * generic_count
		for index in generic_count:
			var type_id := str(type_list[index % type_list.size()])
			var size := each + (spare if index == 0 else 0)
			if size <= 0:
				continue
			var data: Dictionary = db.units.get(type_id, {})
			var token := _make(db, type_id, size, str(data.get("name", type_id)), "g%d" % index)
			units.append(token)
	var spare_commanders: Array = []
	for commander_id in commanders:
		spare_commanders.append(str(commander_id))
	for unit in units:
		if str(unit.get("commander_id", "")) != "":
			continue
		if spare_commanders.is_empty():
			break
		unit["commander_id"] = str(spare_commanders.pop_front())
	var total := 0
	for unit in units:
		total += int(unit["strength"])
	if not units.is_empty() and total != forces:
		units[0]["strength"] = maxi(1, int(units[0]["strength"]) + (forces - total))
		units[0]["max_strength"] = int(units[0]["strength"])
	return units


static func _make(db: ContentDB, type_id: String, size: int, name: String, uid: String) -> Dictionary:
	var data: Dictionary = db.units.get(type_id, {})
	var unit := _from_data(data, size, uid)
	unit["type"] = type_id
	unit["name"] = name
	if str(unit.get("base", "")) == "":
		unit["base"] = type_id
	return unit


static func _from_data(data: Dictionary, size: int, uid: String) -> Dictionary:
	return {
		"uid": uid + "_" + str(size),
		"type": str(data.get("base", data.get("id", "infantry"))),
		"name": str(data.get("name", "Company")),
		"strength": size,
		"max_strength": size,
		"attack": int(data.get("attack", 8)),
		"defense": int(data.get("defense", 8)),
		"ranged": bool(data.get("ranged", false)),
		"vs": data.get("vs", {}),
		"base": str(data.get("base", "")),
		"elite": false,
		"elite_id": "",
		"commander_id": "",
		"commander_name": "",
	}
