extends RefCounted

const CoinManagerScript := preload("res://scripts/CoinManager.gd")


static func load_coins() -> int:
	return CoinManagerScript.balance()


static func add_coins(amount: int) -> int:
	return CoinManagerScript.add(amount)
