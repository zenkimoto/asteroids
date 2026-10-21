class_name Hud
extends CanvasLayer
## In-game score, wave and lives display. Values are pushed in by the game scene.

@onready var _score_label: Label = %ScoreLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _lives_label: Label = %LivesLabel


func set_score(score: int) -> void:
	_score_label.text = "SCORE  %d" % score


func set_wave(wave: int) -> void:
	_wave_label.text = "WAVE  %d" % wave


func set_lives(lives: int) -> void:
	_lives_label.text = "LIVES  %d" % maxi(lives, 0)
