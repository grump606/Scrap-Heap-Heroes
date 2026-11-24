## Towers shoot enemies in range: the nearest minion first, a hero only when
## no minion is in range. A tower keeps its target while it stays valid.
## Cores don't shoot. Stateless: all state is in the world.
class_name TowerSystem
extends RefCounted


static func run(world: SimWorld) -> void:
	if not world.lane_objectives:
		return
	var rules := world.rules
	for id in world.sorted_structure_ids():
		var s: StructureState = world.structures[id]
		if s.dead or s.kind != StructureState.Kind.TOWER:
			continue
		var t := world.unit(s.target_id) if s.target_id != 0 else null
		if not _in_range(world, s, t):
			t = _pick(world, s)
			s.target_id = t.entity_id if t != null else 0
		if t == null or world.tick < s.attack_ready:
			continue
		DamageSystem.deal(world, s.entity_id, t, rules.tower_damage)
		s.attack_ready = world.tick + rules.seconds_to_ticks(rules.tower_attack_interval)
		world.emit(SimEvent.new(SimEvent.Type.SHOT, world.tick, s.entity_id, {
			"x": s.position.x, "z": s.position.z, "tx": t.position.x, "tz": t.position.z,
		}))


## Enemy heroes and minions only: towers ignore dummies and structures.
static func _in_range(world: SimWorld, s: StructureState, u: UnitState) -> bool:
	if u == null or u.dead or u.team == s.team or u.team == UnitState.TEAM_NEUTRAL:
		return false
	if not (u is HeroState or u is MinionState):
		return false
	return AbilityUtil.flat(u.position).distance_to(AbilityUtil.flat(s.position)) <= world.rules.tower_range + u.radius


static func _pick(world: SimWorld, s: StructureState) -> UnitState:
	var best_minion: UnitState = null
	var best_hero: UnitState = null
	var dm := INF
	var dh := INF
	for u in world.units():
		if not _in_range(world, s, u):
			continue
		var d := AbilityUtil.flat(u.position).distance_to(AbilityUtil.flat(s.position))
		if u is MinionState and d < dm:
			best_minion = u
			dm = d
		elif u is HeroState and d < dh:
			best_hero = u
			dh = d
	return best_minion if best_minion != null else best_hero
