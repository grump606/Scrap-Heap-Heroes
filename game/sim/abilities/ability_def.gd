## Tunable values for one ability. Pure data; saved instances live in
## res://data/abilities/<id>.tres. `logic` picks the sim script that runs it
## (see AbilityRegistry); each script reads only the fields it needs.
## Times are in seconds, distances in meters, speeds in meters per second.
class_name AbilityDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var logic: StringName = &""
@export var is_ultimate: bool = false
@export var cooldown: float = 5.0
## Delay between the press and the effect. The caster is rooted meanwhile.
@export var windup: float = 0.0
## Aimed at a spot on the ground (up to reach away) rather than a direction:
## the windup telegraph is drawn there.
@export var targets_point: bool = false

@export_group("Hit")
@export var damage: int = 0
## Extra damage paid on a wall slam (Wall Crush).
@export var bonus_damage: int = 0
@export var radius: float = 0.0
@export var reach: float = 0.0
@export var angle_deg: float = 90.0
## Flurries (Rocket Jab): how many hits, and the time between them.
@export var hits: int = 1
@export var hit_interval: float = 0.0
## Damage multiplier while empowered (Dive Bomb during Frenzy Run).
@export var empowered_multiplier: float = 1.0

@export_group("Movement")
@export var knockback_speed: float = 0.0
@export var knockback_duration: float = 0.0
@export var dash_speed: float = 0.0
@export var dash_duration: float = 0.0

@export_group("Effect")
## How long a buff or debuff lasts.
@export var duration: float = 0.0
## Strength of the buff or debuff: slow fraction, armor amount, ...
@export var magnitude: float = 0.0
@export var stun_duration: float = 0.0
## Time added to the effect (Frenzy Run: per new enemy hero hit).
@export var extend_duration: float = 0.0

@export_group("Support")
## Healing: a flat amount for instant heals, per second for heals over time.
@export var heal: int = 0
## Damage a shield absorbs, and how long it lasts.
@export var shield: int = 0
@export var shield_duration: float = 0.0
