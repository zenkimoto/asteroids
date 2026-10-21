class_name GameEffects
extends Node2D
## Container and director for transient gameplay effects. The game scene wires
## gameplay signals to the on_* methods; each spawns particle bursts, shards or
## shockwaves as children here and nudges the camera and screen flash. Effects
## free themselves when done, are capped at `max_active_effects`, pause with the
## game and are cleared when a session starts.

@export var settings: EffectSettings
@export var camera: ScreenShake
@export var screen_flash: ScreenFlash
@export var player: Player

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	SettingsManager.setting_changed.connect(_on_setting_changed)
	_apply_intensity()


## Particle-count multiplier from the player's particle intensity setting.
func get_intensity() -> float:
	return settings.get_intensity(SettingsManager.get_particle_intensity())


func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if camera != null:
		camera.stop()
	if screen_flash != null:
		screen_flash.clear()


func on_asteroid_destroyed(asteroid: Asteroid) -> void:
	var size_factor := asteroid.get_radius() / 40.0
	var color := asteroid.variant_settings.outline_color
	_burst(settings.asteroid_debris, asteroid.global_position, color, size_factor)
	_add(ShardBurst.create(asteroid.get_outline(), asteroid.global_transform, color, 2.0,
			settings.shard_speed, settings.shard_lifetime, asteroid.velocity * 0.5, _rng))
	match asteroid.size:
		Asteroid.Size.LARGE:
			_add(Shockwave.create(asteroid.global_position, asteroid.get_radius() * 0.5,
					asteroid.get_radius() * 1.8, Color(color, 0.6), 5.0, 0.4))
			_shake(settings.shake_large_asteroid)
		Asteroid.Size.MEDIUM:
			_shake(settings.shake_medium_asteroid)


func on_ufo_destroyed(ufo: Ufo) -> void:
	var size_factor := ufo.get_radius() / 30.0
	var color := ufo.type_settings.outline_color
	_burst(settings.explosion_core, ufo.global_position, settings.explosion_color, size_factor)
	_burst(settings.explosion_sparks, ufo.global_position, color, size_factor)
	_add(ShardBurst.create(ufo.get_outline(), ufo.global_transform, color, 2.5,
			settings.shard_speed * 1.3, settings.shard_lifetime, ufo.velocity * 0.4, _rng))
	_add(Shockwave.create(ufo.global_position, ufo.get_radius() * 0.4, ufo.get_radius() * 3.0,
			Color(settings.explosion_color, 0.7), 7.0, 0.5))
	_shake(settings.shake_ufo)
	_flash(settings.explosion_color, settings.flash_ufo, 0.25)


func on_player_died() -> void:
	var at := player.global_position
	_burst(settings.explosion_core, at, settings.explosion_color, 1.6)
	_burst(settings.explosion_sparks, at, settings.ship_color, 1.6)
	_add(ShardBurst.create(player.get_outline(), player.global_transform, settings.ship_color, 2.5,
			settings.shard_speed * 1.5, settings.shard_lifetime * 1.4, Vector2.ZERO, _rng))
	_add(Shockwave.create(at, 10.0, 160.0, Color(settings.ship_color, 0.8), 8.0, 0.6))
	_shake(settings.shake_ship)
	_flash(Color.WHITE, settings.flash_ship, 0.35)


func on_shield_absorbed() -> void:
	var at := player.global_position
	_burst(settings.shield_break, at, settings.shield_color, 1.0)
	_add(Shockwave.create(at, player.shield_radius, player.shield_radius * 2.6,
			Color(settings.shield_color, 0.9), 6.0, 0.45))
	_shake(settings.shake_shield)


## Connected to each bolt's `hit`; `projectile` is bound when the bolt is fired.
func on_projectile_hit(_target: Node2D, projectile: Projectile) -> void:
	if not is_instance_valid(projectile):
		return
	var color := projectile.get_color()
	_burst(settings.projectile_impact, projectile.global_position, color, 1.0, projectile.rotation + PI)


func on_player_fired(projectile: Projectile) -> void:
	projectile.hit.connect(on_projectile_hit.bind(projectile))
	_burst(settings.muzzle_flash, projectile.global_position, projectile.get_color(), 0.6, projectile.rotation)


func on_ufo_spawned(ufo: Ufo) -> void:
	ufo.fired.connect(on_ufo_fired)


func on_ufo_fired(shot: EnemyProjectile) -> void:
	_burst(settings.muzzle_flash, shot.global_position, settings.enemy_fire_color, 0.9, shot.velocity.angle())


func on_pickup_collected(pickup: PowerUpPickup) -> void:
	var color := pickup.definition.color
	_burst(settings.pickup_sparkle, pickup.global_position, color, 1.0)
	_add(Shockwave.create(pickup.global_position, 12.0, 70.0, Color(color, 0.8), 4.0, 0.35))


func on_wave_started(_wave: int) -> void:
	var center := Playfield.get_center()
	var reach := Playfield.get_playfield_size().length() * 0.55
	_add(Shockwave.create(center, 40.0, reach, settings.wave_color, 10.0, 0.9))


func on_wave_completed(_wave: int, _bonus: int) -> void:
	_flash(settings.wave_color, settings.flash_wave_complete, 0.5)


func _burst(burst_settings: ParticleBurstSettings, at: Vector2, color: Color, size: float,
		angle: float = 0.0) -> void:
	if burst_settings == null:
		return
	_add(ParticleBurst.create(burst_settings, at, color, size, get_intensity(), angle))


## Adds an effect, first removing the oldest ones if the cap would be exceeded.
func _add(effect: Node2D) -> void:
	while get_child_count() >= settings.max_active_effects:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	add_child(effect)


func _shake(amount: float) -> void:
	if camera != null:
		camera.add_trauma(amount)


func _flash(color: Color, strength: float, duration: float) -> void:
	if screen_flash != null:
		screen_flash.flash(color, strength, duration)


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == SettingsManager.PARTICLE_INTENSITY:
		_apply_intensity()
	elif key == SettingsManager.SCREEN_SHAKE and camera != null and not SettingsManager.is_screen_shake_enabled():
		camera.stop()


## Persistent emitters (the ship's exhaust) follow the setting live.
func _apply_intensity() -> void:
	if player != null:
		player.set_particle_intensity(get_intensity())
