## Weasel, pet: a burst of speed (magnitude = extra speed fraction, duration).
class_name Sprint
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, _ctx: CastContext) -> void:
	Status.add(caster, Status.Kind.HASTE, world.tick + world.rules.seconds_to_ticks(def.duration), def.magnitude)
