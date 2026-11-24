# Scrap Heap Heroes: Roster Review (Draft)

Nov 23, 2026 · @Grump606

Scrap Heap Heroes is a 3v3 third-person brawler where each hero is an animal that fights in two forms: a nimble pet and a heavy mech. This draft collects the decisions so far so we can review the roster and change heroes one at a time.

Status: six heroes are drafted, and Rabbit has just been reworked (see the Rabbit section). Everything here is a working draft, and all numbers are placeholders for playtesting.

## Setting and theme

The identity is an animal piloting a mech, set in the Rumble League, a pro brawling league held in a scrapyard stadium. The old toy-box and pocket-dimension framing is retired.

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

Six heroes cover tank, damage, and support with two playstyles each; Rabbit is the only hero with an open slot.

| Hero | Role | Pet form | Mech form | Notes |
| --- | --- | --- | --- | --- |
| Wombat (Wilma, she) | Positional tank | Dust Bath (cleanse, slight slow), Mud Slide (slide, extra hide, faster scrap pickup) | Rump Bump (cone knockback), Wall Crush (wall-slam bonus), Brace (planted, extra hide), Burrow Burst ultimate (knockback ring) | Heavy Hide passive: flat damage reduction. Name locked as Gale. |
| Tortoise (Gus, he) | Zone tank | Shell Up (hold to tuck in, much less damage), Mossy Step (slowing moss trail) | Barrier Wall, Bulwark Dome, Slow Stomp, Fortress Mode ultimate (movable mech, anchored shield) | Steady Footing passive halves knockback and knockdown. See the Tortoise section. |
| Weasel (Noodle, he) | Dive damage | Sprint (speed burst), Pounce (leap across gaps) | Rocket Boost, Dive Bomb (ground-circle dive), Rocket Jab, Frenzy Run ultimate | Replaces Fox. Vent Runner passive. See the Weasel section. |
| Owl (Orson, he) | Ranged damage | Glide, Spot (reveals enemies through walls) | Mortar Lob, Scope Mode, Perch Stance, Eclipse Barrage ultimate | Night Eyes reveal. See the Owl section. |
| Capybara (Yuzu, she) | Healer | Chill Aura (stronger while still), Yuzu Toss (aimed heal), Calm Pulse | Hot Spring, Steam Jet, Bubble Shield, Grand Onsen ultimate | Replaces Axolotl. Healing is mostly positional. See the Capybara section. |
| Rabbit (Pogo, she) | Mobility support | Spring Mound, Thump | Mega Mound, Big Bounce, speed boost, Grand Thump (AoE stun ultimate) | Reworked, see next section. |

## Rabbit: Pogo (revised)

Rabbit keeps its pet-form launching, drops the Launch Cannon because it took control away from teammates, and gains an area stun ultimate that pairs with Elephant's knockback.

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

* Form switching is locked while an ally is being launched. They must land before switching, because switching forms can't be used to dodge.
* If a mech-form ally's energy runs out mid-launch, they eject to pet form when the timer expires, and the flight path stays as set at launch.

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

## Open questions

- [ ] Rabbit: should Grand Thump's 3-second knockdown do any damage?
- [ ] Ring-outs: confirm soft ring-outs on a couple of side platforms only.
- [ ] Title: Scrap Heap Heroes is the working title; run a full trademark check before announcing.
- [ ] Owl: tune the Eclipse Barrage interrupt threshold once there is a working model; Spot's extra-damage bonus is on hold.
- [ ] Team rule: revisit free pick after playtests (forced 1-1-1 for now).

* [ ] Weasel: confirm Frenzy Run, where Dive Bomb becomes enemy-only with more damage, is the right ultimate.

- [ ] Capybara: tune Yuzu Toss limits (heal amount, cooldown, energy-refill pause) so it doesn't reward staying in pet form.

## Prototype plan

The prototype builds three heroes first and keeps the code multiplayer-ready from the start.

1. **Foundation:** one hero, one enclosed arena, movement, third-person camera, and form switching.
2. **Core kit:** abilities, the energy meter with tunable values, and a training dummy.
3. **Match loop:** minions, a tower, the Power Core, and basic bots that use the same command system as players.
4. **First three heroes:** Wombat, Weasel, and Capybara, to test knockback, mobility, and healing.
5. **Then add:** Rabbit, Owl, and Tortoise one at a time, balancing as you go.
6. **Later:** networking tests, soft ring-outs, and the neutral salvage-rig objective.

Structure rules for multiplayer later: keep game logic separate from rendering and input, route all actions through commands, use a fixed timestep, and seed the random number generator.
