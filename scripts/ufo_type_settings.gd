class_name UfoTypeSettings
extends Resource
## Balance and look of one UFO type (large or small) at its first wave. Later
## waves scale the speed, fire rate, accuracy and shot speed (see UfoSettings).

@export_group("Body")
## Half the saucer's width in pixels; the shape is drawn from it.
@export_range(8.0, 120.0, 1.0) var radius: float = 36.0
## Hits needed to destroy it.
@export_range(1, 20) var hit_points: int = 3
@export_range(0, 10000, 10) var score: int = 200

@export_group("Movement")
## Horizontal speed in pixels per second while crossing the screen.
@export_range(10.0, 800.0, 5.0) var speed: float = 110.0
## Speed of its occasional up or down drift.
@export_range(0.0, 600.0, 5.0) var vertical_speed: float = 70.0

@export_group("Weapon")
## Seconds between shots.
@export_range(0.2, 10.0, 0.05) var fire_interval: float = 2.2
## Shots stray up to this many degrees either side of the aim line.
@export_range(0.0, 90.0, 0.5) var aim_error_degrees: float = 22.0
## How far ahead of a moving ship it aims (0 = where the ship is now, 1 = full lead).
@export_range(0.0, 1.0, 0.05) var lead_factor: float = 0.0
@export_range(50.0, 2000.0, 10.0) var projectile_speed: float = 380.0
@export_range(0.2, 6.0, 0.05) var projectile_lifetime: float = 2.2

@export_group("Look")
@export var hull_color: Color = Color(0.05, 0.12, 0.06, 1)
@export var outline_color: Color = Color(0.55, 1, 0.35, 1)
@export var dome_color: Color = Color(0.3, 0.6, 0.3, 0.8)
## Colour its band glows just before it fires.
@export var attack_color: Color = Color(1, 0.9, 0.3, 1)
@export var hit_flash_color: Color = Color(1, 1, 1, 1)
