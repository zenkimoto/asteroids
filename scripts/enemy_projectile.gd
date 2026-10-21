class_name EnemyProjectile
extends WrappingEntity
## Hostile UFO shot. Flies straight and wraps; it is a player hazard and
## disappears when it hits the ship or its lifetime runs out.

signal expired

## Small wrap margin so shots reappear promptly on the other side.
const WRAP_MARGIN: float = 8.0
## Spin of the diamond-shaped shot, in radians per second.
const SPIN_SPEED: float = 9.0

var _time_left: float = 0.0


func _ready() -> void:
	wrap_margin = WRAP_MARGIN
	add_to_group(HAZARD_GROUP)


## Sets position, direction, speed and lifetime; call before adding it to the tree.
func setup(start: Vector2, direction: Vector2, speed: float, lifetime: float) -> void:
	position = start
	velocity = direction * speed
	_time_left = lifetime


func _entity_physics_process(delta: float) -> void:
	rotation += SPIN_SPEED * delta
	_time_left -= delta
	if _time_left <= 0.0:
		expired.emit()
		despawn()


## Called by the player when this shot hits the ship.
func on_player_hit() -> void:
	despawn()
