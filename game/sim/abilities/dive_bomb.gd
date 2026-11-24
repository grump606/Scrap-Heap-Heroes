## Weasel, mech: aim a circle on the ground (up to reach away). Weasel rises
## during the windup (rooted and exposed), then flies there in dash_duration
## and slams down: every enemy within radius takes damage, plus bonus_damage
## scaled by how far the dive went (full bonus at full reach).
##
## During Frenzy Run, Dive Bomb can only target an enemy hero (the one
## nearest the aim, within reach), flies at where that hero is when the rise
## ends, and deals empowered_multiplier times the damage.
class_name DiveBomb
extends RefCounted

## Peak of the arc, for the view.
const RISE_HEIGHT := 4.0
## Frenzy targeting: how far off the aim an enemy may be.
const FRENZY_AIM_ANGLE := 60.0


static func pick_target(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> int:
	if not Status.active(caster, Status.Kind.FRENZY, world.tick):
		return 0
	var t := AbilityUtil.best_in_cone(caster, AbilityUtil.enemy_heroes(world, caster), ctx.aim, def.reach, FRENZY_AIM_ANGLE)
	return t.entity_id if t != null else AbilityRegistry.NO_VALID_TARGET


static func on_windup(world: SimWorld, caster: HeroState, def: AbilityDef, _ctx: CastContext, ticks: int) -> void:
	caster.air_start = world.tick
	caster.air_end = world.tick + ticks + world.rules.seconds_to_ticks(def.dash_duration)
	caster.air_height = RISE_HEIGHT


## End of the rise: fly to the spot (or the frenzy target).
static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	var to := AbilityRegistry.ground_point(world, caster, def, ctx)
	var d := AbilityUtil.flat(to) - AbilityUtil.flat(caster.position)
	var flight := maxi(world.rules.seconds_to_ticks(def.dash_duration), 1)
	if d.length() > 0.01:
		KnockbackSystem.dash(world, caster, d, d.length() / (flight * world.tick_dt), flight)
	caster.air_end = world.tick + flight
	var empowered := ctx.target_id > 0
	AbilitySystem.schedule(world, caster, AbilitySystem.slot_of(caster, def), flight, ctx, 1,
		{"dist": d.length(), "empowered": empowered})


## Touchdown, wherever Weasel actually is (a push mid-flight moves the landing).
static func follow_up(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	caster.forced_until = world.tick
	caster.velocity = Vector3.ZERO
	var dist: float = ctx.data.get("dist", 0.0)
	var amount := float(def.damage) + def.bonus_damage * clampf(dist / maxf(def.reach, 0.01), 0.0, 1.0)
	if ctx.data.get("empowered", false):
		amount *= def.empowered_multiplier
	for u in AbilityUtil.enemies_in_radius(world, caster, caster.position, def.radius):
		DamageSystem.deal(world, caster.entity_id, u, roundi(amount))
	AbilityUtil.area_event(world, caster, "ring", caster.position, def.radius)
