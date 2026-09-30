extends Node

## Real renderer capture harness. Run via run_qa.ps1 -Suite capture.
## Screenshots cover every claimant, every primary campaign phase, overlays,
## the tactical field, Chronicle, and a full-length assembled epilogue.

var destination := "res://tests/.artifacts/screenshots"
var manifest: Array = []
var resolution_name := "1280x720"


func _ready() -> void:
	var expected := OS.get_environment("USURPER_QA_USER_ROOT").replace("\\", "/").to_lower()
	if expected == "" or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(expected + "/"):
		push_error("Use tests/run_qa.ps1 to isolate saves before taking captures.")
		get_tree().quit(2)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("capture_dir="):
			destination = argument.trim_prefix("capture_dir=")
		elif argument.begins_with("viewport="):
			resolution_name = argument.trim_prefix("viewport=")
	destination += "/" + resolution_name
	DirAccess.make_dir_recursive_absolute(destination)
	await _run()
	var file := FileAccess.open(destination + "/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	print("VISUAL_CAPTURE_OK frames=%d path=%s" % [manifest.size(), destination])
	get_tree().quit(0)


func _run() -> void:
	var menu = load(GameManager.SCENE_MENU).instantiate()
	await _mount(menu)
	await _capture("01_main_menu", menu)
	if menu.has_method("_open_settings"):
		menu.call("_open_settings")
		await _capture("02_settings", menu)
	await _remove(menu)
	var select = load(GameManager.SCENE_SELECT).instantiate()
	await _mount(select)
	await _capture("03_claimant_select", select)
	await _remove(select)
	var index := 4
	for claimant in GameManager.db.claimant_order:
		var state := CampaignState.new()
		state.setup(str(claimant), GameManager.db)
		state.rng.seed = 20260930
		GameManager.state = state
		var campaign = load(GameManager.SCENE_CAMPAIGN).instantiate()
		await _mount(campaign)
		await _capture("%02d_%s_briefing" % [index, claimant], campaign)
		index += 1
		EventDirector.pick_audience(state, GameManager.db)
		state.phase = "event"
		campaign.call("_refresh")
		await _capture("%02d_%s_petition" % [index, claimant], campaign)
		index += 1
		var event := EventDirector.current(state, GameManager.db)
		for choice_index in event.get("choices", []).size():
			var choice: Dictionary = event.choices[choice_index]
			var scene_change := false
			for effect in choice.get("effects", []):
				if str(effect.get("op", "")) in ["battle", "defeat"]:
					scene_change = true
			if not scene_change and ConditionChecker.choice_failures(choice, state, GameManager.db).is_empty():
				campaign.call("_choose", choice_index)
				await _capture("%02d_%s_decision_receipt" % [index, claimant], campaign)
				index += 1
				break
		state.phase = "action"
		campaign.call("_refresh")
		await _capture("%02d_%s_decrees" % [index, claimant], campaign)
		index += 1
		CampaignRules.close_week(state, GameManager.db)
		campaign.call("_refresh")
		await _capture("%02d_%s_response" % [index, claimant], campaign)
		index += 1
		if str(claimant) == "mira":
			for overlay in ["map", "court", "army", "ledger", "world", "throne", "pause"]:
				if campaign.has_method("_open_" + overlay):
					campaign.call("_open_" + overlay)
					await _capture("%02d_%s" % [index, overlay], campaign)
					index += 1
					if overlay == "court":
						var button := _find_button(campaign, "Captain Garran")
						if button != null:
							button.pressed.emit()
							await _capture("%02d_court_character_details" % index, campaign)
							index += 1
							_scroll_bottom(campaign._overlay)
							await _capture("%02d_court_character_details_bottom" % index, campaign)
							index += 1
					campaign.call("_close_overlay")
		await _remove(campaign)
	var state: CampaignState = GameManager.state
	state.forces = 3200
	state.pending_battle = {"battle_id": "throne_conquest", "on_victory": [], "on_defeat": [], "on_retreat": []}
	GameManager.battle_setup = CampaignRules.build_battle(state, GameManager.db)
	var battle = load(GameManager.SCENE_BATTLE).instantiate()
	await _mount(battle)
	await _capture("%02d_tactical_battle" % index, battle)
	index += 1
	await _remove(battle)
	state.claim = 100
	state.stability = 75
	state.rations = 80
	state.blocs["people"] = 60
	state.reputation = 30
	GameManager.ending = EndingDirector.resolve(state, GameManager.db, "conquest", {"outcome": "victory"}, "triumph")
	var ending = load(GameManager.SCENE_ENDING).instantiate()
	await _mount(ending)
	await _capture("%02d_complete_ending" % index, ending)
	index += 1
	_scroll_bottom(ending)
	await _capture("%02d_complete_ending_bottom" % index, ending)
	index += 1
	await _remove(ending)
	for entry in GameManager.db.chronicle_entries:
		MetaProgress.unlocked[str(entry)] = true
	var chronicle = load(GameManager.SCENE_CHRONICLE).instantiate()
	await _mount(chronicle)
	await _capture("%02d_chronicle" % index, chronicle)
	index += 1
	await _remove(chronicle)
	# Verify the public and discovered versions of the three gated biographies.
	var helper = load("res://tests/release_audit.gd").new()
	helper.db = GameManager.db
	for character_id in ["arlo", "oren_pell", "nessa_grey"]:
		for revealed in [false, true]:
			var court_state := CampaignState.new()
			court_state.setup("mira", GameManager.db)
			if revealed:
				court_state = helper._witness({"claimant": "mira"}, GameManager.db.characters[character_id].get("biography_requires", {}))
			GameManager.state = court_state
			var campaign = load(GameManager.SCENE_CAMPAIGN).instantiate()
			await _mount(campaign)
			campaign.call("_open_court")
			var button := _find_button(campaign, str(GameManager.db.characters[character_id].name))
			if button != null:
				button.pressed.emit()
			await _capture("%02d_%s_biography_%s" % [index, character_id, "revealed" if revealed else "public"], campaign)
			index += 1
			await _remove(campaign)
	# All claimants receive a complete personal epilogue, plus council headlines.
	for fixture in [["mira", "peoples_crown"], ["ethan", "peoples_crown"], ["arlo", "blood_of_erol"], ["mira", "no_king"], ["mira", "regency"]]:
		var route: Dictionary = {}
		for candidate in GameManager.db.routes:
			if str(candidate.id) == str(fixture[1]):
				route = candidate
				break
		var ending_state: CampaignState = helper._witness(route.get("requires", {}), {"claimant": fixture[0]})
		if ending_state == null:
			push_error("Ending capture fixture has no witness " + str(fixture))
			continue
		ending_state.stability = 75
		ending_state.rations = 80
		ending_state.blocs.people = 60
		ending_state.reputation = 30
		GameManager.state = ending_state
		GameManager.ending = EndingDirector.resolve(ending_state, GameManager.db, str(fixture[1]), {"outcome": "victory"}, "triumph")
		var personal_ending = load(GameManager.SCENE_ENDING).instantiate()
		await _mount(personal_ending)
		await _capture("%02d_%s_%s_ending" % [index, fixture[0], fixture[1]], personal_ending)
		index += 1
		_scroll_bottom(personal_ending)
		await _capture("%02d_%s_%s_ending_bottom" % [index, fixture[0], fixture[1]], personal_ending)
		index += 1
		await _remove(personal_ending)
	helper.free()


func _mount(node: Node) -> void:
	add_child(node)
	if node is Control:
		(node as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for frame in 4:
		await get_tree().process_frame


func _remove(node: Node) -> void:
	node.queue_free()
	await get_tree().process_frame


func _capture(name: String, node: Node) -> void:
	for frame in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screenshot := get_viewport().get_texture().get_image()
	var output := destination + "/" + name + ".png"
	var code := screenshot.save_png(output)
	if code != OK:
		push_error("Could not save screenshot: " + output)
	var controls: Array = []
	_control_bounds(node, controls)
	manifest.append({"screen": name, "file": output, "viewport": [screenshot.get_width(), screenshot.get_height()], "controls": controls})
	print("CAPTURE ", output)


func _control_bounds(node: Node, rows: Array) -> void:
	if node is Control and node.is_visible_in_tree():
		var control := node as Control
		var rect := control.get_global_rect()
		var text := ""
		if control is Button or control is Label or control is RichTextLabel:
			text = control.text
		if text != "":
			rows.append({"class": control.get_class(), "text": text, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	for child in node.get_children():
		_control_bounds(child, rows)


func _find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.is_visible_in_tree() and (node as Button).text.begins_with(prefix):
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, prefix)
		if found != null:
			return found
	return null


func _scroll_bottom(node: Node) -> void:
	if node is ScrollContainer:
		(node as ScrollContainer).scroll_vertical = 100000
	for child in node.get_children():
		_scroll_bottom(child)
