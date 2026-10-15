extends RefCounted

signal changed

const COLLECT := "collect"
const SCORE := "score"
const DESTROY_BLOCKS := "destroy_blocks"
const DESTROY_ICE := "destroy_ice"
const CLEAR_INFECTED := "clear_infected"
const CHARGE_GENERATOR := "charge_generator"
const CHARGE_DRONE := "charge_drone"
const CLEAR_PATH := "clear_path"
const OPEN_DOOR := "open_door"
const CREATE_KEYS := "create_keys"
const RESCUE_DRONE := "rescue_drone"
const DEFEAT_BOSS := "defeat_boss"

const TileScript := preload("res://scripts/Tile.gd")

var goals: Array = []


func add_goal(type: String, amount: int, tile_type: String = "") -> void:
	goals.append({
		"type": type,
		"tile_type": tile_type,
		"amount": amount,
		"current": 0,
	})
	changed.emit()


func record_match(tiles: Array, points: int, charge_rates = null) -> void:
	var rates: Dictionary = charge_rates if charge_rates is Dictionary else {}
	var counts := {}
	for tile in tiles:
		var key := _tile_key(tile)
		counts[key] = int(counts.get(key, 0)) + 1
	var moved := false
	for goal in goals:
		var gained := 0
		if goal.type == COLLECT:
			gained = int(counts.get(goal.tile_type, 0))
		elif goal.type == SCORE:
			gained = points
		elif goal.type == CHARGE_GENERATOR or goal.type == CHARGE_DRONE:
			for key in counts:
				gained += int(counts[key]) * int(rates.get(key, 0))
		if _gain(goal, gained):
			moved = true
	if moved:
		changed.emit()


func add_progress(type: String, amount: int, tile_type: String = "") -> void:
	var moved := false
	for goal in goals:
		if str(goal.type) != type:
			continue
		if tile_type != "" and str(goal.tile_type) != tile_type:
			continue
		if _gain(goal, amount):
			moved = true
	if moved:
		changed.emit()


func all_complete() -> bool:
	if goals.is_empty():
		return false
	for goal in goals:
		if int(goal.current) < int(goal.amount):
			return false
	return true


func is_complete(type: String) -> bool:
	var found := false
	for goal in goals:
		if str(goal.type) != type:
			continue
		found = true
		if int(goal.current) < int(goal.amount):
			return false
	return found


func hud_text() -> String:
	var lines: PackedStringArray = []
	for goal in goals:
		lines.append("Goal: %s" % _detail(goal))
	if lines.is_empty():
		return "Goal:"
	return "\n".join(lines)


func status_text() -> String:
	var lines: PackedStringArray = []
	for goal in goals:
		lines.append(_detail(goal))
	return "\n".join(lines)


func _gain(goal: Dictionary, amount: int) -> bool:
	var room: int = int(goal.amount) - int(goal.current)
	if amount <= 0 or room <= 0:
		return false
	goal.current = int(goal.current) + mini(amount, room)
	return true


func _detail(goal: Dictionary) -> String:
	return "%s: %d/%d" % [_label(goal), int(goal.current), int(goal.amount)]


func _label(goal: Dictionary) -> String:
	if goal.type == COLLECT:
		match str(goal.tile_type):
			"battery":
				return "Batteries"
			"gear":
				return "Gears"
			"microchip":
				return "Microchips"
			"bolt":
				return "Bolts"
			"energy_crystal":
				return "Energy Crystals"
			_:
				return str(goal.tile_type)
	match str(goal.type):
		SCORE:
			return "Score"
		DESTROY_BLOCKS:
			return "Blocks"
		DESTROY_ICE:
			return "Ice"
		CLEAR_INFECTED:
			return "Infected"
		CHARGE_GENERATOR:
			return "Generator"
		CHARGE_DRONE:
			return "Drone"
		CLEAR_PATH:
			return "Path"
		OPEN_DOOR:
			return "Gate"
		CREATE_KEYS:
			return "Keys"
		RESCUE_DRONE:
			return "Drone"
		DEFEAT_BOSS:
			return "Defeat"
		_:
			return str(goal.type)


func _tile_key(tile: Tile) -> String:
	match tile.tile_type:
		TileScript.Type.BATTERY:
			return "battery"
		TileScript.Type.GEAR:
			return "gear"
		TileScript.Type.MICROCHIP:
			return "microchip"
		TileScript.Type.BOLT:
			return "bolt"
		TileScript.Type.ENERGY_CRYSTAL:
			return "energy_crystal"
		_:
			return ""
