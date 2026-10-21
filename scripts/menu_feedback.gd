extends Node
## Autoload "MenuFeedback": consistent feel for every menu without per-screen
## code. Moving focus with the keyboard or mouse plays a tick, pressing a button
## or picking an option plays a confirm sound, and hovering a button with the
## mouse also focuses it, so keyboard focus and the highlighted button never
## disagree. MenuPanel plays the "back" sound when Esc closes a panel.

## Focus changes this soon after real input count as the player's, so focus
## moved by code (a screen opening) stays silent.
const INPUT_WINDOW_FRAMES: int = 2

var _last_input_frame: int = -100


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func _input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed) or event is InputEventMouseMotion \
			or (event is InputEventMouseButton and event.pressed) or event is InputEventJoypadButton:
		_last_input_frame = Engine.get_process_frames()


func play_move() -> void:
	AudioManager.play(&"ui_move")


func play_select() -> void:
	AudioManager.play(&"ui_select")


func play_back() -> void:
	AudioManager.play(&"ui_back")


func _on_node_added(node: Node) -> void:
	# A control re-entering the tree keeps its earlier connections.
	if not node is Control or node.has_meta(&"menu_feedback"):
		return
	var control := node as Control
	if control is OptionButton:
		(control as OptionButton).item_selected.connect(_on_item_selected)
	elif control is BaseButton:
		(control as BaseButton).pressed.connect(play_select)
	elif control is Slider:
		(control as Slider).value_changed.connect(_on_slider_changed.bind(control))
	else:
		return
	control.mouse_entered.connect(_focus_on_hover.bind(control))
	control.set_meta(&"menu_feedback", true)


func _on_focus_changed(_control: Control) -> void:
	if Engine.get_process_frames() - _last_input_frame <= INPUT_WINDOW_FRAMES:
		play_move()


func _on_item_selected(_index: int) -> void:
	play_select()


## Sliders tick as they move, but only when the player moved them.
func _on_slider_changed(_value: float, slider: Slider) -> void:
	if slider.has_focus() and Engine.get_process_frames() - _last_input_frame <= INPUT_WINDOW_FRAMES:
		play_move()


func _focus_on_hover(control: Control) -> void:
	if control.is_visible_in_tree() and control.focus_mode != Control.FOCUS_NONE \
			and not (control is BaseButton and (control as BaseButton).disabled) \
			and not control.has_focus():
		control.grab_focus()
