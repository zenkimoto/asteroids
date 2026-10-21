class_name WrappingEntity
extends GameEntity
## A GameEntity that wraps around the playfield edges: asteroids, player shots
## and UFO shots (and later power-ups).

## Distance past the screen edge before wrapping; usually the entity's radius.
var wrap_margin: float = 0.0


func _after_move() -> void:
	position = ScreenWrap.wrap_position(position, Playfield.get_playfield_rect(), wrap_margin)
