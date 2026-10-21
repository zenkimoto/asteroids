class_name MenuPanel
extends Control
## Base for full-screen menu panels and dialogs. open() shows the panel and
## focuses `default_focus`; Esc (ui_cancel) or close() hides it and emits
## `closed` so whoever opened it can take focus back.

signal closed

@export var default_focus: Control
## When false, Esc is ignored (for dialogs that need an answer).
@export var close_on_cancel: bool = true


func _ready() -> void:
	visible = false


func open() -> void:
	visible = true
	if default_focus != null:
		default_focus.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and close_on_cancel and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
