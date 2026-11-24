## Damage with flat reduction and a floor. Stateless.
##
## reduction = passive flat value (doubled in mech form) + ARMOR buffs,
##             0 while VULNERABLE; ultimates ignore part of it.
## dealt     = max(amount - reduction, ceil(amount * damage_floor_fraction))
##
## Structures: only heroes damage them (mech form multiplies it by
## mech_structure_multiplier), and a core takes nothing while its tower stands.
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


## The amount a hit from source does to a structure before reduction: 0 if
## the source can't hurt it, more if a mech hero is hitting.
static func structure_amount(world: SimWorld, source_id: int, s: StructureState, amount: int) -> int:
	var src := world.unit(source_id)
	if not (src is HeroState):
		return 0
	if s.kind == StructureState.Kind.CORE and world.structure(s.team, StructureState.Kind.TOWER) != null:
		return 0
	if src.form == HeroState.Form.MECH:
		return int(amount * world.rules.mech_structure_multiplier)
	return amount


## Deals the hit and returns the damage done. Death is handled by MatchFlowSystem.
static func deal(world: SimWorld, source_id: int, target: UnitState, amount: int, ultimate: bool = false) -> int:
	if target.dead or target.hp <= 0 or amount <= 0:
		return 0  # Already down this tick; MatchFlowSystem finishes it off.
	if target is StructureState:
		amount = structure_amount(world, source_id, target, amount)
		if amount <= 0:
			return 0
	var dealt := preview(world, target, amount, ultimate)
	target.hp = maxi(target.hp - dealt, 0)
	if target is DummyState:
		target.reset_at = world.tick + world.rules.seconds_to_ticks(world.rules.dummy_reset_time)
	world.emit(SimEvent.new(SimEvent.Type.HIT, world.tick, target.entity_id, {
		"amount": dealt, "source": source_id, "x": target.position.x, "z": target.position.z,
	}))
	return dealt
