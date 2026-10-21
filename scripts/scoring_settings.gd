class_name ScoringSettings
extends Resource
## Combo multiplier and extra-life rewards. Point values per enemy live with the
## enemy settings (asteroids.tres, ufos.tres); the wave bonus is in waves.tres.

@export_group("Combo")
## A kill within this many seconds of the previous one continues the combo.
@export_range(0.5, 10.0, 0.1) var combo_window: float = 3.0
## Every this many consecutive kills raise the multiplier by 1.
@export_range(1, 50) var kills_per_multiplier_step: int = 5
@export_range(1, 20) var max_multiplier: int = 5

@export_group("Extra lives")
## A life is awarded each time the score passes another multiple of this (0 = off).
@export_range(0, 1000000, 500) var extra_life_every: int = 10000
