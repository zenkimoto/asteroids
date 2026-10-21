class_name Projectile
extends Area2D
## Player laser bolt. Flies straight, wraps around the screen and disappears after
## its lifetime or on its first successful hit.

## Small wrap margin so bolts reappear promptly on the other side.
const WRAP_MARGIN: float = 8.0

var velocity: Vector2 = Vector2.ZERO
var damage: int = 1

var _time_left: float = 0.0
var _spent: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


## Sets the bolt's position, direction and speed; call right after adding it.
func launch(start: Vector2, direction: Vector2, inherited_velocity: Vector2, settings: WeaponSettings) -> void:
	global_position = start
	rotation = direction.angle()
	velocity = direction * settings.projectile_speed + inherited_velocity
	damage = settings.damage
	_time_left = settings.projectile_lifetime


func _physics_process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
		return
	position += velocity * delta
	position = ScreenWrap.wrap_position(position, Playfield.get_playfield_rect(), WRAP_MARGIN)


func _on_area_entered(area: Area2D) -> void:
	# A bolt can touch several asteroids in one step; it only ever hits one.
	if _spent or not area.has_method(&"take_hit"):
		return
	if area.take_hit(damage):
		_spent = true
		set_deferred("monitoring", false)
		queue_free()
