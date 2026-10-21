extends RuntimeTestSuite
## Balance playtests: the Autopilot plays several full sessions at high speed
## and the suite reports how far it gets, how long waves take and what kills
## it. The numbers guide tuning; the checks only catch a broken curve (a game
## that can't be survived at all, or one that never ends).

const SESSIONS: int = 8
## Simulation speed while playing.
const TIME_SCALE: float = 6.0
## A session stops here if the pilot is still alive (game seconds).
const MAX_SESSION_SECONDS: float = 900.0

var _pilot: Autopilot
var _deaths: Dictionary = {}
var _wave_started_at: float = 0.0
var _wave_times: Dictionary = {}
## Seconds each wave spent waiting on UFOs after its last asteroid was gone.
var _ufo_tails: Dictionary = {}
var _field_cleared_at: float = -1.0


func suite_name() -> String:
	return "playtest"


func test_autopilot_sessions() -> void:
	var waves_reached: Array[int] = []
	var scores: Array[int] = []
	var minutes: Array[float] = []
	var finished := 0
	var steps := Engine.max_physics_steps_per_frame
	Engine.max_physics_steps_per_frame = 16
	for session in SESSIONS:
		if session > 0:
			await runner.new_game()
		var result: Dictionary = await _play_session()
		waves_reached.append(result["wave"])
		scores.append(result["score"])
		minutes.append(result["seconds"] / 60.0)
		finished += 1 if result["game_over"] else 0
		# Printed straight away: a full run takes a while.
		print("[TEST]   session %d: wave %d, score %d, %.1f min%s" % [session + 1, result["wave"], result["score"],
				result["seconds"] / 60.0, "" if result["game_over"] else " (stopped, still alive)"])
	Engine.max_physics_steps_per_frame = steps
	waves_reached.sort()
	scores.sort()
	note("median wave %d (range %d-%d), median score %d" % [
			waves_reached[SESSIONS / 2], waves_reached[0], waves_reached[-1], scores[SESSIONS / 2]])
	var wave_lines := PackedStringArray()
	for wave in _wave_times.keys():
		var times: Array = _wave_times[wave]
		var total := 0.0
		for t in times:
			total += t
		wave_lines.append("w%d %.0fs" % [wave, total / times.size()])
	note("average time to clear: " + ", ".join(wave_lines))
	var tail_lines := PackedStringArray()
	for wave in _ufo_tails.keys():
		var tails: Array = _ufo_tails[wave]
		var total := 0.0
		for t in tails:
			total += t
		tail_lines.append("w%d %.0fs" % [wave, total / tails.size()])
	note("of which waiting on UFOs after the last asteroid: " + ", ".join(tail_lines))
	note("lives lost to: " + str(_deaths))
	check(waves_reached[SESSIONS / 2] >= 2, "a typical session clears wave 1")
	check(finished > 0, "sessions do end in Game Over")


func _play_session() -> Dictionary:
	_pilot = Autopilot.new()
	_pilot.game = game
	runner.add_child(_pilot)
	game.player.died.connect(_on_player_died)
	game.wave_manager.wave_started.connect(_on_wave_started)
	game.wave_manager.wave_completed.connect(_on_wave_completed)
	game.asteroid_field.field_cleared.connect(_on_field_cleared)
	var started := ScoreManager.survival_time
	var over: bool = await runner.wait_until(func() -> bool:
		return GameManager.state == GameManager.State.GAME_OVER \
				or ScoreManager.survival_time - started > MAX_SESSION_SECONDS,
		TIME_SCALE, MAX_SESSION_SECONDS / TIME_SCALE + 60.0)
	_pilot.release_all()
	_pilot.queue_free()
	return {
		"wave": game.wave_manager.current_wave,
		"score": ScoreManager.score,
		"seconds": ScoreManager.survival_time - started,
		"game_over": over and GameManager.state == GameManager.State.GAME_OVER,
	}


func _on_wave_started(_wave: int) -> void:
	_wave_started_at = ScoreManager.survival_time
	_field_cleared_at = -1.0


func _on_field_cleared() -> void:
	if _field_cleared_at < 0.0:
		_field_cleared_at = ScoreManager.survival_time


func _on_wave_completed(wave: int, _bonus: int) -> void:
	if not _wave_times.has(wave):
		_wave_times[wave] = []
	_wave_times[wave].append(ScoreManager.survival_time - _wave_started_at)
	if not _ufo_tails.has(wave):
		_ufo_tails[wave] = []
	var cleared := _field_cleared_at if _field_cleared_at >= 0.0 else ScoreManager.survival_time
	_ufo_tails[wave].append(ScoreManager.survival_time - cleared)


## Records what was closest to the ship when it was destroyed.
func _on_player_died() -> void:
	var player := game.player
	var bounds := Playfield.get_playfield_rect()
	var cause := "unknown"
	var nearest := INF
	var hazards: Array = []
	hazards.append_array(game.asteroid_field.get_asteroids())
	hazards.append_array(game.ufo_fleet.get_ufos())
	# A shot that hit the ship has already despawned but still exists this frame.
	hazards.append_array(game.enemy_projectiles.get_children().filter(func(node: Node) -> bool: return node is GameEntity))
	for hazard: GameEntity in hazards:
		var distance := ScreenWrap.wrapped_distance(player.global_position, hazard.position, bounds)
		if hazard.has_method(&"get_radius"):
			distance -= hazard.get_radius()
		if distance < nearest:
			nearest = distance
			cause = _describe(hazard)
	_deaths[cause] = _deaths.get(cause, 0) + 1


func _describe(hazard: GameEntity) -> String:
	if hazard is Asteroid:
		var asteroid := hazard as Asteroid
		return "%s %s asteroid" % [Asteroid.Variant.keys()[asteroid.variant].to_lower(),
				Asteroid.Size.keys()[asteroid.size].to_lower()]
	if hazard is Ufo:
		return "%s UFO (ram)" % Ufo.Type.keys()[(hazard as Ufo).ufo_type].to_lower()
	return "UFO shot"
