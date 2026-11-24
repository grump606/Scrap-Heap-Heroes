## A lane minion. Walks toward the enemy base, fights enemy minions and
## heroes it meets, and holds outside enemy structures (it can't damage them;
## it soaks tower shots for its heroes). Driven by MinionAiSystem.
class_name MinionState
extends UnitState

## Enemy it is fighting, or 0.
var target_id: int = 0
var attack_ready: int = 0


func to_dict() -> Dictionary:
	var d := super()
	d["target_id"] = target_id
	return d


func hash_fields() -> Array:
	return super() + [target_id, attack_ready]
