## Healing and shields. Stateless.
##
## healed = amount * (1 - strongest HEAL_CUT), capped at max health. Only
## living heroes are healed or shielded. Base healing (MatchFlowSystem) is
## separate: it is the base, not an ability, and isn't cut.
class_name HealSystem
extends RefCounted


## Heals target and returns the health restored.
static func heal(world: SimWorld, source_id: int, target: UnitState, amount: int) -> int:
	if not (target is HeroState) or target.dead or target.hp <= 0 or amount <= 0:
		return 0
	var cut := Status.strongest(target, Status.Kind.HEAL_CUT, world.tick)
	var healed := mini(int(round(amount * (1.0 - cut))), target.max_hp - target.hp)
	if healed <= 0:
		return 0
	target.hp += healed
	world.emit(SimEvent.new(SimEvent.Type.HEAL, world.tick, target.entity_id, {
		"amount": healed, "source": source_id, "x": target.position.x, "z": target.position.z,
	}))
	return healed


## Gives target a shield that absorbs amount damage for ticks.
static func shield(world: SimWorld, source_id: int, target: UnitState, amount: int, ticks: int) -> void:
	if not (target is HeroState) or target.dead or amount <= 0 or ticks <= 0:
		return
	Status.add(target, Status.Kind.SHIELD, world.tick + ticks, amount)
	world.emit(SimEvent.new(SimEvent.Type.SHIELD, world.tick, target.entity_id, {
		"amount": amount, "source": source_id,
	}))


## Total shield a unit has left right now.
static func shield_left(world: SimWorld, u: UnitState) -> int:
	return int(Status.total(u, Status.Kind.SHIELD, world.tick))
