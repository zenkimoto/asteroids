# Exporting release builds

This project ships three ready-made export presets in `export_presets.cfg`:
**Windows Desktop**, **macOS** and **Linux**. Each one writes to
`asteroids_release/<platform>/`, which Git and Godot both ignore.

## One-time setup

1. **Install the export templates.** Open **Editor → Manage Export
   Templates…**, check that the version shown is **4.7.2.stable**, then click
   **Download and Install**. Wait for it to finish (about 1 GB) and close the
   window.
2. **Load the presets.** Godot reads `export_presets.cfg` only when the project
   opens. If the project was open when the file changed, choose **Project →
   Reload Current Project**.

## Exporting

1. Choose **Project → Export…**. The three presets are listed on the left.
2. Click **Export All…** and choose **Release**.
3. Godot writes:

   | Preset | Output |
   |---|---|
   | Windows Desktop | `asteroids_release/windows/Asteroids.exe` |
   | macOS | `asteroids_release/macos/Asteroids.zip` (contains `Asteroids.app`) |
   | Linux | `asteroids_release/linux/Asteroids.x86_64` |

To export just one platform, select its preset and click **Export Project…**.
Untick **Export With Debug** so you get a release build, keep the suggested
file name, and click **Save**.

## Packaging

For each platform, make a folder named `Asteroids-1.0.0-<platform>`. Put in it:

- the exported game (on macOS, unzip `Asteroids.zip` and use the
  `Asteroids.app` inside)
- `README.md` and `CONTROLS.md`
- `LICENSE` and `THIRD_PARTY_NOTICES.md`
- the `licenses/` folder (Godot's license notices, which have to ship with
  the game)

Then zip the folder. On macOS, right-click the folder and choose **Compress**.

## Checking a build

- **macOS:** open `Asteroids.app`. The build is ad-hoc signed but not
  notarized, so the first time, right-click it, choose **Open**, then confirm.
- **Windows:** run `Asteroids.exe`. SmartScreen may warn about an unknown
  publisher; choose **More info → Run anyway**.
- **Linux:** run `./Asteroids.x86_64` (first `chmod +x Asteroids.x86_64` if
  needed).

In each build, check that:

- the main menu opens with music
- a game starts
- pause, the leaderboard and settings all work

Debug overlays (F3) are not included in release builds.

## What the presets are set to

If a preset is ever lost or reset, recreate it with **Add…** in the Export
window and set these options. Everything else can stay at its default.

| Setting | Windows Desktop | macOS | Linux |
|---|---|---|---|
| Resources → Export Mode | Export all resources | Export all resources | Export all resources |
| Resources → Filters to exclude | `addons/godot_ai/*, tests/*, tools/*, asteroids_release/*, builds/*` | same | same |
| Export Path | `asteroids_release/windows/Asteroids.exe` | `asteroids_release/macos/Asteroids.zip` | `asteroids_release/linux/Asteroids.x86_64` |
| Binary Format → Architecture | x86_64 | universal | x86_64 |
| Binary Format → Embed PCK | On | n/a | On |
| Application → Icon | `res://icon.svg` | `res://icon.svg` | n/a |
| Application → Bundle Identifier | n/a | `com.alex.asteroids` (use your own) | n/a |
| Application → Short Version | n/a | `1.0.0` | n/a |
| Codesign | Off | Built-in (ad-hoc) | n/a |

The exclude filter keeps the tests, the audio generator script and the
development-only Godot AI plugin out of the game.

## Common problems

| Message or symptom | Fix |
|---|---|
| "No export template found" | Repeat one-time setup step 1, and check the version is 4.7.2. |
| macOS: "Cannot export for universal or arm64 if ETC2 ASTC texture format is disabled" | **Project → Project Settings → Rendering → Textures → VRAM Compression → Import ETC2 ASTC** must be on. It already is in this project. |
| macOS: "Invalid bundle identifier" | Set **Application → Bundle Identifier** in the macOS preset, e.g. `com.yourname.asteroids`. |
| The presets disappeared, or show empty filters | The editor rewrote the file with defaults. Restore `export_presets.cfg` from Git and reload the project, or set the options in the table above. |
| The Windows `.exe` has the Godot icon | Changing a Windows icon needs the `rcedit` tool, which on a Mac also needs Wine. Leave the icon as is, or export the Windows build on a Windows PC after setting **Editor Settings → Export → Windows → rcedit**. |

## From the command line

The same exports can run without opening the editor (on a Mac, Godot is
`/Applications/Godot.app/Contents/MacOS/Godot`):

```sh
godot --headless --path . --export-release "Windows Desktop" asteroids_release/windows/Asteroids.exe
godot --headless --path . --export-release "macOS" asteroids_release/macos/Asteroids.zip
godot --headless --path . --export-release "Linux" asteroids_release/linux/Asteroids.x86_64
```

The output folders must exist first. Create them with
`mkdir -p asteroids_release/{windows,macos,linux}`.
