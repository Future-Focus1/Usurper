extends Node

## Persistent Chronicle. The player character does not inherit this knowledge. The game does.

var unlocked := {}
var campaigns: Array = []
var settings := {"fullscreen": false, "volume": 0.8, "muted": false,
	"music_volume": 0.8, "music_muted": false,
	"tone_volume": 0.8, "tone_muted": false,
	"click_volume": 0.8, "click_muted": false}


func _ready() -> void:
	var data := SaveManager.read_json("user://chronicle.json")
	var raw = data.get("unlocked", {})
	if typeof(raw) == TYPE_DICTIONARY:
		for key in raw:
			if bool(raw[key]):
				unlocked[str(key)] = true
	if typeof(data.get("campaigns", [])) == TYPE_ARRAY:
		campaigns = data.get("campaigns", [])
	var prefs := SaveManager.read_json("user://settings.json")
	if not prefs.is_empty():
		settings["fullscreen"] = bool(prefs.get("fullscreen", false))
		settings["volume"] = float(prefs.get("volume", 0.8))
		for key in ["music_volume", "tone_volume", "click_volume"]:
			settings[key] = clampf(float(prefs.get(key, 0.8)), 0.0, 1.0)
		for key in ["muted", "music_muted", "tone_muted", "click_muted"]:
			settings[key] = bool(prefs.get(key, false))


func unlock(id: String) -> bool:
	if id == "" or unlocked.has(id):
		return false
	unlocked[id] = true
	_write()
	return true


func has(id: String) -> bool:
	return unlocked.has(id)


func unlocked_count() -> int:
	return unlocked.size()


func record_campaign(entry: Dictionary) -> void:
	# Continuing a finished save must not inflate Chronicle completion counts.
	var id := str(entry.get("campaign_id", ""))
	if id != "":
		for completed in campaigns:
			if str(completed.get("campaign_id", "")) == id:
				return
	entry["at"] = Time.get_datetime_string_from_system()
	campaigns.append(entry)
	_write()


func completed_claimants() -> Array:
	var found: Array = []
	for entry in campaigns:
		var id := str(entry.get("claimant", ""))
		if id != "" and not found.has(id):
			found.append(id)
	return found


func save_settings() -> void:
	SaveManager.write_json("user://settings.json", settings)


func _write() -> void:
	SaveManager.write_json("user://chronicle.json", {"unlocked": unlocked, "campaigns": campaigns})
