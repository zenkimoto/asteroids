class_name Hud
extends CanvasLayer
## In-game HUD. Top left: score and combo. Top centre: wave and brief
## notifications. Top right: lives, the shield and active power-ups with their
## countdowns. Values are pushed in by the game scene; countdowns are read each
## frame from `effects` and the combo bar from ScoreManager.

## Seconds a notification stays fully visible before fading.
@export_range(0.2, 5.0, 0.1) var notification_time: float = 1.2
@export var combo_color: Color = Color(1, 0.8, 0.3, 1)

## Set by the game scene; supplies power-up countdowns.
var effects: PowerUpEffects

## PowerUpDefinition.Kind -> [Label, PowerUpDefinition] for each lasting effect shown.
var _effect_rows: Dictionary = {}
var _notification_tween: Tween

@onready var _score_label: Label = %ScoreLabel
@onready var _combo_label: Label = %ComboLabel
@onready var _combo_bar: ProgressBar = %ComboBar
@onready var _wave_label: Label = %WaveLabel
@onready var _notification_label: Label = %NotificationLabel
@onready var _lives_label: Label = %LivesLabel
@onready var _effects_box: VBoxContainer = %EffectsBox


func _ready() -> void:
	set_combo(0, 1)
	_notification_label.modulate.a = 0.0


func _process(_delta: float) -> void:
	_combo_bar.value = ScoreManager.get_combo_time_ratio()
	for kind in _effect_rows:
		_update_effect_row(kind)


func set_score(score: int) -> void:
	_score_label.text = "SCORE  %d" % score


func set_wave(wave: int) -> void:
	_wave_label.text = "WAVE  %d" % wave


func set_lives(lives: int) -> void:
	_lives_label.text = "LIVES  %d" % maxi(lives, 0)


func set_combo(kills: int, multiplier: int) -> void:
	_combo_label.visible = kills > 0
	_combo_bar.visible = kills > 0
	_combo_label.text = "x%d   COMBO %d" % [multiplier, kills]


## Shows a short message under the wave number, then fades it out.
func notify(text: String, color: Color = Color.WHITE) -> void:
	_notification_label.text = text
	_notification_label.add_theme_color_override(&"font_color", color)
	if _notification_tween != null:
		_notification_tween.kill()
	_notification_label.modulate.a = 1.0
	_notification_tween = create_tween()
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
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_font_size_override(&"font_size", 26)
		label.add_theme_color_override(&"font_color", definition.color)
		_effects_box.add_child(label)
		_effect_rows[definition.kind] = [label, definition]
	_update_effect_row(definition.kind)


func on_effect_ended(kind: PowerUpDefinition.Kind) -> void:
	if not _effect_rows.has(kind):
		return
	var label: Label = _effect_rows[kind][0]
	_effect_rows.erase(kind)
	label.queue_free()


func _update_effect_row(kind: PowerUpDefinition.Kind) -> void:
	var label: Label = _effect_rows[kind][0]
	var definition: PowerUpDefinition = _effect_rows[kind][1]
	var title := definition.display_name.to_upper()
	if definition.duration > 0.0 and effects != null:
		label.text = "%s  %.1f" % [title, effects.get_time_left(kind)]
	else:
		label.text = title
