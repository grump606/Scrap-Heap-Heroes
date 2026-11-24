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
## First tick a form switch is allowed again.
var switch_ready_tick: int = 0
## Form asked for this tick by a SWITCH_FORM command; FormSystem consumes it.
var form_request: int = NO_REQUEST
var respawn_tick: int = 0
## First tick each ability slot can be used again, per form.
var pet_ready: Array[int] = []
var mech_ready: Array[int] = []
## First tick the basic attack can be used again (shared by both forms).
var attack_ready: int = 0
## Ability presses this tick: [{slot, aim: Vector2}]; AbilitySystem consumes them.
var ability_requests: Array = []
## The contact dash in progress (Wall Crush, Rocket Boost), or null.
var dash_ability: AbilityDef
## A channeled ability in progress (Steam Jet): its def, the unit it is
## aimed at, and the tick it ends. channel_target 0 = not channeling.
var channel_ability: AbilityDef
var channel_target: int = 0
var channel_until: int = 0
## Airborne arc (Pounce, Dive Bomb), for the view only: the hero is off the
## ground from air_start to air_end, peaking at air_height meters. The sim is
## flat, so being airborne changes nothing else.
var air_start: int = 0
var air_end: int = 0
var air_height: float = 0.0
## Enemy heroes already hit during the current Frenzy Run.
var frenzy_hits: Array[int] = []


func is_channeling() -> bool:
	return channel_target != 0


func stop_channel() -> void:
	channel_ability = null
	channel_target = 0
	channel_until = 0


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
		"attack_ready": attack_ready,
		"channel_target": channel_target,
		"air_start": air_start,
		"air_end": air_end,
		"air_height": air_height,
	})
	return d


func hash_fields() -> Array:
	return super() + [player_id, String(hero_id), spawn, form, mech_energy,
		switch_ready_tick, form_request, respawn_tick, pet_ready, mech_ready, attack_ready,
		ability_requests, String(dash_ability.id) if dash_ability != null else "",
		String(channel_ability.id) if channel_ability != null else "", channel_target, channel_until,
		air_start, air_end, air_height, frenzy_hits]
