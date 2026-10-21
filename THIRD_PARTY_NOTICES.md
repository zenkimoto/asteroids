# Third-party notices

## Godot Engine

Asteroids is built with and ships the Godot Engine 4.7.2 runtime, which is
released under the MIT license:

    Copyright (c) 2014-present Godot Engine contributors.
    Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

The full license is in [licenses/GODOT_LICENSE.txt](licenses/GODOT_LICENSE.txt).
Godot includes third-party components (FreeType, ENet, mbedTLS, the default
Open Sans font and others); their notices are in
[licenses/GODOT_COPYRIGHT.txt](licenses/GODOT_COPYRIGHT.txt). Both files are
copied next to the game in every release package.

## Audio

All sound effects and music in `assets/audio/` were synthesised for this project
by `tools/generate_audio.py` (fixed random seed, no samples or recordings) and
are covered by this project's [LICENSE](LICENSE).

## Graphics and fonts

All ship, asteroid, UFO and effect graphics are drawn in code. The interface
uses Godot's built-in default font (Open Sans, SIL Open Font License 1.1; see
GODOT_COPYRIGHT.txt).

## Development tools (not shipped)

`addons/godot_ai/` is an editor plugin used during development (MIT license,
Copyright (c) 2025 Godot AI contributors; see `addons/godot_ai/LICENSE`). It is
excluded from every export preset, and the plugin removes its runtime helper
from exported builds.
