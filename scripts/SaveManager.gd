extends RefCounted

const PATH := "user://progress.json"
const LEGACY_PATH := "user://save.cfg"

static var _data: Dictionary = {}
static var _loaded := false


static func coins() -> int:
	_ensure()
	return int(_data["coins"])


static func add_coins(amount: int) -> int:
	_ensure()
	_data["coins"] = int(_data["coins"]) + maxi(amount, 0)
	_write()
	return int(_data["coins"])


static func unlocked_levels() -> Array:
	_ensure()
	return (_data["unlocked_levels"] as Array).duplicate()


static func is_unlocked(level_id: String) -> bool:
	_ensure()
	return (_data["unlocked_levels"] as Array).has(level_id)


static func unlock_level(level_id: String) -> void:
	_ensure()
	var unlocked: Array = _data["unlocked_levels"]
	if unlocked.has(level_id):
		return
	unlocked.append(level_id)
	_write()


static func record_level(level_id: String, star_count: int, score: int, moves_left: int) -> void:
	_ensure()
	var unlocked: Array = _data["unlocked_levels"]
	if not unlocked.has(level_id):
		unlocked.append(level_id)
	var levels: Dictionary = _data["levels"]
	var previous: Dictionary = {}
	if levels.has(level_id) and levels[level_id] is Dictionary:
		previous = levels[level_id]
	var best_stars := maxi(int(previous.get("stars", 0)), star_count)
	var best_score := maxi(int(previous.get("best_score", 0)), score)
	var best_moves := int(previous.get("moves_left", moves_left))
	if score >= int(previous.get("best_score", 0)):
		best_moves = moves_left
	levels[level_id] = {
		"stars": best_stars,
		"best_score": best_score,
		"moves_left": best_moves,
	}
	_write()


static func level_result(level_id: String) -> Dictionary:
	_ensure()
	var levels: Dictionary = _data["levels"]
	if not levels.has(level_id) or not levels[level_id] is Dictionary:
		return {}
	var stored: Dictionary = levels[level_id]
	return {
		"stars": int(stored.get("stars", 0)),
		"best_score": int(stored.get("best_score", 0)),
		"moves_left": int(stored.get("moves_left", 0)),
	}


static func total_stars() -> int:
	_ensure()
	var sum := 0
	var levels: Dictionary = _data["levels"]
	for level_id in levels:
		if levels[level_id] is Dictionary:
			sum += int(levels[level_id].get("stars", 0))
	return sum


static func get_upgrade(upgrade_id: String) -> int:
	_ensure()
	return int((_data["upgrades"] as Dictionary).get(upgrade_id, 0))


static func set_upgrade(upgrade_id: String, level: int) -> void:
	_ensure()
	(_data["upgrades"] as Dictionary)[upgrade_id] = maxi(level, 0)
	_write()


static func sound_settings() -> Dictionary:
	_ensure()
	var sound: Dictionary = _data["sound"]
	return {
		"music": bool(sound.get("music", true)),
		"effects": bool(sound.get("effects", true)),
	}


static func set_sound(music: bool, effects: bool) -> void:
	_ensure()
	_data["sound"] = {"music": music, "effects": effects}
	_write()


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	_data = _defaults()
	if FileAccess.file_exists(PATH):
		_read()
		return
	_import_legacy()
	_write()


static func _defaults() -> Dictionary:
	return {
		"coins": 0,
		"unlocked_levels": ["first_battery"],
		"levels": {},
		"upgrades": {},
		"sound": {"music": true, "effects": true},
	}


static func _read() -> void:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var saved: Dictionary = parsed
	_data["coins"] = int(saved.get("coins", 0))
	if saved.get("unlocked_levels") is Array:
		_data["unlocked_levels"] = saved["unlocked_levels"]
	if saved.get("levels") is Dictionary:
		_data["levels"] = saved["levels"]
	if saved.get("upgrades") is Dictionary:
		_data["upgrades"] = saved["upgrades"]
	if saved.get("sound") is Dictionary:
		_data["sound"] = saved["sound"]


static func _write() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


static func _import_legacy() -> void:
	if not FileAccess.file_exists(LEGACY_PATH):
		return
	var file := FileAccess.open(LEGACY_PATH, FileAccess.READ)
	if file == null:
		return
	var section := ""
	var levels: Dictionary = _data["levels"]
	var unlocked: Array = _data["unlocked_levels"]
	for raw_line in file.get_as_text().split("\n"):
		var line := raw_line.strip_edges()
		if line.begins_with("[") and line.ends_with("]"):
			section = line.substr(1, line.length() - 2)
			continue
		var split_at := line.find("=")
		if split_at == -1:
			continue
		var key := line.substr(0, split_at).strip_edges()
		var value := line.substr(split_at + 1).strip_edges()
		if section == "player" and key == "coins":
			_data["coins"] = int(value)
		elif section.begins_with("level_"):
			var level_id := section.substr(6)
			if not unlocked.has(level_id):
				unlocked.append(level_id)
			var stored: Dictionary = {}
			if levels.has(level_id) and levels[level_id] is Dictionary:
				stored = levels[level_id]
			if key == "stars":
				stored["stars"] = int(value)
			elif key == "score":
				stored["best_score"] = int(value)
			elif key == "moves_left":
				stored["moves_left"] = int(value)
			levels[level_id] = stored
	file.close()
