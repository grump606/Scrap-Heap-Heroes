## Tunable match values. Pure data: no logic beyond defaults and unit helpers.
## The saved instance lives at res://data/match_rules.tres. Per-hero values
## live in HeroDef (res://data/heroes/).
class_name MatchRules
extends Resource

@export var tick_rate: int = 60
@export var arena_half_size: float = 20.0
@export var hero_acceleration: float = 40.0
## Seconds after a form switch before the next is allowed. Short, but long
## enough that switching can't be used to dodge everything.
@export var form_switch_cooldown: float = 2.0
## Bump when any balance value changes (here or in a HeroDef), so old replays
## are rejected, not desynced.
@export var data_version: int = 2


## Rounds, so 0.1 s at 60 Hz is 6 ticks, not 7 from float error.
func seconds_to_ticks(seconds: float) -> int:
	return roundi(seconds * tick_rate)
