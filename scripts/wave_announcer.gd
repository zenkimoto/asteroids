class_name WaveAnnouncer
extends CanvasLayer
## Centre-screen wave messages: the countdown, "GO!" and "Wave complete".
## Its tweens pause with the game.

## Seconds "GO!" stays up before fading.
@export_range(0.0, 3.0, 0.05) var go_display_time: float = 0.6
## Full width of the light bar that sweeps out under the title.
@export_range(0.0, 1600.0, 10.0) var sweep_width: float = 560.0
@export var sweep_color: Color = Color(0.3, 0.95, 1, 0.8)
@export var complete_sweep_color: Color = Color(1, 0.8, 0.3, 0.9)

var _tween: Tween

@onready var _panel: Control = %Panel
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _sweep: ColorRect = %Sweep


func _ready() -> void:
	hide_now()


func show_countdown(wave: int, seconds_left: int) -> void:
	_show("WAVE %d" % wave, str(seconds_left))


func show_wave_started(wave: int) -> void:
	_show("WAVE %d" % wave, "GO!", go_display_time)


func show_wave_complete(wave: int, bonus: int) -> void:
	_show("WAVE %d COMPLETE" % wave, "+%d BONUS" % bonus, 0.0, complete_sweep_color)


func hide_now() -> void:
	if _tween != null:
		_tween.kill()
	visible = false


## Pops the message in and sweeps the light bar out from the centre; with
## `fade_after` > 0 it fades out after that long.
func _show(title: String, subtitle: String, fade_after: float = 0.0, bar_color: Color = sweep_color) -> void:
	var same_title := visible and _title.text == title
	_title.text = title
	_subtitle.text = subtitle
	visible = true
	_sweep.color = bar_color
	if not same_title:
		_sweep.custom_minimum_size.x = 0.0
	if _tween != null:
		_tween.kill()
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2.ONE * 1.3
	_panel.modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.15)
	_tween.tween_property(_sweep, "custom_minimum_size:x", sweep_width, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if fade_after > 0.0:
		_tween.chain().tween_property(_panel, "modulate:a", 0.0, 0.3).set_delay(fade_after)
		_tween.chain().tween_callback(_hide)


func _hide() -> void:
	visible = false
