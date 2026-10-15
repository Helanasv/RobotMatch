extends RefCounted

const SaveManagerScript := preload("res://scripts/SaveManager.gd")

const BASE_COST := 100


static func level(upgrade_id: String) -> int:
	return SaveManagerScript.get_upgrade(upgrade_id)


static func cost(upgrade_id: String) -> int:
	return BASE_COST * (level(upgrade_id) + 1)


static func energy_max() -> int:
	return 100 + level("energy") * 20


static func battery_charge() -> int:
	return 25 + level("energy") * 5


static func strike_damage() -> int:
	return 15 + level("energy") * 5


static func health() -> int:
	return 100 + level("repair") * 25


static func scanner_on() -> bool:
	return level("scanner") > 0


static func effect_text(upgrade_id: String) -> String:
	match upgrade_id:
		"energy":
			return "Max energy: %d" % energy_max()
		"scanner":
			return "Free hints" if scanner_on() else "Costs a hint"
		"repair":
			return "Health: %d" % health()
		_:
			return ""


static func buy(upgrade_id: String) -> bool:
	if not SaveManagerScript.spend_coins(cost(upgrade_id)):
		return false
	SaveManagerScript.set_upgrade(upgrade_id, level(upgrade_id) + 1)
	return true
