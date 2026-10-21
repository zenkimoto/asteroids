extends RuntimeTestSuite
## Leaderboard, settings and key-binding persistence, against scratch files
## (RuntimeTestRunner redirects every save path for the whole run).


func suite_name() -> String:
	return "persistence"


func uses_game() -> bool:
	return false


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_scratch_paths_are_in_use() -> void:
	check_eq(SaveManager.leaderboard_path, RuntimeTestRunner.SCRATCH_LEADERBOARD, "leaderboard redirected")
	check_eq(SettingsManager.settings_path, RuntimeTestRunner.SCRATCH_SETTINGS, "settings redirected")
	check_eq(KeyBindings.controls_path, RuntimeTestRunner.SCRATCH_CONTROLS, "controls redirected")


func test_leaderboard_keeps_top_ten_in_order() -> void:
	SaveManager.leaderboard.clear()
	for i in 12:
		SaveManager.submit_score("Pilot%d" % i, (i + 1) * 100, i + 1)
	var entries := SaveManager.leaderboard.entries
	check_eq(entries.size(), Leaderboard.MAX_ENTRIES, "only ten entries are kept")
	check_eq(entries[0].score, 1200, "best score first")
	check_eq(entries.back().score, 300, "lowest kept score last")
	check_eq(SaveManager.submit_score("Late", 300, 1), 0, "a tie with tenth place doesn't qualify")
	check_eq(SaveManager.submit_score("Tie", 1200, 5), 2, "an equal top score ranks below the earlier one")
	SaveManager.load_leaderboard()
	check_eq(SaveManager.leaderboard.entries.size(), Leaderboard.MAX_ENTRIES, "reloads all ten")
	check_eq(SaveManager.leaderboard.entries[1].player_name, "Tie", "reload keeps the order")


func test_leaderboard_rejects_bad_names_and_scores() -> void:
	SaveManager.leaderboard.clear()
	check_eq(SaveManager.submit_score("ab", 500, 1), 0, "names under three characters are refused")
	check_eq(SaveManager.submit_score("Valid", 0, 1), 0, "a zero score never qualifies")
	check_eq(SaveManager.submit_score("  !!Bob!!  ", 500, 1), 1, "names are cleaned before saving")
	check_eq(SaveManager.leaderboard.entries[0].player_name, "Bob", "the cleaned name is stored")


func test_corrupt_leaderboard_is_set_aside() -> void:
	var path := SaveManager.leaderboard_path
	_write_text(path, "{ this is not json")
	SaveManager.load_leaderboard()
	check(SaveManager.leaderboard.entries.is_empty(), "a corrupt file loads as empty")
	check(FileAccess.file_exists(path + SaveManager.INVALID_SUFFIX), "the corrupt file is kept aside")
	check(SaveManager.submit_score("Fresh", 100, 1) == 1, "scores save again afterwards")


func test_invalid_leaderboard_rows_are_skipped() -> void:
	var rows := [
		{"name": "Good", "score": 900, "wave": 3, "date": "2026-01-02"},
		{"name": "x", "score": 800, "wave": 3, "date": "2026-01-02"},
		{"name": "NoScore", "wave": 3, "date": "2026-01-02"},
		"not a row",
		{"name": "Second", "score": 700, "wave": 2, "date": "2026-01-03"},
	]
	_write_text(SaveManager.leaderboard_path, JSON.stringify({"version": 1, "entries": rows}))
	SaveManager.load_leaderboard()
	check_eq(SaveManager.leaderboard.entries.size(), 2, "valid rows load")
	check_eq(SaveManager.leaderboard.rejected_count, 3, "invalid rows are counted and skipped")


func test_settings_round_trip() -> void:
	SettingsManager.reset_to_defaults()
	SettingsManager.set_value(SettingsManager.MUSIC_VOLUME, 0.3)
	SettingsManager.set_value(SettingsManager.SCREEN_SHAKE, false)
	SettingsManager.set_value(SettingsManager.REDUCE_FLASHING, true)
	SettingsManager.set_value(SettingsManager.PARTICLE_INTENSITY, SettingsManager.ParticleIntensity.LOW)
	SettingsManager.set_value(SettingsManager.PLAYER_NAME, "Tester")
	SettingsManager.flush_pending_save()
	check(FileAccess.file_exists(SettingsManager.settings_path), "settings are written")
	SettingsManager.load_settings()
	check_near(SettingsManager.get_value(SettingsManager.MUSIC_VOLUME), 0.3, 0.001, "music volume persists")
	check_eq(SettingsManager.get_value(SettingsManager.SCREEN_SHAKE), false, "screen shake persists")
	check(SettingsManager.is_reduce_flashing_enabled(), "reduce flashing persists")
	check_eq(SettingsManager.get_particle_intensity(), SettingsManager.ParticleIntensity.LOW, "particles persist")
	check_eq(SettingsManager.get_value(SettingsManager.PLAYER_NAME), "Tester", "player name persists")
	var bus := AudioServer.get_bus_index(SettingsManager.MUSIC_BUS)
	check_near(db_to_linear(AudioServer.get_bus_volume_db(bus)), 0.3, 0.01, "the music bus follows the setting")
	SettingsManager.reset_to_defaults()
	check_eq(SettingsManager.get_value(SettingsManager.PLAYER_NAME), "Tester", "reset keeps the player name")
	check_near(SettingsManager.get_value(SettingsManager.MUSIC_VOLUME), 0.6, 0.001, "reset restores defaults")


func test_settings_validate_values() -> void:
	SettingsManager.reset_to_defaults()
	check(SettingsManager.set_value(SettingsManager.SFX_VOLUME, 5.0), "an out-of-range volume is accepted")
	check_eq(SettingsManager.get_value(SettingsManager.SFX_VOLUME), 1.0, "and clamped to 1")
	check(not SettingsManager.set_value(SettingsManager.SHOW_FPS, "yes"), "a wrong type is refused")
	check(not SettingsManager.set_value(SettingsManager.PLAYER_NAME, "x"), "a too-short name is refused")
	check(not SettingsManager.set_value(SettingsManager.MASTER_VOLUME, NAN), "NaN is refused")
	SettingsManager.reset_to_defaults()


func test_corrupt_or_tampered_settings_fall_back() -> void:
	var path := SettingsManager.settings_path
	_write_text(path, "[1, 2, 3]")
	SettingsManager.load_settings()
	check_near(SettingsManager.get_value(SettingsManager.MASTER_VOLUME), 0.8, 0.001, "a non-object file loads defaults")
	check(FileAccess.file_exists(path + SaveManager.INVALID_SUFFIX), "the bad file is kept aside")
	_write_text(path, JSON.stringify({"version": 1, "settings": {
		"master_volume": "loud", "sfx_volume": 0.25, "particle_intensity": 9, "unknown_key": true}}))
	SettingsManager.load_settings()
	check_near(SettingsManager.get_value(SettingsManager.MASTER_VOLUME), 0.8, 0.001, "a bad value keeps its default")
	check_near(SettingsManager.get_value(SettingsManager.SFX_VOLUME), 0.25, 0.001, "good values still load")
	check_eq(SettingsManager.get_particle_intensity(), SettingsManager.ParticleIntensity.HIGH,
			"an out-of-range enum is clamped")
	SettingsManager.reset_to_defaults()
	SettingsManager.flush_pending_save()


func test_key_bindings_persist_and_reset() -> void:
	KeyBindings.reset_to_defaults()
	check(KeyBindings.rebind(InputActions.FIRE, KEY_J), "fire can be rebound")
	check(not KeyBindings.rebind(InputActions.FIRE, KEY_ESCAPE), "Esc is reserved")
	check(KeyBindings.rebind(InputActions.BOOST, KEY_W), "a key can move to another action")
	check(not KeyBindings.get_keys(InputActions.THRUST_FORWARD).has(KEY_W), "the key leaves its old action")
	# Lose the in-memory bindings, then reload them from disk.
	InputMap.action_erase_events(InputActions.FIRE)
	KeyBindings.load_bindings()
	check_eq(KeyBindings.get_keys(InputActions.FIRE)[0], KEY_J, "rebinding persists")
	check(KeyBindings.get_keys(InputActions.BOOST).has(KEY_W), "moved key persists")
	KeyBindings.reset_to_defaults()
	check_eq(KeyBindings.get_keys(InputActions.FIRE)[0], KEY_SPACE, "reset restores Space for fire")
	check(KeyBindings.get_keys(InputActions.THRUST_FORWARD).has(KEY_W), "reset restores W for thrust")
