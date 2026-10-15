extends Control

const LevelsScript := preload("res://data/levels.gd")
const SaveManagerScript := preload("res://scripts/SaveManager.gd")
const StarIconsScript := preload("res://scripts/StarIcons.gd")


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	$Title.text = LevelsScript.world_name()
	_sync_unlocks()
	for level in LevelsScript.world_levels():
		var level_id := str(level.id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 76)
		var stars := int(SaveManagerScript.level_result(level_id).get("stars", 0))
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 16
		row.offset_right = -16
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		var name_label := Label.new()
		name_label.text = str(level.name)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.add_theme_font_size_override("font_size", 26)
		row.add_child(name_label)
		var stars_box := HBoxContainer.new()
		stars_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars_box.add_theme_constant_override("separation", 4)
		StarIconsScript.fill(stars_box, stars, 32)
		row.add_child(stars_box)
		button.add_child(row)
		button.disabled = not SaveManagerScript.is_unlocked(level_id)
		button.pressed.connect(_open_level.bind(level_id))
		$Scroll/List.add_child(button)


func _sync_unlocks() -> void:
	var catalog: Array = LevelsScript.world_levels()
	var open_next := true
	if LevelsScript.selected_world == "city":
		open_next = SaveManagerScript.get_upgrade("electric_city") > 0
	var ids: Array[String] = []
	for level in catalog:
		var level_id := str(level.id)
		ids.append(level_id)
		if open_next:
			SaveManagerScript.unlock_level(level_id)
		var stars := int(SaveManagerScript.level_result(level_id).get("stars", 0))
		open_next = stars > 0
	if LevelsScript.selected_world == "city" or ids.is_empty():
		return
	var last_level: Dictionary = catalog[ids.size() - 1]
	if not bool(last_level.get("boss", false)) and ids.size() >= 2 and SaveManagerScript.is_unlocked(ids[ids.size() - 2]):
		SaveManagerScript.unlock_level(ids[ids.size() - 1])


func _open_level(level_id: String) -> void:
	LevelsScript.select_level(level_id)
	get_tree().change_scene_to_file("res://scenes/GameBoard.tscn")


func _go_back() -> void:
	if SaveManagerScript.get_upgrade("electric_city") > 0:
		get_tree().change_scene_to_file("res://scenes/WorldSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
