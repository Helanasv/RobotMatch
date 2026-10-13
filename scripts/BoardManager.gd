extends Control

const GRID_SIZE := 8
const GAP := 6.0
const FRAME_PADDING := 8.0

signal swap_committed

enum State { READY, SWAPPING, CHECKING, CLEARING, FALLING, REFILLING, WIN, LOSE }

var grid: Array = []
var state := State.READY
var resolved_waves := 0
var _selected: Tile
var _has_layout := false
var _busy := false
var _origin := Vector2.ZERO
var _cell_size := 1.0
var _upcoming: Array[Tile.Type] = []
var _allowed: Array = []


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


func use_types(types: Array) -> void:
	_allowed = types.duplicate()
	var old_tiles: Array = []
	for child in get_children():
		if child is Tile:
			old_tiles.append(child)
	for tile in old_tiles:
		tile.free()
	grid.clear()
	_upcoming.clear()
	_has_layout = false
	for row in GRID_SIZE:
		for column in GRID_SIZE:
			var tile := Tile.new()
			tile.setup(_next_type(), row, column)
			add_child(tile)
			grid.append(tile)
	_layout_tiles()


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
	_origin = origin
	_cell_size = cell_size
	var first_layout := not _has_layout
	var place_tiles := not _busy or first_layout
	_has_layout = true
	if not place_tiles:
		return

	for row in GRID_SIZE:
		for column in GRID_SIZE:
			var tile: Tile = get_tile(row, column)
			if tile == null:
				continue
			var target := cell_origin(row, column)
			var target_size := Vector2(_cell_size, _cell_size)
			if first_layout:
				tile.position = target + Vector2(0, -_cell_size * 0.45)
				tile.size = target_size
			tile.move_to(target, target_size, 0.22 if first_layout else 0.16)


func has_layout() -> bool:
	return _has_layout


func set_state(next: State) -> void:
	state = next
	_busy = state != State.READY


func can_swap() -> bool:
	return _has_layout and state == State.READY


func get_selected() -> Tile:
	return _selected


func select_tile(tile: Tile) -> void:
	if _selected != null and is_instance_valid(_selected) and _selected != tile:
		_selected.set_selected(false)
	_selected = tile
	tile.set_selected(true)


func clear_selection() -> void:
	if _selected != null and is_instance_valid(_selected):
		_selected.set_selected(false)
	_selected = null


func is_orthogonal_neighbor(a: Tile, b: Tile) -> bool:
	return absi(a.row - b.row) + absi(a.column - b.column) == 1


func tile_at(row: int, column: int) -> Tile:
	if row < 0 or column < 0 or row >= GRID_SIZE or column >= GRID_SIZE:
		return null
	return get_tile(row, column)


func cell_size() -> float:
	return maxf(_cell_size, 1.0)


func cell_origin(row: int, column: int) -> Vector2:
	return _origin + Vector2(column, row) * (_cell_size + GAP)


func queue_types(types: Array) -> void:
	for type in types:
		_upcoming.append(type)


func detach_tile(tile: Tile) -> void:
	if tile == null:
		return
	var index := tile.row * GRID_SIZE + tile.column
	if index >= 0 and index < grid.size() and grid[index] == tile:
		grid[index] = null


func swap_tiles(a: Tile, b: Tile, commit: bool) -> void:
	if a == null or b == null or a == b:
		return
	set_state(State.SWAPPING)
	var pos_a := a.position
	var size_a := a.size
	var pos_b := b.position
	var size_b := b.size
	if commit:
		_exchange(a, b)
	var tween_a := a.move_to(pos_b, size_b, 0.18)
	var tween_b := b.move_to(pos_a, size_a, 0.18)
	await _wait(tween_a)
	await _wait(tween_b)
	if not commit:
		tween_a = a.move_to(pos_a, size_a, 0.16)
		tween_b = b.move_to(pos_b, size_b, 0.16)
		await _wait(tween_a)
		await _wait(tween_b)
		set_state(State.READY)
		return
	swap_committed.emit()


func release_swap() -> void:
	set_state(State.READY)


func reject_move(tile: Tile, direction: Vector2i) -> void:
	if tile == null:
		return
	set_state(State.SWAPPING)
	var origin := tile.position
	var tile_size := tile.size
	var step := Vector2(direction) * tile_size.x * 0.28
	await _wait(tile.move_to(origin + step, tile_size, 0.1))
	await _wait(tile.move_to(origin, tile_size, 0.14))
	set_state(State.READY)


func collapse() -> void:
	var tweens: Array = []
	for column in GRID_SIZE:
		var write := GRID_SIZE - 1
		for row in range(GRID_SIZE - 1, -1, -1):
			var tile: Tile = get_tile(row, column)
			if tile == null:
				continue
			if write != row:
				grid[row * GRID_SIZE + column] = null
				grid[write * GRID_SIZE + column] = tile
				tile.set_grid_position(write, column)
				tweens.append(tile.move_to(cell_origin(write, column), tile.size, 0.22))
			write -= 1
	for tween in tweens:
		await _wait(tween)


func refill() -> void:
	var tweens: Array = []
	var tile_size := Vector2(_cell_size, _cell_size)
	for column in GRID_SIZE:
		var holes: Array[int] = []
		for row in GRID_SIZE:
			if get_tile(row, column) == null:
				holes.append(row)
		for i in holes.size():
			var row: int = holes[i]
			var tile := Tile.new()
			tile.setup(_next_type(), row, column)
			add_child(tile)
			var from_above := holes.size() - i
			tile.position = cell_origin(-from_above, column)
			tile.size = tile_size
			grid[row * GRID_SIZE + column] = tile
			tweens.append(tile.move_to(cell_origin(row, column), tile_size, 0.24))
	for tween in tweens:
		await _wait(tween)


func _next_type() -> Tile.Type:
	if not _upcoming.is_empty():
		return _upcoming.pop_front()
	if _allowed.is_empty():
		return randi_range(0, Tile.Type.size() - 1) as Tile.Type
	return _allowed[randi_range(0, _allowed.size() - 1)]


func _exchange(a: Tile, b: Tile) -> void:
	var a_index := a.row * GRID_SIZE + a.column
	var b_index := b.row * GRID_SIZE + b.column
	grid[a_index] = b
	grid[b_index] = a
	var row := a.row
	var column := a.column
	a.set_grid_position(b.row, b.column)
	b.set_grid_position(row, column)


func _wait(tween: Tween) -> void:
	if tween == null or not tween.is_valid() or not tween.is_running():
		return
	await tween.finished
