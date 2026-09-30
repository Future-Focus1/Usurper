extends Node


func _ready() -> void:
	var gm: Node = get_node("/root/GameManager")
	var db: ContentDB = gm.db
	var state := CampaignState.new()
	state.setup("mira", db)
	state.rng.seed = 7
	var gold_before := state.gold
	var forecast: PackedStringArray = WeekLoop.forecast(state, db)
	if state.gold != gold_before:
		push_error("Forecast changed the treasury")
		get_tree().quit(1)
		return
	if forecast.is_empty():
		push_error("Forecast was empty")
		get_tree().quit(1)
		return
	state.fear = 0
	state.stability = 80
	state.foreign = 2
	for rid in state.rivals:
		state.rivals[rid]["claim"] = 10
		state.rivals[rid]["strategy"] = "mixed"
		state.rivals[rid]["gold"] = 0
		state.rivals[rid]["forces"] = 10
		state.rivals[rid]["alive"] = true
	CampaignRules.close_week(state, db)
	if state.foreign != 2:
		push_error("Foreign pressure rose while the realm was calm: %d" % state.foreign)
		get_tree().quit(1)
		return
	if state.phase != "response":
		push_error("Week did not end on the realm's answer")
		get_tree().quit(1)
		return
	for rid in state.rivals:
		var claim := int(state.rivals[rid]["claim"])
		if claim % 2 != 0:
			push_error("%s gained claim without a matching act (%d)" % [rid, claim])
			get_tree().quit(1)
			return
	state.gold = 10
	state.forces = 40
	var column: Array = ActionBoard.column(state, db, "Military")
	var saw_reason := false
	for row in column:
		if not bool(row["open"]) and str(row["reason"]) != "":
			saw_reason = true
	if not saw_reason:
		push_error("A locked decree did not say why it is locked")
		get_tree().quit(1)
		return
	print("WEEK_LOOP_OK")
	get_tree().quit(0)
