class_name BoostTrail
extends Line2D
## Glowing ribbon left behind the ship while it boosts. Records the target's
## position each frame, ages the points out and tapers toward the tail. It
## draws in world space (top level) and restarts when the ship wraps, so it
## never streaks across the screen.

@export var target: Node2D
@export_range(0.05, 2.0, 0.05) var point_lifetime: float = 0.35
@export_range(2, 200) var max_points: int = 40

## True while the trail should keep growing; old points fade out either way.
var active: bool = false

var _ages: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	global_rotation = 0.0
	clear_trail()


func clear_trail() -> void:
	clear_points()
	_ages.clear()


func _process(delta: float) -> void:
	for i in _ages.size():
		_ages[i] += delta
	while not _ages.is_empty() and _ages[0] >= point_lifetime:
		remove_point(0)
		_ages.remove_at(0)
	if active and target != null and target.is_visible_in_tree():
		add_point(target.global_position)
		_ages.append(0.0)
		if get_point_count() > max_points:
			remove_point(0)
			_ages.remove_at(0)
