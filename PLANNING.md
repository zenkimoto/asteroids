# Game Development Prompt: Asteroids Arcade Game in Godot

## 1. Project Overview

Create a complete, fully playable, 2D arcade-style space shooter inspired by the classic game **Asteroids**, using **Godot 4.7.2 and GDScript**.

The game should capture the simple, addictive gameplay of classic Asteroids while incorporating modern arcade elements such as particle effects, animated spaceship engines, multiple enemy types, power-ups, increasingly difficult levels, and a persistent high-score leaderboard.

The player controls a small spaceship navigating an open field of asteroids and hostile UFOs. The objective is to survive as long as possible, destroy enemies, and accumulate the highest score.

**Technical Requirements:**
- Game Engine: Godot 4.7.2
- Programming Language: GDScript
- Game Type: 2D arcade shooter
- Primary Platform: Desktop (Windows, macOS, Linux)
- Resolution: 1920 × 1080, with responsive scaling
- Frame Rate: Target 60 FPS or better
- Input: Keyboard
- Graphics: Colorful retro arcade/vector-inspired artwork with modern visual effects
- Game Mode: Single-player
- Saving: Local persistent save files
- No external services, accounts, or internet connection required

The result must be a complete Godot project that can be opened, executed, and played without requiring additional manual implementation.

---

## 2. Main Menu

Create a visually appealing main menu featuring a space-themed background with slowly moving stars and occasional asteroids drifting across the screen.

Display the game's title prominently at the top.

**Menu options:**
- **Start Game:** Begins a new game.
- **Leaderboard:** Displays the top 10 high scores.
- **How to Play:** Explains game controls, scoring, enemies, and power-ups.
- **Settings:** Allows the player to adjust audio and game preferences.
- **Quit:** Exits the game.

### Leaderboard

The leaderboard should display:
- Rank
- Player name (3–10 characters)
- Score
- Highest wave reached
- Date achieved

Store leaderboard data locally using a JSON file in Godot's `user://` directory.

Keep the top 10 scores sorted in descending order.

When a player's game ends, check whether their score qualifies for the leaderboard. If so, prompt them to enter their name.

The leaderboard must persist when the game closes and restarts.

Handle missing, empty, or invalid save files gracefully.

---

## 3. Player Spaceship

Create a spaceship controlled using classic Asteroids-style physics with acceleration, rotation, inertia, and momentum.

### Movement Controls

| Key | Action |
|---|---|
| W | Apply forward thrust |
| S | Apply reverse thrust at reduced power |
| A | Rotate spaceship counterclockwise |
| D | Rotate spaceship clockwise |
| Spacebar | Fire primary weapon |
| Shift | Activate boost |
| Esc | Pause / Resume game |

### Movement Physics

Implement the following:

- The spaceship rotates left or right using the A and D keys.
- Pressing W accelerates the spaceship in the direction it is facing.
- Pressing S produces a weaker reverse thrust.
- The ship maintains momentum when thrust is released.
- Apply slight drag to prevent unlimited drifting.
- Limit the ship's maximum velocity.
- Support simultaneous rotation, thrust, and firing.
- Use frame-rate-independent movement calculations.
- The ship wraps around the screen boundaries: exiting from one side causes it to reappear on the opposite side.
- Rotation should be smooth, responsive, and adjustable.

Use exported variables for acceleration, rotational speed, drag, maximum velocity, and boost speed.

### Engine Exhaust Animation

Add visually appealing animated engine exhaust to the spaceship.

**Requirements:**
- When accelerating forward, display an animated blue/orange engine flame behind the ship.
- When using reverse thrust, display a smaller forward-facing exhaust effect.
- When using boost, increase the flame size, brightness, and particle intensity.
- When no thrust is applied, the flames disappear or fade out.
- Engine particles should react to the ship's rotation and movement.
- Use Godot's `GPUParticles2D` or another suitable native particle system.

Include a subtle engine sound whose pitch or volume changes based on thrust intensity.

### Player Health and Lives

The player starts with **3 lives**.

When the spaceship collides with an asteroid, UFO, or enemy projectile:
- Remove one life.
- Play an explosion animation.
- Respawn the spaceship in a safe location.
- Grant 2 seconds of temporary invulnerability.
- Make the spaceship blink during invulnerability.
- Prevent repeated collision damage while invulnerable.

When all lives are lost, transition to the Game Over screen.

Award one additional life every 10,000 points, up to a maximum of 5 lives.

---

## 4. Weapons and Shooting

The player starts with a basic laser weapon.

### Primary Weapon

- Press or hold Spacebar to fire.
- Projectiles travel in the direction the spaceship faces.
- Projectiles inherit a portion of the spaceship's velocity.
- Use a configurable firing cooldown.
- Projectiles disappear after a fixed lifetime.
- Projectiles wrap around the screen boundaries, with a limited lifetime.
- Projectiles destroy asteroids and damage UFOs on collision.
- Display small impact particle effects.

### Weapon Upgrades

Implement the following temporary weapon upgrades:

**Rapid Fire**
- Reduces the firing cooldown.
- Duration: 10 seconds.

**Double Shot**
- Fires two projectiles in a slight spread.
- Duration: 12 seconds.

**Triple Shot**
- Fires three projectiles in a wider spread.
- Duration: 10 seconds.

**Piercing Laser**
- Allows projectiles to pass through multiple asteroids.
- Duration: 8 seconds.

Only one weapon upgrade may be active at a time. Picking up another weapon upgrade replaces the currently active weapon upgrade.

Show the active weapon upgrade and its remaining duration on the HUD.

---

## 5. Asteroids

Create procedurally varied asteroids with randomized shapes, rotations, sizes, and movement speeds.

### Asteroid Sizes

Implement three asteroid sizes:

| Size | Behavior | Score |
|---|---|---:|
| Large | Slow-moving, splits into 2 medium asteroids | 20 |
| Medium | Moderate speed, splits into 2 small asteroids | 50 |
| Small | Fast-moving, destroyed when hit | 100 |

### Asteroid Behavior

- Spawn asteroids at randomized positions outside a safe radius surrounding the player.
- Each asteroid has a random travel direction and rotational speed.
- Asteroids drift continuously across the screen.
- Asteroids wrap around screen boundaries.
- Larger asteroids have greater collision radii.
- When destroyed, asteroids break into smaller pieces according to the table above.
- Smaller fragments inherit some momentum from the original asteroid.
- Avoid creating fragments directly on top of the player.
- Asteroids should have irregular polygonal silhouettes rather than perfect circles.
- Add small explosion particles and a destruction sound when hit.

Use procedural polygon generation or bundled vector-style graphics so that the game does not depend on externally downloaded artwork.

### Asteroid Variations

Introduce additional asteroid variants during later waves:

**Standard Asteroid**
- Normal movement and splitting behavior.

**Fast Asteroid**
- Smaller and significantly faster.
- Introduced starting at Wave 3.

**Armored Asteroid**
- Requires multiple hits before breaking apart.
- Visually differentiated with a metallic appearance.
- Introduced starting at Wave 5.

The scoring and durability of special asteroid types should be configurable.

---

## 6. UFO Enemies

Introduce hostile UFOs that periodically appear and attack the player.

### UFO Types

**Large UFO**
- Moves relatively slowly.
- Fires projectiles toward the player's general position, with imperfect accuracy.
- Requires 3 hits to destroy.
- Awards 200 points.

**Small UFO**
- Moves faster.
- Aims more accurately at the player.
- Requires 2 hits to destroy.
- Awards 500 points.

### UFO Behavior

- UFOs enter from the left or right side of the screen.
- They move across the playfield while occasionally changing vertical direction.
- They avoid getting stuck at screen boundaries.
- They periodically fire hostile projectiles.
- Enemy bullets can damage the player's spaceship.
- UFOs can be destroyed by player projectiles.
- Destroyed UFOs produce animated explosions and particle effects.
- UFOs should have visible differences between the large and small versions.

Use a simple state machine to manage UFO behavior, such as entering, patrolling, attacking, and exiting.

UFO projectiles must look visually distinct from player projectiles.

### Difficulty Scaling

- Wave 1: No UFOs.
- Wave 2: Introduce large UFOs.
- Wave 4: Introduce small UFOs.
- Later waves: Increase UFO spawn frequency, movement speed, and firing frequency.
- Limit simultaneous UFOs to prevent unfair or overwhelming gameplay.

---

## 7. Wave-Based Difficulty Progression

Implement an endless wave system.

The player advances to the next wave after destroying all asteroids and UFOs belonging to the current wave, including asteroid fragments.

Display a short "Wave Complete" animation before starting the next wave.

### Example Difficulty Progression

| Wave | Asteroids | UFOs | New Challenge |
|---|---|---|---|
| 1 | 4 large | None | Introduction |
| 2 | 5 large | 1 large UFO | First UFO |
| 3 | 6 large | 1 large UFO | Fast asteroids |
| 4 | 7 large | 1 large + 1 small UFO | Small UFO |
| 5 | 8 large | 2 UFOs | Armored asteroids |
| 6+ | Increasing | Increasing | Faster enemies |

These values are starting points and should be easy to adjust.

### Scaling Rules

- Increase the number of asteroids gradually each wave.
- Increase asteroid speed with a reasonable maximum limit.
- Increase the frequency of UFO appearances.
- Gradually increase UFO projectile speed and accuracy.
- Increase the likelihood of special asteroid types.
- Limit active enemy counts to avoid performance issues.
- Never spawn an enemy directly on top of the player.
- Ensure each wave remains challenging but fair.

Add a 3-second countdown before the start of each wave.

The player's score, lives, and current power-up status carry over between waves.

---

## 8. Power-Ups

Destroyed asteroids and UFOs have a small chance of dropping temporary power-ups.

Power-ups should float in space, rotate slowly, and have distinctive colors or icons.

### Available Power-Ups

| Power-Up | Effect |
|---|---|
| Shield | Protects the ship from one collision |
| Rapid Fire | Increases weapon firing rate |
| Double Shot | Fires two projectiles |
| Triple Shot | Fires three projectiles |
| Piercing Laser | Projectiles pass through multiple asteroids |
| Repair | Restores one life, up to the maximum |
| Speed Boost | Temporarily increases acceleration and maximum speed |

### Power-Up Rules

- Power-ups are collected by flying into them.
- Each power-up has a distinct visual appearance.
- Play a collection sound when picked up.
- Temporary power-ups display a countdown on the HUD.
- Power-ups expire if not collected within 10 seconds.
- Power-up drop probability should be configurable.
- Shield effects can coexist with a weapon upgrade.
- Speed boosts can coexist with weapon upgrades.
- Recollecting a temporary power-up refreshes its duration.
- Keep drop rates low enough to maintain a balanced arcade experience.

---

## 9. Scoring System

Implement a scoring system that rewards destroying enemies and surviving difficult waves.

### Base Scores

- Large Asteroid: 20 points
- Medium Asteroid: 50 points
- Small Asteroid: 100 points
- Large UFO: 200 points
- Small UFO: 500 points
- Wave Completion: 100 × current wave number

### Score Multiplier

Introduce a combo multiplier:

- Consecutive kills within 3 seconds increase the combo count.
- Every 5 consecutive kills increase the multiplier by 1.
- Maximum score multiplier: 5×.
- The multiplier resets when the player takes damage or fails to destroy another enemy within the combo window.

Display combo notifications when the multiplier increases.

Track the player's total score throughout the game.

Save the final score when the game ends and submit it to the local leaderboard if eligible.

---

## 10. Game HUD

Create a clean, modern arcade-style heads-up display.

Display the following information:

**Top Left**
- Current score
- Current combo multiplier

**Top Center**
- Current wave
- Temporary wave announcements

**Top Right**
- Remaining lives
- Active power-up icons and timers

**Additional HUD Elements**
- High score
- Shield status
- Brief notifications for weapon upgrades
- Wave completion bonuses

Ensure HUD elements remain readable and do not obscure the gameplay area.

Use Godot's Control and CanvasLayer nodes for the HUD.

---

## 11. Pause Menu

Pressing Escape during gameplay opens a pause menu.

The pause menu should contain:
- Resume
- Restart Game
- Settings
- Main Menu
- Quit Game

When paused:
- All gameplay movement stops.
- Projectiles and asteroids stop updating.
- Wave timers and power-up timers stop.
- Particle effects should pause appropriately.
- Menu navigation remains responsive.

Restarting or returning to the main menu should request confirmation before abandoning a game.

---

## 12. Game Over Screen

When the player loses all lives, display a Game Over screen containing:

- Final Score
- Highest Wave Reached
- Total Asteroids Destroyed
- Total UFOs Destroyed
- Total Survival Time
- Whether the player achieved a new high score

If the score qualifies for the top 10, display a name-entry dialog.

After score submission, update the local leaderboard.

Provide buttons for:
- Play Again
- View Leaderboard
- Main Menu
- Quit

---

## 13. Visual Style and Animations

Use a polished retro arcade aesthetic with modern visual effects.

### Visual Direction

- Dark space background.
- Subtle parallax starfield with multiple layers.
- Bright, neon-inspired outlines.
- Colorful particle effects.
- Smooth movement and rotation animations.
- Easily distinguishable enemies and projectiles.
- Consistent visual design across gameplay and menus.

### Required Effects

**Spaceship**
- Animated engine exhaust.
- Boost exhaust effects.
- Shield glow.
- Invulnerability blinking.
- Destruction explosion.

**Asteroids**
- Rotating irregular shapes.
- Break-apart animation.
- Small debris particles.
- Hit flashes.

**UFOs**
- Animated running lights.
- Weapon firing effects.
- Hit flashes.
- Explosion animation.

**Environment**
- Moving starfield.
- Subtle background parallax.
- Optional distant nebula effects.
- Screen shake for significant explosions.
- Optional camera flash on large impacts.

Implement effects efficiently and avoid excessive particle counts.

---

## 14. Audio and Music

Include retro arcade-style sound effects and background music.

### Sound Effects

- Laser firing
- Asteroid destruction
- UFO destruction
- Player explosion
- Engine thrust
- Boost activation
- Power-up collection
- Shield absorption
- New wave announcement
- Menu selections
- Game over

### Music

- Looping background music for menus.
- Looping background music during gameplay.
- Music should remain subtle and not overpower sound effects.
- Increase musical intensity during later waves if practical.

### Audio Settings

Provide independent volume controls for:
- Master volume
- Music
- Sound effects

Include mute options.

Save these settings locally and reload them when the game starts.

Use generated or properly licensed audio assets. Do not depend on downloading copyrighted game assets.

---

## 15. Settings and Accessibility

Create a Settings menu supporting:

- Master volume
- Music volume
- Sound effects volume
- Fullscreen / windowed mode
- Screen shake on/off
- Particle intensity: Low / Medium / High
- Show FPS: On / Off

Where practical, allow players to customize keyboard bindings.

Use readable interface text, clear contrast, and avoid relying solely on color to differentiate important objects.

Persist settings between sessions.

---

## 16. Godot Project Architecture

Organize the project into reusable scenes and scripts.

### Suggested Scene Structure

```text
res://
├── scenes/
│   ├── main_menu.tscn
│   ├── game.tscn
│   ├── player.tscn
│   ├── asteroid.tscn
│   ├── ufo.tscn
│   ├── projectile.tscn
│   ├── power_up.tscn
│   ├── hud.tscn
│   ├── pause_menu.tscn
│   ├── game_over.tscn
│   ├── leaderboard.tscn
│   └── settings_menu.tscn
├── scripts/
│   ├── game_manager.gd
│   ├── player.gd
│   ├── asteroid.gd
│   ├── ufo.gd
│   ├── projectile.gd
│   ├── power_up.gd
│   ├── wave_manager.gd
│   ├── score_manager.gd
│   ├── save_manager.gd
│   ├── audio_manager.gd
│   └── settings_manager.gd
├── assets/
│   ├── sprites/
│   ├── audio/
│   ├── fonts/
│   └── effects/
├── resources/
│   └── game_balance/
└── project.godot
```

The exact structure may be adjusted if a different organization is more suitable.

### Architecture Requirements

- Use GDScript with Godot 4 syntax.
- Use reusable scene instances for asteroids, UFOs, projectiles, and power-ups.
- Use signals to communicate events between gameplay objects and managers.
- Use Autoload singletons where appropriate for persistent game state, audio, and settings.
- Avoid tight coupling between unrelated game systems.
- Use clearly named variables, functions, and signals.
- Use typed GDScript where practical.
- Use exported variables and resources for gameplay balancing.
- Use collision layers and masks to distinguish players, enemies, projectiles, and power-ups.
- Manage object creation and destruction safely.
- Clean up projectiles, particles, and enemies when they are no longer needed.
- Use delta time for movement and physics calculations.
- Avoid unnecessary object allocations during gameplay.
- Ensure screen wrapping works consistently for the player, asteroids, and appropriate projectiles.
- Include comments explaining important gameplay logic.

### Configurable Gameplay Values

Centralize important balance settings, including:

- Player acceleration
- Player maximum speed
- Rotation speed
- Reverse thrust power
- Boost speed and duration
- Weapon firing cooldown
- Projectile speed and lifetime
- Asteroid size and velocity
- Asteroid hit points
- UFO movement speed
- UFO firing cooldown
- Enemy spawn intervals
- Wave difficulty scaling
- Power-up drop probabilities
- Power-up durations
- Starting lives
- Maximum lives
- Score values

Avoid scattering hardcoded gameplay values throughout the project.

---

## 17. Collision and Gameplay Rules

Implement consistent collision handling:

1. Player projectiles damage asteroids and UFOs.
2. Enemy projectiles damage the player but not enemies.
3. Asteroids and UFOs can damage the player through direct contact.
4. Power-ups are collected by the player without dealing damage.
5. Invulnerable players cannot lose lives.
6. Active shields absorb one collision and then disappear.
7. Each projectile must apply damage only according to its weapon type.
8. Destroyed enemies must award points only once.
9. Destroyed enemies must not continue interacting with other objects.
10. Wave completion should occur only when all wave enemies, including fragments, are eliminated.

Ensure that simultaneous collisions do not create duplicate points, duplicate explosions, or repeated player damage.

---

## 18. Game States

Implement explicit game states:

- MAIN_MENU
- STARTING
- PLAYING
- WAVE_TRANSITION
- PAUSED
- GAME_OVER

The game should correctly manage transitions between states.

Examples:
- Player movement and shooting are disabled outside appropriate gameplay states.
- Restarting the game resets all session-specific values.
- Pausing freezes gameplay timers.
- Wave transitions prevent unwanted spawns.
- Returning to the main menu cleans up active gameplay objects.

---

## 19. Testing and Quality Requirements

Before considering the project complete, verify the following:

### Gameplay
- WASD movement works correctly.
- The spaceship rotates and accelerates smoothly.
- Momentum and screen wrapping behave correctly.
- Engine exhaust responds to thrust.
- Holding Spacebar fires at the intended rate.
- Projectiles hit and destroy asteroids.
- Large asteroids split into medium asteroids.
- Medium asteroids split into small asteroids.
- Small asteroids are destroyed completely.
- UFOs appear and attack the player.
- Enemy collisions remove lives correctly.
- Player respawning and invulnerability work.
- Power-ups activate and expire properly.
- Wave transitions occur correctly.
- Difficulty increases gradually.
- Scores and combo multipliers calculate correctly.

### Menus and Persistence
- Main menu buttons work.
- Game pause and resume work.
- Game Over is triggered appropriately.
- Leaderboard entries save and load correctly.
- Scores remain after restarting the game.
- Settings persist between sessions.
- Restarting the game properly resets gameplay state.

### Stability
- No GDScript syntax errors.
- No missing scenes or resources.
- No broken signal connections.
- No invalid node references.
- No repeated collision damage.
- No endless accumulation of inactive objects.
- No accidental duplicate scoring.
- No game-breaking issues when restarting, pausing, or returning to the menu.

### Performance
- Maintain smooth gameplay at 1080p.
- Avoid excessive particle allocations.
- Support numerous simultaneous asteroids and projectiles.
- Use object pooling if practical and beneficial.
- Avoid performance degradation over long gameplay sessions.

---

## 20. Development and Delivery Instructions

Build a complete, functional game rather than a prototype or isolated code examples.

### Implementation Order

**Phase 1: Core Gameplay**
- Create the Godot project.
- Implement player movement and physics.
- Implement shooting and projectiles.
- Implement asteroid spawning, splitting, and destruction.
- Implement collision handling.
- Implement basic scoring and lives.

**Phase 2: Game Structure**
- Implement the main menu.
- Implement wave progression.
- Implement difficulty scaling.
- Implement the HUD.
- Implement pause and Game Over states.

**Phase 3: Enemies and Upgrades**
- Implement UFO enemy AI.
- Implement additional asteroid types.
- Implement weapon upgrades.
- Implement power-ups.
- Implement the combo multiplier.

**Phase 4: Polish**
- Add engine exhaust animations.
- Add explosions and particle effects.
- Add sound effects and music.
- Add screen shake and hit effects.
- Polish menus and HUD.

**Phase 5: Persistence and Testing**
- Implement the leaderboard.
- Implement settings persistence.
- Verify project functionality.
- Fix errors and edge cases.
- Perform gameplay balance adjustments.

### Deliverables

Provide:

1. A complete Godot project with all required scenes, scripts, and resources.
2. A configured `project.godot` file with the correct main scene, input actions, and Autoloads.
3. All gameplay scripts and necessary assets.
4. A functional local leaderboard and settings persistence system.
5. A README explaining how to open, run, and play the game.
6. A brief description of the project architecture and major gameplay systems.
7. A list of controls.
8. Any known limitations or incomplete features, if applicable.

### Important Development Rules

- Do not provide pseudocode as a substitute for working code.
- Do not leave placeholder functions for required gameplay features.
- Do not omit required scenes, scripts, or referenced resources.
- Do not rely on assets that are missing from the project.
- Prefer simple, reliable implementations over unnecessarily complex systems.
- Ensure all scene references and resource paths are valid.
- Prioritize a playable, stable game before adding cosmetic improvements.
- If a feature proves too complex, implement the simplest functional version consistent with the requirements rather than leaving it incomplete.
- Verify code compatibility with the specified Godot version.
- If command-line or editor testing is available, run the project and resolve reported errors.
- If testing tools are unavailable, explicitly identify what has not been verified.

**Final Goal:** Produce a polished, replayable, arcade-style Asteroids game that starts immediately in Godot, feels responsive, becomes increasingly challenging, and encourages players to compete for the highest score.
