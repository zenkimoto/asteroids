class_name PlayerMovementSettings
extends Resource
## Tunable movement values for the player ship. Edit
## res://resources/game_balance/player_movement.tres to rebalance.

@export_group("Thrust")
## Forward acceleration in pixels per second squared.
@export_range(0.0, 3000.0, 10.0) var acceleration: float = 650.0
## Reverse thrust strength as a fraction of forward acceleration.
@export_range(0.0, 1.0, 0.05) var reverse_thrust_ratio: float = 0.5

@export_group("Rotation")
## Turn rate in degrees per second.
@export_range(30.0, 720.0, 5.0) var rotation_speed_degrees: float = 270.0

@export_group("Speed Limits")
## Normal top speed in pixels per second.
@export_range(50.0, 2000.0, 10.0) var max_speed: float = 600.0
## Exponential drag coefficient per second. 0 = no drag (drift forever).
@export_range(0.0, 5.0, 0.05) var drag: float = 0.4
## How quickly speed above the current limit bleeds off (e.g. after a boost ends).
@export_range(0.0, 5000.0, 50.0) var overspeed_deceleration: float = 700.0

@export_group("Boost")
## Instant velocity added in the facing direction when a boost starts.
@export_range(0.0, 1000.0, 10.0) var boost_impulse: float = 250.0
## Acceleration multiplier while boosting.
@export_range(1.0, 5.0, 0.1) var boost_acceleration_multiplier: float = 1.8
## Top speed multiplier while boosting.
@export_range(1.0, 5.0, 0.1) var boost_max_speed_multiplier: float = 1.6
## Seconds a boost lasts.
@export_range(0.1, 10.0, 0.1) var boost_duration: float = 1.5
## Seconds after a boost ends before another can start.
@export_range(0.0, 30.0, 0.1) var boost_cooldown: float = 3.0

@export_group("Screen Wrap")
## Distance past the screen edge before wrapping; roughly the ship's radius.
@export_range(0.0, 200.0, 1.0) var wrap_margin: float = 26.0
