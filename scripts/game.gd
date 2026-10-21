class_name Game
extends Node2D
## Gameplay scene. Applies the balance configuration, wires gameplay objects to
## GameManager and ScoreManager, and builds or clears the world for each session.
## It holds no score or game state of its own.

@onready var player: Player = $Player
@onready var asteroid_field: AsteroidField = $AsteroidField
@onready var projectiles: EntityContainer = $Projectiles
@onready var timers: TimerScheduler = $Timers
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
	asteroid_field.field_cleared.connect(_on_field_cleared)
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


func _rules() -> GameRules:
	return GameManager.balance.rules


## Clears everything left from the previous session, then builds the new one.
func _on_session_started() -> void:
	timers.cancel_all()
	projectiles.clear()
	asteroid_field.clear()
	player.respawn(Playfield.get_center(), _rules().invulnerability_duration)
	asteroid_field.spawn_field(_rules().asteroids_per_field)


func _on_state_changed(_previous: int, current: int) -> void:
	player.controls_enabled = current == GameManager.State.PLAYING \
			or current == GameManager.State.WAVE_TRANSITION
	pause_overlay.visible = current == GameManager.State.PAUSED
	if current == GameManager.State.PAUSED:
		pause_overlay.focus_default()
	if current == GameManager.State.GAME_OVER:
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


func _on_field_cleared() -> void:
	if GameManager.begin_wave_transition():
		timers.schedule(_rules().field_refill_delay, _refill_field)


func _refill_field() -> void:
	asteroid_field.spawn_field(_rules().asteroids_per_field)
	GameManager.end_wave_transition()
