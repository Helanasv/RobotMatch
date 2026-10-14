extends Control

const GRID_SIZE := 8
const GAP := 6.0
const FRAME_PADDING := 8.0
const BLOCK_TEXTURE: Texture2D = preload("res://assets/tiles/block.svg")
const VIRUS_TEXTURE: Texture2D = preload("res://assets/tiles/virus.svg")

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
var _layout_dirty := false
var _cells: Array = []
var _markers := {}


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
			if _blocks_fall(row, column):
				grid.append(null)
				continue
			var tile := Tile.new()
			tile.setup(_next_type(), row, column)
			add_child(tile)
			grid.append(tile)
	_layout_tiles()


func place_blocks(positions: Array) -> void:
	_clear_markers()
	_cells.clear()
	for _i in GRID_SIZE * GRID_SIZE:
		_cells.append("")
	for pos in positions:
		var row := int(pos[0])
		var column := int(pos[1])
		_cells[row * GRID_SIZE + column] = "metal"
		_markers["%d,%d" % [row, column]] = _picture(BLOCK_TEXTURE, 0)


func damage_blocks(tiles: Array, special: bool) -> int:
	if _cells.size() != GRID_SIZE * GRID_SIZE:
		return 0
	var hit := {}
	for tile in tiles:
		for row_step in [-1, 0, 1]:
			for column_step in [-1, 0, 1]:
				if row_step == 0 and column_step == 0:
					continue
				if not special and absi(row_step) + absi(column_step) != 1:
					continue
				var row: int = tile.row + row_step
				var column: int = tile.column + column_step
				if row < 0 or column < 0 or row >= GRID_SIZE or column >= GRID_SIZE:
					continue
				if str(_cells[row * GRID_SIZE + column]) != "metal":
					continue
				hit["%d,%d" % [row, column]] = Vector2i(row, column)
	for key in hit:
		var cell: Vector2i = hit[key]
		_cells[cell.x * GRID_SIZE + cell.y] = ""
		var marker = _markers.get(key)
		if is_instance_valid(marker):
			marker.queue_free()
		_markers.erase(key)
	return hit.size()


func block_count() -> int:
	var count := 0
	for kind in _cells:
		if str(kind) == "metal":
			count += 1
	return count


func place_infected(positions: Array) -> void:
	_ensure_cells()
	for pos in positions:
		_infect(int(pos[0]), int(pos[1]))
	_place_markers()


func clear_infected_near(tiles: Array) -> int:
	if _cells.size() != GRID_SIZE * GRID_SIZE:
		return 0
	var hit := {}
	for tile in tiles:
		_mark_infected(hit, tile.row, tile.column)
		_mark_infected(hit, tile.row - 1, tile.column)
		_mark_infected(hit, tile.row + 1, tile.column)
		_mark_infected(hit, tile.row, tile.column - 1)
		_mark_infected(hit, tile.row, tile.column + 1)
	for key in hit:
		var cell: Vector2i = hit[key]
		_cells[cell.x * GRID_SIZE + cell.y] = ""
		var marker = _markers.get(key)
		if is_instance_valid(marker):
			marker.queue_free()
		_markers.erase(key)
	return hit.size()


func spread_virus() -> bool:
	if _cells.size() != GRID_SIZE * GRID_SIZE:
		return false
	for row in GRID_SIZE:
		for column in GRID_SIZE:
			if str(_cells[row * GRID_SIZE + column]) != "infected":
				continue
			for step in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var next_row: int = row + int(step.y)
				var next_column: int = column + int(step.x)
				if next_row < 0 or next_column < 0 or next_row >= GRID_SIZE or next_column >= GRID_SIZE:
					continue
				if str(_cells[next_row * GRID_SIZE + next_column]) != "":
					continue
				_infect(next_row, next_column)
				_place_markers()
				return true
	return false


func infected_count() -> int:
	var count := 0
	for kind in _cells:
		if str(kind) == "infected":
			count += 1
	return count


func _picture(texture: Texture2D, layer: int) -> TextureRect:
	var marker := TextureRect.new()
	marker.texture = texture
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marker.z_index = layer
	add_child(marker)
	return marker


func _ensure_cells() -> void:
	if _cells.size() == GRID_SIZE * GRID_SIZE:
		return
	_cells.clear()
	for _i in GRID_SIZE * GRID_SIZE:
		_cells.append("")


func _infect(row: int, column: int) -> void:
	_cells[row * GRID_SIZE + column] = "infected"
	var key := "%d,%d" % [row, column]
	if _markers.has(key) and is_instance_valid(_markers[key]):
		return
	_markers[key] = _picture(VIRUS_TEXTURE, 2)


func _mark_infected(hit: Dictionary, row: int, column: int) -> void:
	if row < 0 or column < 0 or row >= GRID_SIZE or column >= GRID_SIZE:
		return
	if str(_cells[row * GRID_SIZE + column]) != "infected":
		return
	hit["%d,%d" % [row, column]] = Vector2i(row, column)


func _blocks_fall(row: int, column: int) -> bool:
	if _cells.size() != GRID_SIZE * GRID_SIZE:
		return false
	return str(_cells[row * GRID_SIZE + column]) == "metal"


func _clear_markers() -> void:
	for key in _markers:
		var marker = _markers[key]
		if is_instance_valid(marker):
			marker.free()
	_markers.clear()


func _place_markers() -> void:
	if _cell_size < 1.0:
		return
	var tile_size := Vector2(_cell_size, _cell_size)
	for key in _markers:
		var marker = _markers[key]
		if not is_instance_valid(marker):
			continue
		var parts: PackedStringArray = key.split(",")
		marker.position = cell_origin(int(parts[0]), int(parts[1]))
		marker.size = tile_size


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
	var geometry_changed := absf(_cell_size - cell_size) > 0.5 or _origin.distance_to(origin) > 0.5
	_origin = origin
	_cell_size = cell_size
	_place_markers()
	var first_layout := not _has_layout
	var animating := state == State.SWAPPING or state == State.CLEARING or state == State.FALLING or state == State.REFILLING
	_has_layout = true
	if animating:
		if geometry_changed:
			_layout_dirty = true
		return
	if not first_layout and not geometry_changed and _busy:
		return

	var tile_size := Vector2(_cell_size, _cell_size)
	for row in GRID_SIZE:
		for column in GRID_SIZE:
			var tile: Tile = get_tile(row, column)
			if tile == null:
				continue
			var target := cell_origin(row, column)
			if first_layout:
				tile.position = target + Vector2(0, -_cell_size * 0.45)
				tile.size = tile_size
			tile.move_to(target, tile_size, 0.22 if first_layout else 0.12)


func has_layout() -> bool:
	return _has_layout


func set_state(next: State) -> void:
	state = next
	_busy = state != State.READY
	if state == State.READY and _layout_dirty:
		_layout_dirty = false
		snap_tiles()


func snap_tiles() -> void:
	if _cell_size < 1.0:
		return
	var tile_size := Vector2(_cell_size, _cell_size)
	for row in GRID_SIZE:
		for column in GRID_SIZE:
			var tile: Tile = get_tile(row, column)
			if tile == null:
				continue
			tile.halt()
			tile.position = cell_origin(row, column)
			tile.size = tile_size
	_place_markers()


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
			if _blocks_fall(row, column):
				write = row - 1
				continue
			var tile: Tile = get_tile(row, column)
			if tile == null:
				continue
			if write != row:
				grid[row * GRID_SIZE + column] = null
				grid[write * GRID_SIZE + column] = tile
				tile.set_grid_position(write, column)
				tweens.append(tile.move_to(cell_origin(write, column), Vector2(_cell_size, _cell_size), 0.22))
			write -= 1
	for tween in tweens:
		await _wait(tween)


func refill() -> void:
	var tweens: Array = []
	var tile_size := Vector2(_cell_size, _cell_size)
	for column in GRID_SIZE:
		var holes: Array[int] = []
		for row in GRID_SIZE:
			if get_tile(row, column) == null and not _blocks_fall(row, column):
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
