class_name AsteroidSizeSettings
extends Resource
## Balance values for one asteroid size (large, medium or small).

## Average radius in pixels; the generated outline varies around it.
@export_range(4.0, 200.0, 1.0) var radius: float = 40.0
@export_range(0.0, 1000.0, 5.0) var min_speed: float = 60.0
@export_range(0.0, 1000.0, 5.0) var max_speed: float = 120.0
@export_range(0, 10000, 5) var score: int = 20
## Hits needed to destroy it.
@export_range(1, 20) var hit_points: int = 1
