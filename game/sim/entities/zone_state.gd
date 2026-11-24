## A lasting area on the ground (Hot Spring, Grand Onsen). Not a unit: it
## can't be hit or pushed. ZoneSystem runs it; the ability script that made
## it (by def.logic) decides what it does each tick.
class_name ZoneState
extends RefCounted

var entity_id: int
var team: int
## The hero that placed it.
var owner_id: int
## Tunables. Not hashed: MatchRules.data_version covers them.
var def: AbilityDef
var position: Vector3 = Vector3.ZERO
var radius: float = 1.0
var start_tick: int = 0
## Removed once tick reaches this.
var until: int = 0
## Units that already got this zone's one-time effect (Hot Spring's shield).
var granted: Array[int] = []


func to_dict() -> Dictionary:
	return {
		"entity_id": entity_id,
		"team": team,
		"owner_id": owner_id,
		"ability": String(def.id) if def != null else "",
		"position": position,
		"radius": radius,
		"start_tick": start_tick,
		"until": until,
	}


func hash_fields() -> Array:
	return [entity_id, team, owner_id, String(def.id) if def != null else "", position, radius,
		start_tick, until, granted]
