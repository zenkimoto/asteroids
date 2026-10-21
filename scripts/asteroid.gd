class_name Asteroid
extends WrappingEntity
## A drifting, spinning asteroid with a randomly generated outline. Call setup()
## before adding it to the tree. It reports its destruction through `destroyed`;
## the AsteroidField decides what to spawn next.

enum Size { LARGE, MEDIUM, SMALL }
enum Variant { STANDARD, FAST, ARMORED }

## Emitted when a hit removes hit points but doesn't destroy it.
signal damaged(asteroid: Asteroid, hit_points_left: int)
## Emitted once when shot apart, before it despawns.
signal destroyed(asteroid: Asteroid)

## Members of this group hurt the player on contact.
const HAZARD_GROUP: StringName = &"player_hazards"

var size: Size = Size.LARGE
var size_settings: AsteroidSizeSettings
var variant: Variant = Variant.STANDARD
var variant_settings: AsteroidVariantSettings
var spin: float = 0.0
var hit_points: int = 1
var max_hit_points: int = 1

var _radius: float = 0.0

var _outline: PackedVector2Array = PackedVector2Array()

@onready var _fill: Polygon2D = $Fill
@onready var _outline_line: Line2D = $Outline
@onready var _collision: CollisionPolygon2D = $Collision
@onready var _plating: Line2D = $Plating


func setup(
		p_size: Size,
		p_variant: Variant,
		settings: AsteroidSettings,
		p_position: Vector2,
		p_velocity: Vector2,
		rng: RandomNumberGenerator
) -> void:
	size = p_size
	size_settings = settings.get_size_settings(p_size)
	variant = p_variant
	variant_settings = settings.get_variant_settings(p_variant)
	_radius = size_settings.radius * variant_settings.radius_scale
	position = p_position
	velocity = p_velocity
	wrap_margin = _radius
	hit_points = size_settings.hit_points + variant_settings.extra_hit_points
	max_hit_points = hit_points
	spin = rng.randf_range(settings.min_spin, settings.max_spin) * (1.0 if rng.randf() < 0.5 else -1.0)
	rotation = rng.randf() * TAU
	_outline = _generate_outline(rng, settings)


func _ready() -> void:
	add_to_group(HAZARD_GROUP)
	_fill.polygon = _outline
	_outline_line.points = _outline
	_collision.polygon = _outline
	_fill.color = variant_settings.fill_color
	_outline_line.default_color = variant_settings.outline_color
	_plating.visible = variant_settings.show_plating
	_plating.default_color = variant_settings.plating_color
	_plating.points = _scaled_outline(0.62)


func _entity_physics_process(delta: float) -> void:
	rotation += spin * delta


func get_radius() -> float:
	return _radius


## Points awarded for destroying it: the size's score scaled by the variant.
func get_score_value() -> int:
	return roundi(size_settings.score * variant_settings.score_multiplier)


## Applies damage. Returns false if the asteroid was already destroyed, so a
## projectile is never spent on a dying asteroid and points are awarded once.
func take_hit(damage: int = 1) -> bool:
	if is_despawned:
		return false
	hit_points -= damage
	if hit_points > 0:
		_show_damage()
		damaged.emit(self, hit_points)
		return true
	# Stop being a hazard this frame, not when the node is finally freed.
	remove_from_group(HAZARD_GROUP)
	destroyed.emit(self)
	despawn()
	return true


## Flashes the outline and dims the plating so each absorbed hit is visible.
func _show_damage() -> void:
	_plating.modulate.a = lerpf(0.25, 1.0, float(hit_points - 1) / maxf(max_hit_points - 1, 1.0))
	_outline_line.default_color = variant_settings.hit_flash_color
	var tween := create_tween()
	tween.tween_property(_outline_line, "default_color", variant_settings.outline_color, 0.18)


func _scaled_outline(factor: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in _outline:
		points.append(point * factor)
	return points


## Points around a circle with jittered radii and angles, giving a lumpy rock.
func _generate_outline(rng: RandomNumberGenerator, settings: AsteroidSettings) -> PackedVector2Array:
	var count := rng.randi_range(settings.min_vertices, maxi(settings.min_vertices, settings.max_vertices))
	var points := PackedVector2Array()
	var step := TAU / count
	for i in count:
		var angle := i * step + rng.randf_range(-0.3, 0.3) * step
		var distance := _radius * rng.randf_range(1.0 - settings.irregularity, 1.0 + settings.irregularity * 0.5)
		points.append(Vector2.from_angle(angle) * distance)
	return points
