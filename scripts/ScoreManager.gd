extends RefCounted

signal changed

const MOVE_LIMIT := 20
const BATTERY_GOAL := 10

var score := 0
var multiplier := 1
var moves := MOVE_LIMIT
var batteries := 0


func spend_move() -> void:
	multiplier = 1
	if moves > 0:
		moves -= 1
	changed.emit()


func points_for_length(length: int) -> int:
	if length >= 5:
		return 150
	if length == 4:
		return 80
	if length == 3:
		return 30
	return 0


func add_match_lengths(lengths: Array) -> int:
	var base := 0
	for length in lengths:
		base += points_for_length(length)
	var gained := base * multiplier
	score += gained
	changed.emit()
	return gained


func add_batteries(count: int) -> void:
	if count <= 0:
		return
	batteries += count
	changed.emit()


func increase_combo() -> void:
	multiplier += 1
	changed.emit()


func goal_reached() -> bool:
	return batteries >= BATTERY_GOAL


func stars() -> int:
	if moves >= 10:
		return 3
	if moves >= 5:
		return 2
	return 1


func coins_earned() -> int:
	return stars() * 10


func combo_text() -> String:
	return "Combo x%d" % multiplier


func moves_text() -> String:
	return "Moves: %d/%d" % [moves, MOVE_LIMIT]


func goal_text() -> String:
	return "Goal: Batteries: %d/%d" % [batteries, BATTERY_GOAL]
