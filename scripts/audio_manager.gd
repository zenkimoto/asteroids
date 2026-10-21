extends Node
## Autoload "AudioManager": plays sound effects from a small voice pool on the
## SFX bus and music on the Music bus. Music follows GameManager's state: the menu
## track on the main menu, the game track while playing (its intensity layer fades
## in on later waves), quieter while paused, faded out on game over. Bus volumes
## and mutes are applied by SettingsManager.

enum Track { NONE, MENU, GAME }

const LIBRARY_PATH: String = "res://resources/audio/audio_library.tres"
const SFX_BUS: StringName = &"SFX"
const MUSIC_BUS: StringName = &"Music"
const SFX_VOICES: int = 16
## Linear level treated as silence when fading out.
const SILENCE: float = 0.001

var library: AudioLibrary

var _voices: Array[AudioStreamPlayer] = []
## AudioStreamPlayer -> id of the sound it is playing.
var _voice_sound: Dictionary = {}
## AudioStreamPlayer -> Time.get_ticks_msec() when it started.
var _voice_started: Dictionary = {}
## Sound id -> msec of its last start, for min_interval.
var _last_played: Dictionary = {}
var _warned_missing: Dictionary = {}

var _track: Track = Track.NONE
## Two players so one track can fade out while the next fades in.
var _music: Array[AudioStreamPlayer] = []
var _music_db: Array[float] = [0.0, 0.0]
var _fade: Array[float] = [0.0, 0.0]
var _fade_target: Array[float] = [0.0, 0.0]
var _active: int = 0
## Plays the game track's intensity layer in step with the music player at _intensity_owner.
var _intensity_player: AudioStreamPlayer
var _intensity_owner: int = -1
var _intensity: float = 0.0
var _intensity_target: float = 0.0
var _duck: float = 1.0
var _duck_target: float = 1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	library = load(LIBRARY_PATH) as AudioLibrary
	if library == null:
		push_error("AudioManager: could not load %s; the game will be silent." % LIBRARY_PATH)
		library = AudioLibrary.new()
	for i in SFX_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.name = "Voice%d" % i
		voice.bus = SFX_BUS
		add_child(voice)
		_voices.append(voice)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "Music%d" % i
		player.bus = MUSIC_BUS
		add_child(player)
		_music.append(player)
	_intensity_player = AudioStreamPlayer.new()
	_intensity_player.name = "MusicIntensity"
	_intensity_player.bus = MUSIC_BUS
	add_child(_intensity_player)
	GameManager.state_changed.connect(_on_game_state_changed)
	_on_game_state_changed(GameManager.state, GameManager.state)


func _process(delta: float) -> void:
	var step := delta / maxf(library.music_fade_time, 0.01)
	_duck = move_toward(_duck, _duck_target, step * 2.0)
	_intensity = move_toward(_intensity, _intensity_target, step * 0.5)
	for i in _music.size():
		_fade[i] = move_toward(_fade[i], _fade_target[i], step)
		var player := _music[i]
		if _fade[i] <= SILENCE and _fade_target[i] <= 0.0:
			if player.playing:
				player.stop()
				if i == _intensity_owner:
					_intensity_player.stop()
					_intensity_owner = -1
			continue
		player.volume_db = _music_db[i] + _to_db(_fade[i] * _duck)
	if _intensity_owner >= 0:
		_intensity_player.volume_db = _music_db[_intensity_owner] \
				+ _to_db(_fade[_intensity_owner] * _duck * _intensity)


## Plays sound `id`. `pitch_scale` multiplies the sound's own random pitch.
## Returns false if the sound is unknown or was skipped by its rate limits.
func play(id: StringName, pitch_scale: float = 1.0, volume_offset_db: float = 0.0) -> bool:
	var sound := library.get_sound(id)
	if sound == null or sound.stream == null:
		if not _warned_missing.has(id):
			_warned_missing[id] = true
			push_warning("AudioManager: no sound '%s' in the audio library." % id)
		return false
	var now := Time.get_ticks_msec()
	if sound.min_interval > 0.0 and now - int(_last_played.get(id, -100000)) < sound.min_interval * 1000.0:
		return false
	var voice := _pick_voice(id, sound.max_voices)
	_last_played[id] = now
	_voice_sound[voice] = id
	_voice_started[voice] = now
	voice.stream = sound.stream
	voice.volume_db = sound.volume_db + volume_offset_db
	voice.pitch_scale = maxf(pitch_scale * (1.0 + _rng.randf_range(-sound.pitch_variation, sound.pitch_variation)), 0.05)
	voice.play()
	return true


func get_track() -> Track:
	return _track


## Crossfades to `track` (NONE fades out). Starting the current track again does nothing.
func play_music(track: Track) -> void:
	if track == _track:
		return
	_track = track
	_fade_target[_active] = 0.0
	if track == Track.NONE:
		return
	_active = 1 - _active
	var player := _music[_active]
	player.stop()
	if _intensity_owner == _active:
		_intensity_player.stop()
		_intensity_owner = -1
	var stream := library.menu_music if track == Track.MENU else library.game_music
	if stream == null:
		return
	player.stream = stream
	_music_db[_active] = library.menu_music_db if track == Track.MENU else library.game_music_db
	_fade[_active] = 0.0
	_fade_target[_active] = 1.0
	player.volume_db = _to_db(0.0)
	player.play()
	if track == Track.GAME and library.game_music_intensity != null:
		# Started in the same frame and the same length, so the layer stays in time.
		_intensity_player.stream = library.game_music_intensity
		_intensity_player.volume_db = _to_db(0.0)
		_intensity_player.play()
		_intensity_owner = _active
		_intensity = 0.0


## 0 = base game music only, 1 = the full intensity layer. Changes fade in.
func set_music_intensity(value: float) -> void:
	_intensity_target = clampf(value, 0.0, 1.0)


func set_music_ducked(ducked: bool) -> void:
	_duck_target = db_to_linear(library.paused_duck_db) if ducked else 1.0


func is_music_ducked() -> bool:
	return _duck_target < 1.0


## A free voice; otherwise the oldest one playing this sound once it has
## max_voices copies going, or the oldest voice overall.
func _pick_voice(id: StringName, max_voices: int) -> AudioStreamPlayer:
	var same: Array[AudioStreamPlayer] = []
	var free: AudioStreamPlayer = null
	for voice in _voices:
		if not voice.playing:
			if free == null:
				free = voice
		elif _voice_sound.get(voice) == id:
			same.append(voice)
	if same.size() >= max_voices:
		return _oldest(same)
	if free != null:
		return free
	return _oldest(_voices)


func _oldest(voices: Array[AudioStreamPlayer]) -> AudioStreamPlayer:
	var oldest := voices[0]
	for voice in voices:
		if int(_voice_started.get(voice, 0)) < int(_voice_started.get(oldest, 0)):
			oldest = voice
	return oldest


func _on_game_state_changed(_previous: int, current: int) -> void:
	match current:
		GameManager.State.MAIN_MENU:
			set_music_ducked(false)
			play_music(Track.MENU)
		GameManager.State.STARTING:
			set_music_ducked(false)
			set_music_intensity(0.0)
			play_music(Track.GAME)
		GameManager.State.PLAYING, GameManager.State.WAVE_TRANSITION:
			set_music_ducked(false)
			play_music(Track.GAME)
		GameManager.State.PAUSED:
			set_music_ducked(true)
		GameManager.State.GAME_OVER:
			set_music_ducked(false)
			play_music(Track.NONE)


func _to_db(linear: float) -> float:
	return linear_to_db(maxf(linear, 0.0001))
