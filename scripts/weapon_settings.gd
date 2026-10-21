class_name WeaponSettings
extends Resource
## Balance values for the player's primary weapon.

## Seconds between shots while Spacebar is held.
@export_range(0.02, 2.0, 0.01) var fire_cooldown: float = 0.22
## Projectile speed in pixels per second, before inheriting ship velocity.
@export_range(100.0, 3000.0, 10.0) var projectile_speed: float = 950.0
## Seconds a projectile lives before disappearing.
@export_range(0.1, 5.0, 0.05) var projectile_lifetime: float = 0.85
## Share of the ship's velocity added to each projectile.
@export_range(0.0, 1.0, 0.05) var inherit_velocity_ratio: float = 0.5
## Damage dealt per hit.
@export_range(1, 10) var damage: int = 1
