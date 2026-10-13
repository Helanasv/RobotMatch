extends Control

const GRID_SIZE := 8
const GAP := 6.0
const FRAME_PADDING := 8.0

var grid: Array[Tile] = []
var _selected: Tile
var _has_layout := false


func _ready() -> void:
	clip_contents = true
	_build_board()
	resized.connect(_layout_tiles)
	_layout_tiles()


func get_tile(row: int, column: int) -> Tile:
	return grid[row * GRID_SIZE + column]


func _build_board() -> void:
	var frame := ColorRect.new()
	frame.name = "Frame"
	frame.color = Color(0.14, 0.18, 0.24)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	grid.clear()
	for row in GRID_SIZE:
		for column in GRID_SIZE:
			var tile := Tile.new()
			var type := randi_range(0, Tile.Type.size() - 1) as Tile.Type
			tile.setup(type, row, column)
			tile.gui_input.connect(_on_tile_input.bind(tile))
			add_child(tile)
			grid.append(tile)


func _layout_tiles() -> void:
	if grid.is_empty() or size.x < 1.0 or size.y < 1.0:
		return

	var available := minf(size.x, size.y)
	var cell_size := floorf((available - FRAME_PADDING * 2.0 - GAP * float(GRID_SIZE - 1)) / float(GRID_SIZE))
	cell_size = maxf(cell_size, 1.0)
	var board_side := cell_size * float(GRID_SIZE) + GAP * float(GRID_SIZE - 1)
	var framed_side := board_side + FRAME_PADDING * 2.0
	var frame_origin := (size - Vector2(framed_side, framed_side)) * 0.5
	var origin := frame_origin + Vector2(FRAME_PADDING, FRAME_PADDING)

	var frame := get_node("Frame") as ColorRect
	frame.position = frame_origin
	frame.size = Vector2(framed_side, framed_side)

	for row in GRID_SIZE:
		for column in GRID_SIZE:
			var tile := get_tile(row, column)
			var target := origin + Vector2(column, row) * (cell_size + GAP)
			var target_size := Vector2(cell_size, cell_size)
			if not _has_layout:
				tile.position = target + Vector2(0, -cell_size * 0.45)
				tile.size = target_size
			tile.move_to(target, target_size, 0.22 if not _has_layout else 0.16)
	_has_layout = true


func _on_tile_input(event: InputEvent, tile: Tile) -> void:
	if not _is_press(event):
		return
	_select_tile(tile)
	accept_event()


func _is_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return event.pressed
	return false


func _select_tile(tile: Tile) -> void:
	if _selected != null and is_instance_valid(_selected):
		_selected.set_selected(false)
	_selected = tile
	tile.set_selected(true)
