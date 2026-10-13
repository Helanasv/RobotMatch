extends Control

const InputManagerScript := preload("res://scripts/InputManager.gd")
const MatchManagerScript := preload("res://scripts/MatchManager.gd")
const BoardManagerScript := preload("res://scripts/BoardManager.gd")
const ScoreManagerScript := preload("res://scripts/ScoreManager.gd")
const SaveDataScript := preload("res://scripts/SaveData.gd")
const TileScript := preload("res://scripts/Tile.gd")

var _board: Control
var _matches: RefCounted
var _score: RefCounted


func _ready() -> void:
	$Layout/VBox/TopBar/BackButton.pressed.connect(_go_back)
	$WinScreen/Card/Panel/BackButton.pressed.connect(_go_back)
	$LoseScreen/Card/Panel/BackButton.pressed.connect(_go_back)
	_board = $Layout/VBox/BoardHost/Board
	_board.use_types([
		TileScript.Type.BATTERY,
		TileScript.Type.GEAR,
		TileScript.Type.MICROCHIP,
	])
	_matches = MatchManagerScript.new()
	_score = ScoreManagerScript.new()
	_score.changed.connect(_refresh_hud)
	_refresh_hud()
	_board.swap_committed.connect(_on_swap_committed)
	_board.set_state(BoardManagerScript.State.CHECKING)
	var input := InputManagerScript.new()
	input.name = "InputManager"
	add_child(input)
	input.setup(_board)
	_stabilize.call_deferred()


func _on_swap_committed() -> void:
	if _board.state == BoardManagerScript.State.WIN or _board.state == BoardManagerScript.State.LOSE:
		return
	_resolve_matches(true)


func _stabilize() -> void:
	for _i in 20:
		if _board.has_layout():
			break
		await get_tree().process_frame
	await _resolve_matches(false)


func _resolve_matches(award_score: bool) -> void:
	var counted := false
	var waves := 0
	while waves < 30:
		_board.set_state(BoardManagerScript.State.CHECKING)
		var found: Array = _matches.find_matches(_board)
		if found.is_empty():
			_finish_turn(award_score)
			return
		waves += 1
		_board.resolved_waves += 1
		if award_score:
			if not counted:
				_score.spend_move()
				counted = true
			else:
				_score.increase_combo()
			_score.add_match_lengths(_matches.match_lengths(_board))
			_score.add_batteries(_count_batteries(found))
		await _clear_matches(found)
		_board.set_state(BoardManagerScript.State.FALLING)
		await _board.collapse()
		_board.set_state(BoardManagerScript.State.REFILLING)
		await _board.refill()
	_finish_turn(award_score)


func _finish_turn(from_player: bool) -> void:
	if from_player and _score.goal_reached():
		_show_win()
		return
	if from_player and _score.moves <= 0:
		_show_lose()
		return
	_board.set_state(BoardManagerScript.State.READY)


func _count_batteries(tiles: Array) -> int:
	var count := 0
	for tile in tiles:
		if tile.tile_type == TileScript.Type.BATTERY:
			count += 1
	return count


func _clear_matches(tiles: Array) -> void:
	_board.set_state(BoardManagerScript.State.CLEARING)
	for tile in tiles:
		tile.set_matched(true)
	await get_tree().create_timer(0.12).timeout
	var tweens: Array = []
	for tile in tiles:
		_board.detach_tile(tile)
		tweens.append(tile.disappear())
	for tween in tweens:
		await _await_tween(tween)
	for tile in tiles:
		if is_instance_valid(tile):
			tile.queue_free()


func _await_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid() and tween.is_running():
		await tween.finished


func _show_win() -> void:
	_board.set_state(BoardManagerScript.State.WIN)
	var earned: int = _score.coins_earned()
	SaveDataScript.add_coins(earned)
	$LoseScreen.visible = false
	$WinScreen/Card/Panel/ScoreLabel.text = "Score: %d" % _score.score
	$WinScreen/Card/Panel/MovesLabel.text = "Moves left: %d" % _score.moves
	$WinScreen/Card/Panel/StarsLabel.text = "Stars: %d" % _score.stars()
	$WinScreen/Card/Panel/CoinsLabel.text = "Coins: %d" % earned
	$WinScreen.visible = true


func _show_lose() -> void:
	_board.set_state(BoardManagerScript.State.LOSE)
	$WinScreen.visible = false
	$LoseScreen/Card/Panel/Body.text = "Batteries: %d/%d\nScore: %d" % [
		_score.batteries,
		ScoreManagerScript.BATTERY_GOAL,
		_score.score,
	]
	$LoseScreen.visible = true


func _refresh_hud() -> void:
	$Layout/VBox/GoalLabel.text = _score.goal_text()
	$Layout/VBox/Status/ScoreLabel.text = "Score: %d" % _score.score
	$Layout/VBox/Status/ComboLabel.text = _score.combo_text()
	$Layout/VBox/Status/MovesLabel.text = _score.moves_text()


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
