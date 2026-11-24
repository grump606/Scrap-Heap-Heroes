## Capybara, mech: wrap the allied hero nearest the aim (within reach and
## angle_deg) in a bubble that absorbs shield damage for shield_duration.
## With no ally there, Capybara bubbles itself.
class_name BubbleShield
extends RefCounted


static func pick_target(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> int:
	var t := AbilityUtil.best_in_cone(caster, AbilityUtil.allies(world, caster), ctx.aim, def.reach, def.angle_deg)
	return t.entity_id if t != null else caster.entity_id


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	var target := world.unit(ctx.target_id)
	if target != null:
		HealSystem.shield(world, caster.entity_id, target, def.shield, world.rules.seconds_to_ticks(def.shield_duration))
