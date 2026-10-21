@tool
extends McpTestSuite
## Editor-side checks that the balance resources load and hold sensible,
## consistent values, so a tuning edit can't quietly break the game. The
## per-wave formulas run in tests/runtime/balance_tests.gd, because the
## settings scripts only execute inside the running game.

const BALANCE_PATH: String = "res://resources/game_balance/game_balance.tres"

var _balance: GameBalance


func suite_name() -> String:
	return "balance"


func suite_setup(_ctx: Dictionary) -> void:
	_balance = load(BALANCE_PATH) as GameBalance
	if _balance == null:
		fail_setup("%s did not load as a GameBalance" % BALANCE_PATH)


func test_every_section_is_assigned() -> void:
	for section in ["rules", "player_movement", "weapon", "asteroids", "waves", "ufos", "power_ups", "scoring"]:
		assert_true(_balance.get(section) != null, "%s is assigned" % section)


func test_lives_rules() -> void:
	var rules := _balance.rules
	assert_gt(rules.starting_lives, 0, "the game starts with lives")
	assert_true(rules.max_lives >= rules.starting_lives, "the cap is at least the starting lives")
	assert_true(rules.invulnerability_duration > 0.5, "respawn protection lasts long enough to react")
	assert_true(rules.respawn_clear_radius < _balance.asteroids.spawn_safe_radius + 1.0,
			"respawn clearance is achievable on a busy field")


func test_projectiles_reach_across_the_screen() -> void:
	var weapon := _balance.weapon
	var reach := weapon.projectile_speed * weapon.projectile_lifetime
	assert_true(reach > 600.0, "bolts travel a useful distance (%.0f px)" % reach)
	assert_true(reach < 1920.0, "bolts don't wrap back onto the ship (%.0f px)" % reach)
	# Bolts inherit part of the ship's velocity, so compare ground speeds.
	var top_speed := _balance.player_movement.max_speed * _balance.player_movement.boost_max_speed_multiplier
	assert_true(weapon.projectile_speed + top_speed * weapon.inherit_velocity_ratio > top_speed,
			"bolts outrun the ship even when boosting")


func test_asteroid_sizes_shrink_and_speed_up() -> void:
	var asteroids := _balance.asteroids
	assert_true(asteroids.large.radius > asteroids.medium.radius and asteroids.medium.radius > asteroids.small.radius,
			"each split makes smaller rocks")
	assert_true(asteroids.small.score > asteroids.large.score, "small rocks are worth more")
	assert_true(asteroids.min_vertices <= asteroids.max_vertices, "vertex range is ordered")
	var max_wave_rocks := _balance.waves.max_wave_asteroids
	assert_true(asteroids.max_live_asteroids >= max_wave_rocks * 3,
			"the live cap leaves room for a full wave to split")


func test_power_ups_are_complete() -> void:
	var power_ups := _balance.power_ups
	var kinds := {}
	var total_weight := 0.0
	for definition in power_ups.definitions:
		kinds[definition.kind] = true
		total_weight += definition.drop_weight
		assert_true(not definition.display_name.is_empty(), "every power-up has a name")
	assert_eq(kinds.size(), PowerUpDefinition.Kind.size(), "every power-up kind has a definition")
	assert_gt(total_weight, 0.0, "power-ups can drop")
	assert_true(power_ups.pickup_warning_time < power_ups.pickup_lifetime, "pickups blink before vanishing")


func test_leaderboard_name_rules() -> void:
	assert_eq(Leaderboard.sanitize_name("  Ace   Pilot!! "), "Ace Pilot", "names are trimmed and cleaned")
	assert_true(Leaderboard.is_valid_name("Bob"), "three characters is enough")
	assert_false(Leaderboard.is_valid_name("Al"), "two characters is too short")
	assert_false(Leaderboard.is_valid_name("ElevenChars"), "eleven characters is too long")
