## Moves heroes from their held move input. Stateless: all state is in the world.
class_name MovementSystem
extends RefCounted


static func run(world: SimWorld, dt: float) -> void:
	var rules := world.rules
	var half := rules.arena_half_size
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		var target := Vector3(h.move_input.x, 0.0, h.move_input.y) * h.move_speed
		h.velocity = h.velocity.move_toward(target, rules.hero_acceleration * dt)
		h.position += h.velocity * dt
		# Enclosed arena for the prototype: clamp and kill velocity into the wall.
		if absf(h.position.x) > half:
			h.position.x = clampf(h.position.x, -half, half)
			h.velocity.x = 0.0
		if absf(h.position.z) > half:
			h.position.z = clampf(h.position.z, -half, half)
			h.velocity.z = 0.0
		if h.move_input.length_squared() > 0.0001:
			h.facing = atan2(-h.move_input.x, -h.move_input.y)
