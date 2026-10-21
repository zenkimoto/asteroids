class_name ScreenShake
extends Camera2D
## Game camera centred on the playfield. add_trauma() makes it shake; trauma
## decays over time and the offset grows faster than it (trauma^1.5), so small
## hits give a gentle nudge and big explosions a short, strong jolt. Does nothing
## when the player has turned screen shake off.

@export_range(0.0, 60.0, 0.5) var max_offset: float = 18.0
@export_range(0.0, 0.2, 0.005) var max_roll: float = 0.012
## Trauma lost per second.
@export_range(0.1, 10.0, 0.1) var decay: float = 1.8
@export_range(1.0, 60.0, 1.0) var frequency: float = 22.0

var trauma: float = 0.0

var _noise := FastNoiseLite.new()
var _time: float = 0.0


func _ready() -> void:
	position = Playfield.get_center()
	# Camera2D ignores its own rotation by default; the roll needs it.
	ignore_rotation = false
	_noise.seed = randi()
	_noise.frequency = 1.0
	make_current()


func add_trauma(amount: float) -> void:
	if amount <= 0.0 or not SettingsManager.is_screen_shake_enabled():
		return
	trauma = minf(trauma + amount, 1.0)


func stop() -> void:
	trauma = 0.0
	offset = Vector2.ZERO
	rotation = 0.0


func _process(delta: float) -> void:
	if trauma <= 0.0:
		return
	trauma = maxf(trauma - decay * delta, 0.0)
	_time += delta * frequency
	var strength := pow(trauma, 1.5)
	offset = Vector2(_noise.get_noise_2d(_time, 0.0), _noise.get_noise_2d(0.0, _time)) * max_offset * strength
	rotation = _noise.get_noise_2d(_time, _time) * max_roll * strength
	if trauma == 0.0:
		stop()
