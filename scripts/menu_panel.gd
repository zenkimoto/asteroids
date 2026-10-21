class_name MenuPanel
extends Control
## Base for full-screen menu panels and dialogs. open() fades the panel in and
## focuses `default_focus`; Esc (ui_cancel) or close() hides it and emits
## `closed` so whoever opened it can take focus back. Esc plays the "back" sound.

signal closed

@export var default_focus: Control
## When false, Esc is ignored (for dialogs that need an answer).
@export var close_on_cancel: bool = true
## Seconds the panel takes to fade in.
@export_range(0.0, 1.0, 0.01) var fade_in_time: float = 0.12

var _fade_tween: Tween


func _ready() -> void:
	visible = false


func open() -> void:
	visible = true
	if fade_in_time > 0.0:
		if _fade_tween != null:
			_fade_tween.kill()
		modulate.a = 0.0
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "modulate:a", 1.0, fade_in_time)
	if default_focus != null:
		default_focus.grab_focus()


func close() -> void:
	if not visible:
		return
	if _fade_tween != null:
		_fade_tween.kill()
	modulate.a = 1.0
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and close_on_cancel and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		MenuFeedback.play_back()
		close()


## Links `controls` into a loop for keyboard navigation: arrow keys (up/down, or
## left/right when not `vertical`) and Tab wrap from the last to the first.
static func wrap_focus(controls: Array, vertical: bool = true) -> void:
	var count := controls.size()
	for i in count:
		var control: Control = controls[i]
		var next: NodePath = control.get_path_to(controls[(i + 1) % count])
		var previous: NodePath = control.get_path_to(controls[(i - 1 + count) % count])
		if vertical:
			control.focus_neighbor_bottom = next
			control.focus_neighbor_top = previous
		else:
			control.focus_neighbor_right = next
			control.focus_neighbor_left = previous
		control.focus_next = next
		control.focus_previous = previous
