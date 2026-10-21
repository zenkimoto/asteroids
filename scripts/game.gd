class_name Game
extends Node2D
## Runs one play session: score, lives, respawning, field refills and game over.

signal score_changed(score: int)
signal lives_changed(lives: int)
signal game_over(final_score: int)

@export var rules: GameRules

var score: int = 0
var lives: int = 0
var is_game_over: bool = false

@onready var player: Player = $Player
@onready var asteroid_field: AsteroidField = $AsteroidField
@onready var hud: Hud = $Hud
@onready var game_over_screen: GameOverScreen = $GameOverScreen


func _ready() -> void:
	player.weapon.projectile_parent = $Projectiles
	score_changed.connect(hud.set_score)
	lives_changed.connect(hud.set_lives)
	player.died.connect(_on_player_died)
	asteroid_field.asteroid_destroyed.connect(_on_asteroid_destroyed)
	asteroid_field.field_cleared.connect(_on_field_cleared)
	game_over_screen.restart_requested.connect(restart)
	start_session()


func start_session() -> void:
	score = 0
	lives = rules.starting_lives
	is_game_over = false
	score_changed.emit(score)
	lives_changed.emit(lives)
	player.controls_enabled = true
	player.respawn(Playfield.get_center(), rules.invulnerability_duration)
	asteroid_field.spawn_field(rules.asteroids_per_field)


## Reloads the scene, which resets every session value and removes all objects.
func restart() -> void:
	get_tree().reload_current_scene()


func add_score(points: int) -> void:
	if is_game_over:
		return
	score += points
	score_changed.emit(score)


func _on_asteroid_destroyed(asteroid: Asteroid) -> void:
	add_score(asteroid.size_settings.score)


func _on_player_died() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		is_game_over = true
		# Timers connected to methods are dropped automatically if the game is freed.
		get_tree().create_timer(rules.game_over_delay).timeout.connect(_show_game_over)
	else:
		get_tree().create_timer(rules.respawn_delay).timeout.connect(_respawn_player)


func _respawn_player() -> void:
	player.respawn(_find_respawn_point(), rules.invulnerability_duration)


## The center if it is clear of asteroids, otherwise the clearest random spot.
func _find_respawn_point() -> Vector2:
	var center := Playfield.get_center()
	if asteroid_field.is_area_clear(center, rules.respawn_clear_radius):
		return center
	var best := center
	for i in 40:
		var candidate := asteroid_field.find_clear_position(center, 0.0, 1)
		if asteroid_field.is_area_clear(candidate, rules.respawn_clear_radius):
			return candidate
		best = candidate
	# Nowhere is fully clear; invulnerability covers the landing.
	return best


func _show_game_over() -> void:
	player.controls_enabled = false
	game_over.emit(score)
	game_over_screen.show_results(score)


func _on_field_cleared() -> void:
	if is_game_over:
		return
	get_tree().create_timer(rules.field_refill_delay).timeout.connect(_refill_field)


func _refill_field() -> void:
	if not is_game_over:
		asteroid_field.spawn_field(rules.asteroids_per_field)
