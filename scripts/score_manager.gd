extends Node
## Autoload "ScoreManager": the session's score and kill statistics, kept apart
## from the player and the scene. Resets itself when GameManager starts a session.

signal score_changed(score: int)

var score: int = 0
var asteroids_destroyed: int = 0


func _ready() -> void:
	GameManager.session_started.connect(reset)


func reset() -> void:
	score = 0
	asteroids_destroyed = 0
	score_changed.emit(score)


## Adds points; ignored outside active gameplay (menus, Game Over).
func add_points(points: int) -> void:
	if points <= 0 or not GameManager.is_gameplay_active():
		return
	score += points
	score_changed.emit(score)


func record_asteroid_destroyed(asteroid: Asteroid) -> void:
	if not GameManager.is_gameplay_active():
		return
	asteroids_destroyed += 1
	add_points(asteroid.size_settings.score)
