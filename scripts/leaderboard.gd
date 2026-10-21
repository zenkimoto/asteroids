class_name Leaderboard
extends RefCounted
## The top-10 table: sorting, qualification, name rules and conversion to and
## from save data. It knows nothing about files; SaveManager persists it.

const MAX_ENTRIES: int = 10
const NAME_MIN_LENGTH: int = 3
const NAME_MAX_LENGTH: int = 10
const DATA_VERSION: int = 1

## Sorted best first. Equal scores keep the order they were achieved in.
var entries: Array[LeaderboardEntry] = []
## Entries skipped by the last from_data() call because they were invalid.
var rejected_count: int = 0


## A score enters the table if it is positive and the table has room or the
## score beats the lowest entry.
func qualifies(score: int) -> bool:
	if score <= 0:
		return false
	return entries.size() < MAX_ENTRIES or score > entries.back().score


## True when the score would take first place.
func is_new_high_score(score: int) -> bool:
	return score > 0 and (entries.is_empty() or score > entries[0].score)


## 1-based rank the score would get, or 0 if it doesn't qualify.
func get_rank_for(score: int) -> int:
	if not qualifies(score):
		return 0
	return _insert_index(score) + 1


func get_best_score() -> int:
	return entries[0].score if not entries.is_empty() else 0


## Inserts the entry in order and drops anything past the tenth place.
## Returns its 1-based rank, or 0 if it didn't qualify.
func add(entry: LeaderboardEntry) -> int:
	if entry == null or not qualifies(entry.score):
		return 0
	var index := _insert_index(entry.score)
	entries.insert(index, entry)
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	return index + 1


func clear() -> void:
	entries.clear()


func to_data() -> Dictionary:
	var rows: Array = []
	for entry in entries:
		rows.append(entry.to_dict())
	return {"version": DATA_VERSION, "entries": rows}


## Rebuilds the table from saved data. Invalid rows are skipped and counted in
## rejected_count; the rest are re-sorted and trimmed, so a hand-edited file
## can't break the ordering. Returns false if the data has no entries list.
func from_data(data: Dictionary) -> bool:
	entries.clear()
	rejected_count = 0
	var rows: Variant = data.get("entries")
	if not rows is Array:
		return false
	var loaded: Array[LeaderboardEntry] = []
	for row in rows:
		var entry := LeaderboardEntry.from_dict(row)
		if entry == null:
			rejected_count += 1
		else:
			loaded.append(entry)
	# A stable sort keeps the saved order for equal scores.
	for entry in loaded:
		if qualifies(entry.score):
			entries.insert(_insert_index(entry.score), entry)
			if entries.size() > MAX_ENTRIES:
				entries.resize(MAX_ENTRIES)
	return true


## Trims the name and removes characters that aren't letters, digits, spaces
## or - _ . (repeated spaces are collapsed). Length is not enforced here.
static func sanitize_name(text: String) -> String:
	var result := ""
	var last_was_space := true
	for character in text.strip_edges():
		var code := character.unicode_at(0)
		var allowed := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) \
				or (code >= 97 and code <= 122) or character in "-_."
		if character == " ":
			if not last_was_space:
				result += character
			last_was_space = true
		elif allowed:
			result += character
			last_was_space = false
	return result.strip_edges()


static func is_valid_name(text: String) -> bool:
	return text.length() >= NAME_MIN_LENGTH and text.length() <= NAME_MAX_LENGTH \
			and text == sanitize_name(text)


## Index after every entry with an equal or higher score.
func _insert_index(score: int) -> int:
	for i in entries.size():
		if score > entries[i].score:
			return i
	return entries.size()
