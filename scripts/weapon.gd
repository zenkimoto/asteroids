class_name Weapon
extends Node2D
## Fires projectiles from this node's position in the direction the ship faces
## (up, in the ship's local space) while `trigger_held` is true. Power-ups change
## the shot pattern through the modifiers; clear_modifiers() restores the laser.

signal fired(projectile: Projectile)

@export var settings: WeaponSettings
@export var projectile_scene: PackedScene

## Where projectiles are added. Set by the game; defaults to the current scene.
var projectile_parent: Node
## Set by the ship every physics tick.
var trigger_held: bool = false
## The ship's velocity, part of which projectiles inherit.
var source_velocity: Vector2 = Vector2.ZERO

## Bolts per shot, fanned out `spread_degrees` apart.
var shot_count: int = 1
var spread_degrees: float = 0.0
## Scales settings.fire_cooldown (below 1 fires faster).
var cooldown_multiplier: float = 1.0
## Extra asteroids each bolt passes through after its first hit.
var pierce_count: int = 0

var _cooldown_left: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if trigger_held and _cooldown_left <= 0.0:
		fire()


## Fires one shot (`shot_count` bolts) and returns the bolts.
func fire() -> Array[Projectile]:
	var parent := projectile_parent if projectile_parent != null else get_tree().current_scene
	var forward := Vector2.UP.rotated(global_rotation)
	var inherited := source_velocity * settings.inherit_velocity_ratio
	var bolts: Array[Projectile] = []
	for i in shot_count:
		# Centred fan: offsets of -0.5/+0.5 spreads for two bolts, -1/0/+1 for three.
		var offset := (i - (shot_count - 1) * 0.5) * deg_to_rad(spread_degrees)
		var projectile := projectile_scene.instantiate() as Projectile
		parent.add_child(projectile)
		projectile.launch(global_position, forward.rotated(offset), inherited, settings, pierce_count)
		fired.emit(projectile)
		bolts.append(projectile)
	_cooldown_left = settings.fire_cooldown * cooldown_multiplier
	return bolts


func clear_modifiers() -> void:
	shot_count = 1
	spread_degrees = 0.0
	cooldown_multiplier = 1.0
	pierce_count = 0


func reset() -> void:
	trigger_held = false
	_cooldown_left = 0.0
