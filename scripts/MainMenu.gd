extends Control

const CoinManagerScript := preload("res://scripts/CoinManager.gd")
const SaveManagerScript := preload("res://scripts/SaveManager.gd")
const LevelsScript := preload("res://data/levels.gd")

func _ready() -> void:
	$Menu/CoinsLabel.text = "Coins: %d" % CoinManagerScript.balance()
	$Menu/StarsLabel.text = "Stars: %d" % SaveManagerScript.total_stars()
	$Menu/PlayButton.pressed.connect(_open_first_level)
	$Menu/LevelSelectButton.pressed.connect(_open_level_select)
	$Menu/UpgradeButton.pressed.connect(_open_robot_upgrade)
	$Menu/SettingsButton.pressed.connect(_open_settings)


func _open_first_level() -> void:
	LevelsScript.select_level("first_battery")
	get_tree().change_scene_to_file("res://scenes/GameBoard.tscn")


func _open_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")


func _open_robot_upgrade() -> void:
	get_tree().change_scene_to_file("res://scenes/UpgradeMenu.tscn")


func _open_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")
