extends RefCounted

static var selected_id := "first_battery"

const LEVELS := [
	{
		"id": "first_battery",
		"name": "First Battery",
		"moves": 20,
		"tiles": ["battery", "gear", "microchip"],
		"goals": [
			{"type": "collect", "tile_type": "battery", "amount": 10},
		],
		"charge": {},
	},
	{
		"id": "repair_kit",
		"name": "Repair Kit",
		"moves": 25,
		"tiles": ["battery", "gear", "microchip"],
		"goals": [
			{"type": "collect", "tile_type": "battery", "amount": 10},
			{"type": "collect", "tile_type": "gear", "amount": 8},
		],
		"charge": {},
	},
	{
		"id": "start_the_generator",
		"name": "Start the Generator",
		"moves": 30,
		"tiles": ["battery", "gear", "microchip"],
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
		"moves": 30,
		"tiles": ["battery", "gear", "bolt"],
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
		"moves": 32,
		"tiles": ["battery", "gear", "microchip"],
		"goals": [
			{"type": "clear_infected", "tile_type": "", "amount": 10},
			{"type": "collect", "tile_type": "microchip", "amount": 8},
			{"type": "collect", "tile_type": "battery", "amount": 10},
		],
		"charge": {},
		"infected": [[1, 2], [1, 5], [2, 2], [2, 5], [3, 1], [3, 6], [4, 3], [4, 4], [5, 2], [6, 5]],
		"virus_max": 20,
	},
]


static func select_level(level_id: String) -> void:
	selected_id = level_id


static func current() -> Dictionary:
	return get_level(selected_id)


static func get_level(level_id: String) -> Dictionary:
	for level in LEVELS:
		if str(level.id) == level_id:
			return level
	return LEVELS[0]


static func next_id(level_id: String) -> String:
	for index in LEVELS.size():
		if str(LEVELS[index].id) == level_id and index + 1 < LEVELS.size():
			return str(LEVELS[index + 1].id)
	return ""
