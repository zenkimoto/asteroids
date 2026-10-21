class_name PauseOverlay
extends CanvasLayer
## Pause menu: Resume, Restart, Settings, Main Menu and Quit. Restarting,
## leaving to the menu and quitting ask for confirmation first, since they
## abandon the game. Runs while the tree is paused.

signal resume_requested
signal restart_requested
signal main_menu_requested
signal quit_requested

## The confirmed action waiting on the dialog.
var _pending_action: Callable = Callable()
## Button to focus again when a panel or dialog closes.
var _return_focus: Control

@onready var _menu: Control = %Menu
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _settings_button: Button = %SettingsButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _quit_button: Button = %QuitButton
@onready var _settings_panel: SettingsPanel = %SettingsPanel
@onready var _confirm_dialog: ConfirmDialog = %ConfirmDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(resume_requested.emit)
	_restart_button.pressed.connect(_confirm.bind(
			_restart_button, "Restart? Your current game will be lost.", "Restart", restart_requested.emit))
	_settings_button.pressed.connect(_open_panel.bind(_settings_panel, _settings_button))
	_main_menu_button.pressed.connect(_confirm.bind(
			_main_menu_button, "Return to the main menu? Your current game will be lost.", "Main Menu", main_menu_requested.emit))
	_quit_button.pressed.connect(_confirm.bind(
			_quit_button, "Quit the game? Your current game will be lost.", "Quit", quit_requested.emit))
	_settings_panel.closed.connect(_on_panel_closed)
	_confirm_dialog.closed.connect(_on_panel_closed)
	_confirm_dialog.confirmed.connect(_on_confirmed)


func show_menu() -> void:
	visible = true
	_close_panels()
	_resume_button.grab_focus()


func hide_menu() -> void:
	_close_panels()
	visible = false


func is_panel_open() -> bool:
	return _settings_panel.visible or _confirm_dialog.visible


func _open_panel(panel: MenuPanel, from: Control) -> void:
	_return_focus = from
	_menu.visible = false
	panel.open()


func _confirm(from: Control, message: String, confirm_text: String, action: Callable) -> void:
	_pending_action = action
	_return_focus = from
	_menu.visible = false
	_confirm_dialog.ask(message, confirm_text)


func _on_confirmed() -> void:
	var action := _pending_action
	_pending_action = Callable()
	_menu.visible = true
	if action.is_valid():
		action.call()


func _on_panel_closed() -> void:
	_pending_action = Callable()
	_menu.visible = true
	if _return_focus != null:
		_return_focus.grab_focus()


func _close_panels() -> void:
	_pending_action = Callable()
	_settings_panel.visible = false
	_confirm_dialog.visible = false
	_menu.visible = true
