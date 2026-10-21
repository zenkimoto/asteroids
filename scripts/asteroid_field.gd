class_name AsteroidField
extends EntityContainer
## Spawns asteroids, splits them when destroyed and reports when none are left.

signal asteroid_destroyed(asteroid: Asteroid)
signal field_cleared

@export var settings: AsteroidSettings
@export var asteroid_scene: PackedScene
## Asteroids spawn away from this node and fragments avoid it.
@export var player: Player

var _rng := RandomNumberGenerator.new()
## Fragments queued for creation at the end of the frame; they count as alive.
var _pending_fragments: int = 0
## Bumped by clear() so fragments queued before a cleanup are discarded.
var _generation: int = 0


func _ready() -> void:
	super()
	_rng.randomize()


## Live asteroids, including fragments about to be created.
func get_asteroid_count() -> int:
	return get_live_count() + _pending_fragments


func get_asteroids() -> Array[Asteroid]:
	var asteroids: Array[Asteroid] = []
	for entity in get_live_entities():
		asteroids.append(entity as Asteroid)
	return asteroids


## Spawns `count` large asteroids at random spots away from the player.
func spawn_field(count: int) -> void:
	var bounds := Playfield.get_playfield_rect()
	var size_settings := settings.get_size_settings(Asteroid.Size.LARGE)
	for i in count:
		var at := SpawnUtils.find_point_away_from(_rng, _avoid_point(), settings.spawn_safe_radius, bounds)
		spawn_asteroid(Asteroid.Size.LARGE, at, _random_velocity(size_settings))


func spawn_asteroid(size: Asteroid.Size, at: Vector2, velocity: Vector2) -> Asteroid:
	var asteroid := spawn(asteroid_scene, func(node: Node) -> void:
		(node as Asteroid).setup(size, settings, at, velocity, _rng)
	) as Asteroid
	asteroid.destroyed.connect(_on_asteroid_destroyed)
	return asteroid


func clear() -> void:
	_generation += 1
	_pending_fragments = 0
	super()


func _on_asteroid_destroyed(asteroid: Asteroid) -> void:
	asteroid_destroyed.emit(asteroid)
	if asteroid.size != Asteroid.Size.SMALL:
		_spawn_fragments(asteroid)
	# `destroyed` fires before the asteroid despawns, so it may still be counted.
	var remaining := get_asteroid_count() - (1 if is_live(asteroid) else 0)
	if remaining == 0:
		field_cleared.emit()


func _spawn_fragments(parent: Asteroid) -> void:
	var child_size: Asteroid.Size = Asteroid.Size.MEDIUM if parent.size == Asteroid.Size.LARGE else Asteroid.Size.SMALL
	var child_settings := settings.get_size_settings(child_size)
	var player_position := _avoid_point()
	var bounds := Playfield.get_playfield_rect()
	for i in settings.fragment_count:
		var velocity := parent.velocity * settings.fragment_inherit_ratio + _random_velocity(child_settings)
		var offset := Vector2.from_angle(_rng.randf() * TAU) * parent.get_radius() * 0.4
		var at := parent.position + offset
		# Never fire a fresh fragment straight into a ship sitting on the impact point.
		if player != null and player.is_alive \
				and ScreenWrap.wrapped_distance(at, player_position, bounds) < settings.fragment_player_clearance:
			velocity = (at - player_position).normalized() * velocity.length()
		# Spawned deferred: this runs inside a physics callback.
		_pending_fragments += 1
		_spawn_pending_fragment.call_deferred(_generation, child_size, at, velocity)


func _spawn_pending_fragment(generation: int, size: Asteroid.Size, at: Vector2, velocity: Vector2) -> void:
	if generation != _generation:
		return
	_pending_fragments -= 1
	spawn_asteroid(size, at, velocity)


func _random_velocity(size_settings: AsteroidSizeSettings) -> Vector2:
	return Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(size_settings.min_speed, size_settings.max_speed)


func _avoid_point() -> Vector2:
	if player != null:
		return player.global_position
	return Playfield.get_center()
