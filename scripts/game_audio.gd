class_name GameAudio
extends Node
## Sound for gameplay events. The game scene wires gameplay signals to the on_*
## methods, which play effects through AudioManager and raise the music's
## intensity on later waves. Like GameEffects, it never changes game state.

## Pitch of the explosion for each asteroid size: big rocks boom low, small ones crack.
@export var asteroid_pitch_large: float = 0.75
@export var asteroid_pitch_medium: float = 1.0
@export var asteroid_pitch_small: float = 1.35
## Pitch of the laser while the piercing upgrade is active.
@export var piercing_laser_pitch: float = 0.8


func _ready() -> void:
	GameManager.state_changed.connect(_on_game_state_changed)


func on_player_fired(projectile: Projectile) -> void:
	AudioManager.play(&"laser", piercing_laser_pitch if projectile.pierce_left > 0 else 1.0)


func on_asteroid_destroyed(asteroid: Asteroid) -> void:
	var pitch := asteroid_pitch_medium
	match asteroid.size:
		Asteroid.Size.LARGE:
			pitch = asteroid_pitch_large
		Asteroid.Size.SMALL:
			pitch = asteroid_pitch_small
	AudioManager.play(&"asteroid_explode", pitch)


func on_ufo_spawned(ufo: Ufo) -> void:
	ufo.fired.connect(on_ufo_fired)
	ufo.damaged.connect(on_ufo_damaged)


func on_ufo_fired(_shot: EnemyProjectile) -> void:
	AudioManager.play(&"enemy_laser")


func on_ufo_damaged(_ufo: Ufo, _hit_points_left: int) -> void:
	AudioManager.play(&"shield_hit", 1.6, -6.0)


func on_ufo_destroyed(_ufo: Ufo) -> void:
	AudioManager.play(&"ufo_explode")


func on_player_died() -> void:
	AudioManager.play(&"player_explode")


func on_boost_started() -> void:
	AudioManager.play(&"boost")


func on_pickup_collected(_pickup: PowerUpPickup) -> void:
	AudioManager.play(&"pickup")


func on_shield_absorbed() -> void:
	AudioManager.play(&"shield_hit")


func on_extra_life_awarded(_lives: int) -> void:
	AudioManager.play(&"extra_life")


func on_wave_started(wave: int) -> void:
	AudioManager.play(&"wave_start")
	AudioManager.set_music_intensity(AudioManager.library.get_intensity_for_wave(wave))


func on_wave_completed(_wave: int, _bonus: int) -> void:
	AudioManager.play(&"wave_complete")


func _on_game_state_changed(_previous: int, current: int) -> void:
	if current == GameManager.State.GAME_OVER:
		AudioManager.play(&"game_over")
