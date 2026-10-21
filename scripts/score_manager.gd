extends Node
## Autoload "ScoreManager": the session's score, combo multiplier, extra-life
## rewards and statistics (kills, highest wave, survival time), kept apart from the player and the scene. It
## resets itself when GameManager starts a session.
##
## Combo: each asteroid or UFO kill within `combo_window` seconds of the previous
## one extends the combo; every `kills_per_multiplier_step` kills raise the
## multiplier by 1, up to `max_multiplier`. Kill points are multiplied, the wave
## bonus is not. The combo ends when the window runs out or the ship is destroyed.

signal score_changed(score: int)
signal combo_changed(kills: int, multiplier: int)
signal multiplier_increased(multiplier: int)
signal extra_life_awarded(lives: int)

var score: int = 0
var asteroids_destroyed: int = 0
var ufos_destroyed: int = 0
var waves_completed: int = 0
var highest_wave: int = 0
## Seconds of active play this session (stops while paused and once out of lives).
var survival_time: float = 0.0
var combo_kills: int = 0
var multiplier: int = 1

var _combo_time_left: float = 0.0
var _next_extra_life_score: int = 0


func _ready() -> void:
	GameManager.session_started.connect(reset)


## Runs only while the tree is unpaused, so the combo window pauses too.
func _process(delta: float) -> void:
	if GameManager.is_gameplay_active() and GameManager.lives > 0:
		survival_time += delta
	if combo_kills == 0:
		return
	_combo_time_left -= delta
	if _combo_time_left <= 0.0:
		reset_combo()


func reset() -> void:
	score = 0
	asteroids_destroyed = 0
	ufos_destroyed = 0
	waves_completed = 0
	highest_wave = 0
	survival_time = 0.0
	_next_extra_life_score = _scoring().extra_life_every
	reset_combo()
	score_changed.emit(score)


func reset_combo() -> void:
	_combo_time_left = 0.0
	if combo_kills == 0 and multiplier == 1:
		return
	combo_kills = 0
	multiplier = 1
	combo_changed.emit(combo_kills, multiplier)


## Share of the combo window left, 0 to 1 (0 with no combo running).
func get_combo_time_ratio() -> float:
	if combo_kills == 0:
		return 0.0
	return clampf(_combo_time_left / _scoring().combo_window, 0.0, 1.0)


## Adds points as given (no multiplier); ignored outside active gameplay.
func add_points(points: int) -> void:
	if points <= 0 or not GameManager.is_gameplay_active():
		return
	score += points
	score_changed.emit(score)
	_award_extra_lives()


func record_asteroid_destroyed(asteroid: Asteroid) -> void:
	if not GameManager.is_gameplay_active():
		return
	asteroids_destroyed += 1
	_register_kill(asteroid.get_score_value())


func record_ufo_destroyed(ufo: Ufo) -> void:
	if not GameManager.is_gameplay_active():
		return
	ufos_destroyed += 1
	_register_kill(ufo.get_score_value())


func record_wave_reached(wave: int) -> void:
	if GameManager.is_gameplay_active():
		highest_wave = maxi(highest_wave, wave)


func get_summary() -> SessionSummary:
	var summary := SessionSummary.new()
	summary.score = score
	summary.highest_wave = highest_wave
	summary.asteroids_destroyed = asteroids_destroyed
	summary.ufos_destroyed = ufos_destroyed
	summary.survival_time = survival_time
	return summary


func record_wave_completed(wave: int, bonus: int) -> void:
	if not GameManager.is_gameplay_active():
		return
	waves_completed = maxi(waves_completed, wave)
	add_points(bonus)


## Extends the combo, then awards the kill's points at the (possibly new) multiplier.
func _register_kill(base_points: int) -> void:
	var scoring := _scoring()
	combo_kills += 1
	_combo_time_left = scoring.combo_window
	var new_multiplier := mini(1 + floori(float(combo_kills) / scoring.kills_per_multiplier_step), scoring.max_multiplier)
	var increased := new_multiplier > multiplier
	multiplier = new_multiplier
	combo_changed.emit(combo_kills, multiplier)
	if increased:
		multiplier_increased.emit(multiplier)
	add_points(base_points * multiplier)


## One life per `extra_life_every` points passed; at the life cap the reward is skipped.
func _award_extra_lives() -> void:
	var interval := _scoring().extra_life_every
	if interval <= 0:
		return
	while score >= _next_extra_life_score:
		_next_extra_life_score += interval
		if GameManager.add_life():
			extra_life_awarded.emit(GameManager.lives)


func _scoring() -> ScoringSettings:
	return GameManager.balance.scoring
