class_name HowToPlayPanel
extends MenuPanel
## Explains controls, scoring, enemies and power-ups. The text is built from the
## Input Map and the balance resources, so it stays correct when they change.

@export var heading_color: Color = Color(0.3, 0.95, 1, 1)
@export var key_color: Color = Color(1, 0.8, 0.3, 1)

const CONTROLS: Array[Array] = [
	[InputActions.THRUST_FORWARD, "Thrust forward"],
	[InputActions.THRUST_REVERSE, "Reverse thrust (reduced power)"],
	[InputActions.ROTATE_LEFT, "Rotate left"],
	[InputActions.ROTATE_RIGHT, "Rotate right"],
	[InputActions.FIRE, "Fire"],
	[InputActions.BOOST, "Boost"],
	[InputActions.PAUSE, "Pause / resume"],
]

@onready var _body: RichTextLabel = %Body
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	super()
	_back_button.pressed.connect(close)
	_body.text = build_text(GameManager.balance)


## Rebuilt on each open so rebound keys show up.
func open() -> void:
	_body.text = build_text(GameManager.balance)
	super()
	_body.scroll_to_line(0)


func build_text(balance: GameBalance) -> String:
	var lines: PackedStringArray = []
	lines.append(_heading("CONTROLS"))
	for control in CONTROLS:
		lines.append("[color=#%s]%s[/color]   %s" % [key_color.to_html(false), _keys_for(control[0]), control[1]])
	lines.append("The screen wraps: fly off one edge to come back on the other.")

	var asteroids := balance.asteroids
	var scoring := balance.scoring
	lines.append("")
	lines.append(_heading("SCORING"))
	lines.append("Asteroids: large %d, medium %d, small %d. Large and medium ones split when shot." % [
		asteroids.get_size_settings(Asteroid.Size.LARGE).score,
		asteroids.get_size_settings(Asteroid.Size.MEDIUM).score,
		asteroids.get_size_settings(Asteroid.Size.SMALL).score,
	])
	lines.append("Combo: kills within %.0f seconds of each other chain. Every %d kills add 1x to the multiplier, up to %dx." % [
		scoring.combo_window, scoring.kills_per_multiplier_step, scoring.max_multiplier,
	])
	lines.append("Clearing a wave earns a bonus. An extra life every %d points (up to %d lives)." % [
		scoring.extra_life_every, balance.rules.max_lives,
	])

	var ufos := balance.ufos
	lines.append("")
	lines.append(_heading("ENEMIES"))
	lines.append("Fast asteroids (from wave %d) are smaller and quicker, worth %sx points." % [
		balance.waves.fast_first_wave, _number(asteroids.get_variant_settings(Asteroid.Variant.FAST).score_multiplier),
	])
	lines.append("Armored asteroids (from wave %d) take extra hits, worth %sx points." % [
		balance.waves.armored_first_wave, _number(asteroids.get_variant_settings(Asteroid.Variant.ARMORED).score_multiplier),
	])
	lines.append("Large UFO (from wave %d): slow, inaccurate shots, %d hits, %d points." % [
		ufos.large_first_wave, ufos.large.hit_points, ufos.large.score,
	])
	lines.append("Small UFO (from wave %d): fast, aims ahead of you, %d hits, %d points." % [
		ufos.small_first_wave, ufos.small.hit_points, ufos.small.score,
	])

	lines.append("")
	lines.append(_heading("POWER-UPS"))
	lines.append("Destroyed asteroids and UFOs sometimes drop a pickup. Fly into it before it fades.")
	for definition in balance.power_ups.definitions:
		var timing := " (%ss)" % _number(definition.duration) if definition.duration > 0.0 else ""
		lines.append("[color=#%s][lb]%s[rb] %s[/color]%s   %s" % [
			definition.color.to_html(false), definition.icon_text, definition.display_name, timing, definition.description,
		])
	lines.append("A new weapon upgrade replaces the current one.")
	return "\n".join(lines)


func _heading(text: String) -> String:
	return "[font_size=36][color=#%s]%s[/color][/font_size]" % [heading_color.to_html(false), text]


## Readable names of the keys bound to an action, e.g. "W / Up".
func _keys_for(action: StringName) -> String:
	var names: PackedStringArray = []
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key == null:
			continue
		var code := key.keycode if key.keycode != KEY_NONE else key.physical_keycode
		names.append(OS.get_keycode_string(code))
	return " / ".join(names) if not names.is_empty() else "(unbound)"


func _number(value: float) -> String:
	return str(int(value)) if value == floorf(value) else "%.1f" % value
