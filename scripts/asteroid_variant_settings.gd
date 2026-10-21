class_name AsteroidVariantSettings
extends Resource
## Balance and look of one asteroid variant (standard, fast or armored). The size
## settings supply the base values and the variant scales them.

@export var display_name: String = "Standard"

@export_group("Balance")
## Multiplies the size's radius.
@export_range(0.3, 2.0, 0.05) var radius_scale: float = 1.0
## Multiplies the size's speed range.
@export_range(0.3, 4.0, 0.05) var speed_scale: float = 1.0
## Hits added on top of the size's hit points.
@export_range(0, 20) var extra_hit_points: int = 0
## Multiplies the size's score.
@export_range(0.0, 10.0, 0.05) var score_multiplier: float = 1.0
## If true, fragments are this variant too; otherwise they are standard.
@export var fragments_keep_variant: bool = true

@export_group("Look")
@export var fill_color: Color = Color(0.09, 0.07, 0.13, 1)
@export var outline_color: Color = Color(1, 0.55, 0.85, 1)
## Draws an inner plating ring (the armored look) that fades as hits land.
@export var show_plating: bool = false
@export var plating_color: Color = Color(0.78, 0.82, 0.9, 1)
## Outline colour flashed when a hit doesn't destroy the asteroid.
@export var hit_flash_color: Color = Color(1, 1, 1, 1)
