## Capybara, pet: a pulse that cuts the crowd control left on allied heroes
## within radius, Capybara included, by magnitude (0.5 = half).
class_name CalmPulse
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, _ctx: CastContext) -> void:
	for h in AbilityUtil.allies_in_radius(world, caster, caster.position, def.radius):
		Status.shorten_cc(h, world.tick, def.magnitude)
	AbilityUtil.area_event(world, caster, "ring", caster.position, def.radius)
