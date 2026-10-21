class_name Asteroid
extends WrappingEntity
## A drifting, spinning asteroid with a randomly generated outline. Call setup()
## before adding it to the tree. It reports its destruction through `destroyed`;
## the AsteroidField decides what to spawn next.

enum Size { LARGE, MEDIUM, SMALL }

## Emitted when a hit removes hit points but doesn't destroy it.
signal damaged(asteroid: Asteroid, hit_points_left: int)
## Emitted once when shot apart, before it despawns.
signal destroyed(asteroid: Asteroid)

## Members of this group hurt the player on contact.
const HAZARD_GROUP: StringName = &"player_hazards"

var size: Size = Size.LARGE
var size_settings: AsteroidSizeSettings
var spin: float = 0.0
var hit_points: int = 1

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
	wrap_margin = size_settings.radius
	hit_points = size_settings.hit_points
	spin = rng.randf_range(settings.min_spin, settings.max_spin) * (1.0 if rng.randf() < 0.5 else -1.0)
	rotation = rng.randf() * TAU
	_outline = _generate_outline(rng, settings)


func _ready() -> void:
	add_to_group(HAZARD_GROUP)
	_fill.polygon = _outline
	_outline_line.points = _outline
	_collision.polygon = _outline


func _entity_physics_process(delta: float) -> void:
	rotation += spin * delta


func get_radius() -> float:
	return size_settings.radius


## Applies damage. Returns false if the asteroid was already destroyed, so a
## projectile is never spent on a dying asteroid and points are awarded once.
func take_hit(damage: int = 1) -> bool:
	if is_despawned:
		return false
	hit_points -= damage
	if hit_points > 0:
		damaged.emit(self, hit_points)
		return true
	# Stop being a hazard this frame, not when the node is finally freed.
	remove_from_group(HAZARD_GROUP)
	destroyed.emit(self)
	despawn()
	return true


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
