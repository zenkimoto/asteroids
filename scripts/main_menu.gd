class_name MainMenu
extends Node2D
## Title screen: Start Game, Leaderboard, How to Play, Settings and Quit, over
## the drifting-space background. Sub-screens open as panels on top.

@onready var _menu: Control = %Menu
@onready var _start_button: Button = %StartButton
@onready var _leaderboard_button: Button = %LeaderboardButton
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _best_label: Label = %BestLabel
@onready var _leaderboard_panel: LeaderboardPanel = %LeaderboardPanel
@onready var _how_to_play_panel: HowToPlayPanel = %HowToPlayPanel
@onready var _settings_panel: SettingsPanel = %SettingsPanel
@onready var _title: Label = %Title

var _return_focus: Control


func _ready() -> void:
	_start_button.pressed.connect(GameManager.open_game)
	_leaderboard_button.pressed.connect(_open_panel.bind(_leaderboard_panel, _leaderboard_button))
	_how_to_play_button.pressed.connect(_open_panel.bind(_how_to_play_panel, _how_to_play_button))
	_settings_button.pressed.connect(_open_panel.bind(_settings_panel, _settings_button))
	_quit_button.pressed.connect(GameManager.quit_game)
	for panel: MenuPanel in [_leaderboard_panel, _how_to_play_panel, _settings_panel]:
		panel.closed.connect(_on_panel_closed)
	SaveManager.leaderboard_changed.connect(_update_best)
	_update_best()
	MenuPanel.wrap_focus([_start_button, _leaderboard_button, _how_to_play_button, _settings_button, _quit_button])
	_start_button.grab_focus()
	_animate_title()


func _open_panel(panel: MenuPanel, from: Control) -> void:
	_return_focus = from
	_menu.visible = false
	panel.open()


func _on_panel_closed() -> void:
	_menu.visible = true
	if _return_focus != null:
		_return_focus.grab_focus()


## A slow glow pulse on the title.
func _animate_title() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_title, "self_modulate", Color(1.25, 1.25, 1.25, 1.0), 1.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_title, "self_modulate", Color(0.85, 0.85, 0.9, 1.0), 1.6).set_trans(Tween.TRANS_SINE)


func _update_best() -> void:
	var best: int = SaveManager.leaderboard.get_best_score()
	_best_label.visible = best > 0
	_best_label.text = "HIGH SCORE  %d" % best
