extends Node

const SWIPE_FRACTION := 0.35
const DIAGONAL_RATIO := 0.7

var _board: Control
var _pressed: Tile
var _selected_at_press: Tile
var _press_position := Vector2.ZERO
var _tracking := false
var _gesture_is_touch := false


func setup(board: Control) -> void:
	_board = board


func direction_for(delta: Vector2, cell_size: float) -> Vector2i:
	var threshold := maxf(cell_size * SWIPE_FRACTION, 12.0)
	var ax := absf(delta.x)
	var ay := absf(delta.y)
	if maxf(ax, ay) < threshold:
		return Vector2i.ZERO
	var step_x := 1 if delta.x > 0.0 else -1
	var step_y := 1 if delta.y > 0.0 else -1
	var clearly_diagonal := minf(ax, ay) >= threshold * 0.45 and minf(ax, ay) / maxf(ax, ay) >= DIAGONAL_RATIO
	if clearly_diagonal:
		return Vector2i(step_x, step_y)
	if ax > ay:
		return Vector2i(step_x, 0)
	return Vector2i(0, step_y)


func _input(event: InputEvent) -> void:
	if _board == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_gesture_is_touch = true
			_press(event.position)
		else:
			_release(event.position)
			_gesture_is_touch = false
		return
	if _gesture_is_touch:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(event.position)
		else:
			_release(event.position)


func _press(point: Vector2) -> void:
	if not _board.can_swap():
		return
	var tile: Tile = _tile_at(point)
	_pressed = tile
	_selected_at_press = _board.get_selected()
	_press_position = point
	_tracking = tile != null
	if tile != null and _selected_at_press == null:
		_board.select_tile(tile)


func _release(point: Vector2) -> void:
	var tile := _pressed
	var start := _press_position
	var selected := _selected_at_press
	_pressed = null
	_selected_at_press = null
	_tracking = false
	if tile == null or not _board.can_swap():
		return
	var delta := point - start
	var direction := direction_for(delta, _board.cell_size())
	if direction == Vector2i.ZERO:
		_handle_tap(tile, selected)
	else:
		_handle_swipe(tile, direction)


func _handle_tap(tile: Tile, selected: Tile) -> void:
	if selected == null or selected == tile:
		_board.select_tile(tile)
		return
	if _board.is_orthogonal_neighbor(selected, tile):
		_board.clear_selection()
		_board.swap_tiles(selected, tile, true)
		return
	_board.swap_tiles(selected, tile, false)
	_board.select_tile(tile)


func _handle_swipe(tile: Tile, direction: Vector2i) -> void:
	_board.select_tile(tile)
	if direction.x != 0 and direction.y != 0:
		_board.reject_move(tile, direction)
		return
	var neighbor: Tile = _board.tile_at(tile.row + direction.y, tile.column + direction.x)
	if neighbor == null:
		_board.reject_move(tile, direction)
		return
	_board.clear_selection()
	_board.swap_tiles(tile, neighbor, true)


func _tile_at(point: Vector2) -> Tile:
	for tile in _board.grid:
		if tile.get_global_rect().has_point(point):
			return tile
	return null
