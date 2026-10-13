class_name Tile
extends Panel

enum Type {
	BATTERY,
	GEAR,
	MICROCHIP,
	BOLT,
	ENERGY_CRYSTAL,
}

const COLORS: Array[Color] = [
	Color(0.96, 0.8, 0.18),
	Color(0.9, 0.48, 0.14),
	Color(0.24, 0.5, 0.92),
	Color(0.28, 0.74, 0.38),
	Color(0.62, 0.36, 0.9),
]

const NAMES: Array[String] = [
	"Battery",
	"Gear",
	"Microchip",
	"Bolt",
	"Energy Crystal",
]

var tile_type: Type = Type.BATTERY
var row := 0
var column := 0

var _style: StyleBoxFlat
var _label: Label
var _tween: Tween
var _base_border := Color(0.08, 0.1, 0.14)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style = StyleBoxFlat.new()
	_style.set_border_width_all(3)
	_style.set_corner_radius_all(6)
	_style.border_color = _base_border
	add_theme_stylebox_override("panel", _style)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 4
	_label.offset_top = 4
	_label.offset_right = -4
	_label.offset_bottom = -4
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 14)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
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
	if _style == null:
		return
	_style.border_color = Color.WHITE if is_selected else _base_border
	_style.set_border_width_all(5 if is_selected else 3)


func move_to(target_position: Vector2, target_size: Vector2, duration: float = 0.2) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", target_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "size", target_size, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _apply_look() -> void:
	_style.bg_color = COLORS[tile_type]
	_label.text = NAMES[tile_type]
	var dark_text := tile_type == Type.BATTERY or tile_type == Type.GEAR
	_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12) if dark_text else Color.WHITE)
