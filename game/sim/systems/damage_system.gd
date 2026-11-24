## Damage with flat reduction and a floor. Stateless.
##
## reduction = passive flat value (doubled in mech form) + ARMOR buffs,
##             0 while VULNERABLE; ultimates ignore part of it.
## dealt     = max(amount - reduction, ceil(amount * damage_floor_fraction))
class_name DamageSystem
extends RefCounted


static func reduction(world: SimWorld, u: UnitState) -> int:
	if Status.active(u, Status.Kind.VULNERABLE, world.tick):
		return 0
	var r := float(u.base_reduction())
	if u is HeroState and u.form == HeroState.Form.MECH:
		r *= world.rules.mech_reduction_multiplier
	r += Status.total(u, Status.Kind.ARMOR, world.tick)
	return int(r)


## What a hit of this size would deal to u right now, without dealing it.
static func preview(world: SimWorld, u: UnitState, amount: int, ultimate: bool = false) -> int:
	var red := reduction(world, u)
	if ultimate:
		red = int(red * (1.0 - world.rules.ultimate_reduction_ignore))
	var floor_amount := ceili(amount * world.rules.damage_floor_fraction)
	return maxi(amount - red, floor_amount)


## Deals the hit and returns the damage done. Death is handled by MatchFlowSystem.
static func deal(world: SimWorld, source_id: int, target: UnitState, amount: int, ultimate: bool = false) -> int:
	if target.dead or amount <= 0:
		return 0
	var dealt := preview(world, target, amount, ultimate)
	target.hp = maxi(target.hp - dealt, 0)
	if target is DummyState:
		target.reset_at = world.tick + world.rules.seconds_to_ticks(world.rules.dummy_reset_time)
	world.emit(SimEvent.new(SimEvent.Type.HIT, world.tick, target.entity_id, {
		"amount": dealt, "source": source_id, "x": target.position.x, "z": target.position.z,
	}))
	return dealt
