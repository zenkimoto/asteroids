class_name UfoSettings
extends Resource
## UFO balance: both types, which waves bring how many, spawn timing, behaviour
## and per-wave difficulty scaling. Edit res://resources/game_balance/ufos.tres.

@export var large: UfoTypeSettings
@export var small: UfoTypeSettings

@export_group("Waves")
@export_range(1, 100) var large_first_wave: int = 2
@export_range(1, 100) var small_first_wave: int = 4
## UFOs in the first UFO wave; one more is added every `waves_per_extra_ufo` waves.
@export_range(1, 10) var first_wave_ufos: int = 1
@export_range(1, 10) var waves_per_extra_ufo: int = 2
@export_range(1, 20) var max_ufos_per_wave: int = 5
## Share of a wave's UFOs that are small, on the first small-UFO wave.
@export_range(0.0, 1.0, 0.01) var small_share_start: float = 0.5
@export_range(0.0, 1.0, 0.01) var small_share_per_wave: float = 0.05
@export_range(0.0, 1.0, 0.01) var small_share_max: float = 0.6
## UFOs allowed on screen at once.
@export_range(1, 10) var max_concurrent_ufos: int = 2

@export_group("Spawn timing")
## Seconds into a wave before its first UFO arrives.
@export_range(0.0, 60.0, 0.5) var first_spawn_delay: float = 6.0
## Seconds between UFO arrivals on the first UFO wave, and how much shorter it gets.
@export_range(1.0, 60.0, 0.5) var spawn_interval: float = 12.0
@export_range(0.0, 10.0, 0.1) var spawn_interval_decrease_per_wave: float = 0.8
@export_range(1.0, 60.0, 0.5) var min_spawn_interval: float = 5.0
## Once the asteroids are gone, remaining UFOs arrive after this delay instead.
@export_range(0.1, 10.0, 0.1) var hurry_delay: float = 1.5
## UFOs never enter closer than this to the ship.
@export_range(0.0, 1000.0, 10.0) var spawn_safe_radius: float = 350.0

@export_group("Behaviour")
## UFOs keep this far from the top and bottom edges.
@export_range(0.0, 400.0, 5.0) var edge_margin: float = 90.0
## Random time between changes of vertical drift.
@export_range(0.1, 10.0, 0.1) var drift_change_min: float = 0.8
@export_range(0.1, 10.0, 0.1) var drift_change_max: float = 2.2
## Seconds the UFO telegraphs (its band glows) before each shot.
@export_range(0.0, 2.0, 0.05) var attack_windup: float = 0.3

@export_group("Difficulty scaling")
## All of these grow each wave after `large_first_wave`, up to their limit.
@export_range(0.0, 1.0, 0.01) var speed_increase_per_wave: float = 0.05
@export_range(1.0, 4.0, 0.05) var max_speed_multiplier: float = 1.5
@export_range(0.0, 1.0, 0.01) var fire_rate_increase_per_wave: float = 0.08
@export_range(1.0, 4.0, 0.05) var max_fire_rate_multiplier: float = 1.8
## Share of the aim error removed per wave.
@export_range(0.0, 1.0, 0.01) var accuracy_increase_per_wave: float = 0.06
@export_range(0.0, 1.0, 0.05) var min_aim_error_multiplier: float = 0.4
@export_range(0.0, 1.0, 0.01) var projectile_speed_increase_per_wave: float = 0.04
@export_range(1.0, 4.0, 0.05) var max_projectile_speed_multiplier: float = 1.4


func get_type_settings(type: Ufo.Type) -> UfoTypeSettings:
	return small if type == Ufo.Type.SMALL else large


## The UFO types that belong to `wave`, in arrival order.
func get_wave_plan(wave: int) -> Array[Ufo.Type]:
	var plan: Array[Ufo.Type] = []
	if wave < large_first_wave:
		return plan
	var total := mini(first_wave_ufos + floori(float(wave - large_first_wave) / waves_per_extra_ufo), max_ufos_per_wave)
	var smalls := 0
	if wave >= small_first_wave:
		var share := minf(small_share_start + small_share_per_wave * (wave - small_first_wave), small_share_max)
		smalls = clampi(roundi(total * share), 1, total)
	# Alternate so small UFOs don't all arrive at the end.
	for i in total:
		var small_slot := smalls > 0 and (i % 2 == 1 or total - i <= smalls)
		plan.append(Ufo.Type.SMALL if small_slot else Ufo.Type.LARGE)
		if small_slot:
			smalls -= 1
	return plan


func get_spawn_interval(wave: int) -> float:
	return maxf(spawn_interval - spawn_interval_decrease_per_wave * _steps(wave), min_spawn_interval)


func get_speed_multiplier(wave: int) -> float:
	return minf(1.0 + speed_increase_per_wave * _steps(wave), max_speed_multiplier)


func get_fire_rate_multiplier(wave: int) -> float:
	return minf(1.0 + fire_rate_increase_per_wave * _steps(wave), max_fire_rate_multiplier)


func get_aim_error_multiplier(wave: int) -> float:
	return maxf(1.0 - accuracy_increase_per_wave * _steps(wave), min_aim_error_multiplier)


func get_projectile_speed_multiplier(wave: int) -> float:
	return minf(1.0 + projectile_speed_increase_per_wave * _steps(wave), max_projectile_speed_multiplier)


func _steps(wave: int) -> int:
	return maxi(wave - large_first_wave, 0)
