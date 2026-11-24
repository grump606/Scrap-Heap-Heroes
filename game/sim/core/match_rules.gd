## Tunable match values. Pure data: no logic beyond defaults.
## The saved instance lives at res://data/match_rules.tres.
class_name MatchRules
extends Resource

@export var tick_rate: int = 60
## Catch-up cap after a long frame or alt-tab (prevents the spiral of death).
@export var max_ticks_per_frame: int = 5
@export var arena_half_size: float = 20.0
@export var hero_move_speed: float = 6.0
@export var hero_acceleration: float = 40.0
@export var hero_max_hp: int = 1000
## Bump when any balance value changes, so old replays are rejected, not desynced.
@export var data_version: int = 1
