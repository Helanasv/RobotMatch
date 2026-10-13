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


func _collect_lines(board: Control, horizontal: bool, found: Dictionary, lengths) -> void:
	for major in board.GRID_SIZE:
		var run: Array = []
		var run_type := -1
		for minor in board.GRID_SIZE:
			var row: int = major if horizontal else minor
			var column: int = minor if horizontal else major
			var tile: Tile = board.get_tile(row, column)
			if tile == null:
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
