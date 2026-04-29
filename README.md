# Godot Drift Game

Sam's drift car game using Godot. A beginner-friendly, arcade top-down drift racer built in Godot 4.6.2-stable.

## Controls

| Action | Keys |
|---|---|
| Drive forward / brake / reverse | Up / Down (or W / S) |
| Steer | Left / Right (or A / D) |
| Drift | Space (hold) |
| Back to menu | Esc |

## How to play

1. Launch the project in Godot 4.6.2-stable and press F5 (or the play button).
2. From the main menu: **Play** → choose a car → choose a stage → drive.
3. To finish a run: cross the **yellow checkpoint line** on the far side of the track, then return to the **white start/finish line**.
4. Hold **Space** while above the minimum speed and turning to drift. Drift earns score; longer continuous drifts build a combo multiplier.

## Game flow

```
Main Menu -> Car Select -> Stage Select -> Stage 1 (drive) -> Results
```

Each menu has a Back button (and Esc) for navigation.

## V1 scope

What is implemented in V1:

- 5 scenes wired into a complete flow (menu, car select, stage select, gameplay, results)
- Top-down arcade driving with acceleration, braking, reverse, and speed-scaled steering
- Drift mechanic with separate normal vs. drift lateral grip values, gated by a min-drift speed
- Drift scoring that requires drift held + speed + slip angle, with a continuous-drift combo multiplier
- One playable track (Sunset Loop) with a checkpoint + finish line, run timer, and end-of-run results screen
- Two selectable cars with **slightly different stats** (top speed, acceleration, grip, drift grip)
- Selection state shared via a `GameState` autoload

What is intentionally **not** in V1:

- Multiple tracks (the data structure supports more — drop a new `StageData` `.tres` and a stage scene)
- AI opponents, sounds, particle effects
- Tile-based or curved track geometry (V1 uses an oval-style box loop)

## Tuning the feel

All car physics parameters live on `CarData` resources in `data/cars/*.tres`. Open them in Godot and tweak:

- `max_speed` — top speed in px/s
- `acceleration` — accel in px/s²
- `brake_strength` — deceleration when pressing brake while moving forward
- `steering_speed` — how fast the car rotates (rad/s, scaled by speed)
- `grip` — lateral velocity damping when *not* drifting (higher = stickier)
- `drift_grip` — lateral velocity damping while drifting (lower = longer slides)
- `min_drift_speed` — the speed below which the drift button does nothing

Scoring constants live at the top of `scripts/stage_1.gd`:

- `SCORE_PER_SECOND` — base score earned per second of valid drift
- `COMBO_BONUS_PER_SECOND` — added to the combo multiplier per second of continuous drift
- `SLIP_ANGLE_THRESHOLD` — how sideways the car must be (radians) for drift score to count

## Project layout

```
project.godot              # input actions, autoloads, display settings
icon.svg
scenes/
  main_menu.tscn
  car_select.tscn
  stage_select.tscn
  results.tscn
  player_car.tscn
  stages/
    stage_1.tscn
scripts/
  game_state.gd            # autoload: selected car/stage + last run result
  car_data.gd              # Resource: per-car tunables + color
  stage_data.gd            # Resource: stage display name + scene path
  player_car.gd            # CharacterBody2D arcade driving + drift grip swap
  stage_1.gd               # stage logic: HUD, scoring, checkpoint + finish
  main_menu.gd
  car_select.gd
  stage_select.gd
  results.gd
data/
  cars/
    car_red.tres
    car_blue.tres
  stages/
    stage_1.tres
```

## Notes for class

- The drift mechanic is the simplest working arcade model: lateral velocity is damped each tick, and pressing **Space** above the minimum speed swaps in a much weaker damping value so the car slides instead of gripping. This is easy to read in `scripts/player_car.gd` and easy to tune from the resource files.
- Adding a new car: copy `data/cars/car_red.tres`, change the values, and add it to `GameState.available_cars`.
- Adding a new stage: duplicate `scenes/stages/stage_1.tscn`, save a new `StageData` `.tres` pointing at it, and add it to `GameState.available_stages`.
