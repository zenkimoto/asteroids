class_name LivesIcons
extends Control
## A row of small ship outlines, one per remaining life, right-aligned. Used by
## the HUD next to the "LIVES n" text so lives read at a glance.

@export var color: Color = Color(1, 0.55, 0.85, 1)
@export_range(4.0, 40.0, 1.0) var icon_height: float = 26.0
@export_range(0.0, 30.0, 1.0) var spacing: float = 10.0
## Lives drawn at most; the label still shows the exact number.
@export_range(1, 20) var max_icons: int = 6

## Ship outline (nose up) in a 1-unit-tall box, matching the player's hull.
const SHAPE: PackedVector2Array = [
	Vector2(0.0, -0.5), Vector2(0.14, -0.15), Vector2(0.4, 0.5), Vector2(0.16, 0.4),
	Vector2(0.0, 0.45), Vector2(-0.16, 0.4), Vector2(-0.4, 0.5), Vector2(-0.14, -0.15),
]

var lives: int = 0:
	set(value):
		lives = maxi(value, 0)
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2((icon_height * 0.8 + spacing) * max_icons, icon_height + 4.0)


func _draw() -> void:
	var count := mini(lives, max_icons)
	var step := icon_height * 0.8 + spacing
	for i in count:
		var center := Vector2(size.x - icon_height * 0.4 - i * step, size.y * 0.5)
		var points := PackedVector2Array()
		for p in SHAPE:
			points.append(center + p * icon_height)
		draw_colored_polygon(points, Color(color, 0.25))
		points.append(points[0])
		draw_polyline(points, color, 2.0, true)
