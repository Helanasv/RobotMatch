extends Control

const InputManagerScript := preload("res://scripts/InputManager.gd")
const MatchManagerScript := preload("res://scripts/MatchManager.gd")
const BoardManagerScript := preload("res://scripts/BoardManager.gd")
const ScoreManagerScript := preload("res://scripts/ScoreManager.gd")
const GoalManagerScript := preload("res://scripts/GoalManager.gd")
const RewardManagerScript := preload("res://scripts/RewardManager.gd")
const CoinManagerScript := preload("res://scripts/CoinManager.gd")
const SaveManagerScript := preload("res://scripts/SaveManager.gd")
const LevelsScript := preload("res://data/levels.gd")
const TileScript := preload("res://scripts/Tile.gd")

var _board: Control
var _matches: RefCounted
var _score: RefCounted
var _goals: RefCounted
var _level_id := "first_battery"
var _charge_rates: Dictionary = {}
var _virus_max := 0


func _ready() -> void:
	$Layout/VBox/TopBar/BackButton.pressed.connect(_go_back)
	$WinScreen/Card/Panel/BackButton.pressed.connect(_go_back)
	$LoseScreen/Card/Panel/BackButton.pressed.connect(_go_back)
	var level: Dictionary = LevelsScript.current()
	_level_id = str(level.id)
	_charge_rates = level.charge
	$Layout/VBox/TopBar/Title.text = str(level.name)
	_board = $Layout/VBox/BoardHost/Board
	var blocks = level.get("blocks", [])
	if blocks is Array and not blocks.is_empty():
		_board.place_blocks(blocks)
	_board.use_types(_types_for(level.tiles))
	var infected = level.get("infected", [])
	if infected is Array and not infected.is_empty():
		_board.place_infected(infected)
	_virus_max = int(level.get("virus_max", 0))
	_matches = MatchManagerScript.new()
	_score = ScoreManagerScript.new()
	_score.configure(int(level.moves))
	_goals = GoalManagerScript.new()
	for goal in level.goals:
		_goals.add_goal(str(goal.type), int(goal.amount), str(goal.get("tile_type", "")))
	_score.changed.connect(_refresh_hud)
	_goals.changed.connect(_refresh_hud)
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
	var last_size := Vector2.INF
	var stable := 0
	for _i in 40:
		var board_size: Vector2 = _board.size
		if _board.has_layout() and board_size == last_size and board_size.x > 1.0:
			stable += 1
			if stable >= 2:
				break
		else:
			stable = 0
		last_size = board_size
		await get_tree().process_frame
	_board.snap_tiles()
	await _resolve_matches(false)


func _resolve_matches(award_score: bool) -> void:
	_board.snap_tiles()
	var counted := false
	var cleared_infection := 0
	var waves := 0
	while waves < 30:
		_board.set_state(BoardManagerScript.State.CHECKING)
		var found: Array = _matches.find_matches(_board)
		if found.is_empty():
			_finish_turn(award_score, cleared_infection)
			return
		waves += 1
		_board.resolved_waves += 1
		if award_score:
			if not counted:
				_score.spend_move()
				counted = true
			else:
				_score.increase_combo()
			var lengths: Array = _matches.match_lengths(_board)
			var special := false
			for length in lengths:
				if int(length) >= 4:
					special = true
			var gained: int = _score.add_match_lengths(lengths)
			_goals.record_match(found, gained, _charge_rates)
			var broken: int = _board.damage_blocks(found, special)
			if broken > 0:
				_goals.add_progress(GoalManagerScript.DESTROY_BLOCKS, broken)
			var cleaned: int = _board.clear_infected_near(found)
			cleared_infection += cleaned
			if cleaned > 0:
				_goals.add_progress(GoalManagerScript.CLEAR_INFECTED, cleaned)
		await _clear_matches(found)
		_board.set_state(BoardManagerScript.State.FALLING)
		await _board.collapse()
		_board.set_state(BoardManagerScript.State.REFILLING)
		await _board.refill()
	_finish_turn(award_score, cleared_infection)


func _finish_turn(from_player: bool, cleared_infection: int) -> void:
	if from_player and _goals.all_complete():
		_show_win()
		return
	if from_player and _virus_max > 0 and cleared_infection == 0:
		_board.spread_virus()
		_refresh_hud()
	if from_player and _virus_max > 0 and _board.infected_count() >= _virus_max:
		_show_lose(true)
		return
	if from_player and _score.moves <= 0:
		_show_lose(false)
		return
	_board.set_state(BoardManagerScript.State.READY)


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
	var result: Dictionary = RewardManagerScript.make_result(_score.score, _score.moves)
	var earned: int = int(result.coins)
	CoinManagerScript.add(earned)
	RewardManagerScript.save_result(_level_id, result)
	var next_level := LevelsScript.next_id(_level_id)
	if next_level != "":
		SaveManagerScript.unlock_level(next_level)
	$LoseScreen.visible = false
	$WinScreen/Card/Panel/ScoreLabel.text = "Score: %d" % _score.score
	$WinScreen/Card/Panel/MovesLabel.text = "Moves left: %d" % _score.moves
	$WinScreen/Card/Panel/StarsLabel.text = "Stars: %d" % int(result.stars)
	$WinScreen/Card/Panel/CoinsLabel.text = "Coins: %d" % earned
	$WinScreen.visible = true


func _show_lose(outbreak: bool) -> void:
	_board.set_state(BoardManagerScript.State.LOSE)
	$WinScreen.visible = false
	$LoseScreen/Card/Panel/Title.text = "Virus Outbreak" if outbreak else "Out of Moves"
	$LoseScreen/Card/Panel/Body.text = "%s\nScore: %d" % [_goals.status_text(), _score.score]
	$LoseScreen.visible = true


func _refresh_hud() -> void:
	$Layout/VBox/GoalLabel.text = _goals.hud_text()
	var virus_label := $Layout/VBox/VirusLabel
	virus_label.visible = _virus_max > 0
	if _virus_max > 0:
		virus_label.text = "Virus: %d/%d" % [_board.infected_count(), _virus_max]
	$Layout/VBox/Status/ScoreLabel.text = "Score: %d" % _score.score
	$Layout/VBox/Status/ComboLabel.text = _score.combo_text()
	$Layout/VBox/Status/MovesLabel.text = _score.moves_text()


func _types_for(names: Array) -> Array:
	var types: Array = []
	for tile_name in names:
		match str(tile_name):
			"battery":
				types.append(TileScript.Type.BATTERY)
			"gear":
				types.append(TileScript.Type.GEAR)
			"microchip":
				types.append(TileScript.Type.MICROCHIP)
			"bolt":
				types.append(TileScript.Type.BOLT)
			"energy_crystal":
				types.append(TileScript.Type.ENERGY_CRYSTAL)
	return types


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
