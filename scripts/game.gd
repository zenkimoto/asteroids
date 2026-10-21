class_name Game
extends Node2D
## Gameplay scene. Applies the balance configuration, wires gameplay objects to
## GameManager and ScoreManager, and builds or clears the world for each session.
## It holds no score or game state of its own.

@onready var player: Player = $Player
@onready var asteroid_field: AsteroidField = $AsteroidField
@onready var projectiles: EntityContainer = $Projectiles
@onready var timers: TimerScheduler = $Timers
@onready var wave_manager: WaveManager = $WaveManager
@onready var wave_announcer: WaveAnnouncer = $WaveAnnouncer
@onready var hud: Hud = $Hud
@onready var pause_overlay: PauseOverlay = $PauseOverlay
@onready var game_over_screen: GameOverScreen = $GameOverScreen

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_apply_balance(GameManager.balance)
	player.weapon.projectile_parent = projectiles
	# Every connection is made once here; restarts reuse them.
	player.died.connect(_on_player_died)
	asteroid_field.asteroid_destroyed.connect(ScoreManager.record_asteroid_destroyed)
	wave_manager.countdown_started.connect(hud.set_wave)
	wave_manager.countdown_ticked.connect(wave_announcer.show_countdown)
	wave_manager.wave_started.connect(wave_announcer.show_wave_started)
	wave_manager.wave_completed.connect(wave_announcer.show_wave_complete)
	wave_manager.wave_completed.connect(ScoreManager.record_wave_completed)
	ScoreManager.score_changed.connect(hud.set_score)
	GameManager.lives_changed.connect(hud.set_lives)
	GameManager.session_started.connect(_on_session_started)
	GameManager.state_changed.connect(_on_state_changed)
	pause_overlay.resume_requested.connect(GameManager.resume)
	pause_overlay.restart_requested.connect(GameManager.start_session)
	game_over_screen.restart_requested.connect(GameManager.start_session)
	GameManager.start_session()


func _exit_tree() -> void:
	if is_instance_valid(GameManager):
		GameManager.end_session()


func _apply_balance(balance: GameBalance) -> void:
	player.settings = balance.player_movement
	player.weapon.settings = balance.weapon
	asteroid_field.settings = balance.asteroids
	wave_manager.settings = balance.waves


func _rules() -> GameRules:
	return GameManager.balance.rules


## Clears everything left from the previous session, then starts Wave 1's countdown.
func _on_session_started() -> void:
	timers.cancel_all()
	projectiles.clear()
	asteroid_field.clear()
	wave_announcer.hide_now()
	player.respawn(Playfield.get_center(), _rules().invulnerability_duration)
	wave_manager.start()


func _on_state_changed(_previous: int, current: int) -> void:
	player.controls_enabled = current == GameManager.State.PLAYING \
			or current == GameManager.State.WAVE_TRANSITION
	pause_overlay.visible = current == GameManager.State.PAUSED
	if current == GameManager.State.PAUSED:
		pause_overlay.focus_default()
	if current == GameManager.State.GAME_OVER:
		wave_announcer.hide_now()
		game_over_screen.show_results(ScoreManager.score)
	else:
		game_over_screen.hide_results()


func _on_player_died() -> void:
	if GameManager.register_player_death():
		timers.schedule(_rules().respawn_delay, _respawn_player)


func _respawn_player() -> void:
	var at := SpawnUtils.find_clear_point(
			_rng,
			asteroid_field.get_asteroids(),
			_rules().respawn_clear_radius,
			Playfield.get_playfield_rect(),
			Playfield.get_center()
	)
	player.respawn(at, _rules().invulnerability_duration)
