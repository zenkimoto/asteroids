class_name AsteroidField
extends EntityContainer
## Spawns asteroids away from the player, splits them when destroyed and reports
## when none are left. WaveManager decides what each wave contains.

signal asteroid_destroyed(asteroid: Asteroid)
signal field_cleared

@export var settings: AsteroidSettings
@export var asteroid_scene: PackedScene
## Asteroids spawn away from this node and fragments avoid it.
@export var player: Player

## Scales every asteroid's speed, fragments included; set per wave.
var speed_multiplier: float = 1.0

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


## Spawns one large asteroid per entry in `variants`, each clear of the player
## (or the respawn point while the ship is down) and of the others.
func spawn_wave(variants: Array[Asteroid.Variant]) -> void:
	var bounds := Playfield.get_playfield_rect()
	var avoid := _spawn_avoid_points()
	var placed: Array = get_asteroids()
	for variant in variants:
		var variant_settings := settings.get_variant_settings(variant)
		var radius := settings.large.radius * variant_settings.radius_scale
		var at := SpawnUtils.find_spawn_point(
				_rng, avoid, settings.spawn_safe_radius + radius, placed, radius + settings.spawn_spacing, bounds)
		var velocity := _steer_clear(at, _random_velocity(settings.large, variant_settings), avoid, bounds)
		placed.append(spawn_asteroid(Asteroid.Size.LARGE, variant, at, velocity))


func spawn_asteroid(size: Asteroid.Size, variant: Asteroid.Variant, at: Vector2, velocity: Vector2) -> Asteroid:
	var asteroid := spawn(asteroid_scene, func(node: Node) -> void:
		(node as Asteroid).setup(size, variant, settings, at, velocity, _rng)
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
	var child_variant: Asteroid.Variant = parent.variant if parent.variant_settings.fragments_keep_variant \
			else Asteroid.Variant.STANDARD
	var child_settings := settings.get_size_settings(child_size)
	var child_variant_settings := settings.get_variant_settings(child_variant)
	var player_position := _avoid_point()
	var bounds := Playfield.get_playfield_rect()
	# The parent is still counted, but its slot is about to free up.
	var room := settings.max_live_asteroids - (get_asteroid_count() - 1)
	for i in mini(settings.fragment_count, room):
		var velocity := parent.velocity * settings.fragment_inherit_ratio \
				+ _random_velocity(child_settings, child_variant_settings)
		var offset := Vector2.from_angle(_rng.randf() * TAU) * parent.get_radius() * 0.4
		var at := parent.position + offset
		# Never fire a fresh fragment straight into a ship sitting on the impact point.
		if player != null and player.is_alive \
				and ScreenWrap.wrapped_distance(at, player_position, bounds) < settings.fragment_player_clearance:
			velocity = (at - player_position).normalized() * velocity.length()
		# Spawned deferred: this runs inside a physics callback.
		_pending_fragments += 1
		_spawn_pending_fragment.call_deferred(_generation, child_size, child_variant, at, velocity)


func _spawn_pending_fragment(
		generation: int, size: Asteroid.Size, variant: Asteroid.Variant, at: Vector2, velocity: Vector2
) -> void:
	if generation != _generation:
		return
	_pending_fragments -= 1
	spawn_asteroid(size, variant, at, velocity)


func _random_velocity(size_settings: AsteroidSizeSettings, variant_settings: AsteroidVariantSettings) -> Vector2:
	var speed := _rng.randf_range(size_settings.min_speed, size_settings.max_speed) \
			* variant_settings.speed_scale * speed_multiplier
	return Vector2.from_angle(_rng.randf() * TAU) * speed


## Turns `velocity` aside if it points almost straight at one of `avoid`.
func _steer_clear(at: Vector2, velocity: Vector2, avoid: PackedVector2Array, bounds: Rect2) -> Vector2:
	var clearance := deg_to_rad(settings.spawn_heading_clearance)
	for point in avoid:
		var toward := SpawnUtils.wrapped_offset(at, point, bounds)
		var angle := toward.angle_to(velocity)
		if absf(angle) < clearance:
			var side := signf(angle) if angle != 0.0 else 1.0
			velocity = toward.normalized().rotated(side * clearance) * velocity.length()
	return velocity


func _spawn_avoid_points() -> PackedVector2Array:
	if player != null and player.is_alive:
		return PackedVector2Array([player.global_position])
	# The ship respawns as close to the centre as it safely can.
	return PackedVector2Array([Playfield.get_center()])


func _avoid_point() -> Vector2:
	if player != null:
		return player.global_position
	return Playfield.get_center()
