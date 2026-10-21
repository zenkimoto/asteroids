class_name Projectile
extends WrappingEntity
## Player laser bolt. Flies straight, wraps around the screen and despawns after
## its lifetime or on its first successful hit. A piercing bolt carries on
## through up to `pierce_left` more asteroids (a UFO always stops it).

signal hit(target: Node2D)
signal expired

## Small wrap margin so bolts reappear promptly on the other side.
const WRAP_MARGIN: float = 8.0

@export var pierce_color: Color = Color(1, 0.45, 0.95, 1)
@export_range(1.0, 10.0, 0.5) var pierce_width: float = 4.5

var damage: int = 1
var pierce_left: int = 0

var _time_left: float = 0.0


func _ready() -> void:
	wrap_margin = WRAP_MARGIN
	area_entered.connect(_on_area_entered)


## Sets the bolt's position, direction and speed; call right after adding it.
func launch(
		start: Vector2, direction: Vector2, inherited_velocity: Vector2, settings: WeaponSettings, pierce: int = 0
) -> void:
	global_position = start
	rotation = direction.angle()
	velocity = direction * settings.projectile_speed + inherited_velocity
	damage = settings.damage
	_time_left = settings.projectile_lifetime
	pierce_left = pierce
	if pierce > 0:
		var bolt := $Bolt as Line2D
		bolt.default_color = pierce_color
		bolt.width = pierce_width


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
		if pierce_left > 0 and area is Asteroid:
			pierce_left -= 1
		else:
			despawn()
