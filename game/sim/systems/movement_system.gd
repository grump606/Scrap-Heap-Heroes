## Moves every unit. Stateless: all state is in the world.
##
## - Forced movement (dash, knockback) overrides input while it lasts.
## - Heroes otherwise steer toward their held move input, slowed by SLOW and
##   stopped by ROOTED or STUNNED. Dummies just coast to a stop.
## - The arena is enclosed: positions clamp to it. A knockback that hits the
##   wall ends there and pays its slam (Wall Crush), if any.
class_name MovementSystem
extends RefCounted


static func run(world: SimWorld, dt: float) -> void:
	var rules := world.rules
	var half := rules.arena_half_size
	var t := world.tick
	for u in world.units():
		if u.dead:
			continue
		var forced := u.is_forced(t)
		var held := Status.active(u, Status.Kind.ROOTED, t) or Status.active(u, Status.Kind.STUNNED, t)
		if forced:
			u.velocity = u.forced_velocity
		else:
			u.slam_damage = 0
			var target := Vector3.ZERO
			if u is HeroState and not held:
				var slow := Status.strongest(u, Status.Kind.SLOW, t)
				target = Vector3(u.move_input.x, 0.0, u.move_input.y) * u.move_speed * (1.0 - slow)
			u.velocity = u.velocity.move_toward(target, rules.hero_acceleration * dt)
			if held:
				u.velocity = Vector3.ZERO
		u.position += u.velocity * dt

		var hit_wall := false
		if absf(u.position.x) > half:
			u.position.x = clampf(u.position.x, -half, half)
			u.velocity.x = 0.0
			hit_wall = true
		if absf(u.position.z) > half:
			u.position.z = clampf(u.position.z, -half, half)
			u.velocity.z = 0.0
			hit_wall = true
		if hit_wall and forced:
			_hit_wall(world, u)

		if u is HeroState and not forced and not held and u.move_input.length_squared() > 0.0001:
			u.facing = atan2(-u.move_input.x, -u.move_input.y)


static func _hit_wall(world: SimWorld, u: UnitState) -> void:
	u.forced_until = world.tick
	u.velocity = Vector3.ZERO
	if u is HeroState:
		u.dash_ability = null
	if u.slam_damage <= 0:
		return
	var dealt := DamageSystem.deal(world, u.slam_source, u, u.slam_damage)
	if u.slam_stun_ticks > 0:
		Status.add(u, Status.Kind.STUNNED, world.tick + u.slam_stun_ticks)
	world.emit(SimEvent.new(SimEvent.Type.WALL_SLAM, world.tick, u.entity_id, {
		"amount": dealt, "x": u.position.x, "z": u.position.z,
	}))
	u.slam_damage = 0
