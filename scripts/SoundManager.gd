extends Node

const SaveManagerScript := preload("res://scripts/SaveManager.gd")

var _music: AudioStreamPlayer
var _effect: AudioStreamPlayer


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	add_child(_music)
	var stream: AudioStream = load("res://assets/audio/music.wav")
	if stream is AudioStreamWAV:
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music.stream = stream
	_music.volume_db = -16.0
	_effect = AudioStreamPlayer.new()
	add_child(_effect)
	_effect.stream = load("res://assets/audio/click.wav")
	_effect.volume_db = -6.0
	apply()


func apply() -> void:
	var sound: Dictionary = SaveManagerScript.sound_settings()
	if bool(sound.music):
		if not _music.playing:
			_music.play()
	else:
		_music.stop()


func play_click() -> void:
	var sound: Dictionary = SaveManagerScript.sound_settings()
	if not bool(sound.effects) or _effect == null:
		return
	_effect.play()
