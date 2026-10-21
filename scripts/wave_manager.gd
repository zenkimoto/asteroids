class_name WaveManager
extends Node
## Runs the endless wave cycle: countdown, spawn, completion, bonus, then the next
## and harder wave. Difficulty comes from WaveSettings and AsteroidField does the
## spawning. The game scene calls start() at the beginning of every session.

signal countdown_started(wave: int)
signal countdown_ticked(wave: int, seconds_left: int)
signal wave_started(wave: int)
signal wave_completed(wave: int, bonus: int)

@export var settings: WaveSettings
@export var asteroid_field: AsteroidField

var current_wave: int = 0
## True from a wave's spawn until its last asteroid, fragments included, is gone.
var is_wave_active: bool = false

@onready var _timers: TimerScheduler = $Timers


func _ready() -> void:
	asteroid_field.field_cleared.connect(_on_field_cleared)
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
	is_wave_active = true
	GameManager.end_wave_transition()
	wave_started.emit(current_wave)


func _on_field_cleared() -> void:
	if not is_wave_active or not GameManager.begin_wave_transition():
		return
	is_wave_active = false
	wave_completed.emit(current_wave, settings.get_completion_bonus(current_wave))
	_timers.schedule(settings.wave_complete_delay, _begin_countdown.bind(current_wave + 1))


func _on_game_over(_final_score: int) -> void:
	_timers.cancel_all()
	is_wave_active = false
