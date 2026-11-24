## Wombat, pet: kick up a dust cloud. Cleanses Wombat's slows and stuns, and
## slows enemies inside the cloud (radius, magnitude = slow, duration).
class_name DustBath
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, _aim: Vector2) -> void:
	Status.cleanse(caster)
	var until := world.tick + world.rules.seconds_to_ticks(def.duration)
	for u in AbilityUtil.enemies_in_radius(world, caster, caster.position, def.radius):
		Status.add(u, Status.Kind.SLOW, until, def.magnitude)
	AbilityUtil.area_event(world, caster, "ring", caster.position, def.radius)
