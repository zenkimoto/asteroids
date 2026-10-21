class_name Shockwave
extends Node2D
## An expanding ring that thins and fades: explosion blasts, shield breaks and
## the wave-start pulse.

var _from_radius: float = 10.0
var _to_radius: float = 80.0
var _width: float = 6.0
var _color: Color = Color.WHITE
var _lifetime: float = 0.4
var _age: float = 0.0


static func create(at: Vector2, from_radius: float, to_radius: float, color: Color, width: float,
		lifetime: float) -> Shockwave:
	var ring := Shockwave.new()
	ring.position = at
	ring._from_radius = from_radius
	ring._to_radius = to_radius
	ring._color = color
	ring._width = width
	ring._lifetime = maxf(lifetime, 0.05)
	return ring


func _process(delta: float) -> void:
	_age += delta
	if _age >= _lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / _lifetime
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var radius := lerpf(_from_radius, _to_radius, eased)
	var color := Color(_color, _color.a * (1.0 - t))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, color, maxf(_width * (1.0 - t), 1.0), true)
