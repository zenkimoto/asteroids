class_name WrappingEntity
extends Area2D
## Base for gameplay objects that drift at a constant velocity and wrap around the
## playfield (asteroids, projectiles, and later UFO shots and power-ups).
## Subclasses add behaviour in _entity_physics_process() and leave with despawn().

## Emitted once, just before the entity leaves the scene for any gameplay reason.
signal despawned(entity: WrappingEntity)

var velocity: Vector2 = Vector2.ZERO
## Distance past the screen edge before wrapping; usually the entity's radius.
var wrap_margin: float = 0.0
var is_despawned: bool = false


func _physics_process(delta: float) -> void:
	if is_despawned:
		return
	_entity_physics_process(delta)
	if is_despawned:
		return
	position += velocity * delta
	position = ScreenWrap.wrap_position(position, Playfield.get_playfield_rect(), wrap_margin)


## Per-tick hook for subclasses, run before the entity moves. The base does nothing.
func _entity_physics_process(_delta: float) -> void:
	pass


## Removes the entity: it stops colliding at once and is freed at the end of the frame.
func despawn() -> void:
	if is_despawned:
		return
	is_despawned = true
	# Physics flags can't change during a physics callback, so they are deferred.
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	despawned.emit(self)
	queue_free()
