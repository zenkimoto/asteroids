class_name Starfield
extends Node2D
## Layered starfield with faint nebula clouds. Each layer drifts at its own
## speed, and with a `parallax_source` (the ship) the layers also shift against
## its velocity, nearer layers more, for a subtle sense of depth.

@export_range(0, 2000) var star_count: int = 260
@export var star_seed: int = 1337
## Drift of the nearest layer in pixels per second; farther layers move slower.
@export var drift: Vector2 = Vector2(-6.0, 2.0)
## Relative speed of each layer, far to near.
@export var layer_speeds: PackedFloat32Array = [0.2, 0.45, 1.0]
## Node whose `velocity` drives the parallax shift (optional).
@export var parallax_source: Node2D
## Share of the source's velocity applied to the nearest layer.
@export_range(0.0, 0.2, 0.005) var parallax_strength: float = 0.03
@export_range(0, 8) var nebula_count: int = 3
@export var nebula_colors: PackedColorArray = [Color(0.35, 0.15, 0.6, 0.07), Color(0.1, 0.35, 0.6, 0.06), Color(0.6, 0.15, 0.4, 0.05)]
## Stars twinkle by up to this share of their brightness.
@export_range(0.0, 1.0, 0.05) var twinkle: float = 0.3

var _positions: PackedVector2Array = PackedVector2Array()
var _layers: PackedInt32Array = PackedInt32Array()
var _radii: PackedFloat32Array = PackedFloat32Array()
var _alphas: PackedFloat32Array = PackedFloat32Array()
var _phases: PackedFloat32Array = PackedFloat32Array()
var _nebula_positions: PackedVector2Array = PackedVector2Array()
var _nebula_sizes: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0

static var _nebula_texture: Texture2D


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = star_seed
	var field := Playfield.get_playfield_size()
	var layer_count := maxi(layer_speeds.size(), 1)
	for i in star_count:
		var layer := rng.randi_range(0, layer_count - 1)
		_positions.append(Vector2(rng.randf() * field.x, rng.randf() * field.y))
		_layers.append(layer)
		_radii.append(0.6 + 0.6 * layer + rng.randf() * 0.4)
		_alphas.append(0.25 + 0.25 * layer + rng.randf() * 0.2)
		_phases.append(rng.randf() * TAU)
	for i in nebula_count:
		_nebula_positions.append(Vector2(rng.randf_range(0.15, 0.85) * field.x, rng.randf_range(0.15, 0.85) * field.y))
		_nebula_sizes.append(rng.randf_range(0.35, 0.6) * field.y)


func _process(delta: float) -> void:
	_time += delta
	var field := Playfield.get_playfield_size()
	var source_velocity := Vector2.ZERO
	if parallax_source != null and is_instance_valid(parallax_source):
		source_velocity = parallax_source.get(&"velocity")
	for i in _positions.size():
		var speed := layer_speeds[_layers[i]] if not layer_speeds.is_empty() else 1.0
		var motion := drift * speed - source_velocity * parallax_strength * speed
		var p := _positions[i] + motion * delta
		_positions[i] = Vector2(fposmod(p.x, field.x), fposmod(p.y, field.y))
	queue_redraw()


func _draw() -> void:
	var texture := _get_nebula_texture()
	for i in _nebula_positions.size():
		var size := Vector2.ONE * _nebula_sizes[i] * 2.0
		var color := nebula_colors[i % nebula_colors.size()] if not nebula_colors.is_empty() else Color(1, 1, 1, 0.05)
		draw_texture_rect(texture, Rect2(_nebula_positions[i] - size * 0.5, size), false, color)
	for i in _positions.size():
		var shimmer := 1.0 - twinkle * (0.5 + 0.5 * sin(_time * 1.7 + _phases[i]))
		draw_circle(_positions[i], _radii[i], Color(1.0, 1.0, 1.0, _alphas[i] * shimmer))


static func _get_nebula_texture() -> Texture2D:
	if _nebula_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 128
		texture.height = 128
		_nebula_texture = texture
	return _nebula_texture
