# Asteroids

This project was built with Claude Opus 5.5 using the [Godot AI MCP server](https://github.com/hi-godot/godot-ai).  Project planning was done with GPT-6 Astra.

Initial generated documents:
- [PLANNING.md](./PLANNING.md) - Detailed planning document describing the project to Claude describing what will be built.
- [TASK_LIST.md](./TASK_LIST.md) - Implementation plan broken into different phases.  After each phase, manually verified before continuing.
- [PROMPT.md](./PROMPT.md) - Prompt used to implement each phase.

# Overview

A modern take on the classic arcade game, built with **Godot 4.7.2** and
**GDScript**. Fly a vector-style ship through endless waves of asteroids and
UFOs, collect power-ups, chain kills for a score multiplier and compete for a
place on the local top-10 leaderboard.

Single player, keyboard controlled, 1920×1080 with scaling to any window size.
No accounts, internet connection or external services.

## Playing a release build

Download the package for your system from the release and unzip it.

| System | Run |
|---|---|
| Windows (64-bit) | `Asteroids.exe` |
| macOS 11+ (Intel or Apple silicon) | `Asteroids.app`. The build is not notarized, so the first time, right-click the app and choose **Open**, then confirm. |
| Linux (x86_64) | `./Asteroids.x86_64` (mark it executable if needed: `chmod +x Asteroids.x86_64`) |

## Controls

| Action | Keys |
|---|---|
| Thrust | **W** / **↑** |
| Reverse thrust | **S** / **↓** |
| Rotate | **A D** / **← →** |
| Fire (hold) | **Space** |
| Boost | **Shift** |
| Pause | **Esc** |

Menus work with the arrow keys, **Enter** and **Esc**, or the mouse. Keys can be
rebound in **Settings → Controls**. The full reference is in
[CONTROLS.md](CONTROLS.md).

## How to play

- Shoot asteroids to split them: large → two medium → two small → gone.
- Clear every asteroid and UFO in a wave to start a 3-second countdown to the
  next, harder wave (more and faster rocks, fast and armored variants, more
  accurate UFOs).
- Touching an asteroid, a UFO or a UFO shot costs a life. You respawn somewhere
  safe with two seconds of invulnerability. You start with 3 lives (maximum 5)
  and earn an extra life every 10,000 points.
- Kills within 3 seconds of each other build a combo; every 5 raise the
  multiplier, up to ×5. Losing a life resets it.
- Destroyed enemies sometimes drop power-ups: Shield, Rapid Fire, Double Shot,
  Triple Shot, Piercing Laser, Repair and Speed Boost. Uncollected power-ups
  vanish after 10 seconds.

| Target | Points |
|---|---|
| Large / medium / small asteroid | 20 / 50 / 100 (fast ×1.5, armored ×2.5) |
| Large / small UFO | 200 / 500 |
| Wave completed | 100 × wave number |

The in-game **How to Play** screen has the same information, always showing the
current key bindings and balance values.

## Settings and save files

**Settings** covers master, music and sound-effect volume and mute, fullscreen,
screen shake, particle intensity, an FPS counter, reduce flashing, large HUD text
and key bindings. Everything is saved immediately.

Save files are plain JSON in Godot's user data folder:

| System | Folder |
|---|---|
| Windows | `%APPDATA%\Godot\app_userdata\Asteroids\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/Asteroids/` |
| Linux | `~/.local/share/godot/app_userdata/Asteroids/` |

`leaderboard.json` holds the top 10, `settings.json` the settings and
`controls.json` any rebound keys. A damaged file is renamed to `*.invalid` and
the game starts with defaults instead of crashing; delete a file to reset it.

## Running from source

1. Install [Godot 4.7.2](https://godotengine.org/download) (the standard build;
   no .NET needed).
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5** (Run Project). The game starts at the main menu.

## Tests

Gameplay tests run inside the real game, with save files redirected to scratch
files so your leaderboard and settings are never touched.

| Scene | What it covers | Time |
|---|---|---|
| `tests/runtime/runtime_tests.tscn` | 47 checks: ship, asteroids, UFOs, projectiles and power-up edge cases; pause, restart, Game Over and the state machine; leaderboard, settings and key-binding persistence; difficulty curves | ~40 s |
| `tests/runtime/stress_tests.tscn` | 40 s at the asteroid cap with 6 UFOs and constant fire (frame rate and hitches), then 12 restarts checking for leaked nodes, objects and signal connections | ~1 min |
| `tests/runtime/playtest.tscn` | A computer pilot plays 8 full sessions at 6× speed and reports waves reached, time per wave and causes of death, for balance tuning | several minutes |

Run a scene from the editor (open it and press **F6**), or from a terminal:

```sh
godot --path . res://tests/runtime/runtime_tests.tscn
godot --headless --path . res://tests/runtime/runtime_tests.tscn -- --filter=pause,leaderboard
```

Results print as `[TEST] PASS/FAIL` lines followed by a summary, and the
process exits with code 0 only when every check passed. `tests/test_balance.gd`
holds editor-side checks of the balance resources for the Godot AI test runner.

## Building a release

The project includes export presets for **Windows**, **macOS** and **Linux**.
After installing the 4.7.2 export templates, use **Project → Export… → Export
All… → Release**. The builds go to `asteroids_release/`. Step-by-step
instructions, the preset settings and fixes for common errors are in
[EXPORTING.md](EXPORTING.md).

## Project structure

```
scenes/      Scenes: main menu, game, player, asteroid, UFOs, projectiles, HUD, menus
scripts/     One script per scene or system (typed GDScript)
resources/   Balance (.tres per system), particle effects, audio library, UI theme
assets/      Generated sound effects and music
tests/       Runtime test suites, stress test, autopilot playtests, editor checks
tools/       generate_audio.py, which recreates every sound from code
licenses/    Godot Engine license and third-party notices
```

### Architecture

- **Autoloads** hold everything that outlives a scene:
  `GameManager` (state machine: main menu, starting, playing, wave transition,
  paused, game over; lives; scene changes), `ScoreManager` (score, combo,
  extra lives, session statistics), `SaveManager` (JSON files and the
  leaderboard), `SettingsManager` (settings, audio buses, window),
  `AudioManager` (sound-effect voices, music crossfades and intensity layer),
  `KeyBindings` (rebinding and `controls.json`) and `MenuFeedback` (menu sounds
  and focus behaviour).
- **The game scene** (`scenes/game.tscn`, `scripts/game.gd`) wires gameplay
  objects together with signals and resets the world for each session. It holds
  no score or state itself.
- **Spawning** goes through `EntityContainer` subclasses: `AsteroidField`
  (spawning away from the ship, splitting, a 60-rock cap), `UfoFleet` (per-wave
  UFO plans, arrivals from the far edge, escaped UFOs returning),
  `PowerUpSpawner` (drop rolls, a 4-pickup cap) and the projectile containers.
  Every entity extends `GameEntity`, which handles movement, despawning and
  screen wrapping.
- **Waves** come from `WaveManager` with `WaveSettings` and `UfoSettings`; all
  difficulty numbers live in `resources/game_balance/*.tres` and can be tuned in
  the Inspector without touching code.
- **Feedback** is kept apart from rules: `GameEffects` (particles, shards,
  shockwaves, screen shake and flash) and `GameAudio` only listen to gameplay
  signals and never change game state.

## Known limitations

- Keyboard only; there is no gamepad support.
- The macOS build is not notarized, so Gatekeeper asks for confirmation on first
  launch.
- Exports are 64-bit only (Windows x86_64, Linux x86_64, macOS universal).

## License

The game's code and generated audio are under the MIT license; see
[LICENSE](LICENSE). Godot Engine and its components are covered in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
