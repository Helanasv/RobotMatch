extends RefCounted

const SaveManagerScript := preload("res://scripts/SaveManager.gd")


static func balance() -> int:
	return SaveManagerScript.coins()


static func add(amount: int) -> int:
	return SaveManagerScript.add_coins(amount)


static func spend(amount: int) -> bool:
	return SaveManagerScript.spend_coins(amount)
