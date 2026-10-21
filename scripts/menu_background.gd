class_name MenuBackground
extends Node2D
## Main menu backdrop: dark space (stars come from a Starfield child) and
## asteroids that occasionally float across the screen.

@export var background_color: Color = Color(0.02, 0.02, 0.06)
@export var asteroid_scene: PackedScene
@export var asteroid_container: EntityContainer
@export_range(0, 20) var max_asteroids: int = 5
## Seconds between new asteroids while below the limit.
@export_range(0.5, 30.0, 0.5) var asteroid_interval: float = 4.0
@export_range(5.0, 300.0, 5.0) var asteroid_min_speed: float = 25.0
@export_range(5.0, 300.0, 5.0) var asteroid_max_speed: float = 60.0
## Seconds an asteroid drifts before fading out, so the set keeps changing.
@export_range(5.0, 120.0, 1.0) var asteroid_lifetime: float = 40.0
@export_range(0.1, 5.0, 0.1) var asteroid_fade_time: float = 1.5

var _rng := RandomNumberGenerator.new()
var _spawn_time_left: float = 0.0
var _ages: Dictionary = {}


func _ready() -> void:
	_rng.randomize()
	_spawn_time_left = 0.5


func _process(delta: float) -> void:
	_update_asteroids(delta)


func _draw() -> void:
	draw_rect(Playfield.get_playfield_rect(), background_color)


func _update_asteroids(delta: float) -> void:
	if asteroid_scene == null or asteroid_container == null:
		return
	for asteroid: Node in _ages.keys():
		if not is_instance_valid(asteroid):
			_ages.erase(asteroid)
			continue
		_ages[asteroid] += delta
		if _ages[asteroid] >= asteroid_lifetime:
			_ages.erase(asteroid)
			_fade_out(asteroid as GameEntity)
	_spawn_time_left -= delta
	if _spawn_time_left > 0.0 or asteroid_container.get_live_count() >= max_asteroids:
		return
	_spawn_time_left = asteroid_interval
	_spawn_asteroid()


func _fade_out(asteroid: GameEntity) -> void:
	var tween := asteroid.create_tween()
	tween.tween_property(asteroid, "modulate:a", 0.0, asteroid_fade_time)
	tween.tween_callback(asteroid.despawn)


## Starts an asteroid just outside a random edge, heading across the screen.
func _spawn_asteroid() -> void:
	var settings: AsteroidSettings = GameManager.balance.asteroids
	var size: Asteroid.Size = [Asteroid.Size.LARGE, Asteroid.Size.MEDIUM, Asteroid.Size.SMALL][_rng.randi_range(0, 2)]
	var radius := settings.get_size_settings(size).radius
	var field := Playfield.get_playfield_size()
	var start: Vector2
	match _rng.randi_range(0, 3):
		0: start = Vector2(-radius, _rng.randf() * field.y)
		1: start = Vector2(field.x + radius, _rng.randf() * field.y)
		2: start = Vector2(_rng.randf() * field.x, -radius)
		_: start = Vector2(_rng.randf() * field.x, field.y + radius)
	var target := Vector2(_rng.randf_range(0.25, 0.75) * field.x, _rng.randf_range(0.25, 0.75) * field.y)
	var velocity := start.direction_to(target) * _rng.randf_range(asteroid_min_speed, asteroid_max_speed)
	var asteroid := asteroid_container.spawn(asteroid_scene, func(node: Node) -> void:
		(node as Asteroid).setup(size, Asteroid.Variant.STANDARD, settings, start, velocity, _rng)
	) as Asteroid
	# Decoration only: nothing in the menu should collide with it.
	asteroid.remove_from_group(GameEntity.HAZARD_GROUP)
	asteroid.monitorable = false
	_ages[asteroid] = 0.0
