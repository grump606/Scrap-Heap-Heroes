# Scrap Heap Heroes: Architecture Plan

Nov 23, 2026 · @Grump606

## Status and decisions

The first build step is done (Nov 24, 2026): the folder structure, the sim core, the headless determinism and replay tests, and a local and a bot controller sharing one command buffer. The Foundation phase is done too: an enclosed arena, the third-person camera, and pet/mech form switching with a cooldown and per-hero, per-form move speeds (`data/heroes/*.tres`), with placeholder art for both forms. Next up is the Core kit. The design is single-player first, built so multiplayer can be added later without a rewrite. It targets Godot 4.3 or later.

This doc is the single primary reference for Scrap Heap Heroes: the game design (setting, match format, core mechanic and roster) comes first, then the technical architecture. It replaces the separate Roster Review draft. All gameplay numbers are placeholders for playtesting.

- **Language:** GDScript for the prototype. C# stays an option later if the simulation needs more speed.
- **Sim tick rate:** 60 Hz to start, kept as a tunable value (30 Hz is cheaper to network later).
- **First files:** only the empty folders, the sim core scripts, a headless determinism test, and a bot and a local controller that both move one hero. Everything else waits.

## Setting and theme

Scrap Heap Heroes is a 3v3 third-person brawler where each hero is an animal that fights in two forms: a nimble pet and a heavy mech. The identity is an animal piloting a mech, set in the Rumble League, a pro brawling league held in a scrapyard stadium. The old toy-box and pocket-dimension framing is retired.

- **Why scrapyard:** it explains the scrap meter and the patched, repurposed mech look.
- **Map features:** pipes and culverts that only pet form fits through, crane platforms and scrap cliffs for edges, and a giant salvage rig as the neutral objective.
- **Art direction:** chunky, bright, stylized low-poly, with readable animal silhouettes.
- **Working title:** Scrap Heap Heroes (a quick web search found no exact match; the closest is Scrap Metal Heroes Rebuilt, a robot RTS; a full trademark check is still needed).

## Match format and controls

Matches are 3v3, one tank, one damage, one support per team, and last 10 to 15 minutes.

- **Camera and controls:** third-person, direct WASD movement, aimed abilities.
- **Map:** compact, with one main lane, two pet-only side routes, one tower and a Power Core per side, and a neutral salvage-rig objective mid-match.
- **Edges:** soft ring-outs on a couple of side platforms only. Falling means a respawn at the nearest safe spot, lost mech energy, and a short delay, not an instant death. Start the prototype with an enclosed map and add edges later as a toggle.
- **Damage reduction:** flat reduction per hit, with a floor of about 25% of the original hit. Ultimates and damage-over-time partly ignore it. Mech form doubles the flat value.
- **Team rule:** forced 1-1-1 roles for now; free pick can be revisited after playtests.

## Core mechanic: Pet form and Mech form

Every hero switches between a fast, fragile pet and a slow, tough mech, and an energy meter controls how long the mech lasts.

- **Pet form:** fast, fragile, two utility skills; scouts, collects scrap, uses pet-only routes. Refills the mech meter.
- **Mech form:** slow, tough, three combat skills plus an ultimate; breaks towers. Drains the meter.
- **Empty meter:** the hero ejects back to pet form and is briefly vulnerable.
- **Switch cooldown:** short, so it can't be used to dodge everything.
- **Pacing:** the drain rate, refill rate, and switch cooldown are separate tunable values. Working target is about 25 to 40 seconds of mech time, to be tested in the prototype.

## Current roster

Six heroes cover tank, damage, and support with two playstyles each.

| Hero | Role | Pet form | Mech form | Notes |
| --- | --- | --- | --- | --- |
| Wombat (Wilma, she) | Positional tank | Dust Bath (cleanse, slight slow), Mud Slide (slide, extra hide, faster scrap pickup) | Rump Bump (cone knockback), Wall Crush (wall-slam bonus), Brace (planted, extra hide), Burrow Burst ultimate (knockback ring) | Heavy Hide passive: flat damage reduction. |
| Tortoise (Gus, he) | Zone tank | Shell Up (hold to tuck in, much less damage), Mossy Step (slowing moss trail) | Barrier Wall, Bulwark Dome, Slow Stomp, Fortress Mode ultimate (movable mech, anchored shield) | Steady Footing passive halves knockback and knockdown. See the Tortoise section. |
| Weasel (Noodle, he) | Dive damage | Sprint (speed burst), Pounce (leap across gaps) | Rocket Boost, Dive Bomb (ground-circle dive), Rocket Jab, Frenzy Run ultimate | Replaces Fox. Vent Runner passive. See the Weasel section. |
| Owl (Orson, he) | Ranged damage | Glide, Spot (reveals enemies through walls) | Mortar Lob, Scope Mode, Perch Stance, Eclipse Barrage ultimate | Night Eyes reveal. See the Owl section. |
| Capybara (Yuzu, she) | Healer | Yuzu Toss (aimed heal), Calm Pulse | Hot Spring, Steam Jet, Bubble Shield, Grand Onsen ultimate | Chill Aura passive (stronger while still). Replaces Axolotl. Healing is mostly positional. See the Capybara section. |
| Rabbit (Pogo, she) | Mobility support | Spring Mound, Thump | Mega Mound, Big Bounce, speed boost, Grand Thump (AoE stun ultimate) | Reworked, see the Rabbit section. |

## Rabbit: Pogo (revised)

Rabbit keeps its pet-form launching, drops the Launch Cannon because it took control away from teammates, and gains an area stun ultimate that pairs with Wombat's knockback.

**Pet form (kept)**

1. **Spring Mound:** place a bouncy mound that launches allies who step on it in the direction it faces. One out at a time, ally-only, and it only launches allies who are in pet form. The ally chooses to step on it, so nobody loses control.
2. **Thump:** stomp for a short speed boost to nearby allies.

**Mech form**

1. **Mega Mound (replaces Launch Cannon):** a mech-sized spring mound with a longer cooldown than Spring Mound. Only one out at a time, it only launches allies who are in mech form, and the ally decides whether to step on it. Launch distance follows the rules below.
2. **Big Bounce (kept):** a large hop for repositioning.
3. **Speed boost (kept):** a ground pulse that gives nearby allies a brief move-speed boost. The enemy slow from the earlier draft is optional.
4. **Ultimate, Grand Thump (new):** a large area pound around the mech after a visible wind-up. Enemies hit are knocked down for 3 seconds (a starting value to tune later). Allies are unaffected.

**Launch distance rules (both mounds)**

- Distance is proportional to the movement speed of the form each mound serves (pet for Spring Mound, mech for Mega Mound), with one shared multiplier so the two feel consistent.
- A pet-form ally on Spring Mound travels farther than a mech-form ally on Mega Mound, in proportion to how fast each form moves.
- Speed boosts (Thump and the mech speed boost) raise the ally's movement speed, so they also increase launch distance.
- Mega Mound has a longer cooldown than Spring Mound.
- A maximum launch distance cap (a tunable value) keeps stacked boosts from sending allies across the whole map.
- Form switching is locked while an ally is being launched. They must land before switching, because switching forms can't be used to dodge.
- If a mech-form ally's energy runs out mid-launch, they eject to pet form when the timer expires, and the flight path stays as set at launch.

**Grand Thump design notes**

- **Wombat synergy:** knockback sets enemies up and Grand Thump keeps them down, so a team can follow with Wall Crush wall-slam damage or Owl artillery.
- **Counterplay:** a telegraphed ring and wind-up; enemies that are airborne when it lands are not affected.
- **Frustration guard:** a 3-second knockdown (tunable), long cooldown, and a few seconds of immunity to repeat stuns afterward.
- **Commitment:** mech form only, so Rabbit has to be exposed in the mech to use it.

**Other mech slot ideas (Mega Mound chosen; these are shelved)**

| Option | What it does | Trade-off |
| --- | --- | --- |
| Mega Mound (chosen) | A mech-sized spring mound that launches allies farther than Spring Mound. The ally decides whether to step on it. | Simple and consistent with the pet-form kit, but similar to Spring Mound. |
| Bounce Lane | Drops a short line of three springs ahead of the mech, creating a quick route for allies. | More map control, but harder to read and place. |
| Rally Hop | Rabbit hops and nearby allies can press a button to join the hop for a short distance. | Strong team play, but needs clear rules so it isn't confusing. |

## Tortoise: Gus (zone tank)

Tortoise controls space with walls and shields that block only opponents, and it shrugs off knockback and knockdown.

**Passive: Steady Footing:** knockback and knockdown effects against Tortoise are reduced by about half (placeholder). It counters Wombat's shoves and Rabbit's Grand Thump.

**Pet form**

1. **Shell Up:** hold to tuck into the shell. No movement or abilities, but much less damage taken.
2. **Mossy Step:** leave a moss trail for a few seconds that slows enemies walking through it.

**Mech form**

1. **Barrier Wall:** aim and place a wall segment with its own health and a short lifetime. Blocks opponents only.
2. **Bulwark Dome:** plant the mech and raise a dome for a few seconds. Blocks enemy projectiles, and allies inside take reduced damage.
3. **Slow Stomp:** a small area stomp that slows enemies and leaves a brief slow zone.
4. **Ultimate, Fortress Mode:** raise a large stone shield around the mech. Tortoise can keep moving, but the shield stays where it was cast for several seconds.

**Fortress Mode rules**

- The shield blocks opponents only. Allies and allied projectiles pass through it.
- Allies inside the shield take reduced damage.
- Once an ally leaves the shield, or it expires, they keep the reduced-damage buff for a brief time.
- Long cooldown; shield health and duration are placeholders for playtesting.

**Limits and risks**

- No more than two Barrier Walls at once, with a short lifetime, and no placement on objectives, so walls can't seal a lane.
- Owl's artillery arcs over walls, so it counters Tortoise's barriers by design.
- Walls and the shield are shared objects, so the host or server must own them.

## Owl: Orson (ranged damage)

Owl is the long-range damage hero, built around information, positioning, and punishing enemies who stand still.

**Night Eyes:** enemies Owl spots are outlined through walls for the whole team for a few seconds (placeholder).

**Pet form**

1. **Glide:** hold jump to glide slowly downward and cross gaps, pits, and low walls.
2. **Spot:** mark an enemy in your sights. Night Eyes reveals them through walls to the team.

**Mech form**

1. **Mortar Lob:** an aimed arcing shot with slow travel time and a small area burst. It arcs over walls.
2. **Scope Mode:** zoom in for more range and a clearer view, with slowed movement.
3. **Perch Stance:** the mech plants its legs for a few seconds. It can't move, but Mortar Lob gets longer range and a faster fire rate.
4. **Ultimate, Eclipse Barrage:** mark a large area. After a short delay, a barrage of shells lands there over several seconds. The zone is visible to everyone, so enemies can dodge.

**Rules and review notes**

- Eclipse Barrage is interrupted if Owl takes a large hit while casting (damage threshold is a placeholder).
- Spot's through-wall reveal is in. An extra-damage bonus on spotted enemies was discussed but looks too strong, so it stays out of the first prototype and gets reviewed later.
- Aiming arcs needs a clear arc line and landing circle, and shells and barrages must be decided by the host or server.

## Capybara: Yuzu (healer)

Capybara heals mostly through where it stands, with a few aimed skills on top. All values are placeholders.

**Passive: Chill Aura:** nearby allies slowly regain health, and the aura is stronger while Capybara stands still.

**Pet form**

1. **Yuzu Toss:** an aimed lob that heals the first ally it hits for a small amount. Limited so pet form isn't a healing playstyle (see limits below).
2. **Calm Pulse:** a short pulse that shortens crowd control on nearby allies.

**Mech form**

1. **Hot Spring:** place a steaming pool. Allies standing in it heal over time and gain a small shield. One pool at a time, limited duration.
2. **Steam Jet:** a short-range channeled stream aimed at one ally. It heals while the line stays connected and breaks if blocked or out of range.
3. **Bubble Shield:** aim at an ally to wrap them in a bubble that absorbs a set amount of damage for a few seconds.
4. **Ultimate, Grand Onsen:** a large relaxing zone for several seconds. Allies inside heal faster and can't be crowd-controlled. Enemies inside are not weakened, but healing they receive is reduced. The zone is visible to everyone.

**Limits and risks**

- Yuzu Toss heals less than mech-form healing, has a long cooldown, and pauses the pet's mech-energy refill for a few seconds after use, so it trades energy for healing and doesn't reward staying in pet form.
- Staying still makes Capybara a target for Weasel's dives, which is intended counterplay.
- Tortoise and Capybara both protect allies, so keep Tortoise on blocking space and Capybara on healing.
- Grand Onsen's crowd-control immunity could cancel Rabbit's and Wombat's best tools, so it has a short duration and a clear visual.

## Weasel: Noodle (dive damage)

Weasel is a fast dive hero that reaches the backline with pet-form mobility and a rocket mech. All values are placeholders.

**Passive: Vent Runner:** Weasel is the fastest hero through pet-only routes and gets a short speed boost when it exits one.

**Pet form**

1. **Sprint:** a burst of extra speed for a short time.
2. **Pounce:** a leap in the aimed direction that crosses gaps and low walls, with a short cooldown.

**Mech form**

1. **Rocket Boost:** an aimed rocket dash that closes distance. It gives no invulnerability.
2. **Dive Bomb:** aim a target circle on the ground. Weasel rises briefly, then slams down there for area damage, which also makes it a mobility tool. Weasel is exposed during the rise, and damage grows with the distance of the dive.
3. **Rocket Jab:** a quick flurry of short-range rocket punches in front of the mech, for finishing off targets.
4. **Ultimate, Frenzy Run:** for a few seconds, Rocket Boost and Dive Bomb have no cooldown. During it, Dive Bomb can only target enemies (no ground circle) and deals more damage on hit. Each hit on a different enemy extends the timer, and Weasel receives reduced healing while it lasts.

**Limits and risks**

- Dive Bomb's ground circle and rise are visible to enemies, so they can dodge or punish the rise.
- Rocket Boost gives no invulnerability, matching the rule that form switching can't be used to dodge.
- Walls and domes from Tortoise block Weasel, and Wombat's flat damage reduction is weak against Dive Bomb's single big hit.
- Fast dives need the host or server to decide hits, with smoothing on clients.

## Multiplayer-ready rules

Six rules keep the single-player build from becoming a rewrite when remote players arrive.

- **Logic apart from rendering and input.** The simulation runs with no graphics, so it can be tested headless.
- **Everything through commands.** The player and the bots both issue commands to the same system.
- **Fixed timestep.** Game logic advances in fixed ticks, never by frame time.
- **Seeded random numbers.** One seeded generator per world makes matches replayable exactly.
- **Bots follow player rules.** A bot is just another client sending commands, which is what a remote player will be.
- **No globals for player data.** Player state lives in the world, keyed by player id, since several players share one match.

## Folder structure

The `sim/` folder holds all gameplay logic and must never touch scenes, input or audio. Everything the player sees lives in `view/`.

```
scrap-heap-heroes/
├─ project.godot
├─ docs/                          # design doc exports, decisions
├─ data/                          # tunables as plain resources, no logic
│  ├─ heroes/        wombat.tres, tortoise.tres, weasel.tres, ...
│  ├─ abilities/     rump_bump.tres, dive_bomb.tres, ...
│  └─ match_rules.tres            # tick rate, meter drain, team rule
├─ game/
│  ├─ sim/                        # PURE LOGIC. No Node, no scenes, no input, no audio.
│  │  ├─ core/
│  │  │  ├─ sim_world.gd          # owns all state; step(tick, commands) -> events
│  │  │  ├─ tick_clock.gd         # fixed timestep accumulator
│  │  │  ├─ sim_rng.gd            # seeded RNG, per-world, split streams
│  │  │  ├─ command.gd            # player_id, tick, type, payload
│  │  │  ├─ command_buffer.gd     # collects + orders commands per tick
│  │  │  ├─ sim_event.gd          # outgoing events (hit, death, form_switch)
│  │  │  ├─ snapshot.gd           # read-only copy of state for view/net
│  │  │  ├─ match_rules.gd        # the resource type behind data/match_rules.tres
│  │  │  └─ replay_log.gd         # seed, versions, slots, commands, state hashes
│  │  ├─ entities/
│  │  │  ├─ hero_def.gd           # per-hero tunables; the type behind data/heroes/*.tres
│  │  │  ├─ hero_state.gd         # pos, vel, hp, form, mech_energy, cooldowns
│  │  │  ├─ minion_state.gd
│  │  │  ├─ tower_state.gd        # Tower + Power Core
│  │  │  └─ objective_state.gd    # salvage rig
│  │  ├─ systems/                 # stateless functions over world state
│  │  │  ├─ movement_system.gd
│  │  │  ├─ ability_system.gd
│  │  │  ├─ form_system.gd        # pet/mech, meter, eject
│  │  │  ├─ damage_system.gd      # flat reduction + floor
│  │  │  ├─ knockback_system.gd
│  │  │  ├─ minion_ai_system.gd
│  │  │  └─ match_flow_system.gd  # phases, win condition, respawns
│  │  └─ abilities/               # one script per ability, data-driven
│  ├─ control/                    # turns intent into commands
│  │  ├─ controller.gd            # base: produce_commands(snapshot, tick)
│  │  ├─ local_player_controller.gd   # reads Input -> commands
│  │  ├─ bot_controller.gd            # reads snapshot -> commands
│  │  └─ replay_controller.gd         # reads recorded commands
│  ├─ view/                       # PRESENTATION. Reads snapshots, never writes sim.
│  │  ├─ world_view.gd            # spawns/updates visual nodes from snapshot
│  │  ├─ hero_view.gd             # mesh, anim, VFX, interpolation
│  │  ├─ camera_rig.gd            # third-person camera, per local player
│  │  ├─ audio_director.gd        # plays sounds from sim events
│  │  └─ ui/
│  │     ├─ hud.gd                # hp, mech meter, cooldowns
│  │     ├─ scoreboard.gd
│  │     └─ menus/
│  ├─ app/
│  │  ├─ match_session.gd         # the tick loop: controllers -> buffer -> replay -> sim; shared by game and tests
│  │  ├─ match_runner.gd          # only node: drives the session from frame time, wires the view
│  │  ├─ match_setup.gd           # seed, rosters, slots (human/bot/replay)
│  │  └─ settings.gd              # video/audio/input prefs, not gameplay data
│  └─ net/                        # empty until multiplayer; interfaces only
│     └─ transport.gd             # send_commands / receive_snapshot
├─ scenes/                        # .tscn files: arena, heroes, UI
├─ assets/                        # art, audio
└─ tests/
   ├─ run_tests.gd                # headless runner (run an --import first on a fresh checkout)
   ├─ sim/                        # headless tests, no graphics
   └─ replays/                    # recorded replay logs
```

## Core entities

Each gameplay entity has a data-only state in the sim and, where it is visible, a separate view that holds no gameplay state.

| Entity | Lives in | What it is |
| --- | --- | --- |
| Player (hero) | `sim/entities/hero_state.gd`, `view/hero_view.gd` | State holds position, velocity, health, form, mech energy, cooldowns, `player_id` and team. A player is a `player_id` plus a controller; humans and bots differ only in which controller feeds them. |
| Enemy | `minion_state.gd`, `tower_state.gd`, enemy heroes | A MOBA has no AI-only monsters: enemies are the other team's heroes, minions, towers and Power Core. Minions run through `minion_ai_system`. |
| UI | `view/ui/` | Reads snapshots and events only and never edits sim state. A button press becomes a command, like any other input. |
| Level manager | `match_flow_system` (sim), `match_runner` (app) | Split in two: the sim system owns phases, spawns, objective timers and win conditions; the runner loads the arena scene and wires everything together. |

## How state moves

&#91;embedded content: state flow · controllers to commands to sim to views\]

State flows one way: controllers produce commands, the sim applies them each tick, and the views only read the resulting snapshot and events. For multiplayer, only the transport changes: the host runs the sim, and remote players are another controller.

## Rules mapped to the plan

| Rule | How the plan satisfies it |
| --- | --- |
| Logic apart from rendering and input | `sim/` uses only `RefCounted` classes, no Nodes, so `tests/` can run it headless |
| Everything through commands | One `command_buffer`; humans, bots and replays all feed it |
| Fixed timestep | `tick_clock` accumulator, 60 Hz to start; the view interpolates between ticks |
| Seeded RNG | One `sim_rng` per world with separate streams, plus a separate cosmetic RNG for visual effects |
| Bots follow player rules | `bot_controller` sees only the snapshot and emits commands, with no direct state access |
| No globals for player data | State lives in `SimWorld`, keyed by `player_id`; the only autoload is a stateless `Settings` |

## Edge cases

This is a PC game, so the web-only items (browser audio unlock, browser canvas scaling) apply only if the game is ever exported to web.

**Timing and determinism**

- Alt-tab or a long frame can cause a spiral of death, so cap catch-up ticks per frame.
- High-refresh monitors need render interpolation so motion does not stutter.
- Godot's physics (Jolt) is not guaranteed deterministic, so authoritative movement and hits use the sim's own simple collision. Exact replays are reliable on the same build and machine, but not guaranteed across platforms, so multiplayer should use host snapshots, not lockstep.
- Commands arriving on the same tick need a fixed order (by `player_id`), or replays drift.
- Replay files must store the game version and balance-data version, or old replays desync silently. Both are stored and checked: a replay from another build or `data_version` is rejected. Replays also carry spawns and a state hash every 60 ticks plus a final one, so playback reports the first tick that desyncs.
- Entity IDs come from a sim counter, never from node creation order.

**Window and display**

- Resizing needs a stretch mode (`canvas_items` or `viewport`) with the aspect set to keep, and UI built with anchors and containers.
- Ultrawide and odd aspect ratios need safe-area handling for the HUD.
- High-DPI changes and fullscreen/windowed switches must not change sim state or tick rate.
- Moving between monitors with different refresh rates must keep the accumulator stable.

**Input**

- Losing focus must release the captured mouse and clear held keys, or heroes keep running.
- Gamepad hot-plug and rebinding change controllers, not sim code.
- Third-person camera input is view-only; the aim direction travels as part of a command.

**Audio**

- Changing the output device mid-match must not crash or desync.
- Audio plays from events, so a muted or missing audio device cannot affect gameplay.
- Web export only: browsers block audio until the first click.

**Pause and bots**

- Single-player pause stops the tick clock. In multiplayer, pause must not exist as a free dodge.
- Bots must not see hidden information the player cannot, such as enemies outside vision.

## First build step and open items

Done. The first step was kept small to prove the architecture before any hero content exists.

1. Create the empty folder structure above.
2. Write the `sim/core` scripts: world, tick clock, seeded RNG, command, command buffer and snapshot.
3. Add a headless test that runs 1,000 ticks twice with the same seed and checks that both runs end in identical state.
4. Add a local controller and a bot controller that both move one hero through the same command buffer.

Left out of the first step: abilities, forms, UI, art, minions and networking.

- [x] Confirm the folder structure.
- [x] Confirm GDScript, 60 Hz and the first-step scope.
- [x] Give the go-ahead to create files.
- [ ] Add the cosmetic RNG (separate from `sim_rng`) before the first visual effect.

## Prototype roadmap

After the first build step proves the architecture, the prototype builds three heroes first, then adds the rest one at a time. The roster review's earlier Foundation phase bundled camera and form switching into the first step; that now waits until the sim core and determinism test pass.

1. **First build step (done):** the sim core, determinism test and two controllers described above.
2. **Foundation (done):** one hero in one enclosed arena, third-person camera, and form switching. Switching is a command naming the target form; it applies only when the cooldown (`form_switch_cooldown`, 2 s placeholder) has passed, and a blocked request is dropped rather than queued. The meter, drain and eject come with the Core kit.
3. **Core kit:** abilities, the energy meter with tunable values, and a training dummy.
4. **Match loop:** minions, a tower, the Power Core, and basic bots that use the same command system as players.
5. **First three heroes:** Wombat, Weasel, and Capybara, to test knockback, mobility, and healing.
6. **Then add:** Rabbit, Owl, and Tortoise one at a time, balancing as you go.
7. **Later:** networking tests, soft ring-outs, and the neutral salvage-rig objective.

## Open design questions

- [ ] Rabbit: should Grand Thump's 3-second knockdown do any damage? Light damage would keep it from being a setup-only move (review suggestion).
- [ ] Rabbit: Tortoise's Steady Footing and Capybara's Grand Onsen both weaken Grand Thump; check that the ultimate still feels strong against them.
- [ ] Ring-outs: confirm soft ring-outs on a couple of side platforms only.
- [ ] Title: Scrap Heap Heroes is the working title; run a full trademark check before announcing.
- [ ] Owl: tune the Eclipse Barrage interrupt threshold once there is a working model; Spot's extra-damage bonus is on hold.
- [ ] Team rule: revisit free pick after playtests (forced 1-1-1 for now).
- [ ] Weasel: confirm Frenzy Run, where Dive Bomb becomes enemy-only with more damage, is the right ultimate.
- [ ] Capybara: tune Yuzu Toss limits (heal amount, cooldown, energy-refill pause) so it doesn't reward staying in pet form.
- [ ] Prototype: Rabbit arrives after Wombat, Weasel, and Capybara, so the Wombat and Rabbit combo can't be tested early; consider adding Rabbit sooner.
