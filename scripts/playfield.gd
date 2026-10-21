@tool
class_name Playfield
extends Node2D
## Temporary playfield: dark space background, a static starfield and a neon border.
## Its size always matches the project's base viewport (1920x1080), which is also
## the area that screen wrapping will use.

@export var background_color: Color = Color(0.02, 0.02, 0.06):
	set(value):
		background_color = value
		queue_redraw()
@export var border_color: Color = Color(0.2, 0.9, 1.0, 0.6):
	set(value):
		border_color = value
		queue_redraw()
@export_range(0.0, 8.0, 0.5) var border_width: float = 2.0:
	set(value):
		border_width = value
		queue_redraw()
@export_range(0, 2000) var star_count: int = 250:
	set(value):
		star_count = value
		_generate_stars()
@export var star_seed: int = 1337:
	set(value):
		star_seed = value
		_generate_stars()

var _star_positions: PackedVector2Array = PackedVector2Array()
var _star_radii: PackedFloat32Array = PackedFloat32Array()
var _star_alphas: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_generate_stars()


## Size of the playable area in world units.
static func get_playfield_size() -> Vector2:
	return Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)


static func get_playfield_rect() -> Rect2:
	return Rect2(Vector2.ZERO, get_playfield_size())


static func get_center() -> Vector2:
	return get_playfield_size() / 2.0


func _generate_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = star_seed
	var field_size := get_playfield_size()
	_star_positions.resize(star_count)
	_star_radii.resize(star_count)
	_star_alphas.resize(star_count)
	for i in star_count:
		_star_positions[i] = Vector2(rng.randf() * field_size.x, rng.randf() * field_size.y)
		_star_radii[i] = rng.randf_range(0.6, 1.8)
		_star_alphas[i] = rng.randf_range(0.25, 0.9)
	queue_redraw()


func _draw() -> void:
	var rect := get_playfield_rect()
	draw_rect(rect, background_color)
	for i in _star_positions.size():
		draw_circle(_star_positions[i], _star_radii[i], Color(1.0, 1.0, 1.0, _star_alphas[i]))
	if border_width > 0.0:
		draw_rect(rect.grow(-border_width / 2.0), border_color, false, border_width)
