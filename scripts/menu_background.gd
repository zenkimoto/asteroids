class_name MenuBackground
extends Node2D
## Main menu backdrop: dark space with three layers of slowly drifting stars,
## and asteroids that occasionally float across the screen.

@export var background_color: Color = Color(0.02, 0.02, 0.06)
@export_range(0, 2000) var star_count: int = 260
## Drift direction and speed of the nearest star layer; farther layers move slower.
@export var star_drift: Vector2 = Vector2(-18.0, 6.0)
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

const LAYER_SPEEDS: PackedFloat32Array = [0.25, 0.5, 1.0]

var _rng := RandomNumberGenerator.new()
var _star_positions: PackedVector2Array = PackedVector2Array()
var _star_layers: PackedInt32Array = PackedInt32Array()
var _star_radii: PackedFloat32Array = PackedFloat32Array()
var _star_alphas: PackedFloat32Array = PackedFloat32Array()
var _spawn_time_left: float = 0.0
var _ages: Dictionary = {}


func _ready() -> void:
	_rng.randomize()
	var field := Playfield.get_playfield_size()
	_star_positions.resize(star_count)
	_star_layers.resize(star_count)
	_star_radii.resize(star_count)
	_star_alphas.resize(star_count)
	for i in star_count:
		_star_positions[i] = Vector2(_rng.randf() * field.x, _rng.randf() * field.y)
		_star_layers[i] = _rng.randi_range(0, LAYER_SPEEDS.size() - 1)
		_star_radii[i] = 0.6 + 0.5 * _star_layers[i] + _rng.randf() * 0.4
		_star_alphas[i] = 0.25 + 0.25 * _star_layers[i] + _rng.randf() * 0.2
	_spawn_time_left = 0.5


func _process(delta: float) -> void:
	var field := Playfield.get_playfield_size()
	for i in _star_positions.size():
		var p := _star_positions[i] + star_drift * LAYER_SPEEDS[_star_layers[i]] * delta
		_star_positions[i] = Vector2(fposmod(p.x, field.x), fposmod(p.y, field.y))
	queue_redraw()
	_update_asteroids(delta)


func _draw() -> void:
	draw_rect(Playfield.get_playfield_rect(), background_color)
	for i in _star_positions.size():
		draw_circle(_star_positions[i], _star_radii[i], Color(1.0, 1.0, 1.0, _star_alphas[i]))


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
