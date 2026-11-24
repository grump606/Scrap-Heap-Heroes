## A hero's basic attack (both forms; see HeroDef.pet_attack / mech_attack):
## hits the nearest enemy inside a short cone (reach, angle_deg) for damage.
class_name BasicAttack
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	var aim := ctx.aim
	var best: UnitState = null
	var best_d := INF
	for u in AbilityUtil.enemies_in_cone(world, caster, caster.position, aim, def.reach, def.angle_deg):
		var d := AbilityUtil.flat(u.position).distance_to(AbilityUtil.flat(caster.position)) - u.radius
		if d < best_d:
			best = u
			best_d = d
	if best != null:
		DamageSystem.deal(world, caster.entity_id, best, def.damage)
	AbilityUtil.area_event(world, caster, "swipe", caster.position, def.reach, aim, def.angle_deg)
