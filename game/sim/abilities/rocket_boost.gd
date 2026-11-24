## Weasel, mech: a rocket dash along the aim (dash_speed, dash_duration) that
## stops on the first enemy it touches and hits it for damage. It gives no
## invulnerability.
class_name RocketBoost
extends RefCounted


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	KnockbackSystem.dash(world, caster, ctx.aim, def.dash_speed, world.rules.seconds_to_ticks(def.dash_duration))
	caster.dash_ability = def


static func on_contact(world: SimWorld, caster: HeroState, def: AbilityDef, target: UnitState) -> void:
	DamageSystem.deal(world, caster.entity_id, target, def.damage)
