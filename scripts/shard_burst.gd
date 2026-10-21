class_name ShardBurst
extends Node2D
## Break-apart animation: an outline cut into its edges, which fly outward,
## spin and fade. Drawn in one node, so a burst is cheap however many edges.

var _starts: PackedVector2Array = PackedVector2Array()
var _ends: PackedVector2Array = PackedVector2Array()
var _centers: PackedVector2Array = PackedVector2Array()
var _velocities: PackedVector2Array = PackedVector2Array()
var _spins: PackedFloat32Array = PackedFloat32Array()
var _color: Color = Color.WHITE
var _width: float = 2.0
var _lifetime: float = 0.7
var _age: float = 0.0


## `points` is a closed outline in local space, placed by `xform` (position,
## rotation and scale of the object breaking apart). Every edge becomes a shard.
static func create(points: PackedVector2Array, xform: Transform2D, color: Color, width: float,
		speed: float, lifetime: float, inherited_velocity: Vector2, rng: RandomNumberGenerator) -> ShardBurst:
	var burst := ShardBurst.new()
	burst._color = color
	burst._width = width
	burst._lifetime = maxf(lifetime, 0.05)
	var center := xform.origin
	for i in points.size():
		var a := xform * points[i]
		var b := xform * points[(i + 1) % points.size()]
		var mid := (a + b) * 0.5
		var outward := (mid - center).normalized() if mid != center else Vector2.from_angle(rng.randf() * TAU)
		burst._centers.append(mid)
		burst._starts.append(a - mid)
		burst._ends.append(b - mid)
		burst._velocities.append(outward * speed * rng.randf_range(0.5, 1.2) + inherited_velocity)
		burst._spins.append(rng.randf_range(-6.0, 6.0))
	return burst


func _process(delta: float) -> void:
	_age += delta
	if _age >= _lifetime:
		queue_free()
		return
	for i in _centers.size():
		_centers[i] += _velocities[i] * delta
		_velocities[i] *= exp(-2.5 * delta)
		var turn := _spins[i] * delta
		_starts[i] = _starts[i].rotated(turn)
		_ends[i] = _ends[i].rotated(turn)
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - _age / _lifetime
	var color := Color(_color, _color.a * fade)
	for i in _centers.size():
		draw_line(_centers[i] + _starts[i], _centers[i] + _ends[i], color, _width, true)
