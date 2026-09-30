extends Node

## Campaign slots live in user://saves. The Chronicle uses a separate file.


func save_campaign(state: CampaignState, slot: int, label: String) -> bool:
	if state == null:
		return false
	DirAccess.make_dir_recursive_absolute(slot_dir())
	var payload := {
		"version": 1,
		"slot": slot,
		"label": label,
		"saved_at": Time.get_datetime_string_from_system(),
		"claimant": state.claimant_id,
		"turn": state.turn,
		"claim": state.claim,
		"summary": "%s — Claim %d" % [Balance.date_line(state.turn), state.claim],
		"state": state.to_dict(),
	}
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Could not write save slot %d" % slot)
		return false
	file.store_string(JSON.stringify(payload))
	return true


func load_campaign(slot: int) -> CampaignState:
	if not FileAccess.file_exists(slot_path(slot)):
		return null
	var file := FileAccess.open(slot_path(slot), FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("state", null)) != TYPE_DICTIONARY:
		return null
	return CampaignState.from_dict(parsed["state"], GameManager.db)


func list_slots() -> Array:
	var rows: Array = []
	for slot in [0, 1, 2, 3]:
		var path := slot_path(slot)
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		parsed["slot"] = slot
		rows.append(parsed)
	rows.sort_custom(func(a, b): return str(a.get("saved_at", "")) > str(b.get("saved_at", "")))
	return rows


func has_any() -> bool:
	return not list_slots().is_empty()


func latest_slot() -> int:
	var rows := list_slots()
	if rows.is_empty():
		return -1
	return int(rows[0].get("slot", -1))


func slot_dir() -> String:
	return "user://saves"


func slot_path(slot: int) -> String:
	return "user://saves/slot_%d.json" % slot


func write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))


func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
