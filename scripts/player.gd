class_name Player
extends Area2D
## Player spaceship with classic Asteroids movement: rotation, thrust with inertia,
## exponential drag, a speed cap, a timed boost with cooldown and screen wrapping.
## It fires through its Weapon child, collects power-up pickups it touches and
## dies on touching a hazard unless invulnerable or shielded. The hull art points up, so "forward" is Vector2.UP rotated by
## the ship's rotation.

signal boost_started
signal boost_ended
signal boost_ready
signal wrapped(from_position: Vector2, to_position: Vector2)
signal died
signal respawned
signal shield_changed(active: bool)

@export var settings: PlayerMovementSettings
## When false the ship ignores input but keeps drifting (for later game states).
@export var controls_enabled: bool = true

@export_group("Visuals")
## Seconds per on/off cycle half while invulnerable.
@export_range(0.02, 1.0, 0.01) var blink_interval: float = 0.1
## Ship opacity during the "off" half of a blink.
@export_range(0.0, 1.0, 0.05) var blink_alpha: float = 0.2
## Flame length multiplier while boosting.
@export_range(1.0, 3.0, 0.1) var boost_flame_scale: float = 1.7
## Random per-frame variation of the flame length (0 = steady).
@export_range(0.0, 0.5, 0.01) var flame_flicker: float = 0.15
## Radius of the shield ring drawn around the ship.
@export_range(10.0, 100.0, 1.0) var shield_radius: float = 34.0

var velocity: Vector2 = Vector2.ZERO
## Net thrust input this tick: 1 = full forward, negative = reverse.
var thrust_input: float = 0.0
## Rotation input this tick: -1 = counterclockwise, 1 = clockwise.
var rotation_input: float = 0.0
var is_boosting: bool = false
var boost_time_left: float = 0.0
var boost_cooldown_left: float = 0.0
var is_alive: bool = true
var invulnerable_time_left: float = 0.0
## Set by power-ups (Speed Boost); 1 means normal.
var acceleration_multiplier: float = 1.0
var max_speed_multiplier: float = 1.0
## An active shield absorbs the next hazard contact, then disappears.
var has_shield: bool = false
## Invulnerability granted when the shield absorbs a hit.
var shield_grace_time: float = 1.0

var _flicker_rng := RandomNumberGenerator.new()

@onready var _main_flame: Node2D = $MainFlame
@onready var _reverse_flames: Node2D = $ReverseFlames
@onready var _collision: CollisionPolygon2D = $CollisionShape
@onready var _shield_ring: Line2D = $Shield
@onready var weapon: Weapon = $Weapon


func _ready() -> void:
	if settings == null:
		push_warning("Player has no PlayerMovementSettings assigned; using defaults.")
		settings = PlayerMovementSettings.new()
	var ring := PackedVector2Array()
	for i in 32:
		ring.append(Vector2.from_angle(TAU * i / 32.0) * shield_radius)
	_shield_ring.points = ring
	_shield_ring.visible = has_shield
	_update_thrust_visuals()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_read_input()
	_update_boost(delta)
	rotation += rotation_input * deg_to_rad(settings.rotation_speed_degrees) * delta
	var speed_before_thrust := velocity.length()
	_apply_thrust(delta)
	_apply_drag_and_speed_limit(speed_before_thrust, delta)
	global_position += velocity * delta
	_wrap_position()
	_update_thrust_visuals()
	weapon.source_velocity = velocity
	_update_invulnerability(delta)
	_collect_pickups()
	_check_hazard_contact()


func get_forward() -> Vector2:
	return Vector2.UP.rotated(rotation)


func get_speed() -> float:
	return velocity.length()


## Current top speed, including the boost and power-up multipliers.
func get_max_speed() -> float:
	var top_speed := settings.max_speed * max_speed_multiplier
	if is_boosting:
		return top_speed * settings.boost_max_speed_multiplier
	return top_speed


func is_invulnerable() -> bool:
	return invulnerable_time_left > 0.0


## Destroys the ship: it disappears and stops colliding until respawn().
func die() -> void:
	if not is_alive:
		return
	is_alive = false
	set_shield(false)
	reset_motion()
	weapon.reset()
	visible = false
	_collision.set_deferred("disabled", true)
	died.emit()


## Brings the ship back at `at`, facing up, invulnerable for `invulnerability` seconds.
func respawn(at: Vector2, invulnerability: float) -> void:
	global_position = at
	rotation = 0.0
	reset_motion()
	weapon.reset()
	is_alive = true
	visible = true
	invulnerable_time_left = invulnerability
	modulate.a = 1.0
	_collision.set_deferred("disabled", false)
	respawned.emit()


func set_shield(active: bool) -> void:
	if active == has_shield:
		return
	has_shield = active
	_shield_ring.visible = active
	shield_changed.emit(active)


func can_boost() -> bool:
	return not is_boosting and boost_cooldown_left <= 0.0


## Starts a boost if it is off cooldown. Returns true when a boost started.
func try_boost() -> bool:
	if not can_boost():
		return false
	is_boosting = true
	boost_time_left = settings.boost_duration
	velocity += get_forward() * settings.boost_impulse
	boost_started.emit()
	return true


## Stops all motion and boost state, e.g. when respawning.
func reset_motion() -> void:
	velocity = Vector2.ZERO
	thrust_input = 0.0
	rotation_input = 0.0
	is_boosting = false
	boost_time_left = 0.0
	boost_cooldown_left = 0.0
	_update_thrust_visuals()


func _read_input() -> void:
	if not controls_enabled:
		thrust_input = 0.0
		rotation_input = 0.0
		weapon.trigger_held = false
		return
	weapon.trigger_held = Input.is_action_pressed(InputActions.FIRE)
	rotation_input = Input.get_axis(InputActions.ROTATE_LEFT, InputActions.ROTATE_RIGHT)
	thrust_input = Input.get_action_strength(InputActions.THRUST_FORWARD) \
			- Input.get_action_strength(InputActions.THRUST_REVERSE) * settings.reverse_thrust_ratio
	if Input.is_action_just_pressed(InputActions.BOOST):
		try_boost()


func _update_boost(delta: float) -> void:
	if is_boosting:
		boost_time_left -= delta
		if boost_time_left <= 0.0:
			is_boosting = false
			boost_time_left = 0.0
			boost_cooldown_left = settings.boost_cooldown
			boost_ended.emit()
			if boost_cooldown_left <= 0.0:
				boost_ready.emit()
	elif boost_cooldown_left > 0.0:
		boost_cooldown_left = maxf(boost_cooldown_left - delta, 0.0)
		if boost_cooldown_left == 0.0:
			boost_ready.emit()


func _apply_thrust(delta: float) -> void:
	if is_zero_approx(thrust_input):
		return
	var acceleration := settings.acceleration * acceleration_multiplier
	if is_boosting:
		acceleration *= settings.boost_acceleration_multiplier
	velocity += get_forward() * thrust_input * acceleration * delta


func _apply_drag_and_speed_limit(speed_before_thrust: float, delta: float) -> void:
	# Exponential decay keeps drag frame-rate-independent.
	velocity *= exp(-settings.drag * delta)
	# Thrust can never push past the limit. Speed already above it (a boost impulse,
	# or the boost just ending) eases down instead of snapping, so it feels smooth.
	var speed_cap := maxf(get_max_speed(), speed_before_thrust - settings.overspeed_deceleration * delta)
	var speed := velocity.length()
	if speed > speed_cap:
		velocity = velocity / speed * speed_cap


func _wrap_position() -> void:
	var bounds := Rect2(Vector2.ZERO, Playfield.get_playfield_size())
	var wrapped_position := ScreenWrap.wrap_position(global_position, bounds, settings.wrap_margin)
	if wrapped_position != global_position:
		var from_position := global_position
		global_position = wrapped_position
		wrapped.emit(from_position, wrapped_position)


func _update_invulnerability(delta: float) -> void:
	if invulnerable_time_left <= 0.0:
		return
	invulnerable_time_left = maxf(invulnerable_time_left - delta, 0.0)
	var blink_on := fmod(invulnerable_time_left, blink_interval * 2.0) < blink_interval
	modulate.a = 1.0 if invulnerable_time_left == 0.0 or blink_on else blink_alpha


func _collect_pickups() -> void:
	for area in get_overlapping_areas():
		var pickup := area as PowerUpPickup
		if pickup != null:
			pickup.collect()


## Polled every tick rather than using area_entered, so a hazard still overlapping
## the ship when invulnerability ends is caught too. Only one hazard is handled
## per tick, so simultaneous contacts cost at most one shield or one life.
func _check_hazard_contact() -> void:
	if is_invulnerable():
		return
	for area in get_overlapping_areas():
		if area.is_in_group(GameEntity.HAZARD_GROUP):
			# Shots disappear on impact; asteroids and UFOs carry on.
			if area.has_method(&"on_player_hit"):
				area.on_player_hit()
			if has_shield:
				set_shield(false)
				invulnerable_time_left = shield_grace_time
			else:
				die()
			return


func _update_thrust_visuals() -> void:
	var forward_amount := maxf(thrust_input, 0.0)
	_main_flame.visible = forward_amount > 0.0
	if _main_flame.visible:
		var length := forward_amount * _flicker()
		if is_boosting:
			length *= boost_flame_scale
		_main_flame.scale = Vector2(1.0 + (0.3 if is_boosting else 0.0), length)
	var reverse_amount := maxf(-thrust_input, 0.0)
	_reverse_flames.visible = reverse_amount > 0.0
	if _reverse_flames.visible:
		_reverse_flames.scale = Vector2(1.0, _flicker())


func _flicker() -> float:
	return _flicker_rng.randf_range(1.0 - flame_flicker, 1.0 + flame_flicker)
