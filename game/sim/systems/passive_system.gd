## Hero passives with their own logic (HeroDef.passive), run every tick.
## Stateless: all state is in the world.
class_name PassiveSystem
extends RefCounted


static func run(world: SimWorld) -> void:
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		if h.dead or h.def == null or h.def.passive == null:
			continue
		AbilityRegistry.passive_tick(world, h, h.def.passive)
