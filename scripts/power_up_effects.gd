class_name PowerUpEffects
extends Node
## Applies collected power-ups to the player and runs their timers, which pause
## with the game. Rules: only one weapon upgrade is active at a time and a new one
## replaces it; the shield and the speed boost coexist with any weapon upgrade;
## collecting an active timed power-up again refreshes its duration.

## Every collection; `had_effect` is false for a repair at full lives.
signal power_up_applied(definition: PowerUpDefinition, had_effect: bool)
## A lasting effect began or was refreshed (weapon upgrade, speed boost, shield).
signal effect_started(definition: PowerUpDefinition)
signal effect_ended(kind: PowerUpDefinition.Kind)

@export var settings: PowerUpSettings
@export var player: Player

## Seconds left for each active timed effect, by kind.
var _time_left: Dictionary = {}
var _weapon_kind: int = -1


func _ready() -> void:
	player.shield_changed.connect(_on_shield_changed)
	player.died.connect(_on_player_died)


func apply(definition: PowerUpDefinition) -> void:
	var had_effect := true
	match definition.kind:
		PowerUpDefinition.Kind.REPAIR:
			had_effect = GameManager.add_life()
		PowerUpDefinition.Kind.SHIELD:
			player.shield_grace_time = settings.shield_grace_time
			player.set_shield(true)
			effect_started.emit(definition)
		PowerUpDefinition.Kind.SPEED_BOOST:
			_time_left[definition.kind] = definition.duration
			player.acceleration_multiplier = settings.speed_boost_acceleration_multiplier
			player.max_speed_multiplier = settings.speed_boost_max_speed_multiplier
			effect_started.emit(definition)
		_:
			if _weapon_kind != -1 and _weapon_kind != definition.kind:
				_end_effect(_weapon_kind)
			_weapon_kind = definition.kind
			_time_left[definition.kind] = definition.duration
			_apply_weapon_upgrade(definition.kind)
			effect_started.emit(definition)
	power_up_applied.emit(definition, had_effect)


func is_active(kind: PowerUpDefinition.Kind) -> bool:
	if kind == PowerUpDefinition.Kind.SHIELD:
		return player.has_shield
	return _time_left.has(kind)


func get_time_left(kind: PowerUpDefinition.Kind) -> float:
	return _time_left.get(kind, 0.0)


## The active weapon upgrade's kind, or -1 for the basic laser.
func get_weapon_upgrade() -> int:
	return _weapon_kind


## Ends every effect, e.g. on restart.
func clear() -> void:
	for kind in _time_left.keys():
		_end_effect(kind)
	player.set_shield(false)


func _physics_process(delta: float) -> void:
	for kind in _time_left.keys():
		_time_left[kind] -= delta
		if _time_left[kind] <= 0.0:
			_end_effect(kind)


func _apply_weapon_upgrade(kind: PowerUpDefinition.Kind) -> void:
	var weapon := player.weapon
	weapon.clear_modifiers()
	match kind:
		PowerUpDefinition.Kind.RAPID_FIRE:
			weapon.cooldown_multiplier = settings.rapid_fire_cooldown_multiplier
		PowerUpDefinition.Kind.DOUBLE_SHOT:
			weapon.shot_count = 2
			weapon.spread_degrees = settings.double_shot_spread
		PowerUpDefinition.Kind.TRIPLE_SHOT:
			weapon.shot_count = 3
			weapon.spread_degrees = settings.triple_shot_spread
		PowerUpDefinition.Kind.PIERCING_LASER:
			weapon.pierce_count = settings.piercing_extra_targets


func _end_effect(kind: PowerUpDefinition.Kind) -> void:
	_time_left.erase(kind)
	if kind == PowerUpDefinition.Kind.SPEED_BOOST:
		player.acceleration_multiplier = 1.0
		player.max_speed_multiplier = 1.0
	elif kind == _weapon_kind:
		player.weapon.clear_modifiers()
		_weapon_kind = -1
	effect_ended.emit(kind)


## The shield reports its own end (absorbed hit or cleared) through the player.
func _on_shield_changed(active: bool) -> void:
	if not active:
		effect_ended.emit(PowerUpDefinition.Kind.SHIELD)


func _on_player_died() -> void:
	if settings.clear_effects_on_death:
		clear()
