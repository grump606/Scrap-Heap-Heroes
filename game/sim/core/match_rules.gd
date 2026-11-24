## Tunable match values. Pure data: no logic beyond defaults and unit helpers.
## The saved instance lives at res://data/match_rules.tres. Per-hero values
## live in HeroDef (res://data/heroes/), per-ability ones in AbilityDef.
## All numbers are placeholders for playtesting.
class_name MatchRules
extends Resource

@export var tick_rate: int = 60
@export var hero_acceleration: float = 40.0

@export_group("Map")
## The map is one enclosed lane along Z. Team 0's base is at +Z, team 1's at -Z.
@export var arena_half_width: float = 10.0
@export var arena_half_length: float = 45.0
## Distance from the center line (z = 0) to each structure and spawn.
@export var core_z: float = 40.0
@export var tower_z: float = 22.0
@export var minion_spawn_z: float = 34.0
@export var hero_spawn_z: float = 28.0
## Heroes heal this fraction of max health per second while behind their own
## core and within base_heal_radius of its back. Defending in front of the
## core doesn't heal: you have to fall back.
@export var base_heal_radius: float = 4.0
@export var base_heal_per_second: float = 0.08

@export_group("Forms and mech meter")
## Seconds after a form switch before the next is allowed. Short, but long
## enough that switching can't be used to dodge everything.
@export var form_switch_cooldown: float = 2.0
@export var mech_energy_max: float = 100.0
@export var mech_energy_start: float = 50.0
## Energy needed to enter mech form, so a near-empty meter can't flicker in and out.
@export var mech_min_energy_to_switch: float = 30.0
## Drain in mech form. 100 / 3 is about 33 s of mech time (target 25 to 40 s).
@export var mech_drain_per_second: float = 3.0
@export var pet_refill_per_second: float = 5.0
## After an empty meter ejects a hero: no damage reduction, no abilities.
@export var eject_vulnerable_time: float = 1.5

@export_group("Damage")
## A hit always deals at least this fraction of its original amount.
@export var damage_floor_fraction: float = 0.25
## Mech form multiplies a hero's passive flat reduction.
@export var mech_reduction_multiplier: float = 2.0
## Fraction of flat reduction that ultimates ignore.
@export var ultimate_reduction_ignore: float = 0.5
## Mech form "breaks towers": hero damage to structures is multiplied by this in mech form.
@export var mech_structure_multiplier: float = 1.5
@export var respawn_time: float = 4.0

@export_group("Structures")
@export var tower_max_hp: int = 6000
@export var tower_radius: float = 1.5
@export var tower_range: float = 9.0
@export var tower_damage: int = 150
@export var tower_attack_interval: float = 1.2
@export var core_max_hp: int = 8000
@export var core_radius: float = 2.0

@export_group("Minions")
@export var first_wave_time: float = 3.0
@export var wave_interval: float = 25.0
@export var wave_size: int = 3
@export var minion_max_hp: int = 350
@export var minion_radius: float = 0.45
@export var minion_move_speed: float = 3.5
@export var minion_damage: int = 25
@export var minion_reach: float = 1.4
@export var minion_attack_interval: float = 1.0
## Minions chase enemies within this distance; otherwise they walk the lane.
@export var minion_aggro_range: float = 6.0
## Minions stop this far outside the nearest living enemy structure's body.
@export var minion_hold_distance: float = 4.0

@export_group("Training dummies")
@export var dummy_max_hp: int = 2000
## Seconds after the last hit or push before a dummy heals and goes home.
@export var dummy_reset_time: float = 3.0

## Bump when any balance value changes (here, in a HeroDef or an AbilityDef),
## so old replays are rejected, not desynced.
@export var data_version: int = 4


## Rounds, so 0.1 s at 60 Hz is 6 ticks, not 7 from float error.
func seconds_to_ticks(seconds: float) -> int:
	return roundi(seconds * tick_rate)


## +1 for team 0 (base at +Z), -1 for team 1.
static func team_side(team: int) -> float:
	return 1.0 if team == 0 else -1.0
