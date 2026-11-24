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


## Living heroes on the caster's team, by entity id. include_self adds the caster.
static func allies(world: SimWorld, caster: HeroState, include_self: bool = false) -> Array[HeroState]:
	var out: Array[HeroState] = []
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		if not h.dead and h.team == caster.team and (include_self or h != caster):
			out.append(h)
	return out


## Allied heroes whose body overlaps a circle.
static func allies_in_radius(world: SimWorld, caster: HeroState, center: Vector3, radius: float,
		include_self: bool = true) -> Array[HeroState]:
	var out: Array[HeroState] = []
	for h in allies(world, caster, include_self):
		if flat(h.position).distance_to(flat(center)) <= radius + h.radius:
			out.append(h)
	return out


## The unit in `candidates` closest to the aim line inside a cone (reach,
## angle_deg) from the caster: the one the player is pointing at. Null if none.
static func best_in_cone(caster: UnitState, candidates: Array, aim: Vector2, reach: float, angle_deg: float) -> UnitState:
	var half := deg_to_rad(angle_deg) * 0.5
	var best: UnitState = null
	var best_a := INF
	for u in candidates:
		var d := flat(u.position) - flat(caster.position)
		if d.length() > reach + u.radius:
			continue
		var a := absf(aim.angle_to(d)) if d.length() > 0.01 else 0.0
		if a <= half and a < best_a:
			best = u
			best_a = a
	return best


## Living enemy heroes.
static func enemy_heroes(world: SimWorld, caster: HeroState) -> Array[HeroState]:
	var out: Array[HeroState] = []
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		if is_enemy(caster, h):
			out.append(h)
	return out


## True if a living structure stands between a and b.
static func line_blocked(world: SimWorld, a: Vector3, b: Vector3) -> bool:
	var p := flat(a)
	var q := flat(b)
	for id in world.sorted_structure_ids():
		var s: StructureState = world.structures[id]
		if s.dead:
			continue
		var c := flat(s.position)
		var closest := Geometry2D.get_closest_point_to_segment(c, p, q)
		if closest.distance_to(c) < s.radius and c.distance_to(q) > s.radius and c.distance_to(p) > s.radius:
			return true
	return false
