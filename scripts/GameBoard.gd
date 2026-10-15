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
const BossManagerScript := preload("res://scripts/BossManager.gd")
const StarIconsScript := preload("res://scripts/StarIcons.gd")
const RobotStatsScript := preload("res://scripts/RobotStats.gd")

var _board: Control
var _matches: RefCounted
var _score: RefCounted
var _goals: RefCounted
var _level_id := "first_battery"
var _charge_rates: Dictionary = {}
var _virus_max := 0
var _time_limit := 0.0
var _time_left := 0.0
var _timer_running := false
var _blink_time := 0.0
var _reward_id := ""
var _reward_name := ""
var _bonus_coins := 0
var _world_complete := false
var _finale := false
var _boss: RefCounted
var _robot: Robot
var _hint_tiles: Array = []
var _used_shuffle := false
var _hold_timer := false
var _pause_cover: Control
var _settings_cover: Control
var _arrow_line: Line2D
var _arrow_head: Polygon2D


func _ready() -> void:
	$Layout/VBox/TopBar/BackButton.pressed.connect(_go_back)
	$Layout/VBox/Actions/HintButton.pressed.connect(_press_hint)
	$Layout/VBox/Actions/ShuffleButton.pressed.connect(_press_shuffle)
	$Layout/VBox/Actions/PauseButton.pressed.connect(_press_pause)
	$Layout/VBox/Actions/SettingsButton.pressed.connect(_press_settings)
	_build_covers()
	$WinScreen/Card/Panel/BackButton.pressed.connect(_go_back)
	$LoseScreen/Card/Panel/BackButton.pressed.connect(_go_back)
	var level: Dictionary = LevelsScript.current()
	_level_id = str(level.id)
	_charge_rates = level.charge
	$Layout/VBox/TopBar/Title.text = str(level.name)
	_board = $Layout/VBox/BoardHost/Board
	_arrow_line = Line2D.new()
	_arrow_line.width = 10
	_arrow_line.default_color = Color(0.35, 0.95, 1)
	_arrow_line.z_index = 8
	_arrow_line.visible = false
	_board.add_child(_arrow_line)
	_arrow_head = Polygon2D.new()
	_arrow_head.color = Color(0.35, 0.95, 1)
	_arrow_head.z_index = 8
	_arrow_head.visible = false
	_board.add_child(_arrow_head)
	_refresh_hint_button()
	var blocks = level.get("blocks", [])
	if blocks is Array and not blocks.is_empty():
		_board.place_blocks(blocks)
	var locks = level.get("locks", [])
	if locks is Array and not locks.is_empty():
		_board.place_locks(locks)
	var gate = level.get("gate", [])
	if gate is Array and gate.size() == 2:
		_board.place_gate(gate)
	_board.use_types(_types_for(level.tiles))
	var infected = level.get("infected", [])
	if infected is Array and not infected.is_empty():
		_board.place_infected(infected)
	var ice = level.get("ice", [])
	if ice is Array and not ice.is_empty():
		_board.place_ice(ice)
	var drone = level.get("drone", [])
	if drone is Array and drone.size() == 2:
		_board.place_drone(drone)
	_virus_max = int(level.get("virus_max", 0))
	_time_limit = float(level.get("time", 0))
	_time_left = _time_limit
	_reward_id = str(level.get("reward", ""))
	_reward_name = str(level.get("reward_name", ""))
	_bonus_coins = int(level.get("bonus_coins", 0))
	_world_complete = bool(level.get("world_complete", false))
	_finale = bool(level.get("finale", false))
	_robot = $Layout/VBox/RobotPanel
	_robot.setup(RobotStatsScript.energy_max(), RobotStatsScript.health(), RobotStatsScript.battery_charge())
	_robot.changed.connect(_refresh_boss)
	if bool(level.get("boss", false)):
		_boss = BossManagerScript.new()
		_boss.configure(RobotStatsScript.energy_max(), RobotStatsScript.battery_charge(), RobotStatsScript.strike_damage())
		_boss.changed.connect(_refresh_boss)
		_style_boss_bar()
		_refresh_boss()
	var goal_text := str(level.get("goal_text", ""))
	if goal_text != "":
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.94, 0.96, 0.98)
		card_style.set_corner_radius_all(18)
		card_style.content_margin_left = 28
		card_style.content_margin_right = 28
		card_style.content_margin_top = 24
		card_style.content_margin_bottom = 24
		$GoalScreen/Card.add_theme_stylebox_override("panel", card_style)
		$GoalScreen/Card/Panel/Body.text = goal_text
		$GoalScreen/Card/Panel/StartButton.pressed.connect(_close_goal)
		$GoalScreen.visible = true
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


func _process(delta: float) -> void:
	if not _timer_running:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	if _time_left < 10.0:
		_blink_time += delta
	_refresh_timer()
	if _time_left <= 0.0 and _board.state == BoardManagerScript.State.READY:
		_timer_running = false
		if not _goals.all_complete():
			_show_lose(false, true)


func _tools_ready() -> bool:
	return not $GoalScreen.visible and _pause_cover != null and not _pause_cover.visible and not _settings_cover.visible and _board.state == BoardManagerScript.State.READY


func _press_hint() -> void:
	if not _tools_ready():
		return
	var notice: Label = $Layout/VBox/NoticeLabel
	if SaveManagerScript.hints() <= 0 and not RobotStatsScript.scanner_on():
		notice.text = "No hints available"
		notice.visible = true
		return
	var pair: Array = _matches.find_hint(_board)
	if pair.size() < 2:
		notice.text = "No hints available"
		notice.visible = true
		return
	if not RobotStatsScript.scanner_on() and not SaveManagerScript.use_hint():
		notice.text = "No hints available"
		notice.visible = true
		return
	notice.visible = false
	_paint_hint(pair)
	_refresh_hint_button()


func _refresh_hint_button() -> void:
	var left := SaveManagerScript.hints()
	var button: Button = $Layout/VBox/Actions/HintButton
	if RobotStatsScript.scanner_on():
		button.text = "Hint"
	elif left > 0:
		button.text = "Hint %d" % left
	else:
		button.text = "Hint"
	button.disabled = false


func _press_shuffle() -> void:
	if not _tools_ready():
		return
	_used_shuffle = true
	_clear_hint()
	$Layout/VBox/NoticeLabel.visible = false
	_shuffle_types()
	_board.clear_selection()
	await _resolve_matches(false)


func _press_pause() -> void:
	if not _tools_ready():
		return
	_hold_play()
	_pause_cover.visible = true


func _resume_pause() -> void:
	_pause_cover.visible = false
	_release_play()


func _press_settings() -> void:
	if not _tools_ready():
		return
	_hold_play()
	_settings_cover.visible = true


func _close_settings() -> void:
	_settings_cover.visible = false
	_release_play()


func _hold_play() -> void:
	_board.input_locked = true
	_board.clear_selection()
	_hold_timer = _timer_running
	_timer_running = false


func _release_play() -> void:
	_board.input_locked = false
	if _hold_timer and _time_left > 0.0 and _board.state == BoardManagerScript.State.READY:
		_timer_running = true
	_hold_timer = false


func _build_covers() -> void:
	_pause_cover = _make_cover("Paused")
	var resume := Button.new()
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(220, 65)
	resume.add_theme_font_size_override("font_size", 26)
	resume.pressed.connect(_resume_pause)
	_pause_cover.get_node("Card").add_child(resume)
	_settings_cover = _make_cover("Settings")
	var card: VBoxContainer = _settings_cover.get_node("Card")
	var sound: Dictionary = SaveManagerScript.sound_settings()
	var music := CheckButton.new()
	music.text = "Music"
	music.button_pressed = bool(sound.music)
	music.add_theme_font_size_override("font_size", 26)
	music.toggled.connect(_toggle_music)
	card.add_child(music)
	var effects := CheckButton.new()
	effects.text = "Effects"
	effects.button_pressed = bool(sound.effects)
	effects.add_theme_font_size_override("font_size", 26)
	effects.toggled.connect(_toggle_effects)
	card.add_child(effects)
	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(220, 65)
	close.add_theme_font_size_override("font_size", 26)
	close.pressed.connect(_close_settings)
	card.add_child(close)


func _make_cover(title: String) -> Control:
	var cover := Control.new()
	cover.visible = false
	cover.z_index = 12
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cover)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.06, 0.1, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.add_child(dim)
	var card := VBoxContainer.new()
	card.name = "Card"
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_theme_constant_override("separation", 16)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -180
	card.offset_top = -160
	card.offset_right = 180
	card.offset_bottom = 160
	cover.add_child(card)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(0.95, 0.97, 0.98))
	card.add_child(label)
	return cover


func _toggle_music(enabled: bool) -> void:
	var sound: Dictionary = SaveManagerScript.sound_settings()
	SaveManagerScript.set_sound(enabled, bool(sound.effects))
	SoundManager.apply()


func _toggle_effects(enabled: bool) -> void:
	var sound: Dictionary = SaveManagerScript.sound_settings()
	SaveManagerScript.set_sound(bool(sound.music), enabled)
	if enabled:
		SoundManager.play_click()


func _close_goal() -> void:
	$GoalScreen.visible = false


func _on_swap_committed() -> void:
	if _board.state == BoardManagerScript.State.WIN or _board.state == BoardManagerScript.State.LOSE:
		return
	SoundManager.play_click()
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
	_clear_hint()
	var counted := false
	var cleared_infection := 0
	var waves := 0
	while waves < 30:
		_board.set_state(BoardManagerScript.State.CHECKING)
		var found: Array = _matches.find_matches(_board)
		if found.is_empty():
			if award_score and waves == 0:
				_robot.miss()
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
			_robot.react_to_match(found, _score.multiplier, special)
			_strike_boss(found)
			var broken: int = _board.damage_blocks(found, special)
			if broken > 0:
				_goals.add_progress(GoalManagerScript.DESTROY_BLOCKS, broken)
				_goals.add_progress(GoalManagerScript.CLEAR_PATH, broken)
			var cleaned: int = _board.clear_infected_near(found)
			cleared_infection += cleaned
			if cleaned > 0:
				_goals.add_progress(GoalManagerScript.CLEAR_INFECTED, cleaned)
				_goals.add_progress(GoalManagerScript.CLEAR_PATH, cleaned)
			var shattered: int = _board.damage_ice(found)
			if shattered > 0:
				_goals.add_progress(GoalManagerScript.DESTROY_ICE, shattered)
			var unlocked: int = _board.damage_locks(found)
			if unlocked > 0:
				_goals.add_progress(GoalManagerScript.CREATE_KEYS, unlocked)
			_try_open_gate()
		await _clear_matches(found)
		_board.set_state(BoardManagerScript.State.FALLING)
		await _board.collapse()
		_board.set_state(BoardManagerScript.State.REFILLING)
		await _board.refill()
	_finish_turn(award_score, cleared_infection)


func _strike_boss(found: Array) -> void:
	if _boss == null:
		return
	var phase_before: int = _boss.phase
	_boss.apply_tiles(found)
	while _boss.phase > phase_before and _boss.hp > 0:
		_board.spread_virus()
		phase_before += 1
	if _boss.defeated:
		_goals.add_progress(GoalManagerScript.DEFEAT_BOSS, 1)


func _try_open_gate() -> void:
	if _goals.is_complete(GoalManagerScript.CREATE_KEYS) or _goals.is_complete(GoalManagerScript.CHARGE_GENERATOR):
		if _board.open_gate():
			_goals.add_progress(GoalManagerScript.OPEN_DOOR, 1)


func _finish_turn(from_player: bool, cleared_infection: int) -> void:
	if from_player and _goals.all_complete():
		_robot.celebrate()
		_show_win()
		return
	if from_player and _virus_max > 0 and cleared_infection == 0:
		_board.spread_virus()
		_robot.hurt(_robot.VIRUS_DAMAGE, "The virus hurts!")
		_refresh_hud()
	if from_player and _virus_max > 0 and _board.infected_count() >= _virus_max:
		_show_lose(true)
		return
	if from_player and _time_limit > 0.0 and _time_left <= 0.0:
		_show_lose(false, true)
		return
	if from_player and _boss_hits_robot():
		_show_lose(false, false, true)
		return
	if from_player and _score.moves <= 0:
		_show_lose(false, false)
		return
	_board.set_state(BoardManagerScript.State.READY)
	if _time_limit > 0.0 and not _timer_running and _time_left > 0.0:
		_timer_running = true
	_ensure_move()


func _boss_hits_robot() -> bool:
	if _boss == null or _boss.defeated:
		return false
	var hit := 3 if _boss.shield else 1
	_robot.hurt(hit, "The boss hit me!")
	_refresh_boss()
	return _robot.health <= 0


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
	_timer_running = false
	_board.set_state(BoardManagerScript.State.WIN)
	var result: Dictionary = _win_result()
	var earned: int = _bonus_coins if _bonus_coins > 0 else int(result.coins)
	CoinManagerScript.add(earned)
	RewardManagerScript.save_result(_level_id, result)
	var next_level := LevelsScript.next_id(_level_id)
	if next_level != "":
		SaveManagerScript.unlock_level(next_level)
	$LoseScreen.visible = false
	$WinScreen/Card/Panel/Title.text = "Mission Complete!"
	if _finale:
		$WinScreen/Card/Panel/Title.text = "Factory Restored"
	elif _world_complete:
		$WinScreen/Card/Panel/Title.text = "World Complete"
	$WinScreen/Card/Panel/ScoreLabel.text = "Score: %d" % _score.score
	$WinScreen/Card/Panel/MovesLabel.text = "Moves left: %d" % _score.moves
	StarIconsScript.fill($WinScreen/Card/Panel/StarsRow, int(result.stars), 48)
	$WinScreen/Card/Panel/CoinsLabel.text = "Coins: %d" % earned
	var reward_label := $WinScreen/Card/Panel/RewardLabel
	if _finale:
		SaveManagerScript.set_upgrade("electric_city", 1)
		SaveManagerScript.set_upgrade("unique_skin", 1)
		reward_label.visible = true
		reward_label.text = "The robot stops. The lights come back on.\nElectric City is open.\nSkin: Factory Core"
	elif _world_complete:
		SaveManagerScript.set_upgrade("boss", 1)
		SaveManagerScript.set_upgrade("electric_city", 1)
		SaveManagerScript.set_upgrade("special_skin", 1)
		SaveManagerScript.set_upgrade("factory_hero", 1)
		reward_label.visible = true
		reward_label.text = "Boss unlocked\nWorld: Electric City\nSpecial skin\nAchievement: Factory Hero"
	else:
		reward_label.visible = _reward_name != ""
		if _reward_name != "":
			SaveManagerScript.set_upgrade(_reward_id, 1)
			reward_label.text = "Reward: %s" % _reward_name
	$WinScreen.visible = true


func _win_result() -> Dictionary:
	var result: Dictionary = RewardManagerScript.make_result(_score.score, _score.moves)
	if _used_shuffle and int(result.stars) > 2:
		result.stars = 2
		result.coins = RewardManagerScript.coins_for(2)
	return result


func _show_lose(outbreak: bool, timed_out: bool = false, robot_down: bool = false) -> void:
	_timer_running = false
	_board.set_state(BoardManagerScript.State.LOSE)
	$WinScreen.visible = false
	var title := "Out of Moves"
	if robot_down:
		title = "Robot Broken"
	elif timed_out:
		title = "Time's Up"
	elif outbreak:
		title = "Virus Outbreak"
	$LoseScreen/Card/Panel/Title.text = title
	$LoseScreen/Card/Panel/Body.text = "%s\nScore: %d" % [_goals.status_text(), _score.score]
	$LoseScreen.visible = true


func _refresh_hud() -> void:
	$Layout/VBox/GoalLabel.text = _goals.hud_text()
	var virus_label := $Layout/VBox/VirusLabel
	virus_label.visible = _virus_max > 0
	if _virus_max > 0:
		virus_label.text = "Virus: %d/%d" % [_board.infected_count(), _virus_max]
	$Layout/VBox/Status/CoinsLabel.text = "Coins: %d" % CoinManagerScript.balance()
	$Layout/VBox/Status/ScoreLabel.text = "Score: %d" % _score.score
	$Layout/VBox/Status/ComboLabel.text = _score.combo_text()
	$Layout/VBox/Status/MovesLabel.text = _score.moves_text()
	_refresh_timer()
	_refresh_boss()


func _style_boss_bar() -> void:
	var bar: ProgressBar = $Layout/VBox/BossPanel/HealthBar
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.28, 0.22)
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.18, 0.2, 0.24)
	bar.add_theme_stylebox_override("background", background)


func _refresh_boss() -> void:
	var panel: Control = $Layout/VBox/BossPanel
	panel.visible = _boss != null
	if _boss == null:
		return
	$Layout/VBox/BossPanel/BossLabel.text = "Boss: %d/%d" % [_boss.hp, _boss.MAX_HP]
	var bar: ProgressBar = $Layout/VBox/BossPanel/HealthBar
	bar.max_value = _boss.MAX_HP
	bar.value = _boss.hp
	var guard := "Shield" if _boss.shield else "Shield down"
	$Layout/VBox/BossPanel/PhaseLabel.text = "Phase %d  %s\nCharge: %d/%d" % [_boss.phase, guard, _boss.charge, _boss.charge_max]
	$Layout/VBox/BossPanel/HealthLabel.text = "Health: %d/%d" % [_robot.health, _robot.health_max]


func _ensure_move() -> void:
	if _matches.find_hint(_board).size() >= 2:
		return
	_shuffle_types()
	_board.clear_selection()


func _shuffle_types() -> void:
	var tiles: Array = []
	for row in 8:
		for column in 8:
			var tile: Tile = _board.get_tile(row, column)
			if tile == null or _board.is_frozen(tile):
				continue
			tiles.append(tile)
	if tiles.size() < 2:
		return
	var types: Array = []
	for tile in tiles:
		types.append(tile.tile_type)
	for _attempt in 20:
		types.shuffle()
		for index in tiles.size():
			var tile: Tile = tiles[index]
			tile.setup(types[index], tile.row, tile.column)
		if _matches.find_matches(_board).is_empty() and _matches.find_hint(_board).size() >= 2:
			return
	_force_move()


func _force_move() -> bool:
	var kind: int = TileScript.Type.BATTERY
	var other: int = TileScript.Type.GEAR
	for row in 8:
		for column in 6:
			var left: Tile = _board.get_tile(row, column)
			var middle: Tile = _board.get_tile(row, column + 1)
			var right: Tile = _board.get_tile(row, column + 2)
			var below: Tile = _board.tile_at(row + 1, column + 2)
			if left == null or middle == null or right == null or below == null:
				continue
			if _board.is_frozen(left) or _board.is_frozen(middle) or _board.is_frozen(right) or _board.is_frozen(below):
				continue
			left.setup(kind, left.row, left.column)
			middle.setup(kind, middle.row, middle.column)
			below.setup(kind, below.row, below.column)
			right.setup(other, right.row, right.column)
			if _matches.find_hint(_board).size() >= 2:
				return true
	return false


func _clear_hint() -> void:
	for tile in _hint_tiles:
		if is_instance_valid(tile):
			tile.set_hint(false)
	_hint_tiles = []
	if _arrow_line != null:
		_arrow_line.visible = false
		_arrow_line.clear_points()
	if _arrow_head != null:
		_arrow_head.visible = false


func _paint_hint(pair: Array) -> void:
	_clear_hint()
	if pair.size() < 2:
		return
	_hint_tiles = pair
	for tile in pair:
		tile.set_hint(true)
	_show_arrow(pair[0], pair[1])


func _show_arrow(from_tile: Tile, to_tile: Tile) -> void:
	var start: Vector2 = from_tile.position + from_tile.size * 0.5
	var finish: Vector2 = to_tile.position + to_tile.size * 0.5
	var direction: Vector2 = finish - start
	if direction.length() < 1.0:
		return
	direction = direction.normalized()
	var side := Vector2(-direction.y, direction.x)
	var tip: Vector2 = finish - direction * from_tile.size.x * 0.18
	var tail: Vector2 = start + direction * from_tile.size.x * 0.22
	_arrow_line.clear_points()
	_arrow_line.add_point(tail)
	_arrow_line.add_point(tip - direction * 16.0)
	_arrow_line.visible = true
	_arrow_head.polygon = PackedVector2Array([tip, tip - direction * 22.0 + side * 12.0, tip - direction * 22.0 - side * 12.0])
	_arrow_head.visible = true


func _refresh_timer() -> void:
	var timer_label := $Layout/VBox/TimerLabel
	var hurry_label := $Layout/VBox/HurryLabel
	timer_label.visible = _time_limit > 0.0
	if _time_limit <= 0.0:
		hurry_label.visible = false
		return
	var seconds := ceili(_time_left) if _time_left > 0.0 else 0
	timer_label.text = "Time: %d" % seconds
	var hurry := _timer_running and _time_left < 10.0 and _time_left > 0.0
	hurry_label.visible = hurry
	hurry_label.text = "Hurry Up"
	if hurry:
		var bright := fmod(_blink_time, 0.5) < 0.25
		timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.25) if bright else Color(1, 0.85, 0.35))
		hurry_label.modulate.a = 1.0 if bright else 0.25
	else:
		timer_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1))
		hurry_label.modulate.a = 1.0


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
