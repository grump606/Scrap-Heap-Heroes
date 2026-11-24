## Capybara, passive: allied heroes within radius (not Capybara itself)
## regain heal health per second, magnitude times as much while Capybara
## stands still. Pays out every PULSE_TICKS.
class_name ChillAura
extends RefCounted

const PULSE_TICKS := 30
## Below this speed (m/s) Capybara counts as standing still.
const STILL_SPEED := 0.2


static func passive_tick(world: SimWorld, hero: HeroState, def: AbilityDef) -> void:
	if world.tick % PULSE_TICKS != 0:
		return
	var rate := float(def.heal)
	if is_still(hero):
		rate *= def.magnitude
	var amount := roundi(rate * PULSE_TICKS * world.tick_dt)
	for h in AbilityUtil.allies_in_radius(world, hero, hero.position, def.radius, false):
		HealSystem.heal(world, hero.entity_id, h, amount)


static func is_still(hero: HeroState) -> bool:
	return AbilityUtil.flat(hero.velocity).length() < STILL_SPEED
