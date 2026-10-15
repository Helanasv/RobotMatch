extends Control

const CoinManagerScript := preload("res://scripts/CoinManager.gd")
const RobotStatsScript := preload("res://scripts/RobotStats.gd")

const UPGRADES := [
	{"id": "energy", "title": "Upgrade Energy", "icon": preload("res://assets/ui/upgrade_energy.svg")},
	{"id": "scanner", "title": "Upgrade Scanner", "icon": preload("res://assets/ui/upgrade_scanner.svg")},
	{"id": "repair", "title": "Upgrade Repair", "icon": preload("res://assets/ui/upgrade_repair.svg")},
]


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	for upgrade in UPGRADES:
		$Scroll/List.add_child(_card(str(upgrade.id), str(upgrade.title), upgrade.icon))
	_refresh()


func _card(upgrade_id: String, title: String, icon: Texture2D) -> PanelContainer:
	var card := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.custom_minimum_size = Vector2(88, 88)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(picture)
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = title
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", Color(0.918, 0.949, 0.973))
	box.add_child(name_label)
	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.86))
	box.add_child(level_label)
	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 24)
	cost_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4))
	box.add_child(cost_label)
	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.add_theme_font_size_override("font_size", 22)
	effect_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1))
	box.add_child(effect_label)
	var button := Button.new()
	button.name = "BuyButton"
	button.text = "Buy"
	button.custom_minimum_size = Vector2(0, 64)
	button.add_theme_font_size_override("font_size", 26)
	button.pressed.connect(_buy.bind(upgrade_id))
	box.add_child(button)
	card.set_meta("upgrade_id", upgrade_id)
	return card


func _refresh() -> void:
	$CoinsLabel.text = "Coins: %d" % CoinManagerScript.balance()
	for card in $Scroll/List.get_children():
		var upgrade_id := str(card.get_meta("upgrade_id"))
		var box := card.get_child(0)
		box.get_node("LevelLabel").text = "Level: %d" % RobotStatsScript.level(upgrade_id)
		box.get_node("CostLabel").text = "Cost: %d coins" % RobotStatsScript.cost(upgrade_id)
		box.get_node("EffectLabel").text = RobotStatsScript.effect_text(upgrade_id)
		box.get_node("BuyButton").disabled = CoinManagerScript.balance() < RobotStatsScript.cost(upgrade_id)


func _buy(upgrade_id: String) -> void:
	if RobotStatsScript.buy(upgrade_id):
		_refresh()


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
