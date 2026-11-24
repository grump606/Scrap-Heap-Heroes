## Gameplay state for one hero. Plain data, no Node, no visuals.
## A "player" is a player_id plus a controller; this is the hero they drive.
class_name HeroState
extends UnitState

enum Form { PET = 0, MECH = 1 }

## No request pending (see form_request).
const NO_REQUEST := -1

var player_id: int
var hero_id: StringName
## Tunables for this hero. Not hashed: MatchRules.data_version covers them.
var def: HeroDef
var spawn: Vector3 = Vector3.ZERO
var form: int = Form.PET
var mech_energy: float = 0.0
var move_speed: float
## Latest move intent from commands, held until the next MOVE command.
var move_input: Vector2 = Vector2.ZERO
## First tick a form switch is allowed again.
var switch_ready_tick: int = 0
## Form asked for this tick by a SWITCH_FORM command; FormSystem consumes it.
var form_request: int = NO_REQUEST
var respawn_tick: int = 0
## First tick each ability slot can be used again, per form.
var pet_ready: Array[int] = []
var mech_ready: Array[int] = []
## Ability presses this tick: [{slot, aim: Vector2}]; AbilitySystem consumes them.
var ability_requests: Array = []
## The contact dash in progress (Wall Crush), or null.
var dash_ability: AbilityDef


static func other_form(f: int) -> int:
	return Form.PET if f == Form.MECH else Form.MECH


func base_reduction() -> int:
	return def.flat_reduction if def != null else 0


func ready_for(f: int) -> Array[int]:
	return mech_ready if f == Form.MECH else pet_ready


## Applies the per-form stats from def.
func apply_form(f: int) -> void:
	form = f
	move_speed = def.move_speed(f)
	radius = def.radius(f)


func to_dict() -> Dictionary:
	var d := super()
	d.merge({
		"player_id": player_id,
		"hero_id": hero_id,
		"form": form,
		"mech_energy": mech_energy,
		"switch_ready_tick": switch_ready_tick,
		"respawn_tick": respawn_tick,
		"pet_ready": pet_ready.duplicate(),
		"mech_ready": mech_ready.duplicate(),
	})
	return d


func hash_fields() -> Array:
	return super() + [player_id, String(hero_id), spawn, form, mech_energy, move_speed,
		move_input, switch_ready_tick, form_request, respawn_tick, pet_ready, mech_ready,
		ability_requests, String(dash_ability.id) if dash_ability != null else ""]
