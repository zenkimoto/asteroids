extends RuntimeTestSuite
## Edge cases for the ship, asteroids, UFOs, projectiles and power-ups.


func suite_name() -> String:
	return "gameplay"


# ----- player -----

func test_hazard_contact_costs_one_life_then_respawns_clear() -> void:
	await start_empty_wave()
	var player := game.player
	var lives_before := GameManager.lives
	# Two rocks on the ship at once must cost a single life.
	spawn_asteroid(player.global_position)
	spawn_asteroid(player.global_position)
	await runner.wait_physics_frames(3)
	check(not player.is_alive, "ship should be destroyed on contact")
	check_eq(GameManager.lives, lives_before - 1, "simultaneous contacts cost one life")
	await expect_eventually(func() -> bool: return player.is_alive, "ship respawns", 4.0)
	check(player.is_invulnerable(), "respawned ship is invulnerable")
	var nearest := INF
	for asteroid in game.asteroid_field.get_asteroids():
		nearest = minf(nearest, player.global_position.distance_to(asteroid.position))
	check(nearest > rules().respawn_clear_radius * 0.5, "respawn point keeps away from rocks (%.0f px)" % nearest)


func test_invulnerable_ship_ignores_hazards() -> void:
	await start_empty_wave()
	var player := game.player
	player.invulnerable_time_left = 1.0
	var lives_before := GameManager.lives
	spawn_asteroid(player.global_position)
	await runner.wait_physics_frames(10)
	check(player.is_alive, "invulnerable ship survives contact")
	check_eq(GameManager.lives, lives_before, "no life lost while invulnerable")
	# A rock still overlapping when invulnerability ends is caught at once.
	await expect_eventually(func() -> bool: return not player.is_alive,
			"lingering hazard hits once invulnerability ends", 1.0, 3.0)


func test_shield_absorbs_one_hit() -> void:
	await start_empty_wave()
	var player := game.player
	game.power_up_effects.apply(power_up(PowerUpDefinition.Kind.SHIELD))
	var lives_before := GameManager.lives
	spawn_asteroid(player.global_position)
	await runner.wait_physics_frames(3)
	check(player.is_alive, "shield saves the ship")
	check(not player.has_shield, "shield is used up")
	check(player.is_invulnerable(), "grace period follows a shield hit")
	check_eq(GameManager.lives, lives_before, "no life lost to a shielded hit")


func test_enemy_shot_destroys_ship_and_disappears() -> void:
	await start_empty_wave()
	var player := game.player
	var shot := spawn_enemy_shot(player.global_position, Vector2.RIGHT, 0.0)
	await runner.wait_physics_frames(3)
	check(not player.is_alive, "enemy shot destroys the ship")
	check(not is_instance_valid(shot) or shot.is_despawned, "the shot is used up on impact")


func test_last_life_leads_to_game_over() -> void:
	await start_empty_wave()
	var player := game.player
	GameManager.lives = 1
	spawn_asteroid(player.global_position)
	await runner.wait_physics_frames(3)
	check(not player.is_alive, "ship destroyed")
	check_eq(GameManager.lives, 0, "no lives left")
	check(not GameManager.can_pause(), "pausing is refused during the Game Over delay")
	GameManager.pause()
	check(GameManager.state != GameManager.State.PAUSED, "pause() is ignored once out of lives")
	await expect_eventually(func() -> bool: return GameManager.state == GameManager.State.GAME_OVER,
			"Game Over follows the last life", 1.0, rules().game_over_delay + 2.0)
	await runner.wait_game_seconds(rules().respawn_delay + 0.2)
	check(not player.is_alive, "no respawn after the last life")
	check(game.game_over_screen.visible, "Game Over screen is shown")
	check(not player.controls_enabled, "ship controls are off at Game Over")


func test_ship_wraps_at_every_edge() -> void:
	await start_empty_wave()
	var player := game.player
	player.invulnerable_time_left = 100.0
	var size := Playfield.get_playfield_size()
	var margin := player.settings.wrap_margin
	var cases := [
		[Vector2(size.x + margin - 1.0, 300.0), Vector2(300.0, 0.0), "right"],
		[Vector2(-margin + 1.0, 300.0), Vector2(-300.0, 0.0), "left"],
		[Vector2(500.0, -margin + 1.0), Vector2(0.0, -300.0), "top"],
		[Vector2(500.0, size.y + margin - 1.0), Vector2(0.0, 300.0), "bottom"],
	]
	for case in cases:
		player.global_position = case[0]
		player.velocity = case[1]
		await runner.wait_physics_frames(3)
		var inside := Rect2(Vector2(-margin, -margin), size + Vector2(margin, margin) * 2.0)
		var moved := player.global_position.distance_to(case[0])
		check(inside.has_point(player.global_position) and moved > size.y * 0.5,
				"ship wraps across the %s edge (now at %s)" % [case[2], player.global_position])


func test_thrust_never_exceeds_top_speed() -> void:
	await start_empty_wave()
	var player := game.player
	player.invulnerable_time_left = 100.0
	var top_speed := player.settings.max_speed
	var fastest := 0.0
	Input.action_press(InputActions.THRUST_FORWARD)
	for i in 120:
		await runner.get_tree().physics_frame
		fastest = maxf(fastest, player.get_speed())
	Input.action_release(InputActions.THRUST_FORWARD)
	check(fastest <= top_speed + 0.5, "thrust is capped at %.0f (reached %.1f)" % [top_speed, fastest])
	check(fastest > top_speed * 0.9, "two seconds of thrust gets near top speed (%.1f)" % fastest)


func test_boost_respects_cooldown() -> void:
	await start_empty_wave()
	var player := game.player
	player.invulnerable_time_left = 100.0
	check(player.try_boost(), "first boost starts")
	check(not player.try_boost(), "boost can't restart while active")
	await expect_eventually(func() -> bool: return not player.is_boosting, "boost ends", 4.0)
	check(not player.try_boost(), "boost is refused during cooldown")
	await expect_eventually(player.can_boost, "boost becomes ready after its cooldown", 4.0)
	await runner.wait_physics_frames(30)
	check(player.get_speed() <= player.get_max_speed() + 0.5, "speed eases back under the cap after a boost")


# ----- asteroids -----

func test_asteroids_split_by_size() -> void:
	await start_empty_wave()
	game.player.invulnerable_time_left = 100.0
	var at := Vector2(300.0, 300.0)
	var large := spawn_asteroid(at)
	check(large.take_hit(1), "hit lands")
	await runner.wait_physics_frames(2)
	check_eq(count_asteroids(Asteroid.Size.MEDIUM), 2, "a large rock splits into two medium")
	var medium := game.asteroid_field.get_asteroids()[0]
	medium.take_hit(1)
	await runner.wait_physics_frames(2)
	check_eq(count_asteroids(Asteroid.Size.SMALL), 2, "a medium rock splits into two small")
	var small: Asteroid = null
	for asteroid in game.asteroid_field.get_asteroids():
		if asteroid.size == Asteroid.Size.SMALL:
			small = asteroid
	small.take_hit(1)
	await runner.wait_physics_frames(2)
	check_eq(game.asteroid_field.get_asteroid_count(), 2, "a small rock leaves nothing behind")


func test_dying_asteroid_scores_once() -> void:
	await start_empty_wave()
	var asteroid := spawn_asteroid(Vector2(300.0, 300.0))
	var score_before := ScoreManager.score
	check(asteroid.take_hit(1), "first hit destroys it")
	check(not asteroid.take_hit(1), "a second hit in the same frame is refused")
	check_eq(ScoreManager.asteroids_destroyed, 1, "counted once")
	check_eq(ScoreManager.score - score_before, asteroid.get_score_value(), "points awarded once")


func test_armored_asteroid_needs_extra_hits() -> void:
	await start_empty_wave()
	var asteroid := spawn_asteroid(Vector2(300.0, 300.0), Asteroid.Size.LARGE, Asteroid.Variant.ARMORED)
	var hits := asteroid.hit_points
	check(hits > 1, "armored rock has extra hit points")
	for i in hits - 1:
		asteroid.take_hit(1)
	check(not asteroid.is_despawned, "survives until its last hit point")
	asteroid.take_hit(1)
	check(asteroid.is_despawned, "destroyed by the last hit")


func test_fragments_respect_asteroid_cap() -> void:
	await start_empty_wave()
	game.player.invulnerable_time_left = 100.0
	var cap := game.asteroid_field.settings.max_live_asteroids
	for i in cap:
		spawn_asteroid(Vector2(200.0 + i * 3.0, 250.0))
	game.asteroid_field.get_asteroids()[0].take_hit(99)
	await runner.wait_physics_frames(2)
	check_eq(game.asteroid_field.get_asteroid_count(), cap, "splitting never goes past the cap")


func test_clear_discards_queued_fragments() -> void:
	await start_empty_wave()
	spawn_asteroid(Vector2(300.0, 300.0)).take_hit(1)
	game.asteroid_field.clear()
	await runner.wait_physics_frames(3)
	check_eq(game.asteroid_field.get_asteroid_count(), 0, "fragments queued before a clear never appear")


func test_wave_completes_and_next_wave_starts() -> void:
	await runner.skip_countdown()
	game.player.invulnerable_time_left = 1000.0
	check_eq(game.wave_manager.current_wave, 1, "session opens on wave 1")
	var completed := []
	game.wave_manager.wave_completed.connect(func(wave: int, bonus: int) -> void: completed.append([wave, bonus]))
	for i in 20:
		for asteroid in game.asteroid_field.get_asteroids():
			asteroid.take_hit(99)
		await runner.wait_physics_frames(2)
		if game.asteroid_field.get_asteroid_count() == 0:
			break
	check_eq(completed.size(), 1, "wave_completed fires once")
	check_eq(GameManager.state, GameManager.State.WAVE_TRANSITION, "clearing the wave starts a transition")
	await expect_eventually(func() -> bool: return GameManager.state == GameManager.State.PLAYING,
			"wave 2 starts", 8.0)
	check_eq(game.wave_manager.current_wave, 2, "the next wave is wave 2")
	check(game.ufo_fleet.has_remaining_ufos(), "wave 2 brings a UFO")


# ----- projectiles -----

func test_bolt_expires_after_its_lifetime() -> void:
	await start_empty_wave()
	game.player.invulnerable_time_left = 100.0
	var bolts := game.player.weapon.fire()
	check_eq(bolts.size(), 1, "the basic laser fires one bolt")
	check_eq(game.projectiles.get_live_count(), 1, "bolt is in play")
	await runner.wait_game_seconds(game.player.weapon.settings.projectile_lifetime + 0.2)
	check_eq(game.projectiles.get_live_count(), 0, "bolt is gone after its lifetime")


func test_bolt_hits_only_one_target() -> void:
	await start_empty_wave()
	var at := Vector2(400.0, 300.0)
	spawn_asteroid(at)
	spawn_asteroid(at)
	var bolt := launch_bolt(at - Vector2(150.0, 0.0), Vector2.RIGHT)
	await runner.wait_physics_frames(15)
	check_eq(ScoreManager.asteroids_destroyed, 1, "one bolt destroys one of two overlapping rocks")
	check(not is_instance_valid(bolt) or bolt.is_despawned, "the bolt is spent")


func test_piercing_bolt_passes_rocks_but_stops_at_ufo() -> void:
	await start_empty_wave()
	for i in 3:
		spawn_asteroid(Vector2(500.0 + i * 160.0, 300.0), Asteroid.Size.SMALL)
	var bolt := launch_bolt(Vector2(380.0, 300.0), Vector2.RIGHT, 3)
	await runner.wait_physics_frames(40)
	check_eq(ScoreManager.asteroids_destroyed, 3, "a piercing bolt goes through three rocks")
	var ufo := spawn_ufo(Vector2(900.0, 700.0))
	var hit_points := ufo.hit_points
	bolt = launch_bolt(Vector2(780.0, 700.0), Vector2.RIGHT, 3)
	await runner.wait_physics_frames(12)
	check_eq(ufo.hit_points, hit_points - 1, "the UFO takes one hit")
	check(not is_instance_valid(bolt) or bolt.is_despawned, "a UFO always stops a piercing bolt")


func test_bolts_wrap_around_the_screen() -> void:
	await start_empty_wave()
	var size := Playfield.get_playfield_size()
	var bolt := launch_bolt(Vector2(size.x - 4.0, 300.0), Vector2.RIGHT)
	await runner.wait_physics_frames(3)
	check(is_instance_valid(bolt) and bolt.position.x < 100.0, "a bolt reappears on the left")


# ----- UFOs -----

func test_ufo_destroyed_once_and_scored() -> void:
	await start_empty_wave()
	game.player.invulnerable_time_left = 100.0
	var ufo := spawn_ufo(Vector2(400.0, 300.0))
	var score_before := ScoreManager.score
	for i in ufo.type_settings.hit_points:
		check(ufo.take_hit(1), "hit %d lands" % (i + 1))
	check(ufo.is_despawned, "destroyed after its hit points")
	check(not ufo.take_hit(1), "a destroyed UFO takes no more hits")
	check_eq(ScoreManager.ufos_destroyed, 1, "counted once")
	check_eq(ScoreManager.score - score_before, ufo.get_score_value(), "points awarded once")


func test_escaped_ufo_returns_later() -> void:
	await start_empty_wave()
	game.player.invulnerable_time_left = 1000.0
	var fleet := game.ufo_fleet
	fleet.start_wave(2)
	await expect_eventually(func() -> bool: return fleet.get_live_count() == 1, "the wave's UFO arrives", 8.0)
	var ufo := fleet.get_ufos()[0]
	var width := Playfield.get_playfield_size().x
	ufo.position.x = width - ufo.get_radius() if ufo.velocity.x > 0.0 else ufo.get_radius()
	await expect_eventually(func() -> bool: return fleet.get_live_count() == 0, "the UFO flies off", 2.0)
	check(fleet.has_remaining_ufos(), "an escaped UFO still counts as remaining")
	check_eq(GameManager.state, GameManager.State.PLAYING, "an escape doesn't complete the wave")
	await expect_eventually(func() -> bool: return fleet.get_live_count() == 1, "the UFO comes back", 8.0)


func test_ufo_holds_fire_while_ship_is_down() -> void:
	await start_empty_wave()
	game.player.die()
	spawn_ufo(Vector2(600.0, 400.0))
	await runner.wait_game_seconds(rules().respawn_delay - 0.2)
	check_eq(game.enemy_projectiles.get_live_count(), 0, "no shots at a destroyed ship")


# ----- power-ups -----

func test_weapon_upgrades_replace_refresh_and_expire() -> void:
	await start_empty_wave()
	var effects := game.power_up_effects
	var weapon := game.player.weapon
	effects.apply(power_up(PowerUpDefinition.Kind.SHIELD))
	effects.apply(power_up(PowerUpDefinition.Kind.DOUBLE_SHOT))
	check_eq(weapon.shot_count, 2, "double shot fires two bolts")
	effects.apply(power_up(PowerUpDefinition.Kind.TRIPLE_SHOT))
	check_eq(weapon.shot_count, 3, "triple shot replaces double shot")
	check(not effects.is_active(PowerUpDefinition.Kind.DOUBLE_SHOT), "only one weapon upgrade at a time")
	var rapid := power_up(PowerUpDefinition.Kind.RAPID_FIRE)
	effects.apply(rapid)
	check_eq(weapon.shot_count, 1, "rapid fire resets the spread")
	check(weapon.cooldown_multiplier < 1.0, "rapid fire shortens the cooldown")
	check(game.player.has_shield, "the shield coexists with weapon upgrades")
	await runner.wait_game_seconds(1.0)
	effects.apply(rapid)
	check_near(effects.get_time_left(rapid.kind), rapid.duration, 0.1, "collecting it again refreshes the timer")
	await expect_eventually(func() -> bool: return not effects.is_active(rapid.kind), "rapid fire runs out", 8.0)
	check_eq(weapon.cooldown_multiplier, 1.0, "the laser returns to normal")
	check_eq(effects.get_weapon_upgrade(), -1, "no weapon upgrade left")


func test_repair_at_full_lives_has_no_effect() -> void:
	await start_empty_wave()
	var results := []
	game.power_up_effects.power_up_applied.connect(
			func(_definition: PowerUpDefinition, had_effect: bool) -> void: results.append(had_effect))
	GameManager.lives = rules().max_lives
	game.power_up_effects.apply(power_up(PowerUpDefinition.Kind.REPAIR))
	check_eq(GameManager.lives, rules().max_lives, "lives never exceed the cap")
	GameManager.lives = 1
	game.power_up_effects.apply(power_up(PowerUpDefinition.Kind.REPAIR))
	check_eq(GameManager.lives, 2, "repair restores a life")
	check_eq(results, [false, true], "the HUD is told whether repair did anything")


func test_effects_end_when_ship_is_destroyed() -> void:
	await start_empty_wave()
	var effects := game.power_up_effects
	effects.apply(power_up(PowerUpDefinition.Kind.TRIPLE_SHOT))
	effects.apply(power_up(PowerUpDefinition.Kind.SPEED_BOOST))
	game.player.die()
	check_eq(game.player.weapon.shot_count, 1, "weapon upgrade ends with the ship")
	check_eq(game.player.max_speed_multiplier, 1.0, "speed boost ends with the ship")


func test_pickup_collected_exactly_once() -> void:
	await start_empty_wave()
	game.player.invulnerable_time_left = 100.0
	var collected := []
	game.power_ups.collected.connect(func(definition: PowerUpDefinition) -> void: collected.append(definition))
	var pickup := game.power_ups.spawn_pickup(power_up(PowerUpDefinition.Kind.RAPID_FIRE), game.player.global_position)
	await runner.wait_physics_frames(4)
	check_eq(collected.size(), 1, "flying into a pickup collects it")
	check(not is_instance_valid(pickup) or not pickup.collect(), "a pickup can't be collected twice")
	check(game.player.weapon.cooldown_multiplier < 1.0, "the pickup's effect applies")


func test_pickup_expires() -> void:
	await start_empty_wave()
	var settings := game.power_ups.settings
	game.power_ups.spawn_pickup(power_up(PowerUpDefinition.Kind.SHIELD), Vector2(200.0, 200.0))
	await expect_eventually(func() -> bool: return game.power_ups.get_live_count() == 0,
			"an uncollected pickup vanishes", 8.0, settings.pickup_lifetime)


func test_drops_respect_pickup_cap() -> void:
	await start_empty_wave()
	var settings := game.power_ups.settings
	var chance := settings.asteroid_drop_chance
	settings.asteroid_drop_chance = 1.0
	var rock := spawn_asteroid(Vector2(200.0, 200.0))
	for i in settings.max_active_pickups + 5:
		game.power_ups.drop_from_asteroid(rock)
	settings.asteroid_drop_chance = chance
	await runner.wait_physics_frames(2)
	check_eq(game.power_ups.get_live_count(), settings.max_active_pickups, "never more pickups than the cap")
