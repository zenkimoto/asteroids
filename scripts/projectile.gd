class_name Projectile
extends WrappingEntity
## Player laser bolt. Flies straight, wraps around the screen and despawns after
## its lifetime or on its first successful hit.

signal hit(target: Node2D)
signal expired

## Small wrap margin so bolts reappear promptly on the other side.
const WRAP_MARGIN: float = 8.0

var damage: int = 1

var _time_left: float = 0.0


func _ready() -> void:
	wrap_margin = WRAP_MARGIN
	area_entered.connect(_on_area_entered)


## Sets the bolt's position, direction and speed; call right after adding it.
func launch(start: Vector2, direction: Vector2, inherited_velocity: Vector2, settings: WeaponSettings) -> void:
	global_position = start
	rotation = direction.angle()
	velocity = direction * settings.projectile_speed + inherited_velocity
	damage = settings.damage
	_time_left = settings.projectile_lifetime


func _entity_physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		expired.emit()
		despawn()


func _on_area_entered(area: Area2D) -> void:
	# A bolt can touch several targets in one step; it only ever hits one.
	if is_despawned or not area.has_method(&"take_hit"):
		return
	if area.take_hit(damage):
		hit.emit(area)
		despawn()
