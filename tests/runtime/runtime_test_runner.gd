class_name RuntimeTestRunner
extends Node
## Runs gameplay test suites inside the running game, where the autoloads,
## physics and timers behave exactly as they do in play.
##
## Every test gets a fresh gameplay scene. Save files are redirected to scratch
## files in user:// for the whole run and deleted afterwards, so the player's
## leaderboard, settings and key bindings are never touched.
##
## Results are printed as "[TEST] ..." lines. With `quit_when_done` the game
## exits with code 0 when everything passed and 1 otherwise, so the scene can
## be run from the command line:
##     godot --path . res://tests/runtime/runtime_tests.tscn

const GAME_SCENE: PackedScene = preload("res://scenes/game.tscn")
const SCRATCH_SETTINGS: String = "user://test_settings.json"
const SCRATCH_CONTROLS: String = "user://test_controls.json"
const SCRATCH_LEADERBOARD: String = "user://test_leaderboard.json"
## Longest any single wait helper may run before the test is failed.
const WAIT_LIMIT_SECONDS: float = 30.0

## RuntimeTestSuite scripts to run, in order.
@export var suite_scripts: Array[Script] = []
@export var quit_when_done: bool = true
## Only run tests whose name contains one of these comma-separated words
## (empty runs everything). "--filter=word" on the command line overrides it.
@export var test_filter: String = ""

## The gameplay scene for the current test (null for suites that don't use one).
var game: Game

var _passed: int = 0
var _failed: int = 0
var _failures: PackedStringArray = []
var _real_paths: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			test_filter = arg.trim_prefix("--filter=")
	_redirect_save_files()
	_run.call_deferred()


func _run() -> void:
	var started := Time.get_ticks_msec()
	print("[TEST] Running %d suites" % suite_scripts.size())
	for script in suite_scripts:
		await _run_suite(script.new() as RuntimeTestSuite)
	await remove_game()
	Engine.time_scale = 1.0
	_restore_save_files()
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	print("[TEST] SUMMARY passed=%d failed=%d time=%.1fs" % [_passed, _failed, seconds])
	for failure in _failures:
		print("[TEST]   FAILED %s" % failure)
	if quit_when_done:
		# A few frames let log forwarding (e.g. to the editor) catch up first.
		for i in 10:
			await get_tree().process_frame
		get_tree().quit(0 if _failed == 0 else 1)


func _run_suite(suite: RuntimeTestSuite) -> void:
	suite.runner = self
	for test_name in suite.get_test_names():
		if not _matches_filter(test_name):
			continue
		if suite.uses_game():
			await new_game()
		suite.begin_test()
		var started := Time.get_ticks_msec()
		await Callable(suite, test_name).call()
		Engine.time_scale = 1.0
		get_tree().paused = false
		var label := "%s.%s" % [suite.suite_name(), test_name]
		var ms := Time.get_ticks_msec() - started
		if suite.failures.is_empty():
			_passed += 1
			print("[TEST] PASS %s (%d ms)" % [label, ms])
		else:
			_failed += 1
			var message := "; ".join(suite.failures)
			_failures.append("%s: %s" % [label, message])
			print("[TEST] FAIL %s: %s" % [label, message])
		for line in suite.notes:
			print("[TEST]   %s" % line)


func _matches_filter(test_name: String) -> bool:
	if test_filter.strip_edges().is_empty():
		return true
	for word in test_filter.split(",", false):
		if test_name.contains(word.strip_edges()):
			return true
	return false


# ----- gameplay scene -----

## Replaces the gameplay scene with a fresh one, which starts a new session.
func new_game() -> void:
	await remove_game()
	game = GAME_SCENE.instantiate() as Game
	# The runner keeps processing while paused; the game must pause as it does
	# when it is the main scene.
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game)
	await wait_physics_frames(2)


func remove_game() -> void:
	if game == null:
		return
	if is_instance_valid(game):
		remove_child(game)
		game.queue_free()
	game = null
	await get_tree().process_frame


## Runs the first wave's countdown at high speed until the wave is in play.
func skip_countdown() -> void:
	await wait_until(func() -> bool: return GameManager.state == GameManager.State.PLAYING, 8.0)


## Removes every asteroid, UFO, shot and pickup so a test can set up its own
## situation. The ship stays where it is.
func clear_world() -> void:
	game.asteroid_field.clear()
	game.ufo_fleet.clear()
	game.projectiles.clear()
	game.enemy_projectiles.clear()
	game.power_ups.clear()
	await wait_physics_frames(2)


# ----- waiting -----

func wait_physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Waits `seconds` of game time (scaled by Engine.time_scale, stopped by pause).
func wait_game_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, false, true).timeout


## Waits `seconds` of real time, whatever the time scale or pause state.
func wait_real_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


## Waits until `condition` is true, running the game at `time_scale` meanwhile.
## Returns false if `limit` real seconds pass first.
func wait_until(condition: Callable, time_scale: float = 1.0, limit: float = WAIT_LIMIT_SECONDS) -> bool:
	var deadline := Time.get_ticks_msec() + int(limit * 1000.0)
	Engine.time_scale = time_scale
	while not condition.call():
		if Time.get_ticks_msec() > deadline:
			Engine.time_scale = 1.0
			return false
		await get_tree().physics_frame
	Engine.time_scale = 1.0
	return true


# ----- save files -----

func _redirect_save_files() -> void:
	_real_paths = {
		"settings": SettingsManager.settings_path,
		"controls": KeyBindings.controls_path,
		"leaderboard": SaveManager.leaderboard_path,
	}
	SettingsManager.flush_pending_save()
	SettingsManager.settings_path = SCRATCH_SETTINGS
	KeyBindings.controls_path = SCRATCH_CONTROLS
	SaveManager.leaderboard_path = SCRATCH_LEADERBOARD
	delete_scratch_files()


## Puts the real files back in charge and reloads them, discarding anything
## the tests changed in memory.
func _restore_save_files() -> void:
	SettingsManager.flush_pending_save()
	KeyBindings.reset_to_defaults()
	SettingsManager.settings_path = _real_paths["settings"]
	KeyBindings.controls_path = _real_paths["controls"]
	SaveManager.leaderboard_path = _real_paths["leaderboard"]
	SettingsManager.load_settings()
	KeyBindings.load_bindings()
	SaveManager.load_leaderboard()
	delete_scratch_files()


static func delete_scratch_files() -> void:
	for path in [SCRATCH_SETTINGS, SCRATCH_CONTROLS, SCRATCH_LEADERBOARD]:
		for suffix in ["", SaveManager.INVALID_SUFFIX, SaveManager.TEMP_SUFFIX]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)
