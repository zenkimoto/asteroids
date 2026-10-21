class_name SpawnUtils
extends RefCounted
## Helpers for choosing spawn points on the wrapping playfield.


static func random_point(rng: RandomNumberGenerator, bounds: Rect2) -> Vector2:
	return bounds.position + Vector2(rng.randf() * bounds.size.x, rng.randf() * bounds.size.y)


## Shortest wrapped distance from `point` to any of `points` (INF if empty).
static func nearest_distance(point: Vector2, points: PackedVector2Array, bounds: Rect2) -> float:
	var nearest := INF
	for other in points:
		nearest = minf(nearest, ScreenWrap.wrapped_distance(point, other, bounds))
	return nearest


## Shortest vector from `from` to `to` when the bounds wrap around.
static func wrapped_offset(from: Vector2, to: Vector2, bounds: Rect2) -> Vector2:
	var delta := to - from
	if absf(delta.x) > bounds.size.x * 0.5:
		delta.x -= signf(delta.x) * bounds.size.x
	if absf(delta.y) > bounds.size.y * 0.5:
		delta.y -= signf(delta.y) * bounds.size.y
	return delta


## A random point at least `safe_radius` from every point in `avoid` and with
## `spacing` clear around it from `entities`. If none is found in `attempts`
## tries, the best candidate, ranking distance from `avoid` above spacing.
static func find_spawn_point(
		rng: RandomNumberGenerator,
		avoid: PackedVector2Array,
		safe_radius: float,
		entities: Array,
		spacing: float,
		bounds: Rect2,
		attempts: int = 40
) -> Vector2:
	var best := random_point(rng, bounds)
	var best_rank := -INF
	for i in attempts:
		var candidate := random_point(rng, bounds)
		var distance := nearest_distance(candidate, avoid, bounds)
		var open := clearance_at(candidate, entities, bounds)
		if distance >= safe_radius and open >= spacing:
			return candidate
		var rank := minf(distance, safe_radius) * 10000.0 + minf(open, spacing)
		if rank > best_rank:
			best_rank = rank
			best = candidate
	return best


## Distance from `point` to the nearest entity edge (entities with get_radius()
## count their radius). Returns INF when there are no entities.
static func clearance_at(point: Vector2, entities: Array, bounds: Rect2) -> float:
	var nearest := INF
	for entity in entities:
		var node := entity as Node2D
		if node == null:
			continue
		var radius: float = node.get_radius() if node.has_method(&"get_radius") else 0.0
		nearest = minf(nearest, ScreenWrap.wrapped_distance(point, node.position, bounds) - radius)
	return nearest


## `preferred` if it has `clearance` around it, otherwise a random point that does,
## otherwise the most open point found.
static func find_clear_point(
		rng: RandomNumberGenerator,
		entities: Array,
		clearance: float,
		bounds: Rect2,
		preferred: Vector2,
		attempts: int = 40
) -> Vector2:
	var best := preferred
	var best_clearance := clearance_at(preferred, entities, bounds)
	if best_clearance >= clearance:
		return preferred
	for i in attempts:
		var candidate := random_point(rng, bounds)
		var open := clearance_at(candidate, entities, bounds)
		if open >= clearance:
			return candidate
		if open > best_clearance:
			best_clearance = open
			best = candidate
	return best
