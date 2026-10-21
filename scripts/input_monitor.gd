class_name InputMonitor
extends CanvasLayer
## Development overlay that lists every configured input action and highlights the
## ones currently held. Used to confirm the Input Map works; it also logs changes.
## Toggle with F3.

signal action_state_changed(action: StringName, pressed: bool)

@export var pressed_color: Color = Color(0.3, 1.0, 0.5)
@export var released_color: Color = Color(0.55, 0.6, 0.7)
@export_range(8, 64) var font_size: int = 22
@export var log_to_console: bool = true
@export var start_visible: bool = false
## Removes the overlay from release exports so players never see it.
@export var debug_builds_only: bool = true

var _actions: Array[StringName] = []
var _labels: Dictionary[StringName, Label] = {}
var _pressed: Dictionary[StringName, bool] = {}

@onready var _rows: VBoxContainer = %Rows


func _ready() -> void:
	if debug_builds_only and not OS.is_debug_build():
		queue_free()
		return
	# Keep reporting input even when the tree is paused (needed once pause exists).
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = start_visible
	for action in InputActions.missing_actions():
		push_error("Input action '%s' is not defined in the Input Map." % action)
	for action in InputActions.ALL:
		if not InputMap.has_action(action):
			continue
		var label := Label.new()
		label.text = _describe(action)
		label.add_theme_font_size_override("font_size", font_size)
		_rows.add_child(label)
		_actions.append(action)
		_labels[action] = label
		_pressed[action] = false
		_apply_style(action)
	action_state_changed.connect(_on_action_state_changed)
	if log_to_console:
		print("[InputMonitor] %d/%d input actions configured." % [_actions.size(), InputActions.ALL.size()])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.TOGGLE_DEBUG):
		# Not marked handled: other debug overlays toggle on the same key.
		visible = not visible


func _process(_delta: float) -> void:
	for action in _actions:
		var is_pressed := Input.is_action_pressed(action)
		if is_pressed != _pressed[action]:
			_pressed[action] = is_pressed
			action_state_changed.emit(action, is_pressed)


func is_action_held(action: StringName) -> bool:
	return _pressed.get(action, false)


func _on_action_state_changed(action: StringName, is_pressed: bool) -> void:
	_apply_style(action)
	# Only log while the overlay is shown, so normal play doesn't flood the console.
	if log_to_console and visible:
		print("[Input] %s %s" % [action, "pressed" if is_pressed else "released"])


func _apply_style(action: StringName) -> void:
	var color := pressed_color if _pressed[action] else released_color
	_labels[action].add_theme_color_override("font_color", color)


## "rotate_left  [A, Left]": the action name followed by its bound keys.
func _describe(action: StringName) -> String:
	var keys := PackedStringArray()
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event and key_event.physical_keycode != KEY_NONE:
			var keycode := DisplayServer.keyboard_get_keycode_from_physical(key_event.physical_keycode)
			keys.append(OS.get_keycode_string(keycode))
		else:
			keys.append(event.as_text())
	return "%s  [%s]" % [action, ", ".join(keys)]
