extends Node

## Owns the live campaign and moves between screens. Systems stay free of the scene tree.

const SCENE_MENU := "res://scenes/main_menu/main_menu.tscn"
const SCENE_SELECT := "res://scenes/claimant_select/claimant_select.tscn"
const SCENE_CAMPAIGN := "res://scenes/campaign/campaign.tscn"
const SCENE_BATTLE := "res://scenes/battle/battle.tscn"
const SCENE_ENDING := "res://scenes/ending/ending.tscn"
const SCENE_CHRONICLE := "res://scenes/chronicle/chronicle.tscn"

var db := ContentDB.new()
var state: CampaignState
var ending: Dictionary = {}
var return_scene := ""
var battle_setup: Dictionary = {}


func _ready() -> void:
	db.load_all()
	for err in db.validate():
		push_error(err)


func start_new(claimant_id: String) -> void:
	state = CampaignState.new()
	state.setup(claimant_id, db)
	ending = {}
	battle_setup = {}
	_go(SCENE_CAMPAIGN)


func continue_latest() -> bool:
	var slot := SaveManager.latest_slot()
	if slot < 0:
		return false
	return load_slot(slot)


func load_slot(slot: int) -> bool:
	var loaded := SaveManager.load_campaign(slot)
	if loaded == null:
		return false
	state = loaded
	ending = state.ending_data.duplicate(true)
	battle_setup = {}
	if not ending.is_empty():
		_go(SCENE_ENDING)
		return true
	if not state.pending_battle.is_empty():
		launch_battle()
		return true
	_go(SCENE_CAMPAIGN)
	return true


func open_chronicle() -> void:
	var current := get_tree().current_scene
	return_scene = current.scene_file_path if current != null else SCENE_MENU
	_go(SCENE_CHRONICLE)


func close_extra() -> void:
	var dest := return_scene if return_scene != "" else SCENE_MENU
	return_scene = ""
	_go(dest)


func launch_battle() -> void:
	if state == null:
		return
	battle_setup = CampaignRules.build_battle(state, db)
	SaveManager.save_campaign(state, 0, "Before battle")
	_go(SCENE_BATTLE)


func finish_battle(result: Dictionary) -> void:
	if state != null:
		CampaignRules.apply_battle_return(state, db, result)
		SaveManager.save_campaign(state, 0, "After battle")
	battle_setup = {}
	_go(SCENE_CAMPAIGN)


func show_ending(data: Dictionary) -> void:
	ending = data
	if state != null:
		state.ending_data = data.duplicate(true)
		state.phase = "ending"
		for raw in data.get("chronicle", []):
			MetaProgress.unlock(str(raw))
		MetaProgress.record_campaign({
			"campaign_id": state.campaign_id,
			"claimant": state.claimant_id,
			"ending": str(data.get("ending_id", "")),
			"legacy": str(data.get("legacy", "")),
			"title": str(data.get("title", "")),
			"turn": state.turn,
			"victory": not bool(data.get("defeat", false)),
			"kingdom": str(data.get("kingdom", "")),
		})
		SaveManager.save_campaign(state, 0, "Campaign complete")
	_go(SCENE_ENDING)


func to_menu() -> void:
	if state != null:
		SaveManager.save_campaign(state, 0, "Autosave")
	_go(SCENE_MENU)


func to_select() -> void:
	_go(SCENE_SELECT)


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)
