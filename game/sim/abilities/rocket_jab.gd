## Weasel, mech: a flurry of short-range rocket punches in a cone in front
## (reach, angle_deg): `hits` punches of `damage`, hit_interval apart.
class_name RocketJab
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	_punch(world, caster, def, ctx)
	if def.hits > 1:
		AbilitySystem.schedule(world, caster, AbilitySystem.slot_of(caster, def),
			maxi(world.rules.seconds_to_ticks(def.hit_interval), 1), ctx, 1)


static func follow_up(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	_punch(world, caster, def, ctx)
	if ctx.stage + 1 < def.hits:
		AbilitySystem.schedule(world, caster, AbilitySystem.slot_of(caster, def),
			maxi(world.rules.seconds_to_ticks(def.hit_interval), 1), ctx, ctx.stage + 1)


## Each punch follows Weasel's facing, so the flurry tracks a turning target.
static func _punch(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	var aim := ctx.aim
	for u in AbilityUtil.enemies_in_cone(world, caster, caster.position, aim, def.reach, def.angle_deg):
		DamageSystem.deal(world, caster.entity_id, u, def.damage)
	AbilityUtil.area_event(world, caster, "swipe", caster.position, def.reach, aim, def.angle_deg)
