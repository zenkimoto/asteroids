class_name ControlsPanel
extends MenuPanel
## Lists the rebindable gameplay actions with their keys. Choosing an action
## waits for the next key press and binds it as that action's primary key
## (Esc cancels); a key taken from another action is moved, and the message line
## says so. Reset Defaults restores the project's Input Map.

@export var row_font_size: int = 28
@export var waiting_color: Color = Color(1, 0.8, 0.3, 1)
@export var message_color: Color = Color(0.85, 0.92, 1, 1)
@export var warning_color: Color = Color(1, 0.55, 0.85, 1)

## Action -> its key Button.
var _key_buttons: Dictionary = {}
## Action waiting for a key, or &"" when not capturing.
var _capturing: StringName = &""

@onready var _rows: GridContainer = %Rows
@onready var _message: Label = %Message
@onready var _reset_button: Button = %ResetButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	super()
	for action in KeyBindings.get_actions():
		var label := Label.new()
		label.text = KeyBindings.get_display_name(action)
		label.custom_minimum_size = Vector2(300, 0)
		label.add_theme_font_size_override(&"font_size", row_font_size)
		_rows.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(420, 56)
		button.add_theme_font_size_override(&"font_size", row_font_size)
		button.pressed.connect(_start_capture.bind(action))
		_rows.add_child(button)
		_key_buttons[action] = button
	default_focus = _key_buttons[KeyBindings.get_actions()[0]]
	_reset_button.pressed.connect(_on_reset_pressed)
	_back_button.pressed.connect(close)
	KeyBindings.bindings_changed.connect(_refresh)
	_refresh()


func open() -> void:
	_capturing = &""
	_show_message("Choose an action, then press the new key.", message_color)
	_refresh()
	super()


func close() -> void:
	_capturing = &""
	super()


func is_capturing() -> bool:
	return _capturing != &""


func _input(event: InputEvent) -> void:
	if not visible or _capturing == &"":
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	get_viewport().set_input_as_handled()
	var action := _capturing
	_capturing = &""
	var key := key_event.keycode if key_event.keycode != KEY_NONE else key_event.physical_keycode
	if key == KEY_ESCAPE:
		MenuFeedback.play_back()
		_show_message("Cancelled.", message_color)
	else:
		var taken_from := _action_using(key, action)
		if KeyBindings.rebind(action, key):
			MenuFeedback.play_select()
			var text := "%s is now %s." % [KeyBindings.get_display_name(action), OS.get_keycode_string(key)]
			if taken_from != &"":
				text += " It was moved from %s." % KeyBindings.get_display_name(taken_from)
			_show_message(text, warning_color if taken_from != &"" else message_color)
		else:
			_show_message("%s can't be used." % OS.get_keycode_string(key), warning_color)
	_refresh()
	(_key_buttons[action] as Button).grab_focus()


func _start_capture(action: StringName) -> void:
	_capturing = action
	_refresh()
	_show_message("Press a key for %s.  Esc cancels." % KeyBindings.get_display_name(action), waiting_color)


func _refresh() -> void:
	for action: StringName in _key_buttons:
		var button: Button = _key_buttons[action]
		if action == _capturing:
			button.text = "Press a key..."
			button.add_theme_color_override(&"font_color", waiting_color)
			button.add_theme_color_override(&"font_focus_color", waiting_color)
		else:
			button.text = KeyBindings.get_keys_text(action)
			button.remove_theme_color_override(&"font_color")
			button.remove_theme_color_override(&"font_focus_color")


func _on_reset_pressed() -> void:
	_capturing = &""
	KeyBindings.reset_to_defaults()
	_show_message("Controls reset to the defaults.", message_color)


func _action_using(key: Key, except: StringName) -> StringName:
	for action in KeyBindings.get_actions():
		if action != except and key in KeyBindings.get_keys(action):
			return action
	return &""


func _show_message(text: String, color: Color) -> void:
	_message.text = text
	_message.add_theme_color_override(&"font_color", color)
