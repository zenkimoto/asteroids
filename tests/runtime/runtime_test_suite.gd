class_name RuntimeTestSuite
extends RefCounted
## Base for test suites run by RuntimeTestRunner. Every method whose name starts
## with "test_" is a test; it may await. Checks record failures instead of
## stopping, so one run reports every broken expectation.

var runner: RuntimeTestRunner
var failures: PackedStringArray = []
## Measurements a test wants printed under its result.
var notes: PackedStringArray = []

var game: Game:
	get:
		return runner.game


func suite_name() -> String:
	return "unnamed"


## Whether each test needs a fresh gameplay scene.
func uses_game() -> bool:
	return true


func get_test_names() -> PackedStringArray:
	var names := PackedStringArray()
	for method in get_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_") and not names.has(method_name):
			names.append(method_name)
	return names


func begin_test() -> void:
	failures.clear()
	notes.clear()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func check_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s (expected %.3f +/- %.3f, got %.3f)" % [message, expected, tolerance, actual])


func note(text: String) -> void:
	notes.append(text)


## Waits for a condition (see RuntimeTestRunner.wait_until) and records a
## failure with `message` if it never comes true.
func expect_eventually(condition: Callable, message: String, time_scale: float = 1.0, limit: float = 10.0) -> bool:
	var ok: bool = await runner.wait_until(condition, time_scale, limit)
	check(ok, message + " (timed out)")
	return ok


# ----- shared setup helpers -----

func rules() -> GameRules:
	return GameManager.balance.rules


## A started wave with an empty playfield and the ship centred and vulnerable.
func start_empty_wave() -> void:
	await runner.skip_countdown()
	await runner.clear_world()
	game.player.global_position = Playfield.get_center()
	game.player.velocity = Vector2.ZERO
	game.player.invulnerable_time_left = 0.0


func spawn_asteroid(at: Vector2, size: Asteroid.Size = Asteroid.Size.LARGE,
		variant: Asteroid.Variant = Asteroid.Variant.STANDARD, velocity: Vector2 = Vector2.ZERO) -> Asteroid:
	return game.asteroid_field.spawn_asteroid(size, variant, at, velocity)


func count_asteroids(size: Asteroid.Size) -> int:
	var count := 0
	for asteroid in game.asteroid_field.get_asteroids():
		if asteroid.size == size:
			count += 1
	return count


## A UFO placed at `at` (it still moves on its own).
func spawn_ufo(at: Vector2, type: Ufo.Type = Ufo.Type.LARGE) -> Ufo:
	var ufo := game.ufo_fleet.spawn_ufo(type)
	ufo.position = at
	return ufo


func launch_bolt(from: Vector2, direction: Vector2, pierce: int = 0) -> Projectile:
	var bolt := game.player.weapon.projectile_scene.instantiate() as Projectile
	game.projectiles.add_child(bolt)
	bolt.launch(from, direction, Vector2.ZERO, game.player.weapon.settings, pierce)
	return bolt


func spawn_enemy_shot(at: Vector2, direction: Vector2, speed: float, lifetime: float = 5.0) -> EnemyProjectile:
	var scene := game.ufo_fleet.large_ufo_scene.instantiate() as Ufo
	var shot_scene := scene.projectile_scene
	scene.free()
	return game.enemy_projectiles.spawn(shot_scene, func(node: Node) -> void:
		(node as EnemyProjectile).setup(at, direction, speed, lifetime)
	) as EnemyProjectile


func power_up(kind: PowerUpDefinition.Kind) -> PowerUpDefinition:
	return GameManager.balance.power_ups.get_definition(kind)
