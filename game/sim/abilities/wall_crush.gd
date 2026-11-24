## Wombat, mech: charge along the aim (dash_speed, dash_duration). The first
## enemy touched takes damage and is shoved the same way (knockback_speed,
## knockback_duration). If the shove slams it into a wall, it takes
## bonus_damage and is stunned (stun_duration).
class_name WallCrush
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, aim: Vector2) -> void:
	KnockbackSystem.dash(world, caster, aim, def.dash_speed, world.rules.seconds_to_ticks(def.dash_duration))
	caster.dash_ability = def


static func on_contact(world: SimWorld, caster: HeroState, def: AbilityDef, target: UnitState) -> void:
	var dir := AbilityUtil.flat(caster.forced_velocity)
	if dir.length_squared() < 0.0001:
		dir = AbilityUtil.away(caster.position, target.position, Vector2(0, -1))
	DamageSystem.deal(world, caster.entity_id, target, def.damage)
	KnockbackSystem.push(world, target, dir, def.knockback_speed,
		world.rules.seconds_to_ticks(def.knockback_duration),
		def.bonus_damage, world.rules.seconds_to_ticks(def.stun_duration), caster.entity_id)
