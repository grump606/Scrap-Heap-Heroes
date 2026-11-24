## Wombat, mech: plant the mech (duration). Braced, Wombat can't move, shrugs
## off knockback (rooted units ignore it) and gains extra hide (magnitude = armor).
class_name Brace
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, _ctx: CastContext) -> void:
	var until := world.tick + world.rules.seconds_to_ticks(def.duration)
	Status.add(caster, Status.Kind.ROOTED, until)
	Status.add(caster, Status.Kind.ARMOR, until, def.magnitude)
