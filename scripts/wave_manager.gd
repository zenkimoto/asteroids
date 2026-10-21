class_name WaveManager
extends Node
## Runs the endless wave cycle: countdown, spawn, completion, bonus, then the next
## and harder wave. Difficulty comes from WaveSettings; AsteroidField and UfoFleet
## do the spawning. A wave is complete once its asteroids, fragments included,
## and its UFOs are all destroyed. The game scene calls start() every session.

signal countdown_started(wave: int)
signal countdown_ticked(wave: int, seconds_left: int)
signal wave_started(wave: int)
signal wave_completed(wave: int, bonus: int)

@export var settings: WaveSettings
@export var asteroid_field: AsteroidField
@export var ufo_fleet: UfoFleet

var current_wave: int = 0
## True from a wave's spawn until its last asteroid and UFO are destroyed.
var is_wave_active: bool = false

var _asteroids_cleared: bool = false

@onready var _timers: TimerScheduler = $Timers


func _ready() -> void:
	asteroid_field.field_cleared.connect(_on_field_cleared)
	ufo_fleet.wave_ufos_cleared.connect(_try_complete_wave)
	GameManager.game_over.connect(_on_game_over)


## Resets progression and begins the countdown to Wave 1. GameManager must be in
## WAVE_TRANSITION (start_session puts it there).
func start() -> void:
	stop()
	_begin_countdown(1)


## Cancels any pending countdown or wave change.
func stop() -> void:
	_timers.cancel_all()
	current_wave = 0
	is_wave_active = false


func _begin_countdown(wave: int) -> void:
	current_wave = wave
	countdown_started.emit(wave)
	_tick_countdown(settings.countdown_seconds)


func _tick_countdown(seconds_left: int) -> void:
	if seconds_left <= 0:
		_start_wave()
		return
	countdown_ticked.emit(current_wave, seconds_left)
	_timers.schedule(1.0, _tick_countdown.bind(seconds_left - 1))


func _start_wave() -> void:
	asteroid_field.speed_multiplier = settings.get_speed_multiplier(current_wave)
	asteroid_field.spawn_wave(settings.get_composition(current_wave))
	ufo_fleet.start_wave(current_wave)
	_asteroids_cleared = false
	is_wave_active = true
	GameManager.end_wave_transition()
	wave_started.emit(current_wave)


func _on_field_cleared() -> void:
	if not is_wave_active:
		return
	_asteroids_cleared = true
	ufo_fleet.hurry()
	_try_complete_wave()


func _try_complete_wave() -> void:
	if not is_wave_active or not _asteroids_cleared or ufo_fleet.has_remaining_ufos():
		return
	if not GameManager.begin_wave_transition():
		return
	is_wave_active = false
	wave_completed.emit(current_wave, settings.get_completion_bonus(current_wave))
	_timers.schedule(settings.wave_complete_delay, _begin_countdown.bind(current_wave + 1))


func _on_game_over(_final_score: int) -> void:
	_timers.cancel_all()
	ufo_fleet.halt()
	is_wave_active = false
