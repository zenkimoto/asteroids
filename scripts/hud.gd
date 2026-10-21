class_name Hud
extends CanvasLayer
## In-game HUD. Top left: score, best score and combo. Top centre: wave and brief
## notifications. Top right: lives (number and ship icons), the shield and active
## power-ups with their countdowns. Values are pushed in by the game scene;
## countdowns are read each frame from `effects` and the combo bar from
## ScoreManager. Text is outlined to stay readable over the playfield, numbers
## pop when they change, and the Large HUD Text setting scales every label.

## Seconds a notification stays fully visible before fading.
@export_range(0.2, 5.0, 0.1) var notification_time: float = 1.4
@export var combo_color: Color = Color(1, 0.8, 0.3, 1)
@export var best_color: Color = Color(0.6, 0.66, 0.78, 1)
@export var new_best_color: Color = Color(1, 0.55, 0.85, 1)
## Text size multiplier when Large HUD Text is on.
@export_range(1.0, 2.0, 0.05) var large_text_scale: float = 1.3
## A timed power-up pulses during its last seconds.
@export_range(0.0, 10.0, 0.5) var expiry_warning_time: float = 3.0
@export var row_font_size: int = 26

## Set by the game scene; supplies power-up countdowns.
var effects: PowerUpEffects

## PowerUpDefinition.Kind -> [row Control, Label, ProgressBar, PowerUpDefinition].
var _effect_rows: Dictionary = {}
var _notification_tween: Tween
var _score: int = 0
var _best: int = 0
var _lives: int = -1
var _wave: int = 0
var _time: float = 0.0
## Label -> its font size at normal scale.
var _base_font_sizes: Dictionary = {}

@onready var _score_label: Label = %ScoreLabel
@onready var _best_label: Label = %BestLabel
@onready var _combo_label: Label = %ComboLabel
@onready var _combo_bar: ProgressBar = %ComboBar
@onready var _wave_label: Label = %WaveLabel
@onready var _notification_label: Label = %NotificationLabel
@onready var _lives_label: Label = %LivesLabel
@onready var _lives_icons: LivesIcons = %LivesIcons
@onready var _effects_box: VBoxContainer = %EffectsBox


func _ready() -> void:
	set_combo(0, 1)
	_notification_label.modulate.a = 0.0
	for label: Label in [_score_label, _best_label, _combo_label, _wave_label, _notification_label, _lives_label]:
		_base_font_sizes[label] = label.get_theme_font_size(&"font_size")
	SettingsManager.setting_changed.connect(_on_setting_changed)
	_apply_text_scale()


func _process(delta: float) -> void:
	_time += delta
	_combo_bar.value = ScoreManager.get_combo_time_ratio()
	for kind in _effect_rows:
		_update_effect_row(kind)


func set_score(score: int) -> void:
	var increased := score > _score
	_score = score
	_score_label.text = "SCORE  %d" % score
	if increased:
		_pop(_score_label, 1.12)
	if score > _best:
		set_best(score, true)


## `beaten` marks a best set during this game.
func set_best(best: int, beaten: bool = false) -> void:
	_best = best
	_best_label.visible = best > 0
	_best_label.text = ("NEW BEST  %d" if beaten else "BEST  %d") % best
	_best_label.add_theme_color_override(&"font_color", new_best_color if beaten else best_color)


func set_wave(wave: int) -> void:
	_wave_label.text = "WAVE  %d" % wave
	if wave != _wave:
		_pop(_wave_label, 1.25)
	_wave = wave


func set_lives(lives: int) -> void:
	lives = maxi(lives, 0)
	_lives_label.text = "LIVES  %d" % lives
	_lives_icons.lives = lives
	if _lives >= 0 and lives != _lives:
		_pop(_lives_label, 1.2)
	_lives = lives


func set_combo(kills: int, multiplier: int) -> void:
	_combo_label.visible = kills > 0
	_combo_bar.visible = kills > 0
	_combo_label.text = "x%d   COMBO %d" % [multiplier, kills]


## Shows a short message under the wave number: it pops in, holds, then fades.
func notify(text: String, color: Color = Color.WHITE) -> void:
	_notification_label.text = text
	_notification_label.add_theme_color_override(&"font_color", color)
	if _notification_tween != null:
		_notification_tween.kill()
	_notification_label.modulate.a = 1.0
	_notification_label.pivot_offset = _notification_label.size * 0.5
	_notification_label.scale = Vector2.ONE * 1.25
	_notification_tween = create_tween()
	_notification_tween.tween_property(_notification_label, "scale", Vector2.ONE, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_notification_tween.tween_property(_notification_label, "modulate:a", 0.0, 0.4).set_delay(notification_time)


func on_power_up_applied(definition: PowerUpDefinition, had_effect: bool) -> void:
	if definition.kind == PowerUpDefinition.Kind.REPAIR:
		notify("REPAIR  +1 LIFE" if had_effect else "LIVES FULL", definition.color)
	else:
		notify(definition.display_name.to_upper(), definition.color)


func on_multiplier_increased(multiplier: int) -> void:
	notify("COMBO  x%d" % multiplier, combo_color)


func on_extra_life_awarded(_lives: int) -> void:
	notify("EXTRA LIFE", Color(1, 0.55, 0.85, 1))


func on_effect_started(definition: PowerUpDefinition) -> void:
	if not _effect_rows.has(definition.kind):
		var row := VBoxContainer.new()
		row.add_theme_constant_override(&"separation", 2)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_style_label(label, row_font_size, definition.color)
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(200, 5)
		bar.size_flags_horizontal = Control.SIZE_SHRINK_END
		bar.show_percentage = false
		bar.max_value = 1.0
		bar.step = 0.001
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override(&"background", _bar_style(Color(1, 1, 1, 0.12)))
		bar.add_theme_stylebox_override(&"fill", _bar_style(definition.color))
		bar.visible = definition.duration > 0.0
		row.add_child(bar)
		_effects_box.add_child(row)
		_base_font_sizes[label] = row_font_size
		_effect_rows[definition.kind] = [row, label, bar, definition]
		_apply_text_scale()
		row.modulate.a = 0.0
		row.create_tween().tween_property(row, "modulate:a", 1.0, 0.2)
	else:
		_pop(_effect_rows[definition.kind][1], 1.15)
	_update_effect_row(definition.kind)


func on_effect_ended(kind: PowerUpDefinition.Kind) -> void:
	if not _effect_rows.has(kind):
		return
	var row: Control = _effect_rows[kind][0]
	_base_font_sizes.erase(_effect_rows[kind][1])
	_effect_rows.erase(kind)
	row.queue_free()


func _update_effect_row(kind: PowerUpDefinition.Kind) -> void:
	var label: Label = _effect_rows[kind][1]
	var bar: ProgressBar = _effect_rows[kind][2]
	var definition: PowerUpDefinition = _effect_rows[kind][3]
	# The bracketed letter matches the pickup, so rows don't rely on colour alone.
	var title := "[%s] %s" % [definition.icon_text, definition.display_name.to_upper()]
	if definition.duration > 0.0 and effects != null:
		var time_left := effects.get_time_left(kind)
		label.text = "%s  %.1f" % [title, time_left]
		bar.value = clampf(time_left / definition.duration, 0.0, 1.0)
		var warning := time_left <= expiry_warning_time and not SettingsManager.is_reduce_flashing_enabled()
		label.modulate.a = 0.55 + 0.45 * absf(cos(_time * PI * 2.5)) if warning else 1.0
	else:
		label.text = title


## Briefly enlarges a label around its text's anchor and eases it back.
func _pop(label: Label, amount: float) -> void:
	var anchor_x := 0.0
	match label.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			anchor_x = label.size.x * 0.5
		HORIZONTAL_ALIGNMENT_RIGHT:
			anchor_x = label.size.x
	label.pivot_offset = Vector2(anchor_x, label.size.y * 0.5)
	label.scale = Vector2.ONE * amount
	label.create_tween().tween_property(label, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", Color(0, 0, 0.03, 0.85))
	label.add_theme_constant_override(&"outline_size", 6)


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style


func _apply_text_scale() -> void:
	var factor := large_text_scale if SettingsManager.is_large_hud_enabled() else 1.0
	for label: Label in _base_font_sizes:
		label.add_theme_font_size_override(&"font_size", roundi(_base_font_sizes[label] * factor))
	_combo_bar.custom_minimum_size.x = 220.0 * factor


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == SettingsManager.LARGE_HUD:
		_apply_text_scale()
