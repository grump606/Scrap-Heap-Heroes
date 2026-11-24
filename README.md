# Scrap Heap Heroes

3v3 third-person pet/mech brawler, built in Godot 4.3+ with GDScript.
The design and architecture reference is the
[Architecture Plan](docs/Scrap_Heap_Heroes_Architecture_Plan.md).

## Layout

| Folder | What goes there |
| --- | --- |
| `game/sim/` | All gameplay logic. RefCounted only: no Nodes, scenes, Input, audio or frame time. |
| `game/control/` | Controllers that turn intent into commands: local player, bot, replay. |
| `game/view/` | Everything seen or heard. Reads snapshots, never writes to the sim. |
| `game/app/` | `match_session` runs the tick loop (sim, controllers, replay); `match_runner` drives it from frame time and draws it; settings autoload. |
| `game/net/` | Multiplayer interface only, for later. |
| `data/` | Tunable values as resources: `match_rules.tres`, one `heroes/<id>.tres` per hero. |
| `tests/` | Headless tests. |

## Run

- Play: open the folder in Godot and press F5. WASD moves the blue hero,
  right-click captures the mouse to turn the camera, Esc releases it,
  F switches between pet and mech form (2 s cooldown).
  The orange hero is a bot that goes through the same command system.
- Tests:
  ```
  godot --headless --path . --import
  godot --headless --path . -s res://tests/run_tests.gd
  ```
  The import step builds the `.godot/` class cache. It isn't committed, so a
  fresh checkout (or CI) needs it before the tests can resolve `class_name`s.
  On Godot 4.5+ a test that hits a script error, `push_error` or failed
  `assert` counts as failed; older engines only catch failed checks.

## How a tick works

`MatchSession.step()` does one tick, in the game and in the tests alike:


1. Each controller reads its team's `Snapshot` and emits `Command`s.
2. `CommandBuffer.take(tick)` returns them in a fixed order.
3. `SimWorld.step(commands)` advances one fixed tick and returns `SimEvent`s.
4. Every 60 ticks the state hash goes into the replay, so playback can
   detect a desync (`MatchSession.desync_tick`).
5. The view interpolates between the last two snapshots.

Replays carry the seed, slots with spawns, every command and the state
hashes, so `MatchSetup.from_replay()` can rebuild a match from the log alone.
A replay with a different `data_version` or game version
(`application/config/version`) is rejected.
