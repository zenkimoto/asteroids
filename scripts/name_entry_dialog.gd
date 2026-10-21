class_name NameEntryDialog
extends MenuPanel
## Asks for the player's leaderboard name (Leaderboard name rules) and emits
## `submitted` with the cleaned-up name. Esc doesn't dismiss it.

signal submitted(player_name: String)

@export var hint_color: Color = Color(0.55, 0.6, 0.7, 1)
@export var error_color: Color = Color(1, 0.45, 0.4, 1)

@onready var _title_label: Label = %TitleLabel
@onready var _name_edit: LineEdit = %NameEdit
@onready var _hint_label: Label = %HintLabel
@onready var _submit_button: Button = %SubmitButton


func _ready() -> void:
	super()
	close_on_cancel = false
	_name_edit.max_length = Leaderboard.NAME_MAX_LENGTH
	_name_edit.text_changed.connect(_on_text_changed)
	_name_edit.text_submitted.connect(_on_text_submitted)
	_submit_button.pressed.connect(_submit)


## Opens with `title` and the name field pre-filled with `suggested_name`.
func ask(title: String, suggested_name: String = "") -> void:
	_title_label.text = title
	_name_edit.text = suggested_name
	_on_text_changed(suggested_name)
	open()
	_name_edit.grab_focus()
	_name_edit.caret_column = _name_edit.text.length()


func _on_text_changed(text: String) -> void:
	var clean := Leaderboard.sanitize_name(text)
	var valid := Leaderboard.is_valid_name(clean)
	_submit_button.disabled = not valid
	if text.strip_edges().is_empty():
		_set_hint("%d-%d letters or numbers" % [Leaderboard.NAME_MIN_LENGTH, Leaderboard.NAME_MAX_LENGTH], hint_color)
	elif clean.length() < Leaderboard.NAME_MIN_LENGTH:
		_set_hint("At least %d characters" % Leaderboard.NAME_MIN_LENGTH, error_color)
	elif clean != text.strip_edges():
		_set_hint("Saved as \"%s\" (letters, numbers, spaces and - _ . only)" % clean, hint_color)
	else:
		_set_hint("Press Enter to save", hint_color)


func _on_text_submitted(_text: String) -> void:
	_submit()


func _submit() -> void:
	var clean := Leaderboard.sanitize_name(_name_edit.text)
	if not Leaderboard.is_valid_name(clean):
		return
	visible = false
	submitted.emit(clean)


func _set_hint(text: String, color: Color) -> void:
	_hint_label.text = text
	_hint_label.add_theme_color_override(&"font_color", color)
