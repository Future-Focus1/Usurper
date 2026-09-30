extends Node

## Campaign slots live in user://saves. The Chronicle uses a separate file.

var _last_save_usec := 0


func save_campaign(state: CampaignState, slot: int, label: String) -> bool:
	if state == null:
		return false
	if slot < 0 or slot > 3:
		return false
	DirAccess.make_dir_recursive_absolute(slot_dir())
	var saved_usec := _next_save_timestamp()
	var payload := {
		"version": 2,
		"slot": slot,
		"label": label,
		"saved_at": Time.get_datetime_string_from_system(),
		# Keep all 64 bits in JSON, and order rapid manual/autosaves precisely.
		"saved_at_unix_usec": str(saved_usec),
		"claimant": state.claimant_id,
		"turn": state.turn,
		"claim": state.claim,
		"summary": "%s — Claim %d" % [Balance.date_line(state.turn), state.claim],
		"state": state.to_dict(),
	}
	return _atomic_write(slot_path(slot), payload)


func load_campaign(slot: int) -> CampaignState:
	var parsed := read_json(slot_path(slot))
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("state", null)) != TYPE_DICTIONARY:
		return null
	return CampaignState.from_dict(parsed["state"], GameManager.db)


func list_slots() -> Array:
	var rows: Array = []
	for slot in [0, 1, 2, 3]:
		var path := slot_path(slot)
		if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak"):
			continue
		var parsed := read_json(path)
		if parsed.is_empty() or typeof(parsed.get("state", null)) != TYPE_DICTIONARY:
			continue
		parsed["slot"] = slot
		rows.append(parsed)
	rows.sort_custom(func(a, b): return _save_timestamp(a) > _save_timestamp(b))
	return rows


func _next_save_timestamp() -> int:
	if _last_save_usec == 0:
		for row in list_slots():
			_last_save_usec = maxi(_last_save_usec, _save_timestamp(row))
	# Some platforms expose a coarser wall clock than a rapid sequence of saves.
	# Advancing one microsecond on ties gives every successful write a stable order.
	_last_save_usec = maxi(int(Time.get_unix_time_from_system() * 1000000.0), _last_save_usec + 1)
	return _last_save_usec


func _save_timestamp(row: Dictionary) -> int:
	var precise := str(row.get("saved_at_unix_usec", ""))
	if precise.is_valid_int():
		return int(precise)
	# Version-one/two saves retain their local, second-resolution timestamp.
	var legacy := str(row.get("saved_at", ""))
	if legacy.length() < 19 or legacy.substr(4, 1) != "-" or legacy.substr(7, 1) != "-":
		return 0
	var local_seconds := Time.get_unix_time_from_datetime_string(legacy)
	var offset_seconds := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return (local_seconds - offset_seconds) * 1000000


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
	_atomic_write(path, data)


func read_json(path: String) -> Dictionary:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var file := FileAccess.open(candidate, FileAccess.READ)
		if file == null:
			continue
		var parser := JSON.new()
		if parser.parse(file.get_as_text()) == OK and typeof(parser.data) == TYPE_DICTIONARY:
			return parser.data
	return {}


func _atomic_write(path: String, data: Dictionary) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_error("Could not write " + path)
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var original := ProjectSettings.globalize_path(path)
	var backup := original + ".bak"
	if FileAccess.file_exists(path):
		var old_file := FileAccess.open(path, FileAccess.READ)
		var old_valid := false
		if old_file != null:
			var old_parser := JSON.new()
			old_valid = old_parser.parse(old_file.get_as_text()) == OK and typeof(old_parser.data) == TYPE_DICTIONARY
			old_file.close()
		if old_valid:
			if FileAccess.file_exists(path + ".bak"):
				DirAccess.remove_absolute(backup)
			if DirAccess.rename_absolute(original, backup) != OK:
				return false
		elif DirAccess.remove_absolute(original) != OK:
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), original) != OK:
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.rename_absolute(backup, original)
		return false
	return true
