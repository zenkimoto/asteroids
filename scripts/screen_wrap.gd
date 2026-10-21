class_name ScreenWrap
extends RefCounted
## Screen-wrapping helper shared by everything that wraps (player, asteroids, projectiles).


## Wraps a position to the opposite side of the bounds once it has moved `margin`
## pixels past an edge. Using the object's radius as the margin means it has fully
## left the screen before it reappears just outside the opposite edge, so the
## transition is seamless.
static func wrap_position(position: Vector2, bounds: Rect2, margin: float = 0.0) -> Vector2:
	var area := bounds.grow(margin)
	return Vector2(
		wrapf(position.x, area.position.x, area.end.x),
		wrapf(position.y, area.position.y, area.end.y)
	)


## Shortest distance between two points when the bounds wrap around (a torus).
static func wrapped_distance(a: Vector2, b: Vector2, bounds: Rect2) -> float:
	var delta := (b - a).abs()
	delta.x = minf(delta.x, bounds.size.x - delta.x)
	delta.y = minf(delta.y, bounds.size.y - delta.y)
	return delta.length()
