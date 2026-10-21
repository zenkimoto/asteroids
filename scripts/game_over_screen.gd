class_name GameOverScreen
extends CanvasLayer
## Shown when the last life is lost: the session's statistics, whether it set a
## new high score, name entry when the score makes the top 10, and buttons for
## Play Again, View Leaderboard, Main Menu and Quit.

signal restart_requested
signal main_menu_requested
signal quit_requested

## Seconds before anything responds, so a held Spacebar can't skip the screen.
@export_range(0.0, 3.0, 0.1) var input_delay: float = 0.8
@export var high_score_color: Color = Color(1, 0.55, 0.85, 1)
@export var top_ten_color: Color = Color(1, 0.8, 0.3, 1)
@export var plain_color: Color = Color(0.55, 0.6, 0.7, 1)

var _summary: SessionSummary
## Rank the score will take (0 if it doesn't qualify), worked out before saving.
var _qualifying_rank: int = 0
var _is_new_high_score: bool = false
## Rank it was saved at, once the name has been entered.
var _saved_rank: int = 0
var _saved_entry: LeaderboardEntry

@onready var _content: Control = %Content
@onready var _result_label: Label = %ResultLabel
@onready var _score_value: Label = %ScoreValue
@onready var _wave_value: Label = %WaveValue
@onready var _asteroids_value: Label = %AsteroidsValue
@onready var _ufos_value: Label = %UfosValue
@onready var _time_value: Label = %TimeValue
@onready var _play_again_button: Button = %PlayAgainButton
@onready var _leaderboard_button: Button = %LeaderboardButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _quit_button: Button = %QuitButton
@onready var _name_entry: NameEntryDialog = %NameEntryDialog
@onready var _leaderboard_panel: LeaderboardPanel = %LeaderboardPanel
@onready var _input_delay_timer: Timer = $InputDelay


func _ready() -> void:
	visible = false
	_play_again_button.pressed.connect(restart_requested.emit)
	_leaderboard_button.pressed.connect(_open_leaderboard)
	_main_menu_button.pressed.connect(main_menu_requested.emit)
	_quit_button.pressed.connect(quit_requested.emit)
	_name_entry.submitted.connect(_on_name_submitted)
	_leaderboard_panel.closed.connect(_on_leaderboard_closed)
	_input_delay_timer.timeout.connect(_on_input_delay_finished)
	MenuPanel.wrap_focus([_play_again_button, _leaderboard_button, _main_menu_button, _quit_button], false)


func show_results(summary: SessionSummary) -> void:
	_summary = summary
	_saved_rank = 0
	_saved_entry = null
	_qualifying_rank = SaveManager.leaderboard.get_rank_for(summary.score)
	_is_new_high_score = SaveManager.leaderboard.is_new_high_score(summary.score)
	_count_up(summary.score)
	_wave_value.text = str(summary.highest_wave)
	_asteroids_value.text = str(summary.asteroids_destroyed)
	_ufos_value.text = str(summary.ufos_destroyed)
	_time_value.text = SessionSummary.format_time(summary.survival_time)
	_show_result_text()
	_name_entry.visible = false
	_leaderboard_panel.visible = false
	_content.visible = true
	_set_buttons_enabled(false)
	visible = true
	_content.modulate.a = 0.0
	create_tween().tween_property(_content, "modulate:a", 1.0, 0.35)
	_input_delay_timer.start(maxf(input_delay, 0.001))


## Rolls the final score up from zero while the input delay runs.
func _count_up(score: int) -> void:
	_score_value.text = "0"
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void: _score_value.text = str(roundi(value)),
			0.0, float(score), clampf(score / 4000.0, 0.3, 1.0)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func hide_results() -> void:
	_input_delay_timer.stop()
	_name_entry.visible = false
	_leaderboard_panel.visible = false
	visible = false


func is_awaiting_name() -> bool:
	return visible and _qualifying_rank > 0 and _saved_rank == 0


func _show_result_text() -> void:
	var best: int = SaveManager.leaderboard.get_best_score()
	if _is_new_high_score:
		_set_result("NEW HIGH SCORE!", high_score_color)
	elif _saved_rank > 0:
		_set_result("TOP 10 SCORE  -  RANK #%d" % _saved_rank, top_ten_color)
	elif _qualifying_rank > 0:
		_set_result("TOP 10 SCORE  -  RANK #%d" % _qualifying_rank, top_ten_color)
	else:
		_set_result("HIGH SCORE  %d" % best, plain_color)


func _set_result(text: String, color: Color) -> void:
	_result_label.text = text
	_result_label.add_theme_color_override(&"font_color", color)


func _on_input_delay_finished() -> void:
	if is_awaiting_name():
		var title := "NEW HIGH SCORE!" if _is_new_high_score else "TOP 10 SCORE - RANK #%d" % _qualifying_rank
		_content.visible = false
		_name_entry.ask(title, SettingsManager.get_value(SettingsManager.PLAYER_NAME))
		return
	_set_buttons_enabled(true)
	_play_again_button.grab_focus()


func _on_name_submitted(player_name: String) -> void:
	_saved_rank = SaveManager.submit_score(player_name, _summary.score, _summary.highest_wave)
	SettingsManager.set_value(SettingsManager.PLAYER_NAME, player_name)
	if _saved_rank > 0:
		_saved_entry = SaveManager.leaderboard.entries[_saved_rank - 1]
	else:
		push_warning("GameOverScreen: score %d was not added to the leaderboard." % _summary.score)
	_show_result_text()
	_content.visible = true
	_set_buttons_enabled(true)
	_leaderboard_button.grab_focus()


func _open_leaderboard() -> void:
	_content.visible = false
	_leaderboard_panel.open_with_highlight(_saved_entry)


func _on_leaderboard_closed() -> void:
	_content.visible = true
	_leaderboard_button.grab_focus()


func _set_buttons_enabled(enabled: bool) -> void:
	for button in [_play_again_button, _leaderboard_button, _main_menu_button, _quit_button]:
		(button as Button).disabled = not enabled
