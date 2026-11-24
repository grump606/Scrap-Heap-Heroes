## Capybara, mech: place a steaming pool (radius) up to reach away along the
## aim, for duration. Allied heroes in it regain heal health per second, and
## the first time each steps in they get a shield (shield, shield_duration).
## One pool per Capybara: a new one replaces the old.
class_name HotSpring
extends RefCounted

const PULSE_TICKS := 30


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	for id in world.sorted_zone_ids():
		var z: ZoneState = world.zones[id]
		if z.owner_id == caster.entity_id and z.def == def:
			world.zones.erase(id)
	var at := AbilityRegistry.ground_point(world, caster, def, ctx)
	world.add_zone(caster, def, at, def.radius, world.rules.seconds_to_ticks(def.duration))


static func zone_tick(world: SimWorld, zone: ZoneState) -> void:
	var def := zone.def
	var owner: HeroState = world.heroes.get(zone.owner_id)
	if owner == null:
		return
	var pulse := (world.tick - zone.start_tick) % PULSE_TICKS == 0
	for h in AbilityUtil.allies_in_radius(world, owner, zone.position, zone.radius):
		if not zone.granted.has(h.entity_id):
			zone.granted.append(h.entity_id)
			HealSystem.shield(world, owner.entity_id, h, def.shield, world.rules.seconds_to_ticks(def.shield_duration))
		if pulse:
			HealSystem.heal(world, owner.entity_id, h, roundi(def.heal * PULSE_TICKS * world.tick_dt))
