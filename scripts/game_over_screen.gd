class_name GameOverScreen
extends CanvasLayer
## Shown when the last life is lost. Emits restart_requested from its button.

signal restart_requested

## Seconds before the button responds, so a held Spacebar can't skip the screen.
@export_range(0.0, 3.0, 0.1) var input_delay: float = 0.8

@onready var _score_label: Label = %FinalScoreLabel
@onready var _restart_button: Button = %RestartButton
@onready var _input_delay_timer: Timer = $InputDelay


func _ready() -> void:
	visible = false
	_restart_button.pressed.connect(restart_requested.emit)
	_input_delay_timer.timeout.connect(_enable_restart)


func show_results(final_score: int) -> void:
	_score_label.text = "FINAL SCORE  %d" % final_score
	_restart_button.disabled = true
	visible = true
	_input_delay_timer.start(maxf(input_delay, 0.001))


func hide_results() -> void:
	_input_delay_timer.stop()
	visible = false


func _enable_restart() -> void:
	_restart_button.disabled = false
	_restart_button.grab_focus()
