## Capybara, mech: a channeled stream at one allied hero (the one nearest the
## aim within reach and angle_deg). For up to duration it heals them heal
## health per second while the line holds. It breaks if they go out of reach,
## a structure blocks the line, Capybara is stunned, pushed or switches form,
## or either of them dies. Capybara moves magnitude slower while channeling.
## With no ally to aim at, the press does nothing and costs nothing.
class_name SteamJet
extends RefCounted

const PULSE_TICKS := 15
## The stream holds a little past the reach it locks on at.
const BREAK_MARGIN := 1.5


static func pick_target(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> int:
	var t := AbilityUtil.best_in_cone(caster, AbilityUtil.allies(world, caster), ctx.aim, def.reach, def.angle_deg)
	if t == null or AbilityUtil.line_blocked(world, caster.position, t.position):
		return AbilityRegistry.NO_VALID_TARGET
	return t.entity_id


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	caster.channel_ability = def
	caster.channel_target = ctx.target_id
	caster.channel_until = world.tick + world.rules.seconds_to_ticks(def.duration)
	_pulse(world, caster, def, world.unit(ctx.target_id))


static func channel_tick(world: SimWorld, caster: HeroState, def: AbilityDef, target: UnitState) -> bool:
	if target.dead:
		return false
	var d := AbilityUtil.flat(caster.position).distance_to(AbilityUtil.flat(target.position))
	if d > def.reach + BREAK_MARGIN + target.radius or AbilityUtil.line_blocked(world, caster.position, target.position):
		return false
	if (caster.channel_until - world.tick) % PULSE_TICKS == 0:
		_pulse(world, caster, def, target)
	return true


static func _pulse(world: SimWorld, caster: HeroState, def: AbilityDef, target: UnitState) -> void:
	HealSystem.heal(world, caster.entity_id, target, roundi(def.heal * PULSE_TICKS * world.tick_dt))
	Status.refresh(caster, Status.Kind.SLOW, "steam_jet", world.tick + PULSE_TICKS + 1, def.magnitude)
