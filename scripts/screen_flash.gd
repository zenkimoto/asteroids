class_name ScreenFlash
extends CanvasLayer
## Brief full-screen tint for large impacts. Sits under the HUD and never
## blocks input; kept faint so it doesn't hide the playfield.

## Upper limit on any flash's opacity.
@export_range(0.0, 1.0, 0.01) var max_alpha: float = 0.22

var _tween: Tween

@onready var _rect: ColorRect = $Rect


func _ready() -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color(1, 1, 1, 0)


func flash(color: Color, strength: float, duration: float) -> void:
	var alpha := minf(strength, max_alpha)
	if alpha <= 0.0:
		return
	# A stronger flash replaces a fading weaker one; a weaker one never cuts a strong one short.
	if _tween != null and _tween.is_running() and _rect.color.a > alpha:
		return
	if _tween != null:
		_tween.kill()
	_rect.color = Color(color, alpha)
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", 0.0, maxf(duration, 0.01)).set_ease(Tween.EASE_OUT)


func clear() -> void:
	if _tween != null:
		_tween.kill()
	_rect.color.a = 0.0
