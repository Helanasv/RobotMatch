extends RefCounted

const SaveManagerScript := preload("res://scripts/SaveManager.gd")

const LEVEL_CLEAR_COINS := 50
const THREE_STAR_BONUS := 20


static func stars_for(moves_left: int) -> int:
	if moves_left >= 8:
		return 3
	if moves_left >= 3:
		return 2
	return 1


static func coins_for(star_count: int) -> int:
	var coins := LEVEL_CLEAR_COINS
	if star_count >= 3:
		coins += THREE_STAR_BONUS
	return coins


static func make_result(score: int, moves_left: int) -> Dictionary:
	var star_count := stars_for(moves_left)
	return {
		"stars": star_count,
		"coins": coins_for(star_count),
		"score": score,
		"moves_left": moves_left,
	}


static func save_result(level_id: String, result: Dictionary) -> void:
	SaveManagerScript.record_level(
		level_id,
		int(result.stars),
		int(result.score),
		int(result.moves_left)
	)


static func load_result(level_id: String) -> Dictionary:
	var stored: Dictionary = SaveManagerScript.level_result(level_id)
	if stored.is_empty():
		return {}
	stored["score"] = int(stored.get("best_score", 0))
	return stored
