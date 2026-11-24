## Capybara, ultimate: a large zone (radius) around Capybara for duration.
## Allied heroes inside regain heal health per second and can't be crowd
## controlled (no slows, stuns or knockback). Enemies inside aren't weakened
## but receive magnitude less healing.
class_name GrandOnsen
extends RefCounted

const PULSE_TICKS := 30


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, _ctx: CastContext) -> void:
	world.add_zone(caster, def, caster.position, def.radius, world.rules.seconds_to_ticks(def.duration))


static func zone_tick(world: SimWorld, zone: ZoneState) -> void:
	var def := zone.def
	var owner: HeroState = world.heroes.get(zone.owner_id)
	if owner == null:
		return
	# Refreshed every tick, so it lapses right after a hero leaves.
	var until := world.tick + 2
	var pulse := (world.tick - zone.start_tick) % PULSE_TICKS == 0
	for h in AbilityUtil.allies_in_radius(world, owner, zone.position, zone.radius):
		Status.refresh(h, Status.Kind.CC_IMMUNE, "grand_onsen", until)
		if pulse:
			HealSystem.heal(world, owner.entity_id, h, roundi(def.heal * PULSE_TICKS * world.tick_dt))
	for id in world.sorted_hero_ids():
		var e: HeroState = world.heroes[id]
		if AbilityUtil.is_enemy(owner, e) \
				and AbilityUtil.flat(e.position).distance_to(AbilityUtil.flat(zone.position)) <= zone.radius + e.radius:
			Status.refresh(e, Status.Kind.HEAL_CUT, "grand_onsen", until, def.magnitude)
