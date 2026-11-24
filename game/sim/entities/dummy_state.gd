## A training dummy: takes hits and knockback like an enemy, never acts, and
## resets (full health, back home) a few seconds after it was last touched.
class_name DummyState
extends UnitState

var home: Vector3 = Vector3.ZERO
## Tick it resets on; 0 when untouched.
var reset_at: int = 0


func to_dict() -> Dictionary:
	var d := super()
	d["home"] = home
	return d


func hash_fields() -> Array:
	return super() + [home, reset_at]
