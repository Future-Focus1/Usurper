extends Node

## Four connected playthroughs through actual scene/button handlers. The root
## harness survives scene changes; fixtures come from naturally successful seeds.

var errors: Array[String] = []
var buttons_pressed := 0
var battles_played := 0
var report: Array = []
var audit


func _ready() -> void:
	var expected := OS.get_environment("USURPER_QA_USER_ROOT").replace("\\", "/").to_lower()
	if expected == "" or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(expected + "/"):
		push_error("Use tests/run_qa.ps1 for isolated frontend campaign tests.")
		get_tree().quit(2)
		return
	# Keep this harness as a root sibling while the playable current scene changes.
	get_tree().current_scene = null
	audit = load("res://tests/release_audit.gd").new()
	audit.db = GameManager.db
	var file := FileAccess.open("res://tests/.artifacts/winning_replays.json", FileAccess.READ)
	if file == null:
		push_error("Run the campaign audit first to create natural victory traces.")
		get_tree().quit(2)
		return
	var fixtures: Dictionary = JSON.parse_string(file.get_as_text())
	for claimant in GameManager.db.claimant_order:
		if not fixtures.has(str(claimant)):
			errors.append("No natural victory fixture for " + str(claimant))
			continue
		await _campaign(str(claimant), fixtures[str(claimant)])
	await _council_settlement()
	audit.free()
	var result := {"campaigns": report, "buttons_pressed": buttons_pressed, "battles_played": battles_played, "failures": errors}
	var result_file := FileAccess.open("res://tests/.artifacts/frontend_campaign_audit.json", FileAccess.WRITE)
	result_file.store_string(JSON.stringify(result, "\t"))
	for message in errors:
		print("FRONTEND_FAIL ", message)
	print("FRONTEND_CAMPAIGN_OK claimants=%d buttons=%d battles=%d" % [report.size(), buttons_pressed, battles_played] if errors.is_empty() else "FRONTEND_CAMPAIGN_FAILED")
	get_tree().quit(0 if errors.is_empty() else 1)


func _campaign(claimant: String, fixture: Dictionary) -> void:
	var seed_value := int(fixture.seed)
	var policy := str(fixture.policy)
	var selector := RandomNumberGenerator.new()
	selector.seed = seed_value + 97
	GameManager.start_new(claimant)
	GameManager.state.rng.seed = seed_value
	await _frames()
	var saved_petition := false
	var saved_action := false
	for step in 1800:
		var scene := get_tree().current_scene
		if scene == null:
			await _frames()
			continue
		var state: CampaignState = GameManager.state
		if scene.scene_file_path == GameManager.SCENE_ENDING:
			var won := not bool(GameManager.ending.get("defeat", true))
			if not won:
				errors.append("Natural winning UI campaign ended in defeat %s policy=%s seed=%d ending=%s" % [claimant, policy, seed_value, GameManager.ending.get("ending_id", "")])
			if not saved_petition or not saved_action:
				errors.append("Mid-campaign save coverage missing " + claimant)
			var history_count := MetaProgress.campaigns.size()
			var completed_ending := str(GameManager.ending.get("ending_id", ""))
			if not SaveManager.save_campaign(state, 2, "QA completed ending") or not GameManager.load_slot(2):
				errors.append("Completed campaign cannot reload " + claimant)
			await _frames()
			await _frames()
			if get_tree().current_scene.scene_file_path != GameManager.SCENE_ENDING or str(GameManager.ending.get("ending_id", "")) != completed_ending:
				errors.append("Completed save does not restore its ending " + claimant)
			if MetaProgress.campaigns.size() != history_count:
				errors.append("Reloading ending records Chronicle campaign twice " + claimant)
			report.append({"claimant": claimant, "policy": policy, "seed": seed_value, "weeks": state.turn, "ending": GameManager.ending.get("ending_id", ""), "victory": won, "saved_petition": saved_petition, "saved_action": saved_action})
			print("FRONTEND_FINISHED %s week=%d ending=%s" % [claimant, state.turn, GameManager.ending.get("ending_id", "")])
			return
		if scene.scene_file_path == GameManager.SCENE_BATTLE:
			await _battle(scene)
			continue
		if scene.scene_file_path != GameManager.SCENE_CAMPAIGN:
			errors.append("Unexpected scene during frontend campaign " + scene.scene_file_path)
			return
		var receipt := _find_button(scene, "Continue the audience")
		if receipt != null:
			_press(receipt)
			await _frames()
			continue
		match state.phase:
			"overview", "response":
				_press(scene._primary)
				await _frames()
			"event":
				if not saved_petition and state.turn >= 2:
					saved_petition = await _reload(state, "petition")
					continue
				var event := EventDirector.current(state, GameManager.db)
				if event.is_empty():
					scene.call("_refresh")
					await _frames()
					continue
				var legal: Array = []
				for choice in event.get("choices", []):
					if ConditionChecker.choice_failures(choice, state, GameManager.db).is_empty():
						legal.append(choice)
				if legal.is_empty():
					errors.append("No legal petition in frontend campaign " + str(event.id))
					return
				var choice: Dictionary = audit._select(legal, state, policy, selector)
				var button := _find_button(scene, str(choice.text))
				if button == null or button.disabled:
					errors.append("Legal choice has no active button " + str(event.id))
					return
				_press(button)
				await _frames()
			"action":
				if not saved_action and state.turn >= 2:
					saved_action = await _reload(state, "action")
					continue
				var routes: Array = []
				for row in EndingDirector.list_routes(state, GameManager.db):
					if bool(row.open):
						routes.append(row.route)
				if not routes.is_empty():
					var route: Dictionary = routes[selector.randi_range(0, routes.size() - 1)]
					_press(scene._throne)
					await _frames()
					var button := _find_button(scene._overlay, str(route.title))
					if button == null or button.disabled:
						errors.append("Open throne route missing UI button " + str(route.id))
						return
					_press(button)
					await _frames()
					continue
				var legal: Array = []
				for action in ActionBoard.available(state, GameManager.db):
					if ConditionChecker.choice_failures(action, state, GameManager.db).is_empty():
						legal.append(action)
				if legal.is_empty():
					errors.append("No legal decree in frontend campaign " + claimant)
					return
				var action: Dictionary = audit._select(legal, state, policy, selector)
				var category := _find_button(scene, str(action.get("category", "Personal")))
				if category == null:
					errors.append("Action category has no button")
					return
				_press(category)
				await _frames()
				var button := _find_button(scene, str(action.title))
				if button == null or button.disabled:
					errors.append("Legal decree missing active button " + str(action.id))
					return
				_press(button)
				await _frames()
				_press(scene._primary)
				await _frames()
			_:
				errors.append("Unexpected campaign phase " + state.phase)
				return
	errors.append("Frontend campaign exceeded interaction bound " + claimant)


func _reload(state: CampaignState, label: String) -> bool:
	var before_phase := state.phase
	var before_index := state.event_index
	var before_turn := state.turn
	var before_decisions := state.decisions.size()
	if not SaveManager.save_campaign(state, 3, "QA frontend " + label) or not GameManager.load_slot(3):
		errors.append("Frontend save/reload failed " + label)
		return false
	await _frames()
	var loaded: CampaignState = GameManager.state
	if loaded.phase != before_phase or loaded.event_index != before_index or loaded.turn != before_turn or loaded.decisions.size() != before_decisions:
		errors.append("Frontend save/reload repeated or advanced a decision " + label)
	return true


func _council_settlement() -> void:
	GameManager.start_new("mira")
	await _frames()
	var state: CampaignState = GameManager.state
	state.turn = 52
	state.phase = "action"
	var campaign := get_tree().current_scene
	campaign.call("_refresh")
	var category := _find_button(campaign, "Personal")
	_press(category)
	await _frames()
	var wait_button := _find_button(campaign, "Wait and listen")
	if wait_button == null:
		errors.append("Council settlement fixture cannot issue quiet decree")
		return
	_press(wait_button)
	await _frames()
	_press(campaign._primary)
	await _frames()
	if state.turn != 53 or state.phase != "response" or state.defeat_reason != "council_settlement":
		errors.append("Last decree does not reach settlement response")
		return
	_press(campaign._primary)
	await _frames()
	if get_tree().current_scene.scene_file_path != GameManager.SCENE_ENDING or str(GameManager.ending.get("method", "")) != "council_settlement":
		errors.append("Council settlement response button fails to conclude campaign")
	else:
		print("FRONTEND_COUNCIL_SETTLEMENT_OK")


func _battle(scene: Node) -> void:
	battles_played += 1
	for round_index in 12:
		if scene._battle.finished:
			var back := _find_button(scene, "Return to the realm")
			if back == null:
				errors.append("Finished battle has no return button")
				return
			_press(back)
			await _frames()
			return
		var plan: Dictionary = scene._battle.ai_commands("player")
		for lane_index in BattleResolver.LANES.size():
			var order_buttons: Array[Button] = []
			_find_buttons(scene, "Orders", order_buttons)
			if order_buttons.size() != 3:
				errors.append("Battle lane order selectors missing")
				return
			_press(order_buttons[lane_index])
			await _frames()
			var command := _find_button(scene, str(plan[BattleResolver.LANES[lane_index]]).capitalize())
			if command == null:
				errors.append("Tactical command button missing")
				return
			_press(command)
			await _frames()
		var fight := _find_button(scene, "Fight this round")
		if fight == null:
			errors.append("Battle cannot resolve a round")
			return
		_press(fight)
		await _frames()
	errors.append("Battle failed to finish through frontend controls")


func _press(button: Button) -> void:
	buttons_pressed += 1
	button.pressed.emit()


func _frames() -> void:
	for index in 3:
		await get_tree().process_frame


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text and node.is_visible_in_tree():
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _find_buttons(node: Node, text: String, found: Array[Button]) -> void:
	if node is Button and (node as Button).text == text and node.is_visible_in_tree():
		found.append(node as Button)
	for child in node.get_children():
		_find_buttons(child, text, found)
