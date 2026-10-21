class_name PowerUpDefinition
extends Resource
## One power-up type: what it does, how long it lasts, how often it drops and how
## it looks. The list lives in res://resources/game_balance/power_ups.tres.

enum Kind { RAPID_FIRE, DOUBLE_SHOT, TRIPLE_SHOT, PIERCING_LASER, SHIELD, REPAIR, SPEED_BOOST }

@export var kind: Kind = Kind.RAPID_FIRE
@export var display_name: String = "Rapid Fire"
## One or two characters drawn on the pickup.
@export var icon_text: String = "R"
@export var color: Color = Color(1, 0.8, 0.2, 1)
## Seconds the effect lasts; 0 for instant or until-used effects (repair, shield).
@export_range(0.0, 60.0, 0.5) var duration: float = 10.0
## Relative chance of being chosen when a drop happens.
@export_range(0.0, 100.0, 1.0) var drop_weight: float = 10.0


func is_weapon_upgrade() -> bool:
	return kind in [Kind.RAPID_FIRE, Kind.DOUBLE_SHOT, Kind.TRIPLE_SHOT, Kind.PIERCING_LASER]
