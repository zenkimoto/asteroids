extends Node
## Autoload "SaveManager": reads and writes the game's local JSON files in
## user:// and owns the persistent leaderboard.
##
## Missing files load as empty. A file that can't be parsed, or doesn't hold a
## JSON object, is moved aside to "<name>.invalid" so it is never silently
## overwritten, and the game carries on with defaults. Writes go to a temporary
## file first and replace the old file only once fully written.

signal leaderboard_changed
## Emitted when a save file had to be set aside or partly ignored.
signal save_file_recovered(path: String, reason: String)

const LEADERBOARD_PATH: String = "user://leaderboard.json"
const INVALID_SUFFIX: String = ".invalid"
const TEMP_SUFFIX: String = ".tmp"

var leaderboard := Leaderboard.new()


func _ready() -> void:
	load_leaderboard()


func load_leaderboard() -> void:
	var data := read_json(LEADERBOARD_PATH)
	if data.is_empty():
		leaderboard.clear()
	elif not leaderboard.from_data(data):
		_set_aside(LEADERBOARD_PATH, "it has no entries list")
		leaderboard.clear()
	elif leaderboard.rejected_count > 0:
		save_file_recovered.emit(LEADERBOARD_PATH, "%d invalid entries were skipped" % leaderboard.rejected_count)
		push_warning("SaveManager: skipped %d invalid leaderboard entries." % leaderboard.rejected_count)
	leaderboard_changed.emit()


## Adds a finished game to the leaderboard and saves it. Returns the rank (1-10),
## or 0 if the score didn't qualify or the name is invalid.
func submit_score(player_name: String, score: int, wave: int) -> int:
	var clean_name := Leaderboard.sanitize_name(player_name)
	if not Leaderboard.is_valid_name(clean_name):
		return 0
	var rank := leaderboard.add(LeaderboardEntry.create(clean_name, score, wave))
	if rank > 0:
		write_json(LEADERBOARD_PATH, leaderboard.to_data())
		leaderboard_changed.emit()
	return rank


## Returns the file's top-level JSON object, or an empty Dictionary if the file
## is missing, empty or invalid (invalid files are set aside first).
func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	if FileAccess.get_open_error() != OK:
		push_warning("SaveManager: couldn't read %s (error %d)." % [path, FileAccess.get_open_error()])
		return {}
	if text.strip_edges().is_empty():
		return {}
	var json := JSON.new()
	if json.parse(text) != OK:
		_set_aside(path, "JSON error on line %d: %s" % [json.get_error_line() + 1, json.get_error_message()])
		return {}
	if not json.data is Dictionary:
		_set_aside(path, "it doesn't contain a JSON object")
		return {}
	return json.data


## Writes `data` as JSON. Returns false (and keeps the previous file) on failure.
func write_json(path: String, data: Dictionary) -> bool:
	var temp_path := path + TEMP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: couldn't write %s (error %d)." % [temp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var error := DirAccess.rename_absolute(temp_path, path)
	if error != OK:
		push_error("SaveManager: couldn't replace %s (error %d)." % [path, error])
		return false
	return true


func _set_aside(path: String, reason: String) -> void:
	var backup := path + INVALID_SUFFIX
	var error := DirAccess.rename_absolute(path, backup)
	if error == OK:
		push_warning("SaveManager: %s was invalid (%s); moved it to %s and started fresh." % [path, reason, backup])
	else:
		push_warning("SaveManager: %s was invalid (%s); using defaults." % [path, reason])
	save_file_recovered.emit(path, reason)
