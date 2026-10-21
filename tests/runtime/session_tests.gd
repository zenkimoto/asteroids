extends RuntimeTestSuite
## Pause, restart, Game Over and the state machine's edge cases.


func suite_name() -> String:
	return "session"


func _pause_by_key() -> void:
	var event := InputEventAction.new()
	event.action = InputActions.PAUSE
	event.pressed = true
	Input.parse_input_event(event)
	await runner.get_tree().process_frame
	event = InputEventAction.new()
	event.action = InputActions.PAUSE
	event.pressed = false
	Input.parse_input_event(event)
	await runner.get_tree().process_frame


func _lose_all_lives() -> void:
	GameManager.lives = 1
	game.player.invulnerable_time_left = 0.0
	game.player.die()
	await expect_eventually(func() -> bool: return GameManager.state == GameManager.State.GAME_OVER,
			"Game Over is reached", 1.0, rules().game_over_delay + 2.0)


func test_pause_freezes_the_world() -> void:
	await start_empty_wave()
	game.player.invulnerable_time_left = 100.0
	var rock := spawn_asteroid(Vector2(300.0, 300.0), Asteroid.Size.LARGE, Asteroid.Variant.STANDARD, Vector2(120.0, 0.0))
	ScoreManager.record_asteroid_destroyed(spawn_asteroid(Vector2(1500.0, 900.0)))
	await _pause_by_key()
	check_eq(GameManager.state, GameManager.State.PAUSED, "the pause key pauses")
	check(runner.get_tree().paused, "the scene tree is paused")
	check(game.pause_overlay.visible, "the pause menu is shown")
	var frozen_at := rock.position
	var survival := ScoreManager.survival_time
	var combo := ScoreManager.get_combo_time_ratio()
	var invulnerable := game.player.invulnerable_time_left
	await runner.wait_real_seconds(0.5)
	check_eq(rock.position, frozen_at, "asteroids don't move while paused")
	check_eq(ScoreManager.survival_time, survival, "survival time stops while paused")
	check_eq(ScoreManager.get_combo_time_ratio(), combo, "the combo window stops while paused")
	check_eq(game.player.invulnerable_time_left, invulnerable, "invulnerability stops while paused")
	await _pause_by_key()
	check_eq(GameManager.state, GameManager.State.PLAYING, "the pause key resumes play")
	check(not game.pause_overlay.visible, "the pause menu hides")
	await runner.wait_physics_frames(5)
	check(rock.position != frozen_at, "asteroids move again")


func test_pause_during_countdown_resumes_countdown() -> void:
	check_eq(GameManager.state, GameManager.State.WAVE_TRANSITION, "a session opens in the countdown")
	GameManager.pause()
	check_eq(GameManager.state, GameManager.State.PAUSED, "the countdown can be paused")
	Engine.time_scale = 8.0
	await runner.wait_real_seconds(0.6)
	Engine.time_scale = 1.0
	check(not game.wave_manager.is_wave_active, "the wave doesn't start while paused")
	GameManager.resume()
	check_eq(GameManager.state, GameManager.State.WAVE_TRANSITION, "resume returns to the countdown")
	await runner.skip_countdown()
	check_eq(game.wave_manager.current_wave, 1, "wave 1 starts after the countdown")


func test_restart_from_pause_resets_everything() -> void:
	await runner.skip_countdown()
	var effects := game.power_up_effects
	effects.apply(power_up(PowerUpDefinition.Kind.TRIPLE_SHOT))
	ScoreManager.add_points(5000)
	game.power_ups.spawn_pickup(power_up(PowerUpDefinition.Kind.SHIELD), Vector2(200.0, 200.0))
	spawn_ufo(Vector2(400.0, 300.0))
	spawn_enemy_shot(Vector2(100.0, 100.0), Vector2.RIGHT, 50.0)
	game.player.weapon.fire()
	game.player.invulnerable_time_left = 0.0
	game.player.die()
	check(game.timers.get_pending_count() > 0, "a respawn is pending")
	GameManager.pause()
	# What the pause menu's Restart button does after its confirmation.
	game.pause_overlay.restart_requested.emit()
	await runner.wait_physics_frames(2)
	check_eq(GameManager.state, GameManager.State.WAVE_TRANSITION, "restart begins a new countdown")
	check(not runner.get_tree().paused, "the tree is unpaused")
	check(not game.pause_overlay.visible, "the pause menu closes")
	check_eq(GameManager.lives, rules().starting_lives, "lives reset")
	check_eq(ScoreManager.score, 0, "score resets")
	check_eq(ScoreManager.multiplier, 1, "combo resets")
	check_eq(game.wave_manager.current_wave, 1, "back to wave 1")
	check_eq(game.asteroid_field.get_asteroid_count(), 0, "asteroids cleared")
	check_eq(game.ufo_fleet.get_live_count(), 0, "UFOs cleared")
	check_eq(game.enemy_projectiles.get_live_count(), 0, "enemy shots cleared")
	check_eq(game.projectiles.get_live_count(), 0, "player shots cleared")
	check_eq(game.power_ups.get_live_count(), 0, "pickups cleared")
	check_eq(game.timers.get_pending_count(), 0, "the old respawn timer is cancelled")
	check(game.player.is_alive, "the ship is back")
	check_eq(game.player.global_position, Playfield.get_center(), "the ship starts in the centre")
	check_eq(game.player.weapon.shot_count, 1, "weapon upgrades are cleared")
	check_eq(effects.get_weapon_upgrade(), -1, "no upgrade carried over")
	await runner.skip_countdown()
	var expected := game.wave_manager.settings.get_composition(1).size()
	check_eq(game.asteroid_field.get_asteroid_count(), expected, "wave 1 spawns once, with its usual rocks")


func test_restart_from_game_over() -> void:
	await runner.skip_countdown()
	ScoreManager.add_points(1234)
	await _lose_all_lives()
	check(game.game_over_screen.visible, "Game Over screen is shown")
	check_eq(ScoreManager.get_summary().score, 1234, "the final score is kept for the results")
	game.game_over_screen.restart_requested.emit()
	await runner.wait_physics_frames(2)
	check_eq(GameManager.state, GameManager.State.WAVE_TRANSITION, "Play Again starts a countdown")
	check(not game.game_over_screen.visible, "the Game Over screen hides")
	check_eq(GameManager.lives, rules().starting_lives, "lives reset")
	check(game.player.is_alive, "the ship is back")


func test_no_pause_or_lives_change_at_game_over() -> void:
	await runner.skip_countdown()
	await _lose_all_lives()
	await _pause_by_key()
	check_eq(GameManager.state, GameManager.State.GAME_OVER, "the pause key does nothing at Game Over")
	check(not GameManager.add_life(), "no extra lives after Game Over")
	check(not GameManager.register_player_death(), "no deaths counted after Game Over")
	check(not GameManager.begin_wave_transition(), "no wave transitions after Game Over")
	var score := ScoreManager.score
	ScoreManager.add_points(500)
	check_eq(ScoreManager.score, score, "no points after Game Over")


func test_state_machine_refuses_out_of_order_calls() -> void:
	check(not GameManager.begin_wave_transition(), "can't begin a transition during the countdown")
	GameManager.resume()
	check_eq(GameManager.state, GameManager.State.WAVE_TRANSITION, "resume does nothing when not paused")
	GameManager.pause()
	GameManager.end_wave_transition()
	check_eq(GameManager.state, GameManager.State.PAUSED, "a wave can't start while paused")
	GameManager.pause()
	check_eq(GameManager.state, GameManager.State.PAUSED, "pausing twice is harmless")
	GameManager.resume()


func test_extra_lives_are_awarded_and_capped() -> void:
	await start_empty_wave()
	var every := GameManager.balance.scoring.extra_life_every
	var lives := GameManager.lives
	ScoreManager.add_points(every)
	check_eq(GameManager.lives, lives + 1, "an extra life at the first threshold")
	ScoreManager.add_points(every * 10)
	check_eq(GameManager.lives, rules().max_lives, "lives stop at the cap")


func test_combo_builds_and_resets_on_death() -> void:
	await start_empty_wave()
	var step := GameManager.balance.scoring.kills_per_multiplier_step
	for i in step:
		spawn_asteroid(Vector2(300.0 + i * 10.0, 300.0), Asteroid.Size.SMALL).take_hit(1)
	check_eq(ScoreManager.multiplier, 2, "the multiplier rises after %d quick kills" % step)
	game.player.die()
	check_eq(ScoreManager.multiplier, 1, "losing the ship resets the combo")
	await runner.wait_game_seconds(0.1)


func test_main_menu_and_back_leaves_no_stale_state() -> void:
	await runner.skip_countdown()
	GameManager.pause()
	# Leaving gameplay for the menu, as the pause menu's Main Menu button does,
	# without swapping the runner's scene.
	await runner.remove_game()
	check_eq(GameManager.state, GameManager.State.MAIN_MENU, "leaving the game returns to the menu state")
	check(not runner.get_tree().paused, "the tree is unpaused on the menu")
	await runner.new_game()
	check_eq(GameManager.state, GameManager.State.WAVE_TRANSITION, "a new game starts cleanly")
	check_eq(GameManager.lives, rules().starting_lives, "with full lives")
