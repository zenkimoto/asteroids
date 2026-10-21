class_name PauseOverlay
extends CanvasLayer
## Pause screen with Resume and Restart. Runs while the tree is paused.

signal resume_requested
signal restart_requested

@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(resume_requested.emit)
	_restart_button.pressed.connect(restart_requested.emit)


func focus_default() -> void:
	_resume_button.grab_focus()
