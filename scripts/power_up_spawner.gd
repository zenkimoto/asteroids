class_name PowerUpSpawner
extends EntityContainer
## Rolls for a power-up drop whenever an asteroid or UFO is destroyed and spawns
## the floating pickup where it died. Reports each collection.

signal collected(definition: PowerUpDefinition)

@export var settings: PowerUpSettings
@export var pickup_scene: PackedScene

var _rng := RandomNumberGenerator.new()
## Pickups queued for the end of the frame; drops happen inside physics callbacks.
var _pending: int = 0
## Bumped by clear() so drops queued before a cleanup are discarded.
var _generation: int = 0


func _ready() -> void:
	super()
	_rng.randomize()


func drop_from_asteroid(asteroid: Asteroid) -> void:
	_try_drop(asteroid.position, settings.asteroid_drop_chance)


func drop_from_ufo(ufo: Ufo) -> void:
	_try_drop(ufo.position, settings.ufo_drop_chance)


func clear() -> void:
	_generation += 1
	_pending = 0
	super()


func spawn_pickup(definition: PowerUpDefinition, at: Vector2) -> PowerUpPickup:
	var drift := Vector2.from_angle(_rng.randf() * TAU) * settings.pickup_drift_speed
	var pickup := spawn(pickup_scene, func(node: Node) -> void:
		(node as PowerUpPickup).setup(definition, at, drift, settings.pickup_lifetime, settings.pickup_warning_time)
	) as PowerUpPickup
	pickup.collected.connect(_on_pickup_collected)
	return pickup


func _try_drop(at: Vector2, chance: float) -> void:
	if not GameManager.is_gameplay_active():
		return
	if get_live_count() + _pending >= settings.max_active_pickups or _rng.randf() >= chance:
		return
	var lives_full := GameManager.lives >= GameManager.balance.rules.max_lives
	var definition := settings.pick_random(_rng, not lives_full)
	if definition == null:
		return
	_pending += 1
	_spawn_pending.call_deferred(_generation, definition, at)


func _spawn_pending(generation: int, definition: PowerUpDefinition, at: Vector2) -> void:
	if generation != _generation:
		return
	_pending -= 1
	spawn_pickup(definition, at)


func _on_pickup_collected(pickup: PowerUpPickup) -> void:
	collected.emit(pickup.definition)
