class_name SoundEffect
extends Resource
## One sound effect for AudioManager: the stream plus how it is played. Lives in
## the AudioLibrary resource (res://resources/audio/audio_library.tres).

## Name gameplay code plays it by, e.g. &"laser".
@export var id: StringName
@export var stream: AudioStream
@export_range(-40.0, 12.0, 0.5) var volume_db: float = 0.0
## Random pitch spread (plus or minus) so repeats don't sound identical.
@export_range(0.0, 0.5, 0.01) var pitch_variation: float = 0.0
## Minimum seconds between two starts; requests closer together are dropped.
@export_range(0.0, 1.0, 0.01) var min_interval: float = 0.0
## Most copies that may play at once; a new one cuts off the oldest.
@export_range(1, 16) var max_voices: int = 4
