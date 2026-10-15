class_name Robot
extends PanelContainer

signal changed

enum Mood { IDLE, HAPPY, HURT, CHARGE, REPAIR }

const TileScript := preload("res://scripts/Tile.gd")

const ROBOT_NAME := "Robot-01"
const GEAR_REPAIR := 10
const MISS_DAMAGE := 5
const VIRUS_DAMAGE := 4

var energy := 0
var energy_max := 100
var health := 100
var health_max := 100
var mood: Mood = Mood.IDLE

var _charge_step := 25
var _phrase := "Ready."
var _mood_time := 0.0
var _bob := 0.0
var _figure: Control
var _state_label: Label
var _phrase_label: Label
var _energy_bar: ProgressBar
var _health_bar: ProgressBar
var _energy_label: Label
var _health_label: Label


func setup(max_energy: int, max_health: int, charge_step: int) -> void:
	energy_max = maxi(max_energy, 1)
	health_max = maxi(max_health, 1)
	health = health_max
	energy = 0
	_charge_step = maxi(charge_step, 1)
	_show(Mood.IDLE, "Ready.", false)
	_refresh()


func react_to_match(tiles: Array, combo: int, long_match: bool) -> void:
	var batteries := 0
	var gears := 0
	for tile in tiles:
		if not is_instance_valid(tile):
			continue
		if tile.tile_type == TileScript.Type.BATTERY:
			batteries += 1
		elif tile.tile_type == TileScript.Type.GEAR:
			gears += 1
	if batteries > 0:
		energy = mini(energy_max, energy + batteries * _charge_step)
	if gears > 0:
		health = mini(health_max, health + gears * GEAR_REPAIR)
	if batteries > 0 and gears > 0:
		var face: Mood = Mood.CHARGE if batteries >= gears else Mood.REPAIR
		_show(face, "Charging and repairing!")
	elif batteries > 0:
		_show(Mood.CHARGE, "Charging!")
	elif gears > 0:
		_show(Mood.REPAIR, "Repairing!")
	elif combo > 1 or long_match:
		_show(Mood.HAPPY, "Great match!")
	else:
		_show(Mood.HAPPY, "Nice!")
	_refresh()
	changed.emit()


func miss() -> void:
	health = maxi(health - MISS_DAMAGE, 0)
	var line := "That was not a match."
	if health <= 0:
		line = "I need repair!"
	_show(Mood.HURT, line)
	_refresh()
	changed.emit()


func hurt(amount: int, line: String) -> void:
	health = maxi(health - amount, 0)
	if health <= 0:
		line = "I need repair!"
	_show(Mood.HURT, line)
	_refresh()
	changed.emit()


func celebrate() -> void:
	_show(Mood.HAPPY, "Mission complete!")
	_refresh()
	changed.emit()


func _ready() -> void:
	custom_minimum_size = Vector2(0, 148)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.12, 0.2, 0.24)
	panel.set_corner_radius_all(16)
	panel.content_margin_left = 12
	panel.content_margin_right = 12
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	add_theme_stylebox_override("panel", panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_figure = Figure.new()
	_figure.host = self
	_figure.custom_minimum_size = Vector2(112, 124)
	_figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_figure)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 2)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)

	var name_label := Label.new()
	name_label.text = ROBOT_NAME
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.98))
	text.add_child(name_label)

	_state_label = Label.new()
	_state_label.add_theme_font_size_override("font_size", 20)
	_state_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.95))
	text.add_child(_state_label)

	_phrase_label = Label.new()
	_phrase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_phrase_label.add_theme_font_size_override("font_size", 20)
	_phrase_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.86))
	text.add_child(_phrase_label)

	_energy_label = Label.new()
	_energy_label.add_theme_font_size_override("font_size", 18)
	_energy_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.35))
	text.add_child(_energy_label)
	_energy_bar = _bar(Color(0.95, 0.78, 0.22))
	text.add_child(_energy_bar)

	_health_label = Label.new()
	_health_label.add_theme_font_size_override("font_size", 18)
	_health_label.add_theme_color_override("font_color", Color(0.55, 0.9, 0.62))
	text.add_child(_health_label)
	_health_bar = _bar(Color(0.35, 0.78, 0.45))
	text.add_child(_health_bar)
	_refresh()


func _process(delta: float) -> void:
	_bob += delta
	if mood != Mood.IDLE and health > 0:
		_mood_time -= delta
		if _mood_time <= 0.0:
			_settle()
	if _figure != null:
		_figure.queue_redraw()


func paint_figure(canvas: CanvasItem) -> void:
	var center: Vector2 = canvas.get_rect().size * 0.5 + _shift()
	var body := Color(0.28, 0.66, 0.82)
	var head := Color(0.55, 0.84, 0.92)
	match mood:
		Mood.HAPPY:
			body = Color(0.38, 0.78, 0.48)
			head = Color(0.72, 0.92, 0.7)
		Mood.HURT:
			body = Color(0.82, 0.34, 0.32)
			head = Color(0.95, 0.62, 0.55)
		Mood.CHARGE:
			body = Color(0.9, 0.72, 0.22)
			head = Color(0.98, 0.9, 0.55)
		Mood.REPAIR:
			body = Color(0.32, 0.72, 0.58)
			head = Color(0.7, 0.92, 0.8)
	var ink := Color(0.06, 0.1, 0.14)
	canvas.draw_line(center + Vector2(0, -52), center + Vector2(0, -30), Color(0.85, 0.92, 0.96), 4.0)
	var tip := Color(1, 0.86, 0.28) if mood == Mood.CHARGE else Color(0.7, 0.9, 1)
	canvas.draw_circle(center + Vector2(0, -54), 6.0, tip)
	canvas.draw_rect(Rect2(center + Vector2(-26, 8), Vector2(52, 36)), body)
	canvas.draw_rect(Rect2(center + Vector2(-34, 16), Vector2(8, 18)), body)
	canvas.draw_rect(Rect2(center + Vector2(26, 16), Vector2(8, 18)), body)
	canvas.draw_circle(center + Vector2(0, -12), 22.0, head)
	if mood == Mood.HURT:
		_cross_eye(canvas, center + Vector2(-8, -14), ink)
		_cross_eye(canvas, center + Vector2(8, -14), ink)
		canvas.draw_arc(center + Vector2(0, -2), 8.0, PI + 0.4, TAU - 0.4, 8, ink, 2.5)
	else:
		canvas.draw_circle(center + Vector2(-8, -14), 3.2, ink)
		canvas.draw_circle(center + Vector2(8, -14), 3.2, ink)
		if mood == Mood.IDLE:
			canvas.draw_line(center + Vector2(-6, -4), center + Vector2(6, -4), ink, 2.5)
		else:
			canvas.draw_arc(center + Vector2(0, -6), 8.0, 0.35, PI - 0.35, 8, ink, 2.5)
	if mood == Mood.REPAIR:
		canvas.draw_line(center + Vector2(0, 16), center + Vector2(0, 34), Color(0.95, 1, 0.95), 4.0)
		canvas.draw_line(center + Vector2(-8, 25), center + Vector2(8, 25), Color(0.95, 1, 0.95), 4.0)


func _shift() -> Vector2:
	var shift := Vector2(0, sin(_bob * 2.4) * 3.0)
	if mood == Mood.HURT:
		shift.x = sin(_bob * 36.0) * 4.0
	elif mood == Mood.HAPPY:
		shift.y -= absf(sin(_bob * 8.0)) * 8.0
	return shift


func _cross_eye(canvas: CanvasItem, at: Vector2, ink: Color) -> void:
	canvas.draw_line(at + Vector2(-4, -4), at + Vector2(4, 4), ink, 2.5)
	canvas.draw_line(at + Vector2(-4, 4), at + Vector2(4, -4), ink, 2.5)


func _bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 16)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.1, 0.12)
	background.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", background)
	return bar


func _show(next: Mood, line: String, timed: bool = true) -> void:
	mood = next
	_phrase = line
	_mood_time = 1.4 if timed else 0.0


func _settle() -> void:
	if health <= 0:
		_show(Mood.HURT, "I need repair!", false)
		_refresh()
		return
	var line := "I need energy!" if energy * 4 < energy_max else "Ready."
	_show(Mood.IDLE, line, false)
	_refresh()


func _refresh() -> void:
	if _state_label == null:
		return
	_state_label.text = "State: %s" % _state_name()
	_phrase_label.text = _phrase
	_energy_label.text = "Energy: %d/%d" % [energy, energy_max]
	_health_label.text = "Health: %d/%d" % [health, health_max]
	_energy_bar.max_value = energy_max
	_energy_bar.value = energy
	_health_bar.max_value = health_max
	_health_bar.value = health


func _state_name() -> String:
	match mood:
		Mood.HAPPY:
			return "Happy"
		Mood.HURT:
			return "Hurt"
		Mood.CHARGE:
			return "Charging"
		Mood.REPAIR:
			return "Repairing"
		_:
			return "Waiting"


class Figure extends Control:
	var host: PanelContainer

	func _draw() -> void:
		if host != null and host.has_method("paint_figure"):
			host.paint_figure(self)
