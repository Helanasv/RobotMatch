extends Control

const SaveManagerScript := preload("res://scripts/SaveManager.gd")


func _ready() -> void:
	var sound: Dictionary = SaveManagerScript.sound_settings()
	$MusicButton.button_pressed = bool(sound.music)
	$EffectsButton.button_pressed = bool(sound.effects)
	$MusicButton.toggled.connect(_on_music)
	$EffectsButton.toggled.connect(_on_effects)
	$BackButton.pressed.connect(_go_back)


func _on_music(enabled: bool) -> void:
	var sound: Dictionary = SaveManagerScript.sound_settings()
	SaveManagerScript.set_sound(enabled, bool(sound.effects))
	SoundManager.apply()


func _on_effects(enabled: bool) -> void:
	var sound: Dictionary = SaveManagerScript.sound_settings()
	SaveManagerScript.set_sound(bool(sound.music), enabled)
	if enabled:
		SoundManager.play_click()


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
