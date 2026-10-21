class_name Hud
extends CanvasLayer
## In-game score and lives display. Values are pushed in by the game scene.

@onready var _score_label: Label = %ScoreLabel
@onready var _lives_label: Label = %LivesLabel


func set_score(score: int) -> void:
	_score_label.text = "SCORE  %d" % score


func set_lives(lives: int) -> void:
	_lives_label.text = "LIVES  %d" % maxi(lives, 0)
