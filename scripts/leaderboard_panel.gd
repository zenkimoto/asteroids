class_name LeaderboardPanel
extends MenuPanel
## Shows SaveManager's top-10 table: rank, name, score, highest wave and date.
## Refreshes whenever the leaderboard changes; one entry can be highlighted.

@export var row_font_size: int = 30
@export var header_color: Color = Color(0.3, 0.95, 1, 1)
@export var text_color: Color = Color(0.85, 0.92, 1, 1)
@export var highlight_color: Color = Color(1, 0.55, 0.85, 1)
@export var empty_color: Color = Color(0.45, 0.5, 0.6, 1)

var _highlight: LeaderboardEntry

@onready var _rows: GridContainer = %Rows
@onready var _empty_label: Label = %EmptyLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	super()
	_back_button.pressed.connect(close)
	SaveManager.leaderboard_changed.connect(_refresh)
	_refresh()


## Opens the table, highlighting `entry` (e.g. the score just saved) while it's listed.
func open_with_highlight(entry: LeaderboardEntry) -> void:
	_highlight = entry
	_refresh()
	open()


func open() -> void:
	_refresh()
	super()


func close() -> void:
	_highlight = null
	super()


func _refresh() -> void:
	if not is_node_ready():
		return
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var entries: Array[LeaderboardEntry] = SaveManager.leaderboard.entries
	_empty_label.visible = entries.is_empty()
	_add_row(["RANK", "NAME", "SCORE", "WAVE", "DATE"], header_color)
	for i in Leaderboard.MAX_ENTRIES:
		var rank := i + 1
		if i < entries.size():
			var entry: LeaderboardEntry = entries[i]
			var color := highlight_color if entry == _highlight else text_color
			_add_row([str(rank), entry.player_name, str(entry.score), str(entry.wave), entry.date], color)
		else:
			_add_row([str(rank), "---", "-", "-", "-"], empty_color)


func _add_row(cells: Array, color: Color) -> void:
	for i in cells.size():
		var label := Label.new()
		label.text = cells[i]
		label.add_theme_font_size_override(&"font_size", row_font_size)
		label.add_theme_color_override(&"font_color", color)
		# Name left-aligned; numbers right-aligned so digits line up.
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 1 else HORIZONTAL_ALIGNMENT_RIGHT
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if i == 1 else Control.SIZE_FILL
		_rows.add_child(label)
