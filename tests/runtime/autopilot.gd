class_name Autopilot
extends Node
## A simple computer pilot for balance playtests. Every physics tick it presses
## the same input actions a player would: it dodges anything on a collision
## course, otherwise turns toward the nearest target (UFOs first) with a lead
## on the shot and fires once lined up. It plays fairly, not perfectly.

## How far ahead, in seconds, it looks for collisions.
@export var look_ahead: float = 0.9
## Extra room it wants between its hull and a hazard.
@export var safety_margin: float = 40.0
## Degrees off target at which it fires, at least; nearer and bigger targets
## allow a wider angle.
@export var aim_tolerance: float = 3.0
## Beyond this distance it closes in on its target.
@export var engage_distance: float = 450.0
## Above this speed it brakes when nothing threatens it.
@export var cruise_speed: float = 180.0

var game: Game

var _held: Dictionary = {}


func _physics_process(_delta: float) -> void:
	if game == null or not is_instance_valid(game):
		return
	var player := game.player
	if not player.is_alive or not GameManager.is_gameplay_active():
		release_all()
		return
	var bounds := Playfield.get_playfield_rect()
	var threat := _most_urgent_threat(player, bounds)
	if not threat.is_empty():
		_evade(player, threat, bounds)
		return
	_hold(InputActions.BOOST, false)
	var target := _pick_target(player, bounds)
	if target == null:
		_turn_toward(player, -player.velocity if player.get_speed() > 30.0 else player.get_forward())
		_hold(InputActions.FIRE, false)
		_hold(InputActions.THRUST_FORWARD, false)
		_hold(InputActions.THRUST_REVERSE, false)
		return
	var aim := _lead_direction(player, target, bounds)
	var off := _turn_toward(player, aim)
	var distance := ScreenWrap.wrapped_distance(player.global_position, target.position, bounds)
	var radius: float = target.get_radius() if target.has_method(&"get_radius") else 20.0
	var tolerance := maxf(deg_to_rad(aim_tolerance), atan2(radius * 0.8, distance))
	_hold(InputActions.FIRE, absf(off) < tolerance)
	var lined_up := absf(off) < deg_to_rad(20.0)
	var closing_in := distance > engage_distance and lined_up and player.get_speed() < cruise_speed
	var braking := player.get_speed() > cruise_speed and player.velocity.dot(player.get_forward()) > 0.0
	_hold(InputActions.THRUST_FORWARD, closing_in)
	_hold(InputActions.THRUST_REVERSE, braking and not closing_in)


func release_all() -> void:
	for action in [InputActions.THRUST_FORWARD, InputActions.THRUST_REVERSE, InputActions.ROTATE_LEFT,
			InputActions.ROTATE_RIGHT, InputActions.FIRE, InputActions.BOOST]:
		_hold(action, false)


## The hazard that would hit soonest on current courses, as
## {offset, relative_velocity, time}, or empty when nothing is coming.
func _most_urgent_threat(player: Player, bounds: Rect2) -> Dictionary:
	var best := {}
	var hazards: Array = []
	hazards.append_array(game.asteroid_field.get_asteroids())
	hazards.append_array(game.ufo_fleet.get_ufos())
	hazards.append_array(game.enemy_projectiles.get_live_entities())
	for hazard: GameEntity in hazards:
		var offset := SpawnUtils.wrapped_offset(player.global_position, hazard.position, bounds)
		var relative := hazard.velocity - player.velocity
		var radius: float = hazard.get_radius() if hazard.has_method(&"get_radius") else 8.0
		var reach := radius + 22.0 + safety_margin
		var closing := relative.length_squared()
		var time := 0.0 if closing < 1.0 else clampf(-offset.dot(relative) / closing, 0.0, look_ahead)
		var miss := (offset + relative * time).length()
		if miss < reach and (best.is_empty() or time < best["time"]):
			best = {"offset": offset, "relative_velocity": relative, "time": time}
	return best


## Turns side-on to the threat's path and thrusts clear; boosts when it's close.
func _evade(player: Player, threat: Dictionary, _bounds: Rect2) -> void:
	var path: Vector2 = threat["relative_velocity"]
	var offset: Vector2 = threat["offset"]
	var away := -offset.normalized()
	if path.length() > 1.0:
		var side := path.orthogonal().normalized()
		away = side if side.dot(offset) < 0.0 else -side
	var off := _turn_toward(player, away)
	var facing := absf(off) < deg_to_rad(60.0)
	_hold(InputActions.THRUST_FORWARD, facing)
	_hold(InputActions.THRUST_REVERSE, absf(off) > deg_to_rad(120.0))
	_hold(InputActions.BOOST, facing and threat["time"] < 0.35 and player.can_boost())
	_hold(InputActions.FIRE, true)


func _pick_target(player: Player, bounds: Rect2) -> GameEntity:
	var best: GameEntity = null
	var best_score := INF
	var candidates: Array = []
	candidates.append_array(game.ufo_fleet.get_ufos())
	candidates.append_array(game.asteroid_field.get_asteroids())
	for entity: GameEntity in candidates:
		var distance := ScreenWrap.wrapped_distance(player.global_position, entity.position, bounds)
		# UFOs shoot back, so they are worth turning for.
		var score := distance * (0.5 if entity is Ufo else 1.0)
		if score < best_score:
			best_score = score
			best = entity
	return best


## Direction to fire so a bolt meets the target, allowing for its motion.
func _lead_direction(player: Player, target: GameEntity, bounds: Rect2) -> Vector2:
	var weapon := player.weapon
	var bolt_speed := weapon.settings.projectile_speed
	var offset := SpawnUtils.wrapped_offset(player.global_position, target.position, bounds)
	var relative := target.velocity - player.velocity * weapon.settings.inherit_velocity_ratio
	var time := offset.length() / bolt_speed
	return (offset + relative * time).normalized()


## Presses rotate keys toward `direction`; returns the remaining angle.
func _turn_toward(player: Player, direction: Vector2) -> float:
	var off := player.get_forward().angle_to(direction)
	var step := deg_to_rad(player.settings.rotation_speed_degrees) / Engine.physics_ticks_per_second
	_hold(InputActions.ROTATE_RIGHT, off > step * 0.5)
	_hold(InputActions.ROTATE_LEFT, off < -step * 0.5)
	return off


func _hold(action: StringName, pressed: bool) -> void:
	if _held.get(action, false) == pressed:
		return
	_held[action] = pressed
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
