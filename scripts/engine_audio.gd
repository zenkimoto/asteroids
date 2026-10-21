class_name EngineAudio
extends AudioStreamPlayer
## The ship's looping engine rumble. Its volume and pitch glide toward a level
## set by the thrust state: louder and higher while boosting, quieter and lower
## in reverse, silent (and stopped) when coasting.

@export_range(-40.0, 6.0, 0.5) var thrust_db: float = -9.0
@export_range(-40.0, 6.0, 0.5) var boost_db: float = -4.0
@export_range(-40.0, 6.0, 0.5) var reverse_db: float = -15.0
@export_range(0.25, 3.0, 0.05) var thrust_pitch: float = 1.0
@export_range(0.25, 3.0, 0.05) var boost_pitch: float = 1.35
@export_range(0.25, 3.0, 0.05) var reverse_pitch: float = 0.8
## How quickly volume and pitch follow the throttle (higher = snappier).
@export_range(1.0, 40.0, 0.5) var response: float = 10.0

const SILENT: float = 0.002

var _level: float = 0.0
var _target_level: float = 0.0
var _target_pitch: float = 1.0


## `forward` and `reverse` are 0-1 throttle amounts.
func set_thrust(forward: float, reverse: float, boosting: bool) -> void:
	if boosting:
		_target_level = db_to_linear(boost_db)
		_target_pitch = boost_pitch
	elif forward > 0.0:
		_target_level = db_to_linear(thrust_db) * clampf(forward, 0.0, 1.0)
		_target_pitch = lerpf(0.85, 1.0, forward) * thrust_pitch
	elif reverse > 0.0:
		_target_level = db_to_linear(reverse_db) * clampf(reverse, 0.0, 1.0)
		_target_pitch = reverse_pitch
	else:
		_target_level = 0.0


## Cuts the sound at once (death, respawn).
func silence() -> void:
	_level = 0.0
	_target_level = 0.0
	stop()


func _process(delta: float) -> void:
	var blend := 1.0 - exp(-response * delta)
	_level = lerpf(_level, _target_level, blend)
	pitch_scale = maxf(lerpf(pitch_scale, _target_pitch, blend), 0.05)
	if _target_level <= 0.0 and _level < SILENT:
		if playing:
			stop()
		return
	if not playing:
		play()
	volume_db = linear_to_db(maxf(_level, 0.0001))
