class_name SettingsPanel
extends MenuPanel
## Edits SettingsManager's values: audio volumes and mutes, fullscreen, screen
## shake, particle intensity, the FPS counter and the accessibility options
## (reduce flashing, large HUD text), and opens the Controls panel. Changes apply and save at once;
## the controls follow SettingsManager, so they stay in sync wherever they change.
## On/off settings are toggle buttons whose text spells out the state.

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _master_value: Label = %MasterValue
@onready var _music_value: Label = %MusicValue
@onready var _sfx_value: Label = %SfxValue
@onready var _master_mute: Button = %MasterMute
@onready var _music_mute: Button = %MusicMute
@onready var _sfx_mute: Button = %SfxMute
@onready var _fullscreen_toggle: Button = %FullscreenToggle
@onready var _shake_toggle: Button = %ShakeToggle
@onready var _particles_option: OptionButton = %ParticlesOption
@onready var _fps_toggle: Button = %FpsToggle
@onready var _reduce_flashing_toggle: Button = %ReduceFlashingToggle
@onready var _large_hud_toggle: Button = %LargeHudToggle
@onready var _controls_button: Button = %ControlsButton
@onready var _controls_panel: ControlsPanel = %ControlsPanel
@onready var _center: Control = $Center
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton

## Setting key -> [control, value label or null] for the volume rows.
var _volume_rows: Dictionary = {}
## Setting key -> toggle Button for the on/off settings.
var _toggles: Dictionary = {}
## Keys whose toggle reads "Muted"/"Mute" rather than "ON"/"OFF".
var _mute_keys: Array[StringName] = []


func _ready() -> void:
	super()
	_volume_rows = {
		SettingsManager.MASTER_VOLUME: [_master_slider, _master_value],
		SettingsManager.MUSIC_VOLUME: [_music_slider, _music_value],
		SettingsManager.SFX_VOLUME: [_sfx_slider, _sfx_value],
	}
	_toggles = {
		SettingsManager.MASTER_MUTED: _master_mute,
		SettingsManager.MUSIC_MUTED: _music_mute,
		SettingsManager.SFX_MUTED: _sfx_mute,
		SettingsManager.FULLSCREEN: _fullscreen_toggle,
		SettingsManager.SCREEN_SHAKE: _shake_toggle,
		SettingsManager.SHOW_FPS: _fps_toggle,
		SettingsManager.REDUCE_FLASHING: _reduce_flashing_toggle,
		SettingsManager.LARGE_HUD: _large_hud_toggle,
	}
	_mute_keys = [SettingsManager.MASTER_MUTED, SettingsManager.MUSIC_MUTED, SettingsManager.SFX_MUTED]
	for key: StringName in _volume_rows:
		var slider: HSlider = _volume_rows[key][0]
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 5.0
		slider.value_changed.connect(_on_volume_changed.bind(key))
	for key: StringName in _toggles:
		(_toggles[key] as Button).toggled.connect(_on_toggled.bind(key))
	_particles_option.clear()
	for i in SettingsManager.PARTICLE_INTENSITY_NAMES.size():
		_particles_option.add_item(SettingsManager.PARTICLE_INTENSITY_NAMES[i], i)
	_particles_option.item_selected.connect(_on_particles_selected)
	_reset_button.pressed.connect(SettingsManager.reset_to_defaults)
	_controls_button.pressed.connect(_open_controls)
	_controls_panel.closed.connect(_on_controls_closed)
	_back_button.pressed.connect(close)
	SettingsManager.setting_changed.connect(_on_setting_changed)
	_sync_all()


func open() -> void:
	_sync_all()
	_controls_panel.visible = false
	_center.visible = true
	super()


func close() -> void:
	_controls_panel.visible = false
	_center.visible = true
	super()


func _open_controls() -> void:
	_center.visible = false
	_controls_panel.open()


func _on_controls_closed() -> void:
	_center.visible = true
	_controls_button.grab_focus()


func _sync_all() -> void:
	for key: StringName in SettingsManager.DEFAULTS:
		_on_setting_changed(key, SettingsManager.get_value(key))


## Mirrors a setting into its control without feeding the change back.
func _on_setting_changed(key: StringName, value: Variant) -> void:
	if _volume_rows.has(key):
		var percent := roundf(float(value) * 100.0)
		(_volume_rows[key][0] as HSlider).set_value_no_signal(percent)
		(_volume_rows[key][1] as Label).text = "%d%%" % percent
	elif _toggles.has(key):
		var button: Button = _toggles[key]
		button.set_pressed_no_signal(value)
		if key in _mute_keys:
			button.text = "Muted" if value else "Mute"
		else:
			button.text = "ON" if value else "OFF"
	elif key == SettingsManager.PARTICLE_INTENSITY:
		_particles_option.select(int(value))


func _on_volume_changed(percent: float, key: StringName) -> void:
	SettingsManager.set_value(key, percent / 100.0)


func _on_toggled(pressed: bool, key: StringName) -> void:
	SettingsManager.set_value(key, pressed)


func _on_particles_selected(index: int) -> void:
	SettingsManager.set_value(SettingsManager.PARTICLE_INTENSITY, _particles_option.get_item_id(index))
