extends Control

const LevelsScript := preload("res://data/levels.gd")
const SaveManagerScript := preload("res://scripts/SaveManager.gd")


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	_sync_unlocks()
	for level in LevelsScript.LEVELS:
		var level_id := str(level.id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 76)
		button.add_theme_font_size_override("font_size", 26)
		var stars := int(SaveManagerScript.level_result(level_id).get("stars", 0))
		button.text = str(level.name) if stars == 0 else "%s  Stars: %d" % [level.name, stars]
		button.disabled = not SaveManagerScript.is_unlocked(level_id)
		button.pressed.connect(_open_level.bind(level_id))
		$List.add_child(button)


func _sync_unlocks() -> void:
	var open_next := true
	for level in LevelsScript.LEVELS:
		var level_id := str(level.id)
		if open_next:
			SaveManagerScript.unlock_level(level_id)
		var stars := int(SaveManagerScript.level_result(level_id).get("stars", 0))
		open_next = stars > 0


func _open_level(level_id: String) -> void:
	LevelsScript.select_level(level_id)
	get_tree().change_scene_to_file("res://scenes/GameBoard.tscn")


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
