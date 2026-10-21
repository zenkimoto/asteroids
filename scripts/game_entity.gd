class_name GameEntity
extends Area2D
## Base for spawned gameplay objects (asteroids, UFOs and projectiles). It moves
## at `velocity` every physics tick and leaves the game through despawn().
## Subclasses add behaviour in _entity_physics_process(); WrappingEntity also
## wraps around the screen.

## Emitted once, just before the entity leaves the scene for any gameplay reason.
signal despawned(entity: GameEntity)

## Members of this group hurt the player on contact.
const HAZARD_GROUP: StringName = &"player_hazards"

var velocity: Vector2 = Vector2.ZERO
var is_despawned: bool = false


func _physics_process(delta: float) -> void:
	if is_despawned:
		return
	_entity_physics_process(delta)
	if is_despawned:
		return
	position += velocity * delta
	_after_move()


## Per-tick hook for subclasses, run before the entity moves. The base does nothing.
func _entity_physics_process(_delta: float) -> void:
	pass


## Runs after each move. The base does nothing; WrappingEntity wraps the position.
func _after_move() -> void:
	pass


## Removes the entity: it stops colliding and hurting the player at once and is
## freed at the end of the frame.
func despawn() -> void:
	if is_despawned:
		return
	is_despawned = true
	remove_from_group(HAZARD_GROUP)
	# Physics flags can't change during a physics callback, so they are deferred.
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	despawned.emit(self)
	queue_free()
