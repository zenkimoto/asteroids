class_name AsteroidSettings
extends Resource
## Balance values for asteroids. Edit res://resources/game_balance/asteroids.tres.

@export_group("Sizes")
@export var large: AsteroidSizeSettings
@export var medium: AsteroidSizeSettings
@export var small: AsteroidSizeSettings

@export_group("Variants")
@export var standard: AsteroidVariantSettings
## Smaller and faster; appears from the wave set in WaveSettings.
@export var fast: AsteroidVariantSettings
## Takes several hits; appears from the wave set in WaveSettings.
@export var armored: AsteroidVariantSettings

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
## Minimum gap between asteroids spawned together.
@export_range(0.0, 500.0, 5.0) var spawn_spacing: float = 60.0
## A new asteroid never starts heading within this many degrees of the player.
@export_range(0.0, 90.0, 1.0) var spawn_heading_clearance: float = 35.0
## Performance limit: fragments beyond this many live asteroids aren't created.
@export_range(10, 500) var max_live_asteroids: int = 60

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


func get_variant_settings(variant: Asteroid.Variant) -> AsteroidVariantSettings:
	match variant:
		Asteroid.Variant.FAST:
			return fast
		Asteroid.Variant.ARMORED:
			return armored
		_:
			return standard
