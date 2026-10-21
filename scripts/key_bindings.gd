extends Node
## Autoload "KeyBindings": lets the player change which keys drive each gameplay
## action. Changes apply to the InputMap at once and are saved to
## user://controls.json; the Input Map in project.godot stays the default.
## A key can belong to only one rebindable action, so binding it moves it.
## Esc always pauses and backs out of menus, so it can't be rebound.

signal bindings_changed

const CONTROLS_PATH: String = "user://controls.json"
const DATA_VERSION: int = 1
## Actions the player may rebind and their display names, in menu order.
const REBINDABLE: Array[Array] = [
	[InputActions.THRUST_FORWARD, "Thrust forward"],
	[InputActions.THRUST_REVERSE, "Reverse thrust"],
	[InputActions.ROTATE_LEFT, "Rotate left"],
	[InputActions.ROTATE_RIGHT, "Rotate right"],
	[InputActions.FIRE, "Fire"],
	[InputActions.BOOST, "Boost"],
]
const RESERVED_KEYS: Array[Key] = [KEY_ESCAPE]

## Action -> its keycodes from project.godot.
var _defaults: Dictionary = {}


func _ready() -> void:
	for action in get_actions():
		_defaults[action] = get_keys(action)
	load_bindings()


func get_actions() -> Array[StringName]:
	var actions: Array[StringName] = []
	for row in REBINDABLE:
		actions.append(row[0])
	return actions


func get_display_name(action: StringName) -> String:
	for row in REBINDABLE:
		if row[0] == action:
			return row[1]
	return String(action)


## Keycodes currently bound to `action`, in order (the first is the primary key).
func get_keys(action: StringName) -> Array[Key]:
	var keys: Array[Key] = []
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event != null:
			keys.append(key_event.keycode if key_event.keycode != KEY_NONE else key_event.physical_keycode)
	return keys


## Readable key names, e.g. "W / Up".
func get_keys_text(action: StringName) -> String:
	var names: PackedStringArray = []
	for key in get_keys(action):
		names.append(OS.get_keycode_string(key))
	return " / ".join(names) if not names.is_empty() else "(unbound)"


func is_reserved(key: Key) -> bool:
	return key in RESERVED_KEYS


## Makes `key` the primary key of `action`, removing it from any other
## rebindable action. Returns false for reserved or invalid keys.
func rebind(action: StringName, key: Key) -> bool:
	if not _defaults.has(action) or key == KEY_NONE or is_reserved(key) or OS.get_keycode_string(key).is_empty():
		return false
	for other in get_actions():
		if other != action and key in get_keys(other):
			var remaining := get_keys(other)
			remaining.erase(key)
			_set_keys(other, remaining)
	var keys := get_keys(action)
	keys.erase(key)
	if keys.is_empty():
		keys.append(key)
	else:
		keys[0] = key
	_set_keys(action, keys)
	save_bindings()
	bindings_changed.emit()
	return true


func reset_to_defaults() -> void:
	for action in get_actions():
		_set_keys(action, _defaults[action])
	save_bindings()
	bindings_changed.emit()


## Applies saved bindings; anything missing or invalid keeps its default.
func load_bindings() -> void:
	var data := SaveManager.read_json(CONTROLS_PATH)
	var saved: Variant = data.get("bindings", {})
	if not saved is Dictionary:
		return
	for action in get_actions():
		var keys := _parse_keys(saved.get(String(action)))
		if not keys.is_empty():
			_set_keys(action, keys)
	bindings_changed.emit()


func save_bindings() -> bool:
	var bindings := {}
	for action in get_actions():
		bindings[String(action)] = get_keys(action)
	return SaveManager.write_json(CONTROLS_PATH, {"version": DATA_VERSION, "bindings": bindings})


func _parse_keys(value: Variant) -> Array[Key]:
	var keys: Array[Key] = []
	if not value is Array:
		return keys
	for item: Variant in value:
		if not (item is int or item is float) or float(item) != floorf(float(item)):
			continue
		var key := int(item) as Key
		if key != KEY_NONE and not is_reserved(key) and not OS.get_keycode_string(key).is_empty() and not key in keys:
			keys.append(key)
	return keys


## Replaces the action's key events; other kinds of events (none today) are kept.
func _set_keys(action: StringName, keys: Array) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	for key: Key in keys:
		var event := InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action, event)
