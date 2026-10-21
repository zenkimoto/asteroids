class_name AsteroidSettings
extends Resource
## Balance values for asteroids. Edit res://resources/game_balance/asteroids.tres.

@export_group("Sizes")
@export var large: AsteroidSizeSettings
@export var medium: AsteroidSizeSettings
@export var small: AsteroidSizeSettings

@export_group("Splitting")
## Fragments created when a large or medium asteroid breaks.
@export_range(0, 6) var fragment_count: int = 2
## Share of the parent's velocity each fragment keeps.
@export_range(0.0, 1.0, 0.05) var fragment_inherit_ratio: float = 0.5
## Fragments created closer than this to the player are sent away from it.
@export_range(0.0, 500.0, 5.0) var fragment_player_clearance: float = 120.0

@export_group("Spawning")
## New asteroids never appear closer than this to the player.
@export_range(0.0, 1000.0, 10.0) var spawn_safe_radius: float = 350.0

@export_group("Shape")
@export_range(5, 24) var min_vertices: int = 10
@export_range(5, 24) var max_vertices: int = 14
## How far each outline point may stray from the radius (0 = circle).
@export_range(0.0, 0.8, 0.05) var irregularity: float = 0.35
## Spin speed range in radians per second (direction is random).
@export_range(0.0, 10.0, 0.05) var min_spin: float = 0.2
@export_range(0.0, 10.0, 0.05) var max_spin: float = 1.2


func get_size_settings(size: Asteroid.Size) -> AsteroidSizeSettings:
	match size:
		Asteroid.Size.LARGE:
			return large
		Asteroid.Size.MEDIUM:
			return medium
		_:
			return small
