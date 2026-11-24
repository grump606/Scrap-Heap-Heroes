## Wombat, pet: belly-slide along the aim (dash_speed, dash_duration) and
## gain extra hide afterwards (magnitude = armor, duration).
## The faster scrap pickup arrives with scrap.
class_name MudSlide
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	var aim := ctx.aim
	KnockbackSystem.dash(world, caster, aim, def.dash_speed, world.rules.seconds_to_ticks(def.dash_duration))
	Status.add(caster, Status.Kind.ARMOR, world.tick + world.rules.seconds_to_ticks(def.duration), def.magnitude)
