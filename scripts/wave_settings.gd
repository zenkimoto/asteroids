class_name WaveSettings
extends Resource
## Endless wave progression. Edit res://resources/game_balance/waves.tres.

@export_group("Asteroid count")
## Large asteroids in Wave 1.
@export_range(1, 30) var first_wave_asteroids: int = 4
@export_range(0, 10) var asteroids_added_per_wave: int = 1
## Upper limit on large asteroids in any wave.
@export_range(1, 40) var max_wave_asteroids: int = 12

@export_group("Speed")
## Asteroid speed multiplier gained each wave after the first.
@export_range(0.0, 1.0, 0.01) var speed_increase_per_wave: float = 0.06
@export_range(1.0, 4.0, 0.05) var max_speed_multiplier: float = 1.6

@export_group("Fast asteroids")
@export_range(1, 100) var fast_first_wave: int = 3
## Share of a wave's asteroids that are fast on the first such wave.
@export_range(0.0, 1.0, 0.01) var fast_share_start: float = 0.2
@export_range(0.0, 1.0, 0.01) var fast_share_per_wave: float = 0.05
@export_range(0.0, 1.0, 0.01) var fast_share_max: float = 0.4

@export_group("Armored asteroids")
@export_range(1, 100) var armored_first_wave: int = 5
## Share of a wave's asteroids that are armored on the first such wave.
@export_range(0.0, 1.0, 0.01) var armored_share_start: float = 0.15
@export_range(0.0, 1.0, 0.01) var armored_share_per_wave: float = 0.04
@export_range(0.0, 1.0, 0.01) var armored_share_max: float = 0.3

@export_group("Timing")
## Seconds counted down before each wave spawns.
@export_range(1, 10) var countdown_seconds: int = 3
## How long the "Wave complete" banner shows before the next countdown.
@export_range(0.0, 10.0, 0.1) var wave_complete_delay: float = 2.0

@export_group("Scoring")
## Completing wave N awards N times this.
@export_range(0, 10000, 10) var completion_bonus_per_wave: int = 100


func get_asteroid_count(wave: int) -> int:
	return mini(first_wave_asteroids + asteroids_added_per_wave * (wave - 1), max_wave_asteroids)


func get_speed_multiplier(wave: int) -> float:
	return minf(1.0 + speed_increase_per_wave * (wave - 1), max_speed_multiplier)


func get_completion_bonus(wave: int) -> int:
	return completion_bonus_per_wave * wave


## The variant of every large asteroid in the wave. Once a variant is unlocked
## each wave has at least one, so its introduction is always visible.
func get_composition(wave: int) -> Array[Asteroid.Variant]:
	var total := get_asteroid_count(wave)
	var armored := _variant_count(wave, total, armored_first_wave, armored_share_start, armored_share_per_wave, armored_share_max)
	var fast := mini(_variant_count(wave, total, fast_first_wave, fast_share_start, fast_share_per_wave, fast_share_max), total - armored)
	var variants: Array[Asteroid.Variant] = []
	for i in total:
		if i < armored:
			variants.append(Asteroid.Variant.ARMORED)
		elif i < armored + fast:
			variants.append(Asteroid.Variant.FAST)
		else:
			variants.append(Asteroid.Variant.STANDARD)
	return variants


func _variant_count(wave: int, total: int, first_wave: int, share_start: float, share_per_wave: float, share_max: float) -> int:
	if wave < first_wave:
		return 0
	var share := minf(share_start + share_per_wave * (wave - first_wave), share_max)
	return clampi(roundi(total * share), 1, total)
