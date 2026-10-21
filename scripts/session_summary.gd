class_name SessionSummary
extends RefCounted
## Snapshot of a finished (or running) game's statistics, for the Game Over screen.

var score: int = 0
var highest_wave: int = 0
var asteroids_destroyed: int = 0
var ufos_destroyed: int = 0
## Seconds of active play; pauses and the time after the last life are excluded.
var survival_time: float = 0.0


## Formats seconds as M:SS, or H:MM:SS past an hour.
static func format_time(seconds: float) -> String:
	var total := maxi(int(seconds), 0)
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var secs := total % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	return "%d:%02d" % [minutes, secs]
