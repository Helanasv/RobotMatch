extends RefCounted

static var selected_id := "first_battery"
static var selected_world := "factory"

const LEVELS := [
	{
		"id": "first_battery",
		"name": "First Battery",
		"moves": 14,
		"tiles": ["battery", "gear", "microchip", "energy_crystal"],
		"goals": [
			{"type": "collect", "tile_type": "battery", "amount": 10},
		],
		"charge": {},
	},
	{
		"id": "repair_kit",
		"name": "Repair Kit",
		"moves": 16,
		"tiles": ["battery", "gear", "microchip", "energy_crystal"],
		"goals": [
			{"type": "collect", "tile_type": "battery", "amount": 10},
			{"type": "collect", "tile_type": "gear", "amount": 8},
		],
		"charge": {},
	},
	{
		"id": "start_the_generator",
		"name": "Start the Generator",
		"moves": 20,
		"tiles": ["battery", "gear", "microchip", "energy_crystal"],
		"goals": [
			{"type": "collect", "tile_type": "battery", "amount": 12},
			{"type": "collect", "tile_type": "microchip", "amount": 10},
			{"type": "charge_generator", "tile_type": "", "amount": 100},
		],
		"charge": {"battery": 5, "microchip": 5},
	},
	{
		"id": "clear_the_debris",
		"name": "Clear the Debris",
		"moves": 20,
		"tiles": ["battery", "gear", "bolt", "energy_crystal"],
		"goals": [
			{"type": "destroy_blocks", "tile_type": "", "amount": 8},
			{"type": "collect", "tile_type": "gear", "amount": 10},
			{"type": "collect", "tile_type": "bolt", "amount": 8},
		],
		"charge": {},
		"blocks": [[1, 1], [1, 6], [2, 3], [2, 5], [4, 1], [5, 4], [6, 2], [6, 6]],
	},
	{
		"id": "infected_circuit",
		"name": "Infected Circuit",
		"moves": 22,
		"tiles": ["battery", "gear", "microchip", "energy_crystal"],
		"goals": [
			{"type": "clear_infected", "tile_type": "", "amount": 10},
			{"type": "collect", "tile_type": "microchip", "amount": 8},
			{"type": "collect", "tile_type": "battery", "amount": 10},
		],
		"charge": {},
		"infected": [[1, 2], [1, 5], [2, 2], [2, 5], [3, 1], [3, 6], [4, 3], [4, 4], [5, 2], [6, 5]],
		"virus_max": 20,
	},
	{
		"id": "emergency_mode",
		"name": "Emergency Mode",
		"moves": 26,
		"time": 60,
		"tiles": ["battery", "gear", "microchip", "energy_crystal"],
		"goals": [
			{"type": "collect", "tile_type": "battery", "amount": 18},
			{"type": "score", "tile_type": "", "amount": 2500},
		],
		"charge": {},
	},
	{
		"id": "frozen_storage",
		"name": "Frozen Storage",
		"moves": 24,
		"tiles": ["battery", "gear", "energy_crystal"],
		"goals": [
			{"type": "destroy_ice", "tile_type": "", "amount": 12},
			{"type": "collect", "tile_type": "energy_crystal", "amount": 10},
			{"type": "collect", "tile_type": "battery", "amount": 8},
		],
		"charge": {},
		"ice": [[0, 2], [0, 5], [1, 1], [1, 6], [2, 3], [2, 4], [3, 1], [3, 6], [4, 2], [4, 5], [5, 3], [6, 4]],
	},
	{
		"id": "open_the_gates",
		"name": "Open the Gates",
		"moves": 22,
		"tiles": ["battery", "gear", "bolt"],
		"goals": [
			{"type": "create_keys", "tile_type": "", "amount": 3},
			{"type": "collect", "tile_type": "bolt", "amount": 12},
			{"type": "open_door", "tile_type": "", "amount": 1},
		],
		"charge": {},
		"blocks": [[1, 1], [1, 6], [2, 4], [4, 1], [5, 6], [6, 2]],
		"locks": [[2, 1], [3, 6], [5, 3]],
		"gate": [4, 4],
	},
	{
		"id": "rescue_the_drone",
		"name": "Rescue the Drone",
		"moves": 28,
		"tiles": ["battery", "gear", "microchip"],
		"goals": [
			{"type": "collect", "tile_type": "battery", "amount": 15},
			{"type": "collect", "tile_type": "gear", "amount": 10},
			{"type": "clear_path", "tile_type": "", "amount": 12},
			{"type": "charge_drone", "tile_type": "", "amount": 100},
		],
		"charge": {"battery": 4, "gear": 4},
		"blocks": [[1, 1], [1, 5], [3, 2], [4, 6], [6, 1], [6, 4]],
		"infected": [[0, 4], [2, 2], [2, 6], [4, 3], [5, 6], [7, 2]],
		"drone": [0, 0],
		"reward": "repair_drone",
		"reward_name": "Repair Drone",
	},
	{
		"id": "restart_the_factory",
		"name": "Restart the Factory",
		"moves": 34,
		"tiles": ["battery", "gear", "microchip", "bolt", "energy_crystal"],
		"goals": [
			{"type": "collect", "tile_type": "battery", "amount": 20},
			{"type": "collect", "tile_type": "gear", "amount": 15},
			{"type": "collect", "tile_type": "microchip", "amount": 12},
			{"type": "destroy_blocks", "tile_type": "", "amount": 10},
			{"type": "clear_infected", "tile_type": "", "amount": 10},
			{"type": "charge_generator", "tile_type": "", "amount": 100},
			{"type": "open_door", "tile_type": "", "amount": 1},
		],
		"charge": {"battery": 3, "gear": 3, "microchip": 3},
		"blocks": [[0, 2], [0, 6], [1, 4], [2, 1], [2, 6], [3, 3], [4, 6], [5, 1], [6, 3], [7, 5]],
		"infected": [[0, 4], [1, 1], [1, 6], [3, 1], [3, 5], [4, 2], [5, 4], [5, 6], [6, 1], [7, 2]],
		"gate": [4, 4],
		"bonus_coins": 500,
		"world_complete": true,
	},
	{
		"id": "broken_factory_robot",
		"name": "Broken Factory Robot",
		"moves": 28,
		"boss": true,
		"tiles": ["battery", "gear", "microchip", "bolt", "energy_crystal"],
		"goals": [
			{"type": "defeat_boss", "tile_type": "", "amount": 1},
		],
		"charge": {},
		"blocks": [[1, 1], [1, 6], [3, 3], [4, 5], [6, 2], [6, 6]],
		"infected": [[0, 3], [2, 5], [3, 1], [5, 4], [7, 2], [7, 6]],
		"bonus_coins": 1000,
		"finale": true,
		"goal_text": "Defeat the Broken Factory Robot.\n\nGears deal damage.\nCrystals deal stronger damage.\nA microchip drops the shield.\nBatteries charge your robot.\nBolts restore the boss.\nEach turn the robot hits back.",
	},
]

const CITY_LEVELS := [
	{
		"id": "city_lights",
		"name": "City Lights",
		"moves": 14,
		"tiles": ["battery", "gear", "microchip", "energy_crystal"],
		"goals": [
			{"type": "collect", "tile_type": "battery", "amount": 8},
			{"type": "collect", "tile_type": "gear", "amount": 6},
		],
		"charge": {},
	},
	{
		"id": "power_lines",
		"name": "Power Lines",
		"moves": 18,
		"tiles": ["battery", "gear", "bolt", "energy_crystal"],
		"goals": [
			{"type": "destroy_blocks", "tile_type": "", "amount": 6},
			{"type": "collect", "tile_type": "gear", "amount": 8},
		],
		"charge": {},
		"blocks": [[1, 2], [1, 5], [3, 3], [4, 6], [6, 1], [6, 4]],
	},
	{
		"id": "night_circuit",
		"name": "Night Circuit",
		"moves": 18,
		"tiles": ["battery", "gear", "microchip", "energy_crystal"],
		"goals": [
			{"type": "clear_infected", "tile_type": "", "amount": 6},
			{"type": "collect", "tile_type": "microchip", "amount": 8},
		],
		"charge": {},
		"infected": [[1, 1], [1, 6], [3, 3], [4, 5], [6, 2], [7, 4]],
		"virus_max": 16,
	},
]


static func select_world(world_id: String) -> void:
	selected_world = world_id


static func world_levels() -> Array:
	if selected_world == "city":
		return CITY_LEVELS
	return LEVELS


static func world_name() -> String:
	if selected_world == "city":
		return "Electric City"
	return "Factory"


static func select_level(level_id: String) -> void:
	selected_id = level_id


static func current() -> Dictionary:
	return get_level(selected_id)


static func get_level(level_id: String) -> Dictionary:
	for level in LEVELS:
		if str(level.id) == level_id:
			return level
	for level in CITY_LEVELS:
		if str(level.id) == level_id:
			return level
	return LEVELS[0]


static func next_id(level_id: String) -> String:
	for catalog in [LEVELS, CITY_LEVELS]:
		for index in catalog.size():
			if str(catalog[index].id) == level_id and index + 1 < catalog.size():
				return str(catalog[index + 1].id)
	return ""
