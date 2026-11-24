## Weasel, pet: leap along the aim (dash_speed, dash_duration). The leap is
## meant to cross gaps and low walls; the lane has none yet, so for now it is
## a quick dash that the view draws as a hop.
class_name Pounce
extends RefCounted

## Peak of the hop, for the view.
const HOP_HEIGHT := 1.2


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	var ticks := world.rules.seconds_to_ticks(def.dash_duration)
	KnockbackSystem.dash(world, caster, ctx.aim, def.dash_speed, ticks)
	caster.air_start = world.tick
	caster.air_end = world.tick + ticks
	caster.air_height = HOP_HEIGHT
