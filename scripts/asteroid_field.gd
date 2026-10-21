class_name AsteroidField
extends Node2D
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


func _ready() -> void:
	_rng.randomize()


## Live asteroids, including fragments about to be created.
func get_asteroid_count() -> int:
	var count := _pending_fragments
	for child in get_children():
		if child is Asteroid and not child.is_destroyed:
			count += 1
	return count


## Spawns `count` large asteroids at random spots away from the player.
func spawn_field(count: int) -> void:
	for i in count:
		var size_settings := settings.get_size_settings(Asteroid.Size.LARGE)
		var position_ := find_clear_position(_avoid_point(), settings.spawn_safe_radius)
		spawn_asteroid(Asteroid.Size.LARGE, position_, _random_velocity(size_settings))


func spawn_asteroid(size: Asteroid.Size, at: Vector2, velocity: Vector2) -> Asteroid:
	var asteroid := asteroid_scene.instantiate() as Asteroid
	asteroid.setup(size, settings, at, velocity, _rng)
	asteroid.destroyed.connect(_on_asteroid_destroyed)
	add_child(asteroid)
	return asteroid


## A random position at least `clearance` away (across screen wrap) from `avoid`.
## Falls back to the best candidate found if no fully clear spot exists.
func find_clear_position(avoid: Vector2, clearance: float, attempts: int = 30) -> Vector2:
	var bounds := Playfield.get_playfield_rect()
	var best := Vector2.ZERO
	var best_distance := -1.0
	for i in attempts:
		var candidate := Vector2(_rng.randf() * bounds.size.x, _rng.randf() * bounds.size.y)
		var distance := ScreenWrap.wrapped_distance(candidate, avoid, bounds)
		if distance >= clearance:
			return candidate
		if distance > best_distance:
			best_distance = distance
			best = candidate
	return best


## True when no live asteroid's edge is within `clearance` of `point`.
func is_area_clear(point: Vector2, clearance: float) -> bool:
	var bounds := Playfield.get_playfield_rect()
	for child in get_children():
		var asteroid := child as Asteroid
		if asteroid and not asteroid.is_destroyed:
			if ScreenWrap.wrapped_distance(point, asteroid.position, bounds) < clearance + asteroid.get_radius():
				return false
	return true


func _on_asteroid_destroyed(asteroid: Asteroid) -> void:
	asteroid_destroyed.emit(asteroid)
	if asteroid.size != Asteroid.Size.SMALL:
		_spawn_fragments(asteroid)
	# The destroyed asteroid is already flagged, so it is not counted.
	if get_asteroid_count() == 0:
		field_cleared.emit()


func _spawn_pending_fragment(size: Asteroid.Size, at: Vector2, velocity: Vector2) -> void:
	_pending_fragments -= 1
	spawn_asteroid(size, at, velocity)


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
		call_deferred(&"_spawn_pending_fragment", child_size, at, velocity)


func _random_velocity(size_settings: AsteroidSizeSettings) -> Vector2:
	return Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(size_settings.min_speed, size_settings.max_speed)


func _avoid_point() -> Vector2:
	if player != null:
		return player.global_position
	return Playfield.get_center()
