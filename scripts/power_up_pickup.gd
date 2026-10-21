class_name PowerUpPickup
extends WrappingEntity
## A floating power-up. It drifts, spins slowly, wraps around the screen and is
## collected when the ship flies into it. It blinks shortly before vanishing.

signal collected(pickup: PowerUpPickup)
signal expired(pickup: PowerUpPickup)

const RADIUS: float = 20.0
## Spin of the frame in radians per second; the icon stays upright.
const SPIN_SPEED: float = 0.8
## Seconds per blink while it is about to vanish.
const BLINK_PERIOD: float = 0.3

var definition: PowerUpDefinition

var _time_left: float = 0.0
var _warning_time: float = 0.0

@onready var _frame: Node2D = $Frame
@onready var _fill: Polygon2D = $Frame/Fill
@onready var _outline: Line2D = $Frame/Outline
@onready var _icon: Label = $Icon


## Call before adding it to the tree.
func setup(p_definition: PowerUpDefinition, at: Vector2, drift: Vector2, lifetime: float, warning_time: float) -> void:
	definition = p_definition
	position = at
	velocity = drift
	_time_left = lifetime
	_warning_time = warning_time


func _ready() -> void:
	wrap_margin = RADIUS
	var hexagon := PackedVector2Array()
	for i in 6:
		hexagon.append(Vector2.from_angle(TAU * i / 6.0) * RADIUS)
	_fill.polygon = hexagon
	_fill.color = Color(definition.color, 0.18)
	_outline.points = hexagon
	_outline.default_color = definition.color
	_icon.text = definition.icon_text
	_icon.add_theme_color_override(&"font_color", definition.color)


## Hands the power-up over once. Returns false if it was already taken or gone.
func collect() -> bool:
	if is_despawned:
		return false
	collected.emit(self)
	despawn()
	return true


func _entity_physics_process(delta: float) -> void:
	_frame.rotation += SPIN_SPEED * delta
	_time_left -= delta
	if _time_left <= 0.0:
		expired.emit(self)
		despawn()
		return
	var blinking := _time_left < _warning_time and fmod(_time_left, BLINK_PERIOD) < BLINK_PERIOD * 0.5
	modulate.a = 0.3 if blinking else 1.0
