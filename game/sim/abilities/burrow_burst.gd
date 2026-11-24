## Wombat, ultimate: after a windup, erupt in a ring (radius) that damages
## every enemy and knocks them outward (knockback_speed, knockback_duration).
## As an ultimate it ignores part of their flat damage reduction.
class_name BurrowBurst
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	var aim := ctx.aim
	var ticks := world.rules.seconds_to_ticks(def.knockback_duration)
	for u in AbilityUtil.enemies_in_radius(world, caster, caster.position, def.radius):
		DamageSystem.deal(world, caster.entity_id, u, def.damage, def.is_ultimate)
		KnockbackSystem.push(world, u, AbilityUtil.away(caster.position, u.position, aim), def.knockback_speed, ticks)
	AbilityUtil.area_event(world, caster, "ring", caster.position, def.radius)
