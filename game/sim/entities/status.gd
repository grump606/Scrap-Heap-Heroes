## Timed effects on a unit. Stored as plain dictionaries in UnitState.statuses
## so they hash and snapshot simply: {"kind": int, "until": int, "value": float},
## plus "tag": String for effects that refresh in place (see refresh).
## A status is active while tick < until.
class_name Status
extends RefCounted

enum Kind {
	SLOW = 0,        ## value: fraction of move speed removed (strongest wins)
	ARMOR = 1,       ## value: extra flat damage reduction (stacks)
	ROOTED = 2,      ## can't move; also immune to knockback (planted)
	STUNNED = 3,     ## can't move, cast or switch form
	VULNERABLE = 4,  ## after an eject: no damage reduction, can't cast or switch
	SHIELD = 5,      ## value: damage it still absorbs; used up oldest-expiry first
	HASTE = 6,       ## value: fraction of move speed added (strongest wins)
	HEAL_CUT = 7,    ## value: fraction of incoming healing removed (strongest wins)
	CC_IMMUNE = 8,   ## enemies can't slow, stun or knock back this unit
	NO_REFILL = 9,   ## pet form doesn't refill the mech meter
	FRENZY = 10,     ## Weasel's Frenzy Run. value: ticks added per new enemy hit
}

## What a cleanse (Dust Bath) removes.
const CLEANSABLE := [Kind.SLOW, Kind.STUNNED]
## Crowd control: blocked by CC_IMMUNE, shortened by Calm Pulse.
const CROWD_CONTROL := [Kind.SLOW, Kind.STUNNED]


static func add(u: UnitState, kind: int, until: int, value: float = 0.0) -> void:
	u.statuses.append({"kind": kind, "until": until, "value": value})


## Crowd control from an enemy: refused while the unit is CC_IMMUNE.
## Returns true if it took.
static func add_cc(u: UnitState, kind: int, tick: int, until: int, value: float = 0.0) -> bool:
	if active(u, Kind.CC_IMMUNE, tick):
		return false
	add(u, kind, until, value)
	return true


## Sets the status with this kind and tag (adding it if missing): an effect
## that is reapplied while a condition holds, like standing in a zone.
static func refresh(u: UnitState, kind: int, tag: String, until: int, value: float = 0.0) -> void:
	for s in u.statuses:
		if s["kind"] == kind and s.get("tag", "") == tag:
			s["until"] = maxi(int(s["until"]), until)
			s["value"] = value
			return
	u.statuses.append({"kind": kind, "until": until, "value": value, "tag": tag})


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


## The latest end tick of an active status of this kind, or 0.
static func until_of(u: UnitState, kind: int, tick: int) -> int:
	var best := 0
	for s in u.statuses:
		if s["kind"] == kind and tick < s["until"]:
			best = maxi(best, int(s["until"]))
	return best


## Pushes back the end of every active status of this kind.
static func extend(u: UnitState, kind: int, tick: int, ticks: int) -> void:
	for s in u.statuses:
		if s["kind"] == kind and tick < s["until"]:
			s["until"] = int(s["until"]) + ticks


## Cuts the time left on active crowd control by fraction (0.5 = half).
static func shorten_cc(u: UnitState, tick: int, fraction: float) -> void:
	for s in u.statuses:
		if CROWD_CONTROL.has(s["kind"]) and tick < s["until"]:
			var left := int(s["until"]) - tick
			s["until"] = tick + int(ceil(left * (1.0 - fraction)))


## Takes up to amount out of the unit's shields, the soonest to expire first.
## Returns how much they absorbed.
static func absorb(u: UnitState, tick: int, amount: int) -> int:
	var shields := u.statuses.filter(func(s): return s["kind"] == Kind.SHIELD and tick < s["until"] and s["value"] > 0.0)
	shields.sort_custom(func(a, b): return a["until"] < b["until"])
	var left := amount
	for s in shields:
		if left <= 0:
			break
		var take := mini(left, int(s["value"]))
		s["value"] = float(int(s["value"]) - take)
		left -= take
	u.statuses = u.statuses.filter(func(s): return not (s["kind"] == Kind.SHIELD and s["value"] <= 0.0))
	return amount - left


static func expire(u: UnitState, tick: int) -> void:
	u.statuses = u.statuses.filter(func(s): return tick < s["until"])


static func cleanse(u: UnitState) -> void:
	u.statuses = u.statuses.filter(func(s): return not CLEANSABLE.has(s["kind"]))


## True if the unit may start an ability or switch form this tick.
static func can_act(u: UnitState, tick: int) -> bool:
	return not u.dead and not u.is_forced(tick) and not active(u, Kind.STUNNED, tick) \
		and not active(u, Kind.VULNERABLE, tick)
