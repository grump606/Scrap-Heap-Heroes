## Tunable match values. Pure data: no logic beyond defaults and unit helpers.
## The saved instance lives at res://data/match_rules.tres. Per-hero values
## live in HeroDef (res://data/heroes/), per-ability ones in AbilityDef.
## All numbers are placeholders for playtesting.
class_name MatchRules
extends Resource

@export var tick_rate: int = 60
@export var arena_half_size: float = 20.0
@export var hero_acceleration: float = 40.0

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
@export var respawn_time: float = 4.0

@export_group("Training dummies")
@export var dummy_max_hp: int = 2000
## Seconds after the last hit or push before a dummy heals and goes home.
@export var dummy_reset_time: float = 3.0

## Bump when any balance value changes (here, in a HeroDef or an AbilityDef),
## so old replays are rejected, not desynced.
@export var data_version: int = 3


## Rounds, so 0.1 s at 60 Hz is 6 ticks, not 7 from float error.
func seconds_to_ticks(seconds: float) -> int:
	return roundi(seconds * tick_rate)
