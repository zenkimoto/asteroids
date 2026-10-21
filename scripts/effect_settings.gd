class_name EffectSettings
extends Resource
## Tuning for the game's visual feedback: particle bursts, break-apart shards,
## shockwaves, screen shake and flashes. Lives in res://resources/effects/.

@export_group("Particle intensity")
## Particle-count multiplier for each SettingsManager.ParticleIntensity (Low, Medium, High).
@export var intensity_multipliers: PackedFloat32Array = [0.35, 0.65, 1.0]
## Effects alive at once; the oldest is removed first when a new one would exceed it.
@export_range(8, 512) var max_active_effects: int = 96

@export_group("Bursts")
@export var asteroid_debris: ParticleBurstSettings
@export var explosion_core: ParticleBurstSettings
@export var explosion_sparks: ParticleBurstSettings
@export var projectile_impact: ParticleBurstSettings
@export var muzzle_flash: ParticleBurstSettings
@export var pickup_sparkle: ParticleBurstSettings
@export var shield_break: ParticleBurstSettings

@export_group("Colours")
@export var explosion_color: Color = Color(1, 0.6, 0.2, 1)
@export var ship_color: Color = Color(0.3, 0.95, 1, 1)
@export var impact_color: Color = Color(0.6, 1, 0.95, 1)
@export var enemy_fire_color: Color = Color(1, 0.4, 0.2, 1)
@export var shield_color: Color = Color(0.45, 1, 0.75, 1)
@export var wave_color: Color = Color(0.3, 0.95, 1, 0.5)

@export_group("Shards")
@export_range(0.1, 3.0, 0.05) var shard_lifetime: float = 0.75
@export_range(0.0, 600.0, 5.0) var shard_speed: float = 140.0

@export_group("Screen shake (trauma 0-1)")
@export_range(0.0, 1.0, 0.01) var shake_large_asteroid: float = 0.4
@export_range(0.0, 1.0, 0.01) var shake_medium_asteroid: float = 0.2
@export_range(0.0, 1.0, 0.01) var shake_ufo: float = 0.55
@export_range(0.0, 1.0, 0.01) var shake_ship: float = 0.8
@export_range(0.0, 1.0, 0.01) var shake_shield: float = 0.3

@export_group("Screen flash (opacity)")
@export_range(0.0, 1.0, 0.01) var flash_ship: float = 0.2
@export_range(0.0, 1.0, 0.01) var flash_ufo: float = 0.1
@export_range(0.0, 1.0, 0.01) var flash_wave_complete: float = 0.08


func get_intensity(level: int) -> float:
	if intensity_multipliers.is_empty():
		return 1.0
	return intensity_multipliers[clampi(level, 0, intensity_multipliers.size() - 1)]
