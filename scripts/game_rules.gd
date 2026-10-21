class_name GameRules
extends Resource
## Session-level rules: lives, respawning and asteroid field refills.

@export_range(1, 10) var starting_lives: int = 3
## Seconds between the ship being destroyed and respawning.
@export_range(0.0, 10.0, 0.1) var respawn_delay: float = 1.5
## Seconds of invulnerability (with blinking) after respawning.
@export_range(0.0, 10.0, 0.1) var invulnerability_duration: float = 2.0
## The ship respawns where no asteroid is within this distance, if possible.
@export_range(0.0, 1000.0, 10.0) var respawn_clear_radius: float = 220.0
## Large asteroids in each field.
@export_range(1, 30) var asteroids_per_field: int = 4
## Pause before a cleared field refills.
@export_range(0.0, 10.0, 0.1) var field_refill_delay: float = 2.0
## Pause between the last life being lost and the Game Over screen.
@export_range(0.0, 5.0, 0.1) var game_over_delay: float = 1.0
