## Wombat, mech: a cone bump (reach, angle_deg) that damages enemies and
## knocks them away from Wombat (knockback_speed, knockback_duration).
class_name RumpBump
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	var aim := ctx.aim
	var ticks := world.rules.seconds_to_ticks(def.knockback_duration)
	for u in AbilityUtil.enemies_in_cone(world, caster, caster.position, aim, def.reach, def.angle_deg):
		DamageSystem.deal(world, caster.entity_id, u, def.damage)
		KnockbackSystem.push(world, u, AbilityUtil.away(caster.position, u.position, aim), def.knockback_speed, ticks)
	AbilityUtil.area_event(world, caster, "cone", caster.position, def.reach, aim, def.angle_deg)
