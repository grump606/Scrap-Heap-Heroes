## Wombat, pet: kick up a dust cloud. Cleanses Wombat's slows and stuns, and
## slows enemies inside the cloud (radius, magnitude = slow, duration).
class_name DustBath
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, _ctx: CastContext) -> void:
	Status.cleanse(caster)
	var until := world.tick + world.rules.seconds_to_ticks(def.duration)
	for u in AbilityUtil.enemies_in_radius(world, caster, caster.position, def.radius):
		Status.add_cc(u, Status.Kind.SLOW, world.tick, until, def.magnitude)
	AbilityUtil.area_event(world, caster, "ring", caster.position, def.radius)
