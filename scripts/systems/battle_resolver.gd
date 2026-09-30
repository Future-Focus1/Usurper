class_name BattleResolver
extends RefCounted

## Three lanes, a reserve, and morale. One token stands for a company, not a soldier.

const LANES: Array[String] = ["left", "center", "right"]
const COMMANDS: Array[String] = ["advance", "hold", "charge", "flank", "volley", "rally", "withdraw"]

var rng := RandomNumberGenerator.new()
var title := ""
var enemy_name := ""
var player_name := ""
var battle_id := ""
var rival_id := ""
var lanes := {}
var player_reserve: Array = []
var enemy_reserve: Array = []
var player_morale := 70
var enemy_morale := 70
var round_no := 1
var log_lines: Array = []
var finished := false
var outcome := ""
var deployment_open := true
var player_forces := 1
var enemy_forces := 1
var start_player_strength := 1
var start_enemy_strength := 1
var destroyed: Array = []
var max_rounds := 8


func setup(setup: Dictionary) -> void:
	battle_id = str(setup.get("battle_id", ""))
	title = str(setup.get("title", "Battle"))
	enemy_name = str(setup.get("enemy_name", "Enemy"))
	player_name = str(setup.get("player_name", "You"))
	rival_id = str(setup.get("rival_id", ""))
	player_forces = maxi(1, int(setup.get("player_forces", 1)))
	enemy_forces = maxi(1, int(setup.get("enemy_forces", 1)))
	player_morale = clampi(int(setup.get("player_morale", 70)), 1, 100)
	enemy_morale = clampi(int(setup.get("enemy_morale", 60)), 1, 100)
	var seed := int(setup.get("seed", 1))
	rng.seed = seed if seed != 0 else 1
	lanes = {}
	for lane in LANES:
		lanes[lane] = {"player": [], "enemy": []}
	player_reserve = []
	enemy_reserve = []
	destroyed = []
	_deploy(setup.get("player_units", []), "player")
	_deploy(setup.get("enemy_units", []), "enemy")
	start_player_strength = maxi(1, _strength("player"))
	start_enemy_strength = maxi(1, _strength("enemy"))
	log_lines.append("%s meets %s." % [player_name, enemy_name])


static func auto_resolve(setup: Dictionary) -> Dictionary:
	var battle := BattleResolver.new()
	battle.setup(setup)
	var guard := 0
	while not battle.finished and guard < 12:
		battle.resolve_round(battle.ai_commands("player"))
		guard += 1
	if not battle.finished:
		battle.retreat()
	return battle.result()


func move_player(uid: String, to_lane: String) -> void:
	if finished or not deployment_open:
		return
	var unit := _extract(uid, "player")
	if unit.is_empty():
		return
	if to_lane == "reserve":
		player_reserve.append(unit)
	elif to_lane in LANES:
		lanes[to_lane]["player"].append(unit)


func resolve_round(commands: Dictionary, commit_uid := "", commit_lane := "") -> void:
	if finished:
		return
	deployment_open = false
	if commit_uid != "" and commit_lane in LANES:
		var committed := _take_reserve("player", commit_uid)
		if not committed.is_empty():
			lanes[commit_lane]["player"].append(committed)
			log_lines.append("A reserve company enters the %s." % commit_lane)
	_fill_empty_field("player")
	_fill_empty_field("enemy")
	var enemy_plan := ai_commands("enemy")
	var plan := {}
	for lane in LANES:
		var command := str(commands.get(lane, "advance"))
		plan[lane] = command if command in COMMANDS else "advance"
	var blows: Array = []
	var withdraws: Array = []
	var rally := {"player": 0, "enemy": 0}
	var before := {"player": _strength("player"), "enemy": _strength("enemy")}
	for lane in LANES:
		_plan(lane, "player", str(plan[lane]), "enemy", str(enemy_plan[lane]), blows, withdraws, rally)
		_plan(lane, "enemy", str(enemy_plan[lane]), "player", str(plan[lane]), blows, withdraws, rally)
	var taken := {"player": 0, "enemy": 0}
	for blow in blows:
		var unit: Dictionary = blow["unit"]
		var lane := _find_lane(unit)
		var side := str(unit.get("side", "player"))
		var defender_command := str(plan.get(lane, "advance")) if side == "player" else str(enemy_plan.get(lane, "advance"))
		var damage := int(blow["damage"])
		if defender_command == "hold":
			damage = int(float(damage) * 0.72)
		unit["strength"] = int(unit.get("strength", 0)) - damage
		taken[side] = int(taken[side]) + damage
	var broke := _remove_dead()
	for item in withdraws:
		_withdraw(str(item["lane"]), str(item["side"]))
	for side in ["player", "enemy"]:
		var base := maxi(1, int(before[side]))
		var loss := int(float(taken[side]) / float(base) * 46.0) + int(broke[side]) * 7 - int(rally[side])
		if side == "player":
			player_morale = clampi(player_morale - loss, 0, 100)
		else:
			enemy_morale = clampi(enemy_morale - loss, 0, 100)
	log_lines.append("Morale — you %d, them %d." % [player_morale, enemy_morale])
	_check_end()


func retreat() -> void:
	if finished:
		return
	deployment_open = false
	outcome = "retreat"
	finished = true
	log_lines.append("You sound the retreat. Some of the host gets away.")


func ai_commands(side: String) -> Dictionary:
	var plan := {}
	var morale := player_morale if side == "player" else enemy_morale
	var other := "enemy" if side == "player" else "player"
	for lane in LANES:
		var units: Array = lanes[lane][side]
		if units.is_empty():
			plan[lane] = "advance"
			continue
		if morale < 28:
			plan[lane] = "rally" if lane == "center" else "withdraw"
			continue
		var ranged := false
		var cavalry := false
		for unit in units:
			if bool(unit.get("ranged", false)):
				ranged = true
			if str(unit.get("base", unit.get("type", ""))) == "cavalry":
				cavalry = true
		var foes: Array = lanes[lane][other]
		if ranged and not foes.is_empty():
			plan[lane] = "volley"
		elif cavalry and _foes_ranged(foes):
			plan[lane] = "charge"
		elif _flank_bonus(lane, side):
			plan[lane] = "flank"
		else:
			plan[lane] = "advance"
	return plan


func snapshot() -> Dictionary:
	return {
		"title": title,
		"player_name": player_name,
		"enemy_name": enemy_name,
		"lanes": lanes.duplicate(true),
		"player_reserve": player_reserve.duplicate(true),
		"enemy_reserve": enemy_reserve.duplicate(true),
		"player_morale": player_morale,
		"enemy_morale": enemy_morale,
		"round": round_no,
		"log": log_lines.duplicate(),
		"finished": finished,
		"outcome": outcome,
		"deployment_open": deployment_open,
	}


func result() -> Dictionary:
	var remain_player := _strength("player")
	var remain_enemy := _strength("enemy")
	var player_ratio := 1.0 - float(remain_player) / float(maxi(1, start_player_strength))
	var enemy_ratio := 1.0 - float(remain_enemy) / float(maxi(1, start_enemy_strength))
	if outcome == "retreat":
		player_ratio += 0.12
	var elites_lost: Array = []
	for unit in destroyed:
		var elite_id := str(unit.get("elite_id", ""))
		if bool(unit.get("elite", false)) and elite_id != "" and not elites_lost.has(elite_id):
			elites_lost.append(elite_id)
	return {
		"outcome": outcome if outcome != "" else "stalemate",
		"forces_lost": clampi(int(float(player_forces) * player_ratio), 0, player_forces),
		"enemy_lost": clampi(int(float(enemy_forces) * enemy_ratio), 0, enemy_forces),
		"player_morale": player_morale,
		"enemy_morale": enemy_morale,
		"log": log_lines.duplicate(),
		"commanders": _fates(),
		"elites_lost": elites_lost,
		"title": title,
		"rounds": round_no,
		"battle_id": battle_id,
		"rival_id": rival_id,
	}


func _deploy(units: Array, side: String) -> void:
	var index := 0
	for raw in units:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = raw.duplicate(true)
		unit["side"] = side
		if str(unit.get("uid", "")) == "":
			unit["uid"] = "%s_%d" % [side, index]
		var base := str(unit.get("base", unit.get("type", "")))
		var hold_back := base == "cavalry" and units.size() >= 4 and index == units.size() - 1
		if hold_back:
			_pool(side).append(unit)
		else:
			lanes[LANES[index % 3]][side].append(unit)
		index += 1


func _plan(lane: String, side: String, command: String, other: String, _other_command: String, blows: Array, withdraws: Array, rally: Dictionary) -> void:
	var units: Array = lanes[lane][side]
	var foes: Array = lanes[lane][other]
	if units.is_empty():
		return
	var label := "%s %s" % [_side_name(side), lane]
	if command == "rally":
		rally[side] = int(rally[side]) + 11
		log_lines.append("%s holds the line and rallies." % label)
		return
	if command == "withdraw":
		for unit in units:
			if not foes.is_empty():
				blows.append({"unit": unit, "damage": 12})
		withdraws.append({"lane": lane, "side": side})
		log_lines.append("%s withdraws." % label)
		return
	if foes.is_empty():
		log_lines.append("%s finds no one opposite." % label)
		return
	var mult := 1.0
	if command == "hold":
		mult = 0.55
	elif command == "charge":
		mult = 1.12 if _other_command == "hold" else 1.42
	elif command == "flank":
		mult = 1.58 if _flank_bonus(lane, side) else 0.62
	elif command == "volley":
		_volley(units, foes, blows)
		log_lines.append("%s looses a volley." % label)
		return
	for unit in units:
		blows.append({"unit": foes[0], "damage": _blow(unit, foes[0], mult)})
	log_lines.append("%s presses: %s." % [label, command])


func _volley(units: Array, foes: Array, blows: Array) -> void:
	var ranged: Array = []
	var melee: Array = []
	for unit in units:
		if bool(unit.get("ranged", false)):
			ranged.append(unit)
		else:
			melee.append(unit)
	var shooters: Array = ranged if not ranged.is_empty() else units
	for foe in foes:
		for unit in shooters:
			blows.append({"unit": foe, "damage": int(float(_blow(unit, foe, 0.62)) * (1.0 if not ranged.is_empty() else 0.45))})
	if not melee.is_empty() and not foes.is_empty():
		blows.append({"unit": foes[0], "damage": _blow(melee[0], foes[0], 0.4)})


func _blow(attacker: Dictionary, defender: Dictionary, mult: float) -> int:
	var power := float(attacker.get("attack", 8)) * (float(maxi(1, int(attacker.get("strength", 1)))) / 80.0) * mult * _matchup(attacker, defender)
	var mitigation := float(defender.get("defense", 8)) * (float(maxi(1, int(defender.get("strength", 1)))) / 220.0) * 0.35
	var raw: float = maxf(4.0, power - mitigation)
	return int(raw * rng.randf_range(0.88, 1.12))


func _matchup(attacker: Dictionary, defender: Dictionary) -> float:
	var table = attacker.get("vs", {})
	if typeof(table) != TYPE_DICTIONARY:
		return 1.0
	var kind := str(defender.get("type", ""))
	var base := str(defender.get("base", ""))
	if table.has(kind):
		return float(table[kind])
	if base != "" and table.has(base):
		return float(table[base])
	return 1.0


func _flank_bonus(lane: String, side: String) -> bool:
	var neighbors: Array = ["center"] if lane != "center" else ["left", "right"]
	var other := "enemy" if side == "player" else "player"
	var own := _lane_strength(lane, side)
	for neighbor in neighbors:
		var foe := _lane_strength(str(neighbor), other)
		if foe <= 0 or float(foe) < float(own) * 0.62:
			return true
	return false


func _foes_ranged(foes: Array) -> bool:
	for unit in foes:
		if bool(unit.get("ranged", false)):
			return true
	return false


func _remove_dead() -> Dictionary:
	var broke := {"player": 0, "enemy": 0}
	for lane in LANES:
		for side in ["player", "enemy"]:
			var kept: Array = []
			for unit in lanes[lane][side]:
				if int(unit.get("strength", 0)) <= 0:
					unit["strength"] = 0
					destroyed.append(unit)
					broke[side] = int(broke[side]) + 1
					log_lines.append("%s breaks." % str(unit.get("name", "A company")))
				else:
					kept.append(unit)
			lanes[lane][side] = kept
	return broke


func _withdraw(lane: String, side: String) -> void:
	var moving: Array = lanes[lane][side]
	lanes[lane][side] = []
	for unit in moving:
		_pool(side).append(unit)


func _check_end() -> void:
	var player_broken := player_morale <= 0 or _count("player") == 0
	var enemy_broken := enemy_morale <= 0 or _count("enemy") == 0
	if player_broken or enemy_broken:
		if player_broken and enemy_broken:
			outcome = "stalemate"
			log_lines.append("Both hosts come apart.")
		elif player_broken:
			outcome = "defeat"
			log_lines.append("Your army breaks.")
		else:
			outcome = "victory"
			log_lines.append("The enemy army breaks.")
		finished = true
		return
	round_no += 1
	if round_no > max_rounds:
		var player_ratio := float(_strength("player")) / float(start_player_strength)
		var enemy_ratio := float(_strength("enemy")) / float(start_enemy_strength)
		if abs(player_ratio - enemy_ratio) < 0.06:
			outcome = "stalemate"
		elif player_ratio > enemy_ratio:
			outcome = "victory"
		else:
			outcome = "defeat"
		finished = true
		log_lines.append("Dusk ends it. Neither host is whole.")


func _fates() -> Array:
	var rows: Array = []
	var seen := {}
	for unit in destroyed:
		var commander_id := str(unit.get("commander_id", ""))
		if commander_id == "" or seen.has(commander_id):
			continue
		seen[commander_id] = true
		var roll := rng.randf()
		var fate := "ok"
		if outcome == "victory":
			if roll < 0.06:
				fate = "dead"
			elif roll < 0.4:
				fate = "wounded"
		elif outcome == "retreat":
			if roll < 0.05:
				fate = "dead"
			elif roll < 0.2:
				fate = "captured"
			elif roll < 0.48:
				fate = "wounded"
		else:
			if roll < 0.16:
				fate = "dead"
			elif roll < 0.32:
				fate = "captured"
			elif roll < 0.72:
				fate = "wounded"
		if fate != "ok":
			rows.append({"id": commander_id, "fate": fate})
			log_lines.append("A commander is %s." % fate)
	return rows


func _fill_empty_field(side: String) -> void:
	var field := 0
	for lane in LANES:
		field += lanes[lane][side].size()
	if field > 0 or _pool(side).is_empty():
		return
	lanes["center"][side].append(_pool(side).pop_front())


func _extract(uid: String, side: String) -> Dictionary:
	for lane in LANES:
		var units: Array = lanes[lane][side]
		for index in units.size():
			if str(units[index].get("uid", "")) == uid:
				var unit: Dictionary = units[index]
				units.remove_at(index)
				return unit
	var pool := _pool(side)
	for index in pool.size():
		if str(pool[index].get("uid", "")) == uid:
			var unit: Dictionary = pool[index]
			pool.remove_at(index)
			return unit
	return {}


func _take_reserve(side: String, uid: String) -> Dictionary:
	var pool := _pool(side)
	for index in pool.size():
		if str(pool[index].get("uid", "")) == uid:
			var unit: Dictionary = pool[index]
			pool.remove_at(index)
			return unit
	return {}


func _pool(side: String) -> Array:
	return player_reserve if side == "player" else enemy_reserve


func _strength(side: String) -> int:
	var total := 0
	for lane in LANES:
		for unit in lanes[lane][side]:
			total += maxi(0, int(unit.get("strength", 0)))
	for unit in _pool(side):
		total += maxi(0, int(unit.get("strength", 0)))
	return total


func _lane_strength(lane: String, side: String) -> int:
	var total := 0
	for unit in lanes[lane][side]:
		total += maxi(0, int(unit.get("strength", 0)))
	return total


func _count(side: String) -> int:
	var total := _pool(side).size()
	for lane in LANES:
		total += lanes[lane][side].size()
	return total


func _find_lane(unit: Dictionary) -> String:
	var uid := str(unit.get("uid", ""))
	for lane in LANES:
		for side in ["player", "enemy"]:
			for other in lanes[lane][side]:
				if str(other.get("uid", "")) == uid:
					return lane
	return "center"


func _side_name(side: String) -> String:
	return "You" if side == "player" else enemy_name
