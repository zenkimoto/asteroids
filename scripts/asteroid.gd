class_name Asteroid
extends Area2D
## A drifting, spinning asteroid with a randomly generated outline. Call setup()
## before adding it to the tree. It reports its destruction through `destroyed`;
## the AsteroidField decides what to spawn next.

enum Size { LARGE, MEDIUM, SMALL }

signal destroyed(asteroid: Asteroid)

## Members of this group hurt the player on contact.
const HAZARD_GROUP: StringName = &"player_hazards"

var size: Size = Size.LARGE
var size_settings: AsteroidSizeSettings
var velocity: Vector2 = Vector2.ZERO
var spin: float = 0.0
var hit_points: int = 1
var is_destroyed: bool = false

var _outline: PackedVector2Array = PackedVector2Array()

@onready var _fill: Polygon2D = $Fill
@onready var _outline_line: Line2D = $Outline
@onready var _collision: CollisionPolygon2D = $Collision


func setup(
		p_size: Size,
		settings: AsteroidSettings,
		p_position: Vector2,
		p_velocity: Vector2,
		rng: RandomNumberGenerator
) -> void:
	size = p_size
	size_settings = settings.get_size_settings(p_size)
	position = p_position
	velocity = p_velocity
	hit_points = size_settings.hit_points
	spin = rng.randf_range(settings.min_spin, settings.max_spin) * (1.0 if rng.randf() < 0.5 else -1.0)
	rotation = rng.randf() * TAU
	_outline = _generate_outline(rng, settings)


func _ready() -> void:
	add_to_group(HAZARD_GROUP)
	_fill.polygon = _outline
	_outline_line.points = _outline
	_collision.polygon = _outline


func _physics_process(delta: float) -> void:
	position += velocity * delta
	rotation += spin * delta
	position = ScreenWrap.wrap_position(position, Playfield.get_playfield_rect(), size_settings.radius)


func get_radius() -> float:
	return size_settings.radius


## Applies damage. Returns false if the asteroid was already destroyed, so a
## projectile is never spent on a dying asteroid and points are awarded once.
func take_hit(damage: int = 1) -> bool:
	if is_destroyed:
		return false
	hit_points -= damage
	if hit_points <= 0:
		_destroy()
	return true


func _destroy() -> void:
	is_destroyed = true
	remove_from_group(HAZARD_GROUP)
	# Stop interacting immediately; physics state can only change deferred.
	set_deferred("monitorable", false)
	destroyed.emit(self)
	queue_free()


## Points around a circle with jittered radii and angles, giving a lumpy rock.
func _generate_outline(rng: RandomNumberGenerator, settings: AsteroidSettings) -> PackedVector2Array:
	var count := rng.randi_range(settings.min_vertices, maxi(settings.min_vertices, settings.max_vertices))
	var points := PackedVector2Array()
	var step := TAU / count
	for i in count:
		var angle := i * step + rng.randf_range(-0.3, 0.3) * step
		var distance := size_settings.radius * rng.randf_range(1.0 - settings.irregularity, 1.0 + settings.irregularity * 0.5)
		points.append(Vector2.from_angle(angle) * distance)
	return points
