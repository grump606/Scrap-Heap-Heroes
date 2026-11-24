## State shared by everything that can be hit and pushed: heroes, training
## dummies and (later) minions. Plain data, no Node, no visuals.
class_name UnitState
extends RefCounted

## Team for units every hero may hit, like training dummies.
const TEAM_NEUTRAL := -1

var entity_id: int
var team: int
var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
## Yaw in radians, 0 = facing -Z.
var facing: float = 0.0
var hp: int
var max_hp: int
## Body size for hit tests.
var radius: float = 0.5
var dead: bool = false
## Timed effects, see Status: [{kind, until, value}], in the order applied.
var statuses: Array = []
## Forced movement (a dash or a knockback): velocity is held until this tick.
var forced_velocity: Vector3 = Vector3.ZERO
var forced_until: int = 0
## Paid out if the current knockback slams this unit into a wall (Wall Crush).
var slam_damage: int = 0
var slam_stun_ticks: int = 0
var slam_source: int = 0
## Steering for units that walk (heroes, minions): a direction of length <= 1
## and a top speed. Units with move_speed 0 only coast.
var move_input: Vector2 = Vector2.ZERO
var move_speed: float = 0.0
## Structures never move and ignore knockback.
var immovable: bool = false


func is_forced(tick: int) -> bool:
	return tick < forced_until


## Flat damage reduction from passives, before form and buffs. Heroes override.
func base_reduction() -> int:
	return 0


func to_dict() -> Dictionary:
	return {
		"entity_id": entity_id,
		"team": team,
		"position": position,
		"velocity": velocity,
		"facing": facing,
		"hp": hp,
		"max_hp": max_hp,
		"radius": radius,
		"dead": dead,
		"statuses": statuses.duplicate(true),
	}


## Fields in a fixed order, for hashing. Subclasses append theirs.
func hash_fields() -> Array:
	return [entity_id, team, position, velocity, facing, hp, max_hp, radius, dead,
		statuses, forced_velocity, forced_until, slam_damage, slam_stun_ticks, slam_source,
		move_input, move_speed]
