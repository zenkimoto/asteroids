class_name UfoFleet
extends EntityContainer
## Brings in the UFOs that belong to each wave, a few at a time, from the screen
## edge farther from the ship. A UFO that flies off without being shot down
## comes back later, so a wave's UFOs are only done once all are destroyed.

signal ufo_spawned(ufo: Ufo)
signal ufo_destroyed(ufo: Ufo)
## Every UFO of the current wave has been destroyed.
signal wave_ufos_cleared

@export var settings: UfoSettings
@export var large_ufo_scene: PackedScene
@export var small_ufo_scene: PackedScene
@export var player: Player
## Where UFO shots are added.
@export var projectiles: EntityContainer

var _rng := RandomNumberGenerator.new()
var _wave: int = 0
## UFOs of this wave still to arrive (including ones that flew off).
var _pending: Array[Ufo.Type] = []
## True while the wave still has UFOs to arrive or alive.
var _has_remaining: bool = false
## Set once the asteroids are gone: remaining UFOs arrive quickly.
var _hurry: bool = false
var _spawn_timer: Timer

@onready var _timers: TimerScheduler = $Timers


func _ready() -> void:
	super()
	_rng.randomize()


## Queues this wave's UFOs; the first arrives after the configured delay.
func start_wave(wave: int) -> void:
	halt()
	_wave = wave
	_pending = settings.get_wave_plan(wave)
	_hurry = false
	_has_remaining = not _pending.is_empty()
	if _has_remaining:
		_schedule_spawn(settings.first_spawn_delay)


## True until every UFO of the current wave has been destroyed.
func has_remaining_ufos() -> bool:
	return _has_remaining


func get_ufos() -> Array[Ufo]:
	var ufos: Array[Ufo] = []
	for entity in get_live_entities():
		ufos.append(entity as Ufo)
	return ufos


## Called when the wave's asteroids are gone so the player doesn't wait for UFOs.
func hurry() -> void:
	if _hurry:
		return
	_hurry = true
	if not _pending.is_empty() and (_spawn_timer == null or _spawn_timer.time_left > settings.hurry_delay):
		_schedule_spawn(settings.hurry_delay)


## Stops further arrivals; UFOs already on screen carry on.
func halt() -> void:
	_timers.cancel_all()
	_spawn_timer = null
	_pending.clear()


## Removes every UFO immediately and forgets the wave.
func clear() -> void:
	halt()
	_has_remaining = false
	super()


func spawn_ufo(type: Ufo.Type) -> Ufo:
	var scene := small_ufo_scene if type == Ufo.Type.SMALL else large_ufo_scene
	var radius := settings.get_type_settings(type).radius
	var entry := _pick_entry_point(radius)
	var ufo := spawn(scene, func(node: Node) -> void:
		(node as Ufo).setup(settings, _wave, entry, player, projectiles, _rng)
	) as Ufo
	ufo.destroyed.connect(_on_ufo_destroyed)
	ufo.exited.connect(_on_ufo_exited)
	ufo_spawned.emit(ufo)
	return ufo


func _schedule_spawn(delay: float) -> void:
	_timers.cancel(_spawn_timer)
	_spawn_timer = _timers.schedule(delay, _on_spawn_timer)


func _next_delay() -> float:
	return settings.hurry_delay if _hurry else settings.get_spawn_interval(_wave)


## Sends in the next UFO unless the on-screen limit is reached, then waits again.
func _on_spawn_timer() -> void:
	_spawn_timer = null
	if _pending.is_empty():
		return
	if get_live_count() < settings.max_concurrent_ufos:
		spawn_ufo(_pending.pop_front())
	if not _pending.is_empty():
		_schedule_spawn(_next_delay())


func _on_ufo_destroyed(ufo: Ufo) -> void:
	ufo_destroyed.emit(ufo)
	# `destroyed` fires before the UFO despawns, so it is still counted here.
	if _has_remaining and _pending.is_empty() and get_live_count() - (1 if is_live(ufo) else 0) == 0:
		_has_remaining = false
		wave_ufos_cleared.emit()


func _on_ufo_exited(ufo: Ufo) -> void:
	if not _has_remaining:
		return
	_pending.append(ufo.ufo_type)
	if _spawn_timer == null:
		_schedule_spawn(_next_delay())


## A point just outside the left or right edge, at a height inside the margins,
## at least `spawn_safe_radius` from the ship when possible.
func _pick_entry_point(radius: float) -> Vector2:
	var size := Playfield.get_playfield_size()
	var bounds := Playfield.get_playfield_rect()
	var best := Vector2.ZERO
	var best_distance := -1.0
	for i in 30:
		var from_left := _rng.randf() < 0.5
		var candidate := Vector2(-radius if from_left else size.x + radius,
				_rng.randf_range(settings.edge_margin, size.y - settings.edge_margin))
		if player == null or not player.is_alive:
			return candidate
		var distance := ScreenWrap.wrapped_distance(candidate, player.global_position, bounds)
		if distance >= settings.spawn_safe_radius:
			return candidate
		if distance > best_distance:
			best_distance = distance
			best = candidate
	return best
