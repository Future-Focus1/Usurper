class_name ArtLibrary
extends RefCounted

const NPCS := ["garran_vale", "celene_veyne", "oren_pell", "nessa_grey", "bren_tal", "tomas_maren", "evelyne_maren", "edric_edevane", "aldren_veil", "osric_harrow"]
const UNITS := ["infantry", "spears", "archers", "cavalry", "heavy", "skirmishers", "queens_guard", "storm_knights", "harrow_longbows", "maren_riders"]
static var _textures := {}


static func texture(id: String) -> Texture2D:
	if _textures.has(id):
		return _textures[id]
	var path := "res://assets/art/%s.png" % id
	var result: Texture2D
	if ResourceLoader.exists(path):
		result = load(path)
	elif NPCS.has(id):
		result = _cell("npcs", NPCS.find(id))
	elif UNITS.has(id):
		result = _cell("units", UNITS.find(id))
	elif id == "veteran_band":
		result = _cell("units", 0)
	if result != null:
		_textures[id] = result
	return result


static func _cell(sheet: String, index: int) -> Texture2D:
	var path := "res://assets/art/%s.png" % sheet
	if not ResourceLoader.exists(path):
		return null
	var atlas: Texture2D = load(path)
	var cell_size := Vector2(atlas.get_width() / 5.0, atlas.get_height() / 2.0)
	var result := AtlasTexture.new()
	result.atlas = atlas
	result.region = Rect2(Vector2(index % 5, index / 5) * cell_size, cell_size)
	return result


static func speaker(event: Dictionary, db: ContentDB) -> String:
	var id := str(event.get("speaker_id", ""))
	if id != "":
		return id
	var name := str(event.get("speaker", "")).to_lower()
	for cid in db.character_order:
		var character_name := str(db.characters[cid].get("name", "")).to_lower()
		if name == character_name or (not name.is_empty() and character_name.contains(name)):
			return str(cid)
	return ""
