class_name Weapon
extends Node2D
## Fires projectiles from this node's position in the direction the ship faces
## (up, in the ship's local space) while `trigger_held` is true.

signal fired(projectile: Projectile)

@export var settings: WeaponSettings
@export var projectile_scene: PackedScene

## Where projectiles are added. Set by the game; defaults to the current scene.
var projectile_parent: Node
## Set by the ship every physics tick.
var trigger_held: bool = false
## The ship's velocity, part of which projectiles inherit.
var source_velocity: Vector2 = Vector2.ZERO

var _cooldown_left: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if trigger_held and _cooldown_left <= 0.0:
		fire()


func fire() -> Projectile:
	var parent := projectile_parent if projectile_parent != null else get_tree().current_scene
	var projectile := projectile_scene.instantiate() as Projectile
	parent.add_child(projectile)
	var direction := Vector2.UP.rotated(global_rotation)
	projectile.launch(global_position, direction, source_velocity * settings.inherit_velocity_ratio, settings)
	_cooldown_left = settings.fire_cooldown
	fired.emit(projectile)
	return projectile


func reset() -> void:
	trigger_held = false
	_cooldown_left = 0.0
