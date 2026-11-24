## Capybara, pet: toss a yuzu along the aim. The first allied hero within
## radius of its path (up to reach) is healed for heal. Hit or miss, the toss
## pauses Capybara's mech-meter refill for duration, so healing from pet
## form costs mech time.
class_name YuzuToss
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	var from := AbilityUtil.flat(caster.position)
	var best: HeroState = null
	var best_along := INF
	for h in AbilityUtil.allies(world, caster):
		var rel := AbilityUtil.flat(h.position) - from
		var along := rel.dot(ctx.aim)
		if along < 0.0 or along > def.reach + h.radius:
			continue
		var off := absf(rel.cross(ctx.aim))
		if off <= def.radius + h.radius and along < best_along:
			best = h
			best_along = along
	var length := def.reach
	if best != null and not AbilityUtil.line_blocked(world, caster.position, best.position):
		HealSystem.heal(world, caster.entity_id, best, def.heal)
		length = best_along
	Status.add(caster, Status.Kind.NO_REFILL, world.tick + world.rules.seconds_to_ticks(def.duration))
	AbilityUtil.area_event(world, caster, "line", caster.position, length, ctx.aim)
