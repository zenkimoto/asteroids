class_name LeaderboardEntry
extends RefCounted
## One leaderboard row: who scored what, the highest wave reached and the date.

var player_name: String = ""
var score: int = 0
var wave: int = 1
## Local date the score was achieved, as YYYY-MM-DD.
var date: String = ""


static func create(p_name: String, p_score: int, p_wave: int, p_date: String = "") -> LeaderboardEntry:
	var entry := LeaderboardEntry.new()
	entry.player_name = p_name
	entry.score = p_score
	entry.wave = maxi(p_wave, 1)
	entry.date = p_date if not p_date.is_empty() else Time.get_date_string_from_system()
	return entry


func to_dict() -> Dictionary:
	return {"name": player_name, "score": score, "wave": wave, "date": date}


## Builds an entry from saved data, or returns null if any field is missing,
## of the wrong type or out of range.
static func from_dict(data: Variant) -> LeaderboardEntry:
	if not data is Dictionary:
		return null
	var dict := data as Dictionary
	var raw_name: Variant = dict.get("name")
	var raw_score: Variant = dict.get("score")
	var raw_wave: Variant = dict.get("wave")
	var raw_date: Variant = dict.get("date")
	if not raw_name is String or not raw_date is String:
		return null
	if not _is_whole_number(raw_score) or not _is_whole_number(raw_wave):
		return null
	var clean_name := Leaderboard.sanitize_name(raw_name)
	if not Leaderboard.is_valid_name(clean_name):
		return null
	if int(raw_score) <= 0 or int(raw_wave) < 1 or not _is_valid_date(raw_date):
		return null
	return create(clean_name, int(raw_score), int(raw_wave), raw_date)


## JSON numbers load as floats; accept them only when they hold a whole value.
static func _is_whole_number(value: Variant) -> bool:
	if value is int:
		return true
	return value is float and is_finite(value) and value == floorf(value)


static func _is_valid_date(text: String) -> bool:
	var parts := text.split("-")
	if parts.size() != 3 or parts[0].length() != 4 or parts[1].length() != 2 or parts[2].length() != 2:
		return false
	for part in parts:
		if not part.is_valid_int():
			return false
	var month := parts[1].to_int()
	var day := parts[2].to_int()
	return month >= 1 and month <= 12 and day >= 1 and day <= 31
