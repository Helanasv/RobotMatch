extends Control

func _ready() -> void:
	$Menu/PlayButton.pressed.connect(_open_game_board)
	$Menu/LevelsButton.pressed.connect(_open_level_select)
	$Menu/UpgradesButton.pressed.connect(_open_upgrade_menu)


func _open_game_board() -> void:
	get_tree().change_scene_to_file("res://scenes/GameBoard.tscn")


func _open_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")


func _open_upgrade_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/UpgradeMenu.tscn")
