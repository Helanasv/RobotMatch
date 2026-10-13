extends RefCounted

const PATH := "user://save.cfg"


static func load_coins() -> int:
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return 0
	return int(file.get_value("player", "coins", 0))


static func add_coins(amount: int) -> int:
	var total := load_coins() + maxi(amount, 0)
	var file := ConfigFile.new()
	file.load(PATH)
	file.set_value("player", "coins", total)
	file.save(PATH)
	return total
