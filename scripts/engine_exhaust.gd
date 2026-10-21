class_name EngineExhaust
extends GPUParticles2D
## Continuous engine particles. Particles are left behind in world space, so
## the plume bends with the ship's turns and stretches with its speed.
## set_throttle() controls how much it emits; set_intensity() applies the
## particle intensity setting.

@export var settings: ParticleBurstSettings

var _intensity: float = 1.0


func _ready() -> void:
	one_shot = false
	explosiveness = 0.0
	local_coords = false
	texture = ParticleBurst.get_dot_texture()
	material = ParticleBurst.get_additive_material()
	visibility_rect = Rect2(-800.0, -800.0, 1600.0, 1600.0)
	if settings != null:
		process_material = settings.get_material()
		lifetime = settings.lifetime
	_apply_amount()
	emitting = false


## `amount` 0-1 is the share of particles emitted; 0 stops emission (existing
## particles finish their life).
func set_throttle(throttle: float) -> void:
	var clamped := clampf(throttle, 0.0, 1.0)
	amount_ratio = maxf(clamped, 0.05)
	var should_emit := clamped > 0.0
	if emitting != should_emit:
		emitting = should_emit


func set_intensity(intensity: float) -> void:
	if is_equal_approx(intensity, _intensity):
		return
	_intensity = intensity
	_apply_amount()


## Removes particles still on screen (death, respawn).
func reset() -> void:
	emitting = false
	restart()
	emitting = false


func _apply_amount() -> void:
	if settings != null:
		amount = settings.get_amount(_intensity)
