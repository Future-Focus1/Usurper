extends Node

var _errors: Array[String] = []


func _ready() -> void:
	await _run()
	if _errors.is_empty():
		print("OVERLAY_CLOSE_OK")
		get_tree().quit(0)
	else:
		for line in _errors:
			print("OVERLAY_CLOSE_FAIL ", line)
		get_tree().quit(1)


func _run() -> void:
	var gm: Node = get_node("/root/GameManager")
	var state := CampaignState.new()
	state.setup("mira", gm.db)
	gm.state = state
	var campaign = load("res://scenes/campaign/campaign.tscn").instantiate()
	add_child(campaign)
	if campaign is Control:
		(campaign as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	await _close(campaign, "_open_army", "Army")
	await _close(campaign, "_open_map", "Map")
	await _close(campaign, "_open_court", "Court")
	await _close(campaign, "_open_ledger", "Ledger")


func _close(campaign: Node, opener: String, label: String) -> void:
	campaign.call(opener)
	await get_tree().process_frame
	if campaign._overlay.get_child_count() == 0:
		_errors.append("%s view did not open" % label)
		return
	var view: Node = campaign._overlay.get_child(0)
	var close := _find_button(view, "Close")
	if close == null:
		_errors.append("%s close button was not found" % label)
		return
	close.pressed.emit()
	if is_instance_valid(view) and not view.is_queued_for_deletion():
		_errors.append("%s view was locked and could not close" % label)
	if campaign._overlay.visible or campaign._overlay.get_child_count() > 0:
		_errors.append("%s view stayed open after Close" % label)
	await get_tree().process_frame
	if is_instance_valid(view):
		_errors.append("%s view was still in memory after Close" % label)


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text and node.is_visible_in_tree():
		return node
	for child in node.get_children():
		var found := _find_button(child, text)
		if found != null:
			return found
	return null
