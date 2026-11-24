## Timed effects on a unit. Stored as plain dictionaries in UnitState.statuses
## so they hash and snapshot simply: {"kind": int, "until": int, "value": float}.
## A status is active while tick < until.
class_name Status
extends RefCounted

enum Kind {
	SLOW = 0,        ## value: fraction of move speed removed (strongest wins)
	ARMOR = 1,       ## value: extra flat damage reduction (stacks)
	ROOTED = 2,      ## can't move; also immune to knockback (planted)
	STUNNED = 3,     ## can't move, cast or switch form
	VULNERABLE = 4,  ## after an eject: no damage reduction, can't cast or switch
}

## What a cleanse (Dust Bath) removes.
const CLEANSABLE := [Kind.SLOW, Kind.STUNNED]


static func add(u: UnitState, kind: int, until: int, value: float = 0.0) -> void:
	u.statuses.append({"kind": kind, "until": until, "value": value})


static func active(u: UnitState, kind: int, tick: int) -> bool:
	for s in u.statuses:
		if s["kind"] == kind and tick < s["until"]:
			return true
	return false


static func total(u: UnitState, kind: int, tick: int) -> float:
	var sum := 0.0
	for s in u.statuses:
		if s["kind"] == kind and tick < s["until"]:
			sum += s["value"]
	return sum


static func strongest(u: UnitState, kind: int, tick: int) -> float:
	var best := 0.0
	for s in u.statuses:
		if s["kind"] == kind and tick < s["until"]:
			best = maxf(best, s["value"])
	return best


static func expire(u: UnitState, tick: int) -> void:
	u.statuses = u.statuses.filter(func(s): return tick < s["until"])


static func cleanse(u: UnitState) -> void:
	u.statuses = u.statuses.filter(func(s): return not CLEANSABLE.has(s["kind"]))


## True if the unit may start an ability or switch form this tick.
static func can_act(u: UnitState, tick: int) -> bool:
	return not u.dead and not u.is_forced(tick) and not active(u, Kind.STUNNED, tick) \
		and not active(u, Kind.VULNERABLE, tick)
