extends RefCounted

const MIN_LENGTH := 3


func find_matches(board: Control) -> Array:
	var found := {}
	_collect_lines(board, true, found, null)
	_collect_lines(board, false, found, null)
	var matches: Array = []
	for tile in found:
		matches.append(tile)
	return matches


func match_lengths(board: Control) -> Array:
	var lengths: Array = []
	_collect_lines(board, true, {}, lengths)
	_collect_lines(board, false, {}, lengths)
	return lengths


func find_hint(board: Control) -> Array:
	for row in board.GRID_SIZE:
		for column in board.GRID_SIZE:
			var tile: Tile = board.get_tile(row, column)
			if tile == null or board.is_frozen(tile):
				continue
			for neighbor in [board.tile_at(row, column + 1), board.tile_at(row + 1, column)]:
				if neighbor == null or board.is_frozen(neighbor):
					continue
				board.exchange(tile, neighbor)
				var matched: Array = find_matches(board)
				board.exchange(tile, neighbor)
				if not matched.is_empty():
					return [tile, neighbor]
	return []


func _collect_lines(board: Control, horizontal: bool, found: Dictionary, lengths) -> void:
	for major in board.GRID_SIZE:
		var run: Array = []
		var run_type := -1
		for minor in board.GRID_SIZE:
			var row: int = major if horizontal else minor
			var column: int = minor if horizontal else major
			var tile: Tile = board.get_tile(row, column)
			if tile == null or board.is_frozen(tile):
				_keep_run(run, found, lengths)
				run = []
				run_type = -1
				continue
			if run.is_empty() or tile.tile_type == run_type:
				run.append(tile)
				run_type = tile.tile_type
			else:
				_keep_run(run, found, lengths)
				run = [tile]
				run_type = tile.tile_type
		_keep_run(run, found, lengths)


func _keep_run(run: Array, found: Dictionary, lengths) -> void:
	if run.size() < MIN_LENGTH:
		return
	if lengths != null:
		lengths.append(run.size())
	for tile in run:
		found[tile] = true
