class_name InputActions
extends RefCounted
## Names of the input actions configured in project.godot (Project Settings > Input Map).
## Gameplay code should use these constants rather than raw strings.

const THRUST_FORWARD: StringName = &"thrust_forward"
const THRUST_REVERSE: StringName = &"thrust_reverse"
const ROTATE_LEFT: StringName = &"rotate_left"
const ROTATE_RIGHT: StringName = &"rotate_right"
const FIRE: StringName = &"fire"
const BOOST: StringName = &"boost"
const PAUSE: StringName = &"pause"

const ALL: Array[StringName] = [
	THRUST_FORWARD,
	THRUST_REVERSE,
	ROTATE_LEFT,
	ROTATE_RIGHT,
	FIRE,
	BOOST,
	PAUSE,
]


## Returns every action in ALL that is missing from the InputMap.
static func missing_actions() -> Array[StringName]:
	var missing: Array[StringName] = []
	for action in ALL:
		if not InputMap.has_action(action):
			missing.append(action)
	return missing
