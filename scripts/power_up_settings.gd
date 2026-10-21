class_name PowerUpSettings
extends Resource
## Power-up balance: drop chances, pickup lifetime and the strength of each
## effect. Edit res://resources/game_balance/power_ups.tres.

@export var definitions: Array[PowerUpDefinition] = []

@export_group("Drops")
## Chance that a destroyed asteroid (any size) drops a power-up.
@export_range(0.0, 1.0, 0.005) var asteroid_drop_chance: float = 0.03
## Chance that a destroyed UFO drops a power-up.
@export_range(0.0, 1.0, 0.01) var ufo_drop_chance: float = 0.3
## Performance and balance limit on uncollected pickups.
@export_range(1, 20) var max_active_pickups: int = 4

@export_group("Pickups")
## Uncollected pickups vanish after this many seconds.
@export_range(1.0, 60.0, 0.5) var pickup_lifetime: float = 10.0
## Pickups blink for this many seconds before vanishing.
@export_range(0.0, 10.0, 0.5) var pickup_warning_time: float = 3.0
@export_range(0.0, 200.0, 5.0) var pickup_drift_speed: float = 30.0

@export_group("Effects")
## Fire cooldown multiplier while Rapid Fire is active.
@export_range(0.1, 1.0, 0.05) var rapid_fire_cooldown_multiplier: float = 0.45
## Degrees between neighbouring bolts.
@export_range(0.0, 45.0, 0.5) var double_shot_spread: float = 6.0
@export_range(0.0, 45.0, 0.5) var triple_shot_spread: float = 12.0
## Extra asteroids each Piercing Laser bolt passes through after its first hit.
@export_range(1, 20) var piercing_extra_targets: int = 3
@export_range(1.0, 3.0, 0.05) var speed_boost_acceleration_multiplier: float = 1.4
@export_range(1.0, 3.0, 0.05) var speed_boost_max_speed_multiplier: float = 1.3
## Invulnerability after the shield absorbs a hit, so one overlap can't hit twice.
@export_range(0.0, 5.0, 0.1) var shield_grace_time: float = 1.0
## Losing a life ends active weapon upgrades and the speed boost.
@export var clear_effects_on_death: bool = true


func get_definition(kind: PowerUpDefinition.Kind) -> PowerUpDefinition:
	for definition in definitions:
		if definition.kind == kind:
			return definition
	return null


## A weighted random definition. Repair is left out when `allow_repair` is false
## (lives are full). Returns null if nothing can drop.
func pick_random(rng: RandomNumberGenerator, allow_repair: bool) -> PowerUpDefinition:
	var total := 0.0
	for definition in definitions:
		if _can_drop(definition, allow_repair):
			total += definition.drop_weight
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for definition in definitions:
		if not _can_drop(definition, allow_repair):
			continue
		roll -= definition.drop_weight
		if roll < 0.0:
			return definition
	return null


func _can_drop(definition: PowerUpDefinition, allow_repair: bool) -> bool:
	return definition.drop_weight > 0.0 and (allow_repair or definition.kind != PowerUpDefinition.Kind.REPAIR)
