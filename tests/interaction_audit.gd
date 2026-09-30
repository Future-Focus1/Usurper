extends Node

var errors: Array[String] = []


func _ready() -> void:
	var expected := OS.get_environment("USURPER_QA_USER_ROOT").replace("\\", "/").to_lower()
	if expected == "" or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(expected + "/"):
		push_error("Use tests/run_qa.ps1 for isolated UI interaction tests.")
		get_tree().quit(2)
		return
	await _run()
	for message in errors:
		print("INTERACTION_FAIL ", message)
	print("INTERACTION_AUDIT_OK" if errors.is_empty() else "INTERACTION_AUDIT_FAILED")
	get_tree().quit(0 if errors.is_empty() else 1)


func _run() -> void:
	for claimant in GameManager.db.claimant_order:
		var state := CampaignState.new()
		state.setup(str(claimant), GameManager.db)
		state.rng.seed = 20260930
		EventDirector.pick_audience(state, GameManager.db)
		state.phase = "event"
		GameManager.state = state
		var campaign = load(GameManager.SCENE_CAMPAIGN).instantiate()
		add_child(campaign)
		(campaign as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await get_tree().process_frame
		await get_tree().process_frame
		var event := EventDirector.current(state, GameManager.db)
		var chosen := -1
		for index in event.get("choices", []).size():
			var choice: Dictionary = event.choices[index]
			var safe := ConditionChecker.choice_failures(choice, state, GameManager.db).is_empty()
			for effect in choice.get("effects", []):
				if str(effect.get("op", "")) in ["battle", "defeat", "chance", "assassinate"]:
					safe = false
			if safe:
				chosen = index
				break
		if chosen < 0:
			errors.append("No safe opening fixture for " + str(claimant))
			campaign.queue_free()
			await get_tree().process_frame
			continue
		var before_index := state.event_index
		var before_decisions := state.decisions.size()
		campaign.call("_choose", chosen)
		await get_tree().process_frame
		if state.event_index != before_index + 1:
			errors.append("Receipt failed to commit event before save " + str(claimant))
		if state.decisions.size() != before_decisions + 1:
			errors.append("Decision recorded wrong number of times " + str(claimant))
		var next_index := state.event_index
		if not SaveManager.save_campaign(state, 1, "QA decision receipt"):
			errors.append("Cannot save receipt " + str(claimant))
		var loaded: CampaignState = SaveManager.load_campaign(1)
		if loaded == null or loaded.event_index != next_index or loaded.decisions.size() != state.decisions.size():
			errors.append("Receipt save/reload can repeat decision " + str(claimant))
		var continue_button := _find_button(campaign, "Continue the audience")
		if continue_button == null:
			errors.append("Receipt has no Continue " + str(claimant))
		else:
			continue_button.pressed.emit()
			await get_tree().process_frame
			if state.event_index != next_index:
				errors.append("Continue advanced twice " + str(claimant))
		for opener in ["_open_world", "_open_map", "_open_court", "_open_ledger", "_open_army"]:
			campaign.call(opener)
			await get_tree().process_frame
			var close := _find_button(campaign._overlay, "Close")
			if close == null:
				errors.append(opener + " has no close control")
			else:
				close.pressed.emit()
				await get_tree().process_frame
				if campaign._overlay.visible or campaign._overlay.get_child_count() > 0:
					errors.append(opener + " does not dismiss")
		campaign.queue_free()
		await get_tree().process_frame


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text and node.is_visible_in_tree():
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null
