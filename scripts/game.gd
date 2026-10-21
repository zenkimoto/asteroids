class_name Game
extends Node2D
## Gameplay scene. Applies the balance configuration, wires gameplay objects to
## GameManager and ScoreManager, and builds or clears the world for each session.
## It holds no score or game state of its own.

@onready var player: Player = $Player
@onready var asteroid_field: AsteroidField = $AsteroidField
@onready var projectiles: EntityContainer = $Projectiles
@onready var ufo_fleet: UfoFleet = $UfoFleet
@onready var enemy_projectiles: EntityContainer = $EnemyProjectiles
@onready var power_ups: PowerUpSpawner = $PowerUps
@onready var power_up_effects: PowerUpEffects = $PowerUpEffects
@onready var timers: TimerScheduler = $Timers
@onready var wave_manager: WaveManager = $WaveManager
@onready var wave_announcer: WaveAnnouncer = $WaveAnnouncer
@onready var hud: Hud = $Hud
@onready var pause_overlay: PauseOverlay = $PauseOverlay
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var effects: GameEffects = $Effects
@onready var audio: GameAudio = $Audio

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_apply_balance(GameManager.balance)
	player.weapon.projectile_parent = projectiles
	# Every connection is made once here; restarts reuse them.
	player.died.connect(_on_player_died)
	player.died.connect(ScoreManager.reset_combo)
	asteroid_field.asteroid_destroyed.connect(ScoreManager.record_asteroid_destroyed)
	asteroid_field.asteroid_destroyed.connect(power_ups.drop_from_asteroid)
	ufo_fleet.ufo_destroyed.connect(ScoreManager.record_ufo_destroyed)
	ufo_fleet.ufo_destroyed.connect(power_ups.drop_from_ufo)
	power_ups.collected.connect(power_up_effects.apply)
	_connect_effects()
	_connect_audio()
	power_up_effects.power_up_applied.connect(hud.on_power_up_applied)
	power_up_effects.effect_started.connect(hud.on_effect_started)
	power_up_effects.effect_ended.connect(hud.on_effect_ended)
	hud.effects = power_up_effects
	wave_manager.countdown_started.connect(hud.set_wave)
	wave_manager.countdown_ticked.connect(wave_announcer.show_countdown)
	wave_manager.wave_started.connect(wave_announcer.show_wave_started)
	wave_manager.wave_started.connect(ScoreManager.record_wave_reached)
	wave_manager.wave_completed.connect(wave_announcer.show_wave_complete)
	wave_manager.wave_completed.connect(ScoreManager.record_wave_completed)
	ScoreManager.score_changed.connect(hud.set_score)
	ScoreManager.combo_changed.connect(hud.set_combo)
	ScoreManager.multiplier_increased.connect(hud.on_multiplier_increased)
	ScoreManager.extra_life_awarded.connect(hud.on_extra_life_awarded)
	GameManager.lives_changed.connect(hud.set_lives)
	GameManager.session_started.connect(_on_session_started)
	GameManager.state_changed.connect(_on_state_changed)
	pause_overlay.resume_requested.connect(GameManager.resume)
	pause_overlay.restart_requested.connect(GameManager.start_session)
	pause_overlay.main_menu_requested.connect(GameManager.open_main_menu)
	pause_overlay.quit_requested.connect(GameManager.quit_game)
	game_over_screen.restart_requested.connect(GameManager.start_session)
	game_over_screen.main_menu_requested.connect(GameManager.open_main_menu)
	game_over_screen.quit_requested.connect(GameManager.quit_game)
	GameManager.start_session()


## Visual feedback for gameplay events; effects never change game state.
func _connect_effects() -> void:
	asteroid_field.asteroid_destroyed.connect(effects.on_asteroid_destroyed)
	ufo_fleet.ufo_destroyed.connect(effects.on_ufo_destroyed)
	ufo_fleet.ufo_spawned.connect(effects.on_ufo_spawned)
	player.weapon.fired.connect(effects.on_player_fired)
	player.died.connect(effects.on_player_died)
	player.shield_absorbed.connect(effects.on_shield_absorbed)
	power_ups.pickup_collected.connect(effects.on_pickup_collected)
	wave_manager.wave_started.connect(effects.on_wave_started)
	wave_manager.wave_completed.connect(effects.on_wave_completed)


## Sound for gameplay events; like effects, audio never changes game state.
func _connect_audio() -> void:
	player.weapon.fired.connect(audio.on_player_fired)
	player.died.connect(audio.on_player_died)
	player.boost_started.connect(audio.on_boost_started)
	player.shield_absorbed.connect(audio.on_shield_absorbed)
	asteroid_field.asteroid_destroyed.connect(audio.on_asteroid_destroyed)
	ufo_fleet.ufo_spawned.connect(audio.on_ufo_spawned)
	ufo_fleet.ufo_destroyed.connect(audio.on_ufo_destroyed)
	power_ups.pickup_collected.connect(audio.on_pickup_collected)
	wave_manager.wave_started.connect(audio.on_wave_started)
	wave_manager.wave_completed.connect(audio.on_wave_completed)
	ScoreManager.extra_life_awarded.connect(audio.on_extra_life_awarded)


func _exit_tree() -> void:
	if is_instance_valid(GameManager):
		GameManager.end_session()


func _apply_balance(balance: GameBalance) -> void:
	player.settings = balance.player_movement
	player.weapon.settings = balance.weapon
	asteroid_field.settings = balance.asteroids
	wave_manager.settings = balance.waves
	ufo_fleet.settings = balance.ufos
	power_ups.settings = balance.power_ups
	power_up_effects.settings = balance.power_ups


func _rules() -> GameRules:
	return GameManager.balance.rules


## Clears everything left from the previous session, then starts Wave 1's countdown.
func _on_session_started() -> void:
	timers.cancel_all()
	projectiles.clear()
	enemy_projectiles.clear()
	ufo_fleet.clear()
	asteroid_field.clear()
	power_ups.clear()
	power_up_effects.clear()
	effects.clear()
	wave_announcer.hide_now()
	hud.set_best(SaveManager.leaderboard.get_best_score())
	player.respawn(Playfield.get_center(), _rules().invulnerability_duration)
	wave_manager.start()


func _on_state_changed(_previous: int, current: int) -> void:
	player.controls_enabled = current == GameManager.State.PLAYING \
			or current == GameManager.State.WAVE_TRANSITION
	if current == GameManager.State.PAUSED:
		pause_overlay.show_menu()
	else:
		pause_overlay.hide_menu()
	if current == GameManager.State.GAME_OVER:
		wave_announcer.hide_now()
		game_over_screen.show_results(ScoreManager.get_summary())
	else:
		game_over_screen.hide_results()


func _on_player_died() -> void:
	if GameManager.register_player_death():
		timers.schedule(_rules().respawn_delay, _respawn_player)


func _respawn_player() -> void:
	var hazards: Array = []
	hazards.append_array(asteroid_field.get_asteroids())
	hazards.append_array(ufo_fleet.get_ufos())
	hazards.append_array(enemy_projectiles.get_live_entities())
	var at := SpawnUtils.find_clear_point(
			_rng,
			hazards,
			_rules().respawn_clear_radius,
			Playfield.get_playfield_rect(),
			Playfield.get_center()
	)
	player.respawn(at, _rules().invulnerability_duration)
