class_name AudioLibrary
extends Resource
## Every sound effect and music track, with the mix settings AudioManager uses.

@export var sounds: Array[SoundEffect] = []

@export_group("Music")
@export var menu_music: AudioStream
@export var game_music: AudioStream
## Extra layer with the same tempo and length as `game_music`, faded in on later waves.
@export var game_music_intensity: AudioStream
@export_range(-30.0, 6.0, 0.5) var menu_music_db: float = -4.0
@export_range(-30.0, 6.0, 0.5) var game_music_db: float = -6.0
## Seconds for a crossfade between tracks and for intensity changes.
@export_range(0.05, 5.0, 0.05) var music_fade_time: float = 1.2
## How much the music drops while the game is paused.
@export_range(-40.0, 0.0, 0.5) var paused_duck_db: float = -12.0
## First wave with some of the intensity layer, and the wave where it is at full volume.
@export_range(1, 50) var intensity_start_wave: int = 3
@export_range(1, 50) var intensity_full_wave: int = 7

var _by_id: Dictionary = {}


func get_sound(id: StringName) -> SoundEffect:
	if _by_id.size() != sounds.size():
		_by_id.clear()
		for sound in sounds:
			if sound != null:
				_by_id[sound.id] = sound
	return _by_id.get(id)


## 0 before `intensity_start_wave`, rising evenly to 1 at `intensity_full_wave`.
func get_intensity_for_wave(wave: int) -> float:
	var steps := maxi(intensity_full_wave - intensity_start_wave + 1, 1)
	return clampf(float(wave - intensity_start_wave + 1) / steps, 0.0, 1.0)
