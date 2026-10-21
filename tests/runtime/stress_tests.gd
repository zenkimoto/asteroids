extends RuntimeTestSuite
## Long-session load and leak checks: many enemies and shots at once, then
## repeated restarts, watching frame time, node counts, orphaned nodes and
## signal connections on the autoloads.

## Seconds of heavy play in the load test.
const LOAD_SECONDS: float = 40.0
const MAX_UFOS: int = 6
const ENEMY_SHOTS_PER_SECOND: int = 25
const RESTART_CYCLES: int = 12
## Game seconds after a new scene before nodes are counted: past the first
## wave's countdown, with every short-lived effect already gone.
const SETTLE_SECONDS: float = 4.0
## A frame longer than this counts as a visible hitch.
const HITCH_MSEC: float = 25.0

var _rng := RandomNumberGenerator.new()


func suite_name() -> String:
	return "stress"


## Connection counts of every autoload signal: listeners that outlive the
## gameplay scene would show up as growth here.
func _autoload_connections() -> Dictionary:
	var counts := {}
	for autoload in [GameManager, ScoreManager, SaveManager, SettingsManager, AudioManager, KeyBindings]:
		for info in autoload.get_signal_list():
			var key := "%s.%s" % [autoload.name, info["name"]]
			counts[key] = autoload.get_signal_connection_list(info["name"]).size()
	return counts


func _diff_connections(before: Dictionary, after: Dictionary) -> PackedStringArray:
	var grown := PackedStringArray()
	for key in after:
		if after[key] != before.get(key, 0):
			grown.append("%s %d -> %d" % [key, before.get(key, 0), after[key]])
	return grown


## Node counts under each autoload and each child of the gameplay scene, so
## growth can be traced to the branch that holds it.
func _branch_counts() -> Dictionary:
	var counts := {}
	for child in runner.get_tree().root.get_children():
		if child == runner:
			continue
		counts[String(child.name)] = _count_nodes(child)
	if game != null:
		for child in game.get_children():
			counts["Game/" + String(child.name)] = _count_nodes(child)
	return counts


func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total


func _monitor(monitor: Performance.Monitor) -> int:
	return int(Performance.get_monitor(monitor))


func _random_point() -> Vector2:
	var size := Playfield.get_playfield_size()
	return Vector2(_rng.randf() * size.x, _rng.randf() * size.y)


func test_heavy_long_session_stays_smooth() -> void:
	_rng.seed = 1234
	await runner.skip_countdown()
	var player := game.player
	var effects := game.power_up_effects
	var field := game.asteroid_field
	var fleet := game.ufo_fleet
	var cap := field.settings.max_live_asteroids
	Input.action_press(InputActions.FIRE)
	Input.action_press(InputActions.ROTATE_RIGHT)
	var fps_samples: Array[float] = []
	var worst_frame_ms := 0.0
	var hitches := 0
	var frames := 0
	var last_frame_usec := Time.get_ticks_usec()
	var peaks := {"asteroids": 0, "ufos": 0, "enemy_shots": 0, "bolts": 0, "nodes": 0}
	var started := Time.get_ticks_msec()
	var next_second := 0.0
	while Time.get_ticks_msec() - started < LOAD_SECONDS * 1000.0:
		var elapsed := (Time.get_ticks_msec() - started) / 1000.0
		player.invulnerable_time_left = 1000.0
		if elapsed >= next_second:
			next_second += 1.0
			if elapsed > 1.0:
				fps_samples.append(Engine.get_frames_per_second())
			if effects.get_weapon_upgrade() != PowerUpDefinition.Kind.TRIPLE_SHOT:
				effects.apply(power_up(PowerUpDefinition.Kind.TRIPLE_SHOT))
			player.weapon.cooldown_multiplier = 0.45
			while field.get_asteroid_count() < cap:
				var variant := _rng.randi_range(0, 2) as Asteroid.Variant
				var velocity := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(40.0, 160.0)
				spawn_asteroid(_random_point(), Asteroid.Size.LARGE, variant, velocity)
			while fleet.get_live_count() < MAX_UFOS:
				spawn_ufo(_random_point(), _rng.randi_range(0, 1) as Ufo.Type)
			for i in ENEMY_SHOTS_PER_SECOND:
				spawn_enemy_shot(_random_point(), Vector2.from_angle(_rng.randf() * TAU), 400.0, 2.0)
		await runner.get_tree().process_frame
		var now := Time.get_ticks_usec()
		var frame_ms := (now - last_frame_usec) / 1000.0
		last_frame_usec = now
		if elapsed > 1.0:
			worst_frame_ms = maxf(worst_frame_ms, frame_ms)
			hitches += 1 if frame_ms > HITCH_MSEC else 0
			frames += 1
		peaks["asteroids"] = maxi(peaks["asteroids"], field.get_asteroid_count())
		peaks["ufos"] = maxi(peaks["ufos"], fleet.get_live_count())
		peaks["enemy_shots"] = maxi(peaks["enemy_shots"], game.enemy_projectiles.get_live_count())
		peaks["bolts"] = maxi(peaks["bolts"], game.projectiles.get_live_count())
		peaks["nodes"] = maxi(peaks["nodes"], _monitor(Performance.OBJECT_NODE_COUNT))
	Input.action_release(InputActions.FIRE)
	Input.action_release(InputActions.ROTATE_RIGHT)
	var average_fps := 0.0
	var lowest_fps := INF
	for fps in fps_samples:
		average_fps += fps
		lowest_fps = minf(lowest_fps, fps)
	average_fps /= maxf(fps_samples.size(), 1.0)
	var hitch_share := float(hitches) / maxf(frames, 1.0)
	note("%.0fs under load: FPS avg %.1f, min %.0f; worst frame %.1f ms; %d of %d frames over %.0f ms" % [
			LOAD_SECONDS, average_fps, lowest_fps, worst_frame_ms, hitches, frames, HITCH_MSEC])
	note("peaks: %s; kills: %d asteroids, %d UFOs" % [
			str(peaks), ScoreManager.asteroids_destroyed, ScoreManager.ufos_destroyed])
	check(ScoreManager.asteroids_destroyed > 100, "the load test actually fought (%d kills)" % ScoreManager.asteroids_destroyed)
	check(average_fps >= 58.0, "average frame rate holds 60 (%.1f)" % average_fps)
	check(lowest_fps >= 50.0, "no second drops far below 60 FPS (%.0f)" % lowest_fps)
	check(hitch_share < 0.01, "fewer than 1%% of frames hitch (%.2f%%)" % (hitch_share * 100.0))
	check(peaks["asteroids"] <= cap, "asteroids never pass the cap")


func test_restarts_leave_nothing_behind() -> void:
	_rng.seed = 99
	# Measure a fresh scene at a fixed point (wave 1 just spawned, effects
	# settled) and compare with the same point after all the restarts.
	await runner.new_game()
	await runner.wait_game_seconds(SETTLE_SECONDS)
	var nodes_before := _monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_before := _monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var objects_before := _monitor(Performance.OBJECT_COUNT)
	var connections_before := _autoload_connections()
	var branches_before := _branch_counts()
	for cycle in RESTART_CYCLES:
		await runner.skip_countdown()
		game.player.weapon.fire()
		for i in 10:
			spawn_asteroid(_random_point()).take_hit(1)
		spawn_ufo(_random_point())
		spawn_enemy_shot(_random_point(), Vector2.RIGHT, 300.0)
		game.power_up_effects.apply(power_up(PowerUpDefinition.Kind.SHIELD))
		game.power_ups.spawn_pickup(power_up(PowerUpDefinition.Kind.RAPID_FIRE), _random_point())
		await runner.wait_physics_frames(5)
		if cycle % 3 == 0:
			# Restart from the pause menu inside the same scene.
			GameManager.pause()
			GameManager.start_session()
			await runner.wait_physics_frames(2)
		elif cycle % 3 == 1:
			# Play to Game Over and play again.
			GameManager.lives = 1
			game.player.invulnerable_time_left = 0.0
			game.player.die()
			await runner.wait_until(func() -> bool: return GameManager.state == GameManager.State.GAME_OVER, 4.0)
			GameManager.start_session()
		else:
			# Leave for the menu and come back with a new scene.
			await runner.new_game()
	await runner.new_game()
	await runner.wait_game_seconds(SETTLE_SECONDS)
	var nodes_after := _monitor(Performance.OBJECT_NODE_COUNT)
	var orphans_after := _monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var objects_after := _monitor(Performance.OBJECT_COUNT)
	note("after %d restarts: nodes %d -> %d, orphan nodes %d -> %d, objects %d -> %d" % [
			RESTART_CYCLES, nodes_before, nodes_after, orphans_before, orphans_after, objects_before, objects_after])
	check(orphans_after <= orphans_before, "no orphaned nodes accumulate (%d -> %d)" % [orphans_before, orphans_after])
	var branches_after := _branch_counts()
	var grown_branches := PackedStringArray()
	for branch in branches_after:
		if branches_after[branch] != branches_before.get(branch, 0):
			grown_branches.append("%s %d -> %d" % [branch, branches_before.get(branch, 0), branches_after[branch]])
	check(nodes_after == nodes_before, "node count returns to its baseline (%d -> %d): %s" % [
			nodes_before, nodes_after, ", ".join(grown_branches)])
	# Scripts and resources loaded for the first time during the cycles stay
	# cached, so a little one-off growth is expected; a leak grows per cycle.
	check(objects_after - objects_before < 150, "object count stays flat (%d -> %d)" % [objects_before, objects_after])
	var grown := _diff_connections(connections_before, _autoload_connections())
	check(grown.is_empty(), "autoload signal connections stay constant: %s" % ", ".join(grown))
