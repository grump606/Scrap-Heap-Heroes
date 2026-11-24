## A tower or a Power Core. Never moves. A tower shoots enemies in range,
## minions first. A core can't be damaged while its team's tower stands, and
## destroying it ends the match.
class_name StructureState
extends UnitState

enum Kind { TOWER = 0, CORE = 1 }

var kind: int = Kind.TOWER
## Tower only: who it is shooting, and when it may shoot again.
var target_id: int = 0
var attack_ready: int = 0


func to_dict() -> Dictionary:
	var d := super()
	d["kind"] = kind
	d["target_id"] = target_id
	return d


func hash_fields() -> Array:
	return super() + [kind, target_id, attack_ready]
