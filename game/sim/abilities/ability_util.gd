## Targeting helpers shared by ability scripts. All distances are on the XZ
## plane and count the target's body radius.
class_name AbilityUtil
extends RefCounted


static func is_enemy(caster: UnitState, u: UnitState) -> bool:
	return u != caster and not u.dead and (u.team != caster.team or u.team == UnitState.TEAM_NEUTRAL)


static func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## Enemies whose body overlaps a circle, by entity id.
static func enemies_in_radius(world: SimWorld, caster: UnitState, center: Vector3, radius: float) -> Array[UnitState]:
	var out: Array[UnitState] = []
	for u in world.units():
		if is_enemy(caster, u) and flat(u.position).distance_to(flat(center)) <= radius + u.radius:
			out.append(u)
	return out


## Enemies inside a cone from origin along aim: within reach, and within
## angle_deg / 2 of aim (measured to the body center).
static func enemies_in_cone(world: SimWorld, caster: UnitState, origin: Vector3, aim: Vector2,
		reach: float, angle_deg: float) -> Array[UnitState]:
	var out: Array[UnitState] = []
	var half := deg_to_rad(angle_deg) * 0.5
	for u in world.units():
		if not is_enemy(caster, u):
			continue
		var d := flat(u.position) - flat(origin)
		if d.length() > reach + u.radius:
			continue
		if d.length() > 0.01 and absf(aim.angle_to(d)) > half:
			continue
		out.append(u)
	return out


## The nearest enemy whose body touches the caster's (plus margin), or null.
static func first_enemy_touching(world: SimWorld, caster: UnitState, margin: float) -> UnitState:
	var best: UnitState = null
	var best_d := INF
	for u in world.units():
		if not is_enemy(caster, u):
			continue
		var d := flat(u.position).distance_to(flat(caster.position))
		if d <= caster.radius + u.radius + margin and d < best_d:
			best = u
			best_d = d
	return best


## Direction from a to b on the plane, or fallback if they overlap.
static func away(from: Vector3, to: Vector3, fallback: Vector2) -> Vector2:
	var d := flat(to) - flat(from)
	return d.normalized() if d.length_squared() > 0.0001 else fallback


static func area_event(world: SimWorld, caster: UnitState, shape: String, center: Vector3,
		radius: float, aim: Vector2 = Vector2.ZERO, angle_deg: float = 0.0) -> void:
	world.emit(SimEvent.new(SimEvent.Type.AREA, world.tick, caster.entity_id, {
		"shape": shape, "x": center.x, "z": center.z, "radius": radius,
		"ax": aim.x, "az": aim.y, "angle": angle_deg,
	}))
