## Lasting ground areas (ZoneState): each ticks its ability's effect and is
## removed when it runs out. Stateless: all state is in the world.
class_name ZoneSystem
extends RefCounted


static func run(world: SimWorld) -> void:
	for id in world.sorted_zone_ids():
		var z: ZoneState = world.zones[id]
		if world.tick >= z.until:
			world.zones.erase(id)
			continue
		AbilityRegistry.zone_tick(world, z)
