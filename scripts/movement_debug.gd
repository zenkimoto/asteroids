class_name MovementDebug
extends CanvasLayer
## Development overlay showing the player's live movement values. Toggle with F3.

@export var player: Player
@export var start_visible: bool = false
@export_range(8, 64) var font_size: int = 20

@onready var _label: Label = %Values


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = start_visible
	_label.add_theme_font_size_override("font_size", font_size)
	if player == null:
		push_warning("MovementDebug has no player assigned.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.TOGGLE_DEBUG):
		# Not marked handled: other debug overlays toggle on the same key.
		visible = not visible


func _process(_delta: float) -> void:
	if not visible or player == null:
		return
	var boost_text: String
	if player.is_boosting:
		boost_text = "ACTIVE %.1fs" % player.boost_time_left
	elif player.boost_cooldown_left > 0.0:
		boost_text = "cooldown %.1fs" % player.boost_cooldown_left
	else:
		boost_text = "ready"
	_label.text = "\n".join(PackedStringArray([
		"speed     %4.0f / %.0f px/s" % [player.get_speed(), player.get_max_speed()],
		"velocity  (%5.0f, %5.0f)" % [player.velocity.x, player.velocity.y],
		"heading   %4.0f°" % fposmod(player.rotation_degrees, 360.0),
		"position  (%4.0f, %4.0f)" % [player.global_position.x, player.global_position.y],
		"thrust    %+.2f" % player.thrust_input,
		"turn      %+.0f" % player.rotation_input,
		"boost     %s" % boost_text,
		"[F3] hide",
	]))
