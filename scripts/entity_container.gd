class_name EntityContainer
extends Node2D
## Parent node for spawned gameplay objects (GameEntity children). It creates
## them, counts the live ones and frees them all at once when a session is
## cleaned up. Other children, such as a TimerScheduler, are left alone.

signal entity_added(entity: Node)
signal entity_removed(entity: Node)


func _ready() -> void:
	child_entered_tree.connect(entity_added.emit)
	child_exiting_tree.connect(entity_removed.emit)


## Instantiates `scene`, runs `setup` on it before it enters the tree (so _ready
## sees configured values), adds it and returns it.
func spawn(scene: PackedScene, setup: Callable = Callable()) -> Node:
	var entity := scene.instantiate()
	if setup.is_valid():
		setup.call(entity)
	add_child(entity)
	return entity


## Entities still in play: not despawned and not waiting to be freed.
func get_live_entities() -> Array[Node]:
	var live: Array[Node] = []
	for child in get_children():
		if is_live(child):
			live.append(child)
	return live


func get_live_count() -> int:
	return get_live_entities().size()


## Removes and frees every entity immediately, without despawn effects.
func clear() -> void:
	for child in get_children():
		if child is GameEntity:
			remove_child(child)
			child.queue_free()


static func is_live(node: Node) -> bool:
	var entity := node as GameEntity
	return entity != null and not entity.is_despawned and not entity.is_queued_for_deletion()
