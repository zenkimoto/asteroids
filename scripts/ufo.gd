class_name Ufo
extends GameEntity
## Hostile saucer. It enters from the left or right edge, crosses the screen
## drifting up and down (PATROLLING), stops to telegraph and fire at the ship
## (ATTACKING), and leaves off the far edge (EXITING). The scene's `ufo_type`
## picks its balance from UfoSettings; call setup() before adding it to the tree.

enum Type { LARGE, SMALL }
enum State { ENTERING, PATROLLING, ATTACKING, EXITING }

signal state_changed(ufo: Ufo, state: State)
## Emitted when a hit removes hit points but doesn't destroy it.
signal damaged(ufo: Ufo, hit_points_left: int)
## Emitted once when shot down, before it despawns.
signal destroyed(ufo: Ufo)
## Emitted when it flies off the far edge without being destroyed.
signal exited(ufo: Ufo)
signal fired(projectile: EnemyProjectile)

@export var ufo_type: Type = Type.LARGE
@export var projectile_scene: PackedScene
@export_group("Running lights")
@export_range(0, 16) var light_count: int = 5
## Steps per second of the chasing light pattern; faster while attacking.
@export_range(0.5, 30.0, 0.5) var light_chase_speed: float = 6.0
@export_range(1.0, 6.0, 0.25) var attack_chase_multiplier: float = 3.0

var state: State = State.ENTERING
var type_settings: UfoTypeSettings
var hit_points: int = 1
## Movement and weapon values after wave scaling.
var speed: float = 0.0
var vertical_speed: float = 0.0
var fire_interval: float = 1.0
var aim_error: float = 0.0
var projectile_speed: float = 0.0

var _settings: UfoSettings
var _player: Player
var _projectiles: EntityContainer
var _rng: RandomNumberGenerator
## 1 when crossing left to right, -1 when crossing right to left.
var _direction: float = 1.0
var _drift: float = 0.0
var _drift_time_left: float = 0.0
var _fire_cooldown: float = 0.0
var _windup_left: float = 0.0
var _lights: Array[Polygon2D] = []
var _light_phase: float = 0.0

@onready var _collision: CollisionPolygon2D = $Collision
@onready var _hull: Polygon2D = $Hull
@onready var _dome: Polygon2D = $Dome
@onready var _outline: Line2D = $Outline
@onready var _band: Line2D = $Band
@onready var _glow: Line2D = $Glow
@onready var _lights_root: Node2D = $Lights


func setup(
		settings: UfoSettings,
		wave: int,
		entry: Vector2,
		player: Player,
		projectiles: EntityContainer,
		rng: RandomNumberGenerator
) -> void:
	_settings = settings
	type_settings = settings.get_type_settings(ufo_type)
	_player = player
	_projectiles = projectiles
	_rng = rng
	hit_points = type_settings.hit_points
	speed = type_settings.speed * settings.get_speed_multiplier(wave)
	vertical_speed = type_settings.vertical_speed * settings.get_speed_multiplier(wave)
	fire_interval = type_settings.fire_interval / settings.get_fire_rate_multiplier(wave)
	aim_error = deg_to_rad(type_settings.aim_error_degrees * settings.get_aim_error_multiplier(wave))
	projectile_speed = type_settings.projectile_speed * settings.get_projectile_speed_multiplier(wave)
	position = entry
	_direction = 1.0 if entry.x < Playfield.get_center().x else -1.0
	velocity = Vector2(_direction * speed, 0.0)
	# The first shot comes a little sooner than the rest.
	_fire_cooldown = fire_interval * 0.5


func _ready() -> void:
	add_to_group(HAZARD_GROUP)
	_build_shape(type_settings.radius)


func get_radius() -> float:
	return type_settings.radius


func get_outline() -> PackedVector2Array:
	return _outline.points


func get_score_value() -> int:
	return type_settings.score


## Applies damage. Returns false if it was already destroyed, so a projectile is
## never spent on a dying UFO and points are awarded once.
func take_hit(damage: int = 1) -> bool:
	if is_despawned:
		return false
	hit_points -= damage
	if hit_points > 0:
		_flash(_outline, type_settings.hit_flash_color, type_settings.outline_color)
		_flash_hull()
		damaged.emit(self, hit_points)
		return true
	destroyed.emit(self)
	despawn()
	return true


func _entity_physics_process(delta: float) -> void:
	_update_lights(delta)
	match state:
		State.ENTERING:
			if _is_fully_inside():
				_set_state(State.PATROLLING)
		State.PATROLLING:
			_update_drift(delta)
			_fire_cooldown -= delta
			if _fire_cooldown <= 0.0 and _player != null and _player.is_alive:
				_windup_left = _settings.attack_windup
				_band.default_color = type_settings.attack_color
				_set_state(State.ATTACKING)
		State.ATTACKING:
			_update_drift(delta)
			_windup_left -= delta
			if _windup_left <= 0.0:
				_fire()
				_fire_cooldown = fire_interval
				_band.default_color = type_settings.outline_color
				_set_state(State.PATROLLING)
		State.EXITING:
			if _is_fully_outside():
				exited.emit(self)
				despawn()
				return
	if (state == State.PATROLLING or state == State.ATTACKING) and _has_reached_far_edge():
		_band.default_color = type_settings.outline_color
		velocity.y = 0.0
		_set_state(State.EXITING)


## Changes vertical drift now and then, and always turns back before the top or
## bottom margin so it never hugs an edge.
func _update_drift(delta: float) -> void:
	_drift_time_left -= delta
	if _drift_time_left <= 0.0:
		_drift = float(_rng.randi_range(-1, 1))
		_drift_time_left = _rng.randf_range(_settings.drift_change_min, _settings.drift_change_max)
	var height := Playfield.get_playfield_size().y
	if position.y < _settings.edge_margin:
		_drift = 1.0
	elif position.y > height - _settings.edge_margin:
		_drift = -1.0
	velocity = Vector2(_direction * speed, _drift * vertical_speed)


## Fires one shot at the ship's position, led by its velocity for accurate types,
## then rotated by a random error within `aim_error`.
func _fire() -> void:
	if _player == null or not _player.is_alive or _projectiles == null:
		return
	var bounds := Playfield.get_playfield_rect()
	var target := _player.global_position
	var travel_time := ScreenWrap.wrapped_distance(position, target, bounds) / projectile_speed
	target += _player.velocity * travel_time * type_settings.lead_factor
	var direction := SpawnUtils.wrapped_offset(position, target, bounds).normalized()
	direction = direction.rotated(_rng.randf_range(-aim_error, aim_error))
	var start := position + direction * type_settings.radius * 0.7
	var shot := _projectiles.spawn(projectile_scene, func(node: Node) -> void:
		(node as EnemyProjectile).setup(start, direction, projectile_speed, type_settings.projectile_lifetime)
	) as EnemyProjectile
	fired.emit(shot)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	state_changed.emit(self, new_state)


func _is_fully_inside() -> bool:
	var width := Playfield.get_playfield_size().x
	var r := type_settings.radius
	return position.x >= r if _direction > 0.0 else position.x <= width - r


func _has_reached_far_edge() -> bool:
	var width := Playfield.get_playfield_size().x
	var r := type_settings.radius
	return position.x >= width - r if _direction > 0.0 else position.x <= r


func _is_fully_outside() -> bool:
	var width := Playfield.get_playfield_size().x
	var r := type_settings.radius
	return position.x > width + r if _direction > 0.0 else position.x < -r


func _flash(line: Line2D, flash_color: Color, base_color: Color) -> void:
	line.default_color = flash_color
	var tween := create_tween()
	tween.tween_property(line, "default_color", base_color, 0.15)


func _flash_hull() -> void:
	_hull.color = type_settings.hull_color.lerp(type_settings.hit_flash_color, 0.5)
	var tween := create_tween()
	tween.tween_property(_hull, "color", type_settings.hull_color, 0.15)


## Chasing running lights along the band: one bright light travels across, the
## rest glow dimly. While winding up to fire they chase faster in the attack colour.
func _update_lights(delta: float) -> void:
	if _lights.is_empty():
		return
	var attacking := state == State.ATTACKING
	_light_phase += delta * light_chase_speed * (attack_chase_multiplier if attacking else 1.0)
	var lead := int(_light_phase) % _lights.size()
	var color := type_settings.attack_color if attacking else type_settings.outline_color
	for i in _lights.size():
		var distance := (lead - i + _lights.size()) % _lights.size()
		_lights[i].color = Color(color, 1.0 if distance == 0 else (0.55 if distance == 1 else 0.2))


func _build_lights(r: float) -> void:
	for i in light_count:
		var light := Polygon2D.new()
		var x := lerpf(-0.7 * r, 0.7 * r, (i + 0.5) / light_count)
		var size := maxf(r * 0.07, 2.0)
		light.polygon = PackedVector2Array([Vector2(-size, 0), Vector2(0, -size), Vector2(size, 0), Vector2(0, size)])
		light.position = Vector2(x, 0.14 * r)
		_lights_root.add_child(light)
		_lights.append(light)


## Classic saucer: a wide hull with a band across the middle and a dome on top.
func _build_shape(r: float) -> void:
	var body := PackedVector2Array([
		Vector2(-r, 0.0), Vector2(-0.55 * r, -0.32 * r), Vector2(-0.3 * r, -0.32 * r),
		Vector2(-0.22 * r, -0.62 * r), Vector2(0.22 * r, -0.62 * r), Vector2(0.3 * r, -0.32 * r),
		Vector2(0.55 * r, -0.32 * r), Vector2(r, 0.0), Vector2(0.55 * r, 0.3 * r), Vector2(-0.55 * r, 0.3 * r),
	])
	_collision.polygon = body
	_hull.polygon = body
	_hull.color = type_settings.hull_color
	_outline.points = body
	_outline.default_color = type_settings.outline_color
	_glow.points = body
	_glow.default_color = Color(type_settings.outline_color, 0.18)
	_build_lights(r)
	_dome.polygon = PackedVector2Array([
		Vector2(-0.3 * r, -0.32 * r), Vector2(-0.22 * r, -0.62 * r),
		Vector2(0.22 * r, -0.62 * r), Vector2(0.3 * r, -0.32 * r),
	])
	_dome.color = type_settings.dome_color
	_band.points = PackedVector2Array([Vector2(-r, 0.0), Vector2(r, 0.0)])
	_band.default_color = type_settings.outline_color
