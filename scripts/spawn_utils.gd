class_name SpawnUtils
extends RefCounted
## Helpers for choosing spawn points on the wrapping playfield.


static func random_point(rng: RandomNumberGenerator, bounds: Rect2) -> Vector2:
	return bounds.position + Vector2(rng.randf() * bounds.size.x, rng.randf() * bounds.size.y)


## A random point at least `clearance` away from `avoid` (measured across the
## screen wrap). If none is found in `attempts` tries, the farthest candidate.
static func find_point_away_from(
		rng: RandomNumberGenerator,
		avoid: Vector2,
		clearance: float,
		bounds: Rect2,
		attempts: int = 30
) -> Vector2:
	var best := random_point(rng, bounds)
	var best_distance := -1.0
	for i in attempts:
		var candidate := random_point(rng, bounds)
		var distance := ScreenWrap.wrapped_distance(candidate, avoid, bounds)
		if distance >= clearance:
			return candidate
		if distance > best_distance:
			best_distance = distance
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
