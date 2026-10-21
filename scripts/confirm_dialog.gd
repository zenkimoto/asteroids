class_name ConfirmDialog
extends MenuPanel
## Yes/no question. ask() sets the text and opens it; Confirm emits `confirmed`,
## Cancel or Esc just closes it (emitting `closed`).

signal confirmed

@onready var _message_label: Label = %MessageLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	super()
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(close)
	MenuPanel.wrap_focus([_confirm_button, _cancel_button], false)


func ask(message: String, confirm_text: String = "Yes") -> void:
	_message_label.text = message
	_confirm_button.text = confirm_text
	open()


func _on_confirm_pressed() -> void:
	visible = false
	confirmed.emit()
