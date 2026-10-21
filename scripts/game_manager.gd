extends Node
## Autoload "GameManager": the game's state machine. Owns the current state, lives,
## pausing and session start/restart, and loads the balance configuration.
## Gameplay scenes react to its signals and never change state directly.

enum State { MAIN_MENU, STARTING, PLAYING, WAVE_TRANSITION, PAUSED, GAME_OVER }

signal state_changed(previous: State, current: State)
## Emitted while STARTING: listeners reset score and rebuild the world.
signal session_started
signal lives_changed(lives: int)
signal game_over(final_score: int)

const BALANCE_PATH: String = "res://resources/game_balance/game_balance.tres"

## Allowed transitions; anything else is refused and reported as an error.
const TRANSITIONS: Dictionary = {
	State.MAIN_MENU: [State.STARTING],
	State.STARTING: [State.PLAYING, State.MAIN_MENU],
	State.PLAYING: [State.WAVE_TRANSITION, State.PAUSED, State.GAME_OVER, State.MAIN_MENU],
	State.WAVE_TRANSITION: [State.PLAYING, State.PAUSED, State.GAME_OVER, State.MAIN_MENU],
	State.PAUSED: [State.PLAYING, State.WAVE_TRANSITION, State.STARTING, State.MAIN_MENU],
	State.GAME_OVER: [State.STARTING, State.MAIN_MENU],
}

var balance: GameBalance = load(BALANCE_PATH)
var state: State = State.MAIN_MENU
var lives: int = 0

var _state_before_pause: State = State.PLAYING
## Set when the last life is lost; the game ends after a short delay.
var _out_of_lives: bool = false
var _timers: TimerScheduler


func _ready() -> void:
	# Keeps reading the pause key while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timers = TimerScheduler.new()
	_timers.name = "Timers"
	# Session timers must stop while paused even though this node never does.
	_timers.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_timers)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.PAUSE):
		return
	if state == State.PAUSED:
		resume()
		get_viewport().set_input_as_handled()
	elif can_pause():
		pause()
		get_viewport().set_input_as_handled()


func get_state_name(value: State = state) -> String:
	return State.keys()[value]


## True while the world is live: the ship can act and points count.
func is_gameplay_active() -> bool:
	return state == State.PLAYING or state == State.WAVE_TRANSITION


func can_pause() -> bool:
	return is_gameplay_active() and not _out_of_lives


## Starts a fresh session from the menu, the pause screen or Game Over.
func start_session() -> bool:
	if not _change_state(State.STARTING):
		return false
	_timers.cancel_all()
	get_tree().paused = false
	_out_of_lives = false
	lives = balance.rules.starting_lives
	lives_changed.emit(lives)
	session_started.emit()
	return _change_state(State.PLAYING)


## Leaves gameplay entirely (called when the gameplay scene is removed).
func end_session() -> void:
	_timers.cancel_all()
	get_tree().paused = false
	if state != State.MAIN_MENU:
		_change_state(State.MAIN_MENU)


func pause() -> void:
	if not can_pause():
		return
	_state_before_pause = state
	get_tree().paused = true
	_change_state(State.PAUSED)


func resume() -> void:
	if state != State.PAUSED:
		return
	get_tree().paused = false
	_change_state(_state_before_pause)


## Called when the field is cleared. Returns false if a transition isn't allowed now.
func begin_wave_transition() -> bool:
	if state != State.PLAYING or _out_of_lives:
		return false
	return _change_state(State.WAVE_TRANSITION)


func end_wave_transition() -> void:
	if state == State.WAVE_TRANSITION:
		_change_state(State.PLAYING)


## Takes a life. Returns true if the ship should respawn; on the last life the
## game moves to GAME_OVER after the configured delay.
func register_player_death() -> bool:
	if not is_gameplay_active() or _out_of_lives:
		return false
	lives -= 1
	lives_changed.emit(lives)
	if lives > 0:
		return true
	_out_of_lives = true
	_timers.schedule(balance.rules.game_over_delay, _enter_game_over)
	return false


func _enter_game_over() -> void:
	if _change_state(State.GAME_OVER):
		game_over.emit(ScoreManager.score)


func _change_state(new_state: State) -> bool:
	if new_state == state:
		return false
	var allowed: Array = TRANSITIONS[state]
	if not allowed.has(new_state):
		push_error("GameManager: invalid transition %s -> %s" % [get_state_name(state), get_state_name(new_state)])
		return false
	var previous := state
	state = new_state
	state_changed.emit(previous, new_state)
	return true
