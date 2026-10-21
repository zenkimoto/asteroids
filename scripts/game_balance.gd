class_name GameBalance
extends Resource
## Index of every balance resource. GameManager loads this one file and the game
## scene hands each part to its system, so swapping this file retunes everything.

@export var rules: GameRules
@export var player_movement: PlayerMovementSettings
@export var weapon: WeaponSettings
@export var asteroids: AsteroidSettings
