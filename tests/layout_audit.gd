extends Node

var _failures: Array[String] = []


func _ready() -> void:
	await _run()
	if _failures.is_empty():
		print("LAYOUT_OK")
		get_tree().quit(0)
	else:
		for line in _failures:
			print("LAYOUT_FAIL ", line)
		get_tree().quit(1)


func _run() -> void:
	var gm: Node = get_node("/root/GameManager")
	var db: ContentDB = gm.db
	await _mount("menu", load("res://scenes/main_menu/main_menu.tscn").instantiate())
	var menu = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu)
	_fill(menu)
	await get_tree().process_frame
	menu._open_settings()
	await get_tree().process_frame
	await get_tree().process_frame
	await _scan("settings", menu)
	menu.queue_free()
	await _mount("select", load("res://scenes/claimant_select/claimant_select.tscn").instantiate())
	var state := CampaignState.new()
	state.setup("mira", db)
	gm.state = state
	var campaign = load("res://scenes/campaign/campaign.tscn").instantiate()
	add_child(campaign)
	_fill(campaign)
	await get_tree().process_frame
	await get_tree().process_frame
	await _scan("campaign_overview", campaign)
	EventDirector.pick_audience(state, db)
	state.phase = "event"
	campaign._refresh()
	await get_tree().process_frame
	await _scan("campaign_event", campaign)
	state.phase = "action"
	campaign._refresh()
	await get_tree().process_frame
	await _scan("campaign_action", campaign)
	campaign._open_map()
	await get_tree().process_frame
	await _scan("map", campaign)
	campaign._close_overlay()
	campaign._open_court()
	await get_tree().process_frame
	await _scan("court", campaign)
	campaign._close_overlay()
	campaign._open_pause()
	await get_tree().process_frame
	await _scan("pause", campaign)
	campaign._close_overlay()
	campaign._toggle_debug()
	await get_tree().process_frame
	await _scan("debug", campaign)
	campaign._toggle_debug()
	campaign.queue_free()
	state.pending_battle = {"battle_id": "road_bandits", "on_victory": [], "on_defeat": [], "on_retreat": []}
	gm.battle_setup = CampaignRules.build_battle(state, db)
	await _mount("battle", load("res://scenes/battle/battle.tscn").instantiate())
	gm.ending = {"title": "A Quiet Crown", "subtitle": "The bells were wrong.", "paragraphs": ["The city kept the story it could live with."]}
	await _mount("ending", load("res://scenes/ending/ending.tscn").instantiate())
	await _mount("chronicle", load("res://scenes/chronicle/chronicle.tscn").instantiate())


func _mount(name: String, node: Node) -> void:
	add_child(node)
	if node is Control:
		_fill(node)
	await get_tree().process_frame
	await get_tree().process_frame
	await _scan(name, node)
	node.queue_free()
	await get_tree().process_frame


func _fill(node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0


func _scan(name: String, root: Node) -> void:
	var view := get_viewport().get_visible_rect()
	var count := 0
	_walk(name, root, view, count)
	print("SCAN %s viewport=%s fails_so_far=%d" % [name, view.size, _failures.size()])


func _walk(name: String, node: Node, view: Rect2, count: int) -> void:
	if node is Control and node != self:
		var control := node as Control
		if control.visible and control.get_global_rect().size.x > 1.0:
			var rect := control.get_global_rect()
			if control is Button and control.autowrap_mode == TextServer.AUTOWRAP_OFF and not control.text.contains("\n"):
				var font_size2 := control.get_theme_font_size("font_size")
				var needed2 := UiFactory._text_width(control.text, font_size2) + 20.0
				if rect.size.x + 1.0 < needed2:
					_failures.append("%s clipped-label %s '%s' width=%.0f needed=%.0f" % [name, control.get_class(), _sample(control), rect.size.x, needed2])
			if not _inside_clip(control, view):
				if rect.position.x < -2.0 or rect.position.y < -2.0 or rect.end.x > view.size.x + 2.0 or rect.end.y > view.size.y + 2.0:
					_failures.append("%s %s '%s' rect=%s" % [name, control.get_class(), _sample(control), rect])
	for child in node.get_children():
		_walk(name, child, view, count)


func _inside_clip(control: Control, view: Rect2) -> bool:
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			var bounds := (parent as Control).get_global_rect()
			return bounds.position.x >= -2.0 and bounds.position.y >= -2.0 and bounds.end.x <= view.size.x + 2.0 and bounds.end.y <= view.size.y + 2.0
		parent = parent.get_parent()
	return false


func _sample(control: Control) -> String:
	if control is Button or control is Label or control is RichTextLabel:
		return control.text.substr(0, 42).replace("\n", " ")
	return control.name
