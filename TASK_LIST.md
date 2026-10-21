# Asteroids Arcade — Development Phase Checklist

**Engine:** Godot 4.x  
**Language:** GDScript  
**Platform:** Desktop (Windows, macOS, Linux)  
**Goal:** A polished, single-player 2D Asteroids-style arcade game.

## Development Priorities

1. **Gameplay Feel First (Phases 1–3)** — Build responsive controls and a playable core loop.
2. **Architecture & Features Second (Phases 4–8)** — Build reusable systems and complete gameplay features.
3. **Visual Polish Third (Phases 9–11)** — Refine presentation, test, and prepare for release.

---

# Priority 1 — Gameplay Feel

## Phase 1 — Project Setup

**Goal:** A clean Godot project that launches without errors.

- [ ] Create the Godot 4 project and set the main scene.
- [ ] Configure 1920×1080 resolution and responsive viewport scaling.
- [ ] Set up input actions for movement, shooting, boost, and pause.
- [ ] Create folders for scenes, scripts, assets, and resources.
- [ ] Create a temporary playfield and placeholder spaceship.
- [ ] Verify the project launches in the editor and desktop build.

**Definition of done:** The project launches, displays the playfield, and recognizes all configured inputs.

## Phase 2 — Spaceship Controls & Physics

**Goal:** Responsive classic Asteroids-style movement.

- [ ] Create the reusable Player spaceship scene.
- [ ] Implement W/S forward and reverse thrust with inertia.
- [ ] Implement A/D rotation and simultaneous movement inputs.
- [ ] Add maximum velocity, drag, and configurable movement settings.
- [ ] Implement seamless screen wrapping.
- [ ] Implement temporary speed boost with cooldown.
- [ ] Add a placeholder engine thrust visual and movement debug values.

**Definition of done:** The spaceship moves smoothly, maintains momentum, rotates, boosts, and wraps around the screen.

## Phase 3 — Core Combat & Gameplay

**Goal:** A complete playable asteroid-destruction loop.

- [ ] Create the projectile scene and Spacebar firing mechanics.
- [ ] Implement randomized large, medium, and small asteroids.
- [ ] Implement asteroid splitting and fragment movement.
- [ ] Configure collision layers, masks, and hit detection.
- [ ] Add player lives, collision damage, respawning, and invulnerability.
- [ ] Implement basic scoring and score HUD.
- [ ] Implement a basic Game Over and restart flow.
- [ ] Playtest and adjust acceleration, drag, projectile speed, and asteroid speed.

**Definition of done:** The player can shoot asteroids, earn points, lose lives, and restart a complete session.

### Milestone 1 — Playable Prototype

- [ ] Ship movement, shooting, and collisions feel responsive.
- [ ] Asteroids split and score correctly.
- [ ] Life loss, Game Over, and restart work reliably.
- [ ] No blocking runtime errors remain.

---

# Priority 2 — Architecture & Features

## Phase 4 — Architecture & Game Management

**Goal:** A modular architecture that supports future features.

- [ ] Implement a GameManager and explicit game states.
- [ ] Create reusable scenes and signals for gameplay objects.
- [ ] Create centralized configuration resources for game balance.
- [ ] Separate score tracking from the player controller.
- [ ] Implement reliable pause, resume, restart, and cleanup behavior.
- [ ] Introduce reusable spawning utilities and lifecycle management.
- [ ] Verify transitions and repeated restarts do not create duplicate objects or signals.

**Definition of done:** Core gameplay runs through reusable, independently maintained systems with reliable state transitions.

## Phase 5 — Wave Progression & Difficulty

**Goal:** Endless waves that become progressively harder.

- [ ] Build a WaveManager for spawning and progression.
- [ ] Implement wave start countdown and completion detection.
- [ ] Scale asteroid counts and speed with wave number.
- [ ] Add fast asteroids starting at Wave 3.
- [ ] Add armored asteroids starting at Wave 5.
- [ ] Implement wave completion scoring bonuses.
- [ ] Establish safe spawn zones and performance limits.

**Definition of done:** Waves progress automatically, challenge rises gradually, and enemies never spawn unfairly on top of the player.

## Phase 6 — UFO Enemy System

**Goal:** Enemy spacecraft that provide dynamic combat challenges.

- [ ] Create reusable large and small UFO scenes.
- [ ] Implement UFO movement and behavior states.
- [ ] Implement enemy projectiles, aiming, and firing cooldowns.
- [ ] Add UFO health, collisions, and scoring.
- [ ] Introduce large UFOs at Wave 2 and small UFOs at Wave 4.
- [ ] Scale movement speed, aim accuracy, and fire rate.
- [ ] Limit concurrent UFOs and verify wave completion tracking.

**Definition of done:** Both UFO types appear, attack, take damage, and scale properly without breaking progression.

## Phase 7 — Weapons, Power-Ups & Scoring

**Goal:** More variety, tactical choices, and score-chasing.

- [ ] Implement rapid fire, double shot, triple shot, and piercing lasers.
- [ ] Implement shield, repair, and speed-boost pickups.
- [ ] Add configurable power-up drop rates and lifetimes.
- [ ] Implement timed effects and upgrade replacement rules.
- [ ] Implement combo scoring and maximum multiplier.
- [ ] Implement extra-life rewards and life cap.
- [ ] Display active upgrades, timers, shields, and combo status.

**Definition of done:** All power-ups work correctly, expire properly, and produce accurate scoring under simultaneous collisions.

## Phase 8 — Menus, Leaderboard & Persistence

**Goal:** A complete game that can be played repeatedly and remembers progress.

- [ ] Build main menu and navigation.
- [ ] Build How to Play, Settings, and Pause screens.
- [ ] Build Game Over screen with session statistics.
- [ ] Implement top-10 leaderboard sorting and name entry.
- [ ] Save and load scores and settings using local JSON.
- [ ] Add volume, display mode, and gameplay preference settings.
- [ ] Handle invalid save files and restart persistence tests.

**Definition of done:** The entire game can be operated through its menus; scores and preferences survive restarting the application.

### Milestone 2 — Feature Complete

- [ ] Waves, UFOs, weapons, power-ups, and scoring work together.
- [ ] Menus, pause, Game Over, and restart are stable.
- [ ] Leaderboard and settings persist between sessions.
- [ ] A complete game session can be played without developer intervention.

---

# Priority 3 — Visual Polish

## Phase 9 — Visual Effects & Animations

**Goal:** Visually satisfying and clearly readable arcade action.

- [ ] Create final spaceship, asteroid, UFO, and projectile designs.
- [ ] Add animated forward and reverse engine exhaust.
- [ ] Add boost trails and particle intensity changes.
- [ ] Add explosions, debris, hit flashes, and projectile impacts.
- [ ] Add shield glow and invulnerability blinking.
- [ ] Add starfield parallax, wave transitions, and subtle screen shake.
- [ ] Implement adjustable particle intensity and effect cleanup.

**Definition of done:** All significant player actions and collisions have clear visual feedback without obscuring the playfield.

## Phase 10 — Audio & UI Polish

**Goal:** A cohesive presentation with responsive menus and feedback.

- [ ] Add firing, thrust, boost, explosion, and pickup sound effects.
- [ ] Add menu and gameplay background music.
- [ ] Implement music, sound effects, and master audio buses.
- [ ] Polish HUD layout, typography, notifications, and animations.
- [ ] Polish main menu, leaderboard, Settings, and Game Over screens.
- [ ] Add keyboard-focused menu navigation and accessibility options.
- [ ] Check usability at different window sizes.

**Definition of done:** The game has consistent audio and visual styling, clear feedback, and readable screens.

## Phase 11 — Testing, Optimization & Release

**Goal:** A stable, packaged version of the finished game.

- [ ] Test player, asteroid, UFO, projectile, and power-up edge cases.
- [ ] Test pause, restart, Game Over, leaderboard, and settings persistence.
- [ ] Test long sessions with many simultaneous enemies and projectiles.
- [ ] Check for performance issues, orphaned nodes, and signal leaks.
- [ ] Adjust game balance and difficulty based on repeated playtests.
- [ ] Validate Windows, macOS, and Linux exports.
- [ ] Prepare README, controls reference, licenses, and release build.

**Definition of done:** The project runs reliably, maintains smooth gameplay, and is ready to distribute.

### Milestone 3 — Release Ready

- [ ] All core gameplay and menus pass final tests.
- [ ] Visual and audio feedback are complete.
- [ ] Performance stays acceptable during longer sessions.
- [ ] Desktop exports and documentation are ready.

---

# Future Expansion Backlog (Post-Release)

- [ ] Hyperspace teleportation (v1.1).
- [ ] Boss mothership encounters (v1.1).
- [ ] Unlockable spaceships (v1.2).
- [ ] Achievements and challenges (v1.2).
- [ ] Bonus collectibles (v1.2).
- [ ] Gamepad support (v1.2).
- [ ] Local two-player cooperative mode (v2.0).
- [ ] Online leaderboard (v2.0).

## Recommended AI Development Workflow

For each phase:

1. Give the coding AI the master game specification and **only the current phase's tasks**.
2. Implement a runnable increment with complete scenes, scripts, and assets for that phase.
3. Test the project in Godot against the checklist and definition of done.
4. Fix any issues before proceeding.
5. Commit the completed phase in Git.

**Rule:** Do not begin the next phase until the current phase meets its definition of done.
