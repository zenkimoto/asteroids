class_name TimerScheduler
extends Node
## Session-scoped one-shot timers. They pause with the game, and cancel_all()
## drops every pending callback so nothing from an old session fires after a restart.


## Calls `callback` after `delay` seconds of unpaused time.
func schedule(delay: float, callback: Callable) -> Timer:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = maxf(delay, 0.001)
	timer.timeout.connect(_on_timeout.bind(timer, callback))
	add_child(timer)
	timer.start()
	return timer


func cancel_all() -> void:
	for timer in get_children():
		timer.stop()
		remove_child(timer)
		timer.queue_free()


func get_pending_count() -> int:
	return get_child_count()


func _on_timeout(timer: Timer, callback: Callable) -> void:
	remove_child(timer)
	timer.queue_free()
	if callback.is_valid():
		callback.call()
