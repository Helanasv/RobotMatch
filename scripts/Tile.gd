class_name Tile
extends Panel

enum Type {
	BATTERY,
	GEAR,
	MICROCHIP,
	BOLT,
	ENERGY_CRYSTAL,
}

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/tiles/battery.svg"),
	preload("res://assets/tiles/gear.svg"),
	preload("res://assets/tiles/microchip.svg"),
	preload("res://assets/tiles/bolt.svg"),
	preload("res://assets/tiles/crystal.svg"),
]

var tile_type: Type = Type.BATTERY
var row := 0
var column := 0

var _style: StyleBoxFlat
var _icon: TextureRect
var _tween: Tween
var _is_selected := false
var _is_matched := false
var _base_border := Color(0.08, 0.1, 0.14)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0, 0, 0, 0)
	_style.set_border_width_all(3)
	_style.set_corner_radius_all(8)
	_style.border_color = _base_border
	add_theme_stylebox_override("panel", _style)

	_icon = TextureRect.new()
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 2
	_icon.offset_top = 2
	_icon.offset_right = -2
	_icon.offset_bottom = -2
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	_apply_look()


func setup(type: Type, grid_row: int, grid_column: int) -> void:
	tile_type = type
	row = grid_row
	column = grid_column
	if is_node_ready():
		_apply_look()


func set_grid_position(grid_row: int, grid_column: int) -> void:
	row = grid_row
	column = grid_column


func set_selected(is_selected: bool) -> void:
	_is_selected = is_selected
	_update_chrome()


func set_matched(is_matched: bool) -> void:
	_is_matched = is_matched
	_update_chrome()


func _update_chrome() -> void:
	if _style == null:
		return
	if _is_matched:
		_style.border_color = Color(1, 0.95, 0.55)
		_style.set_border_width_all(6)
		modulate = Color(1.3, 1.3, 1.3)
		return
	modulate = Color.WHITE
	_style.border_color = Color.WHITE if _is_selected else _base_border
	_style.set_border_width_all(5 if _is_selected else 3)


func halt() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	z_index = 0


func disappear() -> Tween:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := position + size * 0.5
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, 0.18)
	_tween.tween_property(self, "size", Vector2.ZERO, 0.18)
	_tween.tween_property(self, "position", center, 0.18)
	return _tween


func move_to(target_position: Vector2, target_size: Vector2, duration: float = 0.2) -> Tween:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	z_index = 1
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", target_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "size", target_size, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.finished.connect(func() -> void:
		z_index = 0
	)
	return _tween


func _apply_look() -> void:
	if _icon == null:
		return
	_icon.texture = TEXTURES[tile_type]
