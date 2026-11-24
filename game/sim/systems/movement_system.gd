## Moves every unit. Stateless: all state is in the world.
##
## - Forced movement (dash, knockback) overrides steering while it lasts.
## - Units with a move_speed steer toward their move_input, sped up by HASTE,
##   slowed by SLOW and stopped by ROOTED or STUNNED. Others (dummies) coast
##   to a stop.
## - Structures never move, and are solid: walkers are pushed out of them.
## - The lane is enclosed: positions clamp to it. A knockback that hits a wall
##   or a structure ends there and pays its slam (Wall Crush), if any.
class_name MovementSystem
extends RefCounted


static func run(world: SimWorld, dt: float) -> void:
	var rules := world.rules
	var hx := rules.arena_half_width
	var hz := rules.arena_half_length
	var t := world.tick
	var solid: Array[StructureState] = []
	for id in world.sorted_structure_ids():
		if not world.structures[id].dead:
			solid.append(world.structures[id])

	for u in world.units():
		if u.dead or u.immovable:
			continue
		var forced := u.is_forced(t)
		var held := Status.active(u, Status.Kind.ROOTED, t) or Status.active(u, Status.Kind.STUNNED, t)
		if forced:
			u.velocity = u.forced_velocity
		else:
			u.slam_damage = 0
			var target := Vector3.ZERO
			if u.move_speed > 0.0 and not held:
				var slow := Status.strongest(u, Status.Kind.SLOW, t)
				var haste := Status.strongest(u, Status.Kind.HASTE, t)
				target = Vector3(u.move_input.x, 0.0, u.move_input.y) * u.move_speed * (1.0 + haste) * (1.0 - slow)
			# Haste speeds up getting going too, so a short burst is felt at once.
			var accel := rules.hero_acceleration * (1.0 + Status.strongest(u, Status.Kind.HASTE, t))
			u.velocity = u.velocity.move_toward(target, accel * dt)
			if held:
				u.velocity = Vector3.ZERO
		u.position += u.velocity * dt

		var hit_wall := false
		if absf(u.position.x) > hx:
			u.position.x = clampf(u.position.x, -hx, hx)
			u.velocity.x = 0.0
			hit_wall = true
		if absf(u.position.z) > hz:
			u.position.z = clampf(u.position.z, -hz, hz)
			u.velocity.z = 0.0
			hit_wall = true
		for s in solid:
			var d := AbilityUtil.flat(u.position) - AbilityUtil.flat(s.position)
			var min_d := s.radius + u.radius
			if d.length() < min_d:
				# Head-on, a straight push-back would pin the walker in place;
				# lean it to one side (by id, so it's deterministic) to slide around.
				if absf(d.x) < 0.25 * min_d:
					d.x = 0.25 * min_d * (1.0 if u.entity_id % 2 == 0 else -1.0)
				var out := d.normalized() if d.length_squared() > 0.0001 else Vector2(0, MatchRules.team_side(s.team))
				u.position = Vector3(s.position.x + out.x * min_d, u.position.y, s.position.z + out.y * min_d)
				hit_wall = true
		if hit_wall and forced:
			_hit_wall(world, u)

		if u.move_speed > 0.0 and not forced and not held and u.move_input.length_squared() > 0.0001:
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
		Status.add_cc(u, Status.Kind.STUNNED, world.tick, world.tick + u.slam_stun_ticks)
	world.emit(SimEvent.new(SimEvent.Type.WALL_SLAM, world.tick, u.entity_id, {
		"amount": dealt, "x": u.position.x, "z": u.position.z,
	}))
	u.slam_damage = 0
