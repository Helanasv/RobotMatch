extends Control

const LevelsScript := preload("res://data/levels.gd")
const SaveManagerScript := preload("res://scripts/SaveManager.gd")


func _ready() -> void:
	$CityButton.disabled = SaveManagerScript.get_upgrade("electric_city") <= 0
	$FactoryButton.pressed.connect(_open_factory)
	$CityButton.pressed.connect(_open_city)
	$BackButton.pressed.connect(_go_back)


func _open_factory() -> void:
	LevelsScript.select_world("factory")
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")


func _open_city() -> void:
	LevelsScript.select_world("city")
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
