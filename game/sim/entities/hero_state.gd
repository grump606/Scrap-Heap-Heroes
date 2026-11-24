## Gameplay state for one hero. Plain data, no Node, no visuals.
## A "player" is a player_id plus a controller; this is the hero they drive.
class_name HeroState
extends RefCounted

enum Form { PET = 0, MECH = 1 }

## No request pending (see form_request).
const NO_REQUEST := -1

var entity_id: int
var player_id: int
var team: int
var hero_id: StringName
## Tunables for this hero. Not hashed: MatchRules.data_version covers them.
var def: HeroDef
var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
## Yaw in radians, 0 = facing -Z.
var facing: float = 0.0
var hp: int
var max_hp: int
var form: int = Form.PET
var mech_energy: float = 0.0
var move_speed: float
## Latest move intent from commands, held until the next MOVE command.
var move_input: Vector2 = Vector2.ZERO
## First tick a form switch is allowed again.
var switch_ready_tick: int = 0
## Form asked for this tick by a SWITCH_FORM command; FormSystem consumes it.
var form_request: int = NO_REQUEST


static func other_form(f: int) -> int:
	return Form.PET if f == Form.MECH else Form.MECH


func to_dict() -> Dictionary:
	return {
		"entity_id": entity_id,
		"player_id": player_id,
		"team": team,
		"hero_id": hero_id,
		"position": position,
		"velocity": velocity,
		"facing": facing,
		"hp": hp,
		"max_hp": max_hp,
		"form": form,
		"mech_energy": mech_energy,
		"switch_ready_tick": switch_ready_tick,
	}


## Fields in a fixed order, for hashing. Add new fields at the end.
func hash_fields() -> Array:
	return [entity_id, player_id, team, String(hero_id), position, velocity, facing,
		hp, max_hp, form, mech_energy, move_speed, move_input, switch_ready_tick, form_request]
