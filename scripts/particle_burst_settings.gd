class_name ParticleBurstSettings
extends Resource
## One kind of particle burst (debris, sparks, explosion core...): how many
## particles, how they fly and how they fade. The particle colour comes from
## the burst's tint; the ramp here only controls brightness and fade.

## Particles at High intensity; Low and Medium scale this down.
@export_range(1, 200) var amount: int = 16
@export_range(0.05, 5.0, 0.05) var lifetime: float = 0.6
## Share of particles released at once (1 = a single burst).
@export_range(0.0, 1.0, 0.05) var explosiveness: float = 1.0
@export var direction: Vector2 = Vector2.RIGHT
@export_range(0.0, 180.0, 1.0) var spread_degrees: float = 180.0
@export_range(0.0, 2000.0, 5.0) var speed_min: float = 80.0
@export_range(0.0, 2000.0, 5.0) var speed_max: float = 220.0
## Speed lost per second, so debris slows down instead of flying off-screen.
@export_range(0.0, 2000.0, 5.0) var damping: float = 120.0
## Particle size as a multiple of the 32 px soft-dot texture.
@export_range(0.01, 4.0, 0.01) var scale_min: float = 0.15
@export_range(0.01, 4.0, 0.01) var scale_max: float = 0.35
@export_range(0.0, 200.0, 1.0) var emission_radius: float = 4.0
## Brightness at the start; above 1 makes additive particles glow.
@export_range(0.0, 4.0, 0.05) var start_brightness: float = 1.0

var _material: ParticleProcessMaterial


## Particle count for an intensity multiplier (0-1), never below one.
func get_amount(intensity: float) -> int:
	return maxi(1, roundi(amount * intensity))


## Shared process material, built once from the values above.
func get_material() -> ParticleProcessMaterial:
	if _material == null:
		_material = _build_material()
	return _material


func _build_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.direction = Vector3(direction.x, direction.y, 0.0)
	material.spread = spread_degrees
	material.initial_velocity_min = speed_min
	material.initial_velocity_max = speed_max
	material.gravity = Vector3.ZERO
	material.damping_min = damping
	material.damping_max = damping
	material.scale_min = scale_min
	material.scale_max = scale_max
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = emission_radius
	var ramp := Gradient.new()
	ramp.set_color(0, Color(start_brightness, start_brightness, start_brightness, 1.0))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	material.color_ramp = ramp_texture
	# Particles shrink as they fade.
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.25))
	var shrink_texture := CurveTexture.new()
	shrink_texture.curve = shrink
	material.scale_curve = shrink_texture
	return material
