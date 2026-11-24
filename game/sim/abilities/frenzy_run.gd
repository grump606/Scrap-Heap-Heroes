## Weasel, ultimate: for duration, Rocket Boost and Dive Bomb have no
## cooldown, and Dive Bomb becomes an empowered, enemy-only dive (see
## DiveBomb). Each hit on an enemy hero not yet hit this frenzy adds
## extend_duration. Weasel receives magnitude less healing meanwhile.
class_name FrenzyRun
extends RefCounted

## The abilities whose cooldown Frenzy Run waives.
const FREE: Array[StringName] = [&"rocket_boost", &"dive_bomb"]


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, _ctx: CastContext) -> void:
	var until := world.tick + world.rules.seconds_to_ticks(def.duration)
	caster.frenzy_hits.clear()
	Status.add(caster, Status.Kind.FRENZY, until, world.rules.seconds_to_ticks(def.extend_duration))
	Status.add(caster, Status.Kind.HEAL_CUT, until, def.magnitude)
	# Anything already on cooldown is ready at once.
	var list := caster.def.abilities(caster.form)
	for i in list.size():
		if FREE.has(list[i].logic):
			caster.ready_for(caster.form)[i] = world.tick


static func waives_cooldown(world: SimWorld, h: HeroState, def: AbilityDef) -> bool:
	return FREE.has(def.logic) and Status.active(h, Status.Kind.FRENZY, world.tick)


## Called by DamageSystem for every hit one hero lands on another.
static func on_hero_hit(world: SimWorld, src: HeroState, target: HeroState) -> void:
	if src.team == target.team or not Status.active(src, Status.Kind.FRENZY, world.tick):
		return
	if src.frenzy_hits.has(target.entity_id):
		return
	src.frenzy_hits.append(target.entity_id)
	var extra := int(Status.strongest(src, Status.Kind.FRENZY, world.tick))
	# The heal cut lasts exactly as long as the frenzy.
	var end := Status.until_of(src, Status.Kind.FRENZY, world.tick)
	Status.extend(src, Status.Kind.FRENZY, world.tick, extra)
	for s in src.statuses:
		if s["kind"] == Status.Kind.HEAL_CUT and int(s["until"]) == end:
			s["until"] = end + extra
