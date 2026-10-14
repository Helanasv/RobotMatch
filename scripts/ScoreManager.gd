extends RefCounted

signal changed

var move_limit := 20
var score := 0
var multiplier := 1
var moves := 20


func configure(limit: int) -> void:
	move_limit = maxi(limit, 1)
	moves = move_limit


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


func increase_combo() -> void:
	multiplier += 1
	changed.emit()


func combo_text() -> String:
	return "Combo x%d" % multiplier


func moves_text() -> String:
	return "Moves: %d/%d" % [moves, move_limit]
