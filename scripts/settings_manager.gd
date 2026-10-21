extends Node
## Autoload "SettingsManager": the player's preferences. Loads them from
## user://settings.json at startup, applies them (audio bus volumes, window
## mode, FPS counter, minimum window size) and saves every change.
##
## Each setting has a default and a type; saved values of the wrong type are
## ignored and numbers are clamped, so a damaged file can only fall back to
## defaults. Gameplay code reads the public values or listens to setting_changed.

signal setting_changed(key: StringName, value: Variant)

enum ParticleIntensity { LOW, MEDIUM, HIGH }

const SETTINGS_PATH: String = "user://settings.json"
const DATA_VERSION: int = 1

const MASTER_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"

const MASTER_VOLUME: StringName = &"master_volume"
const MUSIC_VOLUME: StringName = &"music_volume"
const SFX_VOLUME: StringName = &"sfx_volume"
const MASTER_MUTED: StringName = &"master_muted"
const MUSIC_MUTED: StringName = &"music_muted"
const SFX_MUTED: StringName = &"sfx_muted"
const FULLSCREEN: StringName = &"fullscreen"
const SCREEN_SHAKE: StringName = &"screen_shake"
const PARTICLE_INTENSITY: StringName = &"particle_intensity"
const SHOW_FPS: StringName = &"show_fps"
const REDUCE_FLASHING: StringName = &"reduce_flashing"
const LARGE_HUD: StringName = &"large_hud"
const PLAYER_NAME: StringName = &"player_name"

## Smallest window the player can resize to; the 1920x1080 layout scales down
## uniformly (letterboxed), and below this text gets too small to read.
const MIN_WINDOW_SIZE: Vector2i = Vector2i(960, 540)

## Volumes are linear, 0 to 1. The defaults also define each setting's type.
const DEFAULTS: Dictionary = {
	MASTER_VOLUME: 0.8,
	MUSIC_VOLUME: 0.6,
	SFX_VOLUME: 0.8,
	MASTER_MUTED: false,
	MUSIC_MUTED: false,
	SFX_MUTED: false,
	FULLSCREEN: false,
	SCREEN_SHAKE: true,
	PARTICLE_INTENSITY: ParticleIntensity.HIGH,
	SHOW_FPS: false,
	REDUCE_FLASHING: false,
	LARGE_HUD: false,
	PLAYER_NAME: "",
}

## Display names for ParticleIntensity, in enum order.
const PARTICLE_INTENSITY_NAMES: PackedStringArray = ["Low", "Medium", "High"]

## Where settings are saved; automated tests point it at a scratch file.
var settings_path: String = SETTINGS_PATH
var _values: Dictionary = DEFAULTS.duplicate()
var _save_queued: bool = false
var _fps_layer: CanvasLayer
var _fps_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_build_fps_counter()
	_apply_minimum_window_size()
	load_settings()


func _process(_delta: float) -> void:
	if _fps_layer.visible:
		_fps_label.text = "FPS %d" % Engine.get_frames_per_second()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush_pending_save()


func get_value(key: StringName) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


## Validates, stores, applies and (at the end of the frame) saves one setting.
## Returns false if the key is unknown or the value can't be used.
func set_value(key: StringName, value: Variant) -> bool:
	if not DEFAULTS.has(key):
		push_error("SettingsManager: unknown setting '%s'." % key)
		return false
	var clean: Variant = _validate(key, value)
	if clean == null:
		return false
	if _values[key] == clean:
		return true
	_values[key] = clean
	_apply(key)
	setting_changed.emit(key, clean)
	_queue_save()
	return true


func reset_to_defaults() -> void:
	for key: StringName in DEFAULTS:
		if key != PLAYER_NAME:
			set_value(key, DEFAULTS[key])


## Reloads from disk, keeping defaults for anything missing or invalid.
func load_settings() -> void:
	_values = DEFAULTS.duplicate()
	var data := SaveManager.read_json(settings_path)
	var saved: Variant = data.get("settings", {})
	var ignored := 0
	if saved is Dictionary:
		for raw_key: Variant in saved:
			var key := StringName(str(raw_key))
			if not DEFAULTS.has(key):
				continue
			var clean: Variant = _validate(key, saved[raw_key])
			if clean == null:
				ignored += 1
			else:
				_values[key] = clean
	else:
		ignored += 1
	if ignored > 0:
		push_warning("SettingsManager: ignored %d invalid saved settings." % ignored)
		SaveManager.save_file_recovered.emit(settings_path, "%d invalid settings were reset" % ignored)
	for key: StringName in _values:
		_apply(key)
		setting_changed.emit(key, _values[key])


func save_settings() -> bool:
	_save_queued = false
	return SaveManager.write_json(settings_path, {"version": DATA_VERSION, "settings": _values.duplicate()})


func is_screen_shake_enabled() -> bool:
	return get_value(SCREEN_SHAKE)


func get_particle_intensity() -> ParticleIntensity:
	return get_value(PARTICLE_INTENSITY)


## Accessibility: no full-screen flashes and no blinking ship.
func is_reduce_flashing_enabled() -> bool:
	return get_value(REDUCE_FLASHING)


## Accessibility: larger HUD text.
func is_large_hud_enabled() -> bool:
	return get_value(LARGE_HUD)


## Returns the value converted to the setting's type, or null if it can't be.
func _validate(key: StringName, value: Variant) -> Variant:
	var default: Variant = DEFAULTS[key]
	match typeof(default):
		TYPE_BOOL:
			return value if value is bool else null
		TYPE_FLOAT:
			if (value is float or value is int) and is_finite(float(value)):
				return clampf(float(value), 0.0, 1.0)
			return null
		TYPE_INT:
			# Enum settings; JSON stores numbers as floats.
			if (value is int or value is float) and float(value) == floorf(float(value)):
				return clampi(int(value), 0, PARTICLE_INTENSITY_NAMES.size() - 1)
			return null
		TYPE_STRING:
			if not value is String:
				return null
			var clean_name := Leaderboard.sanitize_name(value)
			return clean_name if clean_name.is_empty() or Leaderboard.is_valid_name(clean_name) else null
	return null


func _apply(key: StringName) -> void:
	match key:
		MASTER_VOLUME, MASTER_MUTED:
			_apply_bus(MASTER_BUS, get_value(MASTER_VOLUME), get_value(MASTER_MUTED))
		MUSIC_VOLUME, MUSIC_MUTED:
			_apply_bus(MUSIC_BUS, get_value(MUSIC_VOLUME), get_value(MUSIC_MUTED))
		SFX_VOLUME, SFX_MUTED:
			_apply_bus(SFX_BUS, get_value(SFX_VOLUME), get_value(SFX_MUTED))
		FULLSCREEN:
			_apply_window_mode(get_value(FULLSCREEN))
		SHOW_FPS:
			_fps_layer.visible = get_value(SHOW_FPS)


func _apply_bus(bus_name: StringName, volume: float, muted: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, muted or volume <= 0.0)


func _apply_window_mode(fullscreen: bool) -> void:
	# Headless runs and the editor's embedded game view have no window to change.
	if DisplayServer.get_name() == "headless" or Engine.is_embedded_in_editor():
		return
	var wanted := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != wanted:
		DisplayServer.window_set_mode(wanted)


func _apply_minimum_window_size() -> void:
	if DisplayServer.get_name() == "headless" or Engine.is_embedded_in_editor():
		return
	get_window().min_size = MIN_WINDOW_SIZE


## Music and SFX buses normally come from default_bus_layout.tres; this keeps
## volume settings working if the layout is missing.
func _ensure_audio_buses() -> void:
	for bus_name in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, MASTER_BUS)


func _build_fps_counter() -> void:
	_fps_layer = CanvasLayer.new()
	_fps_layer.name = "FpsCounter"
	_fps_layer.layer = 100
	_fps_layer.visible = false
	_fps_label = Label.new()
	_fps_label.add_theme_font_size_override(&"font_size", 22)
	_fps_label.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6, 0.9))
	_fps_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_fps_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_fps_label.offset_left = 16.0
	_fps_label.offset_bottom = -10.0
	_fps_layer.add_child(_fps_label)
	add_child(_fps_layer)


func _queue_save() -> void:
	if _save_queued:
		return
	_save_queued = true
	flush_pending_save.call_deferred()


## Writes a queued change now (used before quitting).
func flush_pending_save() -> void:
	if _save_queued:
		save_settings()
