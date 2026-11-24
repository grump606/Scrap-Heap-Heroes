## Minion waves and minion behavior. Stateless: all state is in the world.
##
## Waves: rules.wave_size minions per team, first at first_wave_time, then
## every wave_interval. Each minion:
## - fights the nearest enemy hero, minion or dummy within aggro range
##   (melee: stops in reach and hits every minion_attack_interval);
## - otherwise walks the lane toward the enemy base, drifting to the middle;
## - holds minion_hold_distance outside the first living enemy structure. It
##   can't damage structures; it is there to soak tower shots.
class_name MinionAiSystem
extends RefCounted


static func run(world: SimWorld) -> void:
	if not world.lane_objectives:
		return
	_spawn_waves(world)
	for id in world.sorted_minion_ids():
		var m: MinionState = world.minions[id]
		if not m.dead:
			_think(world, m)


static func _spawn_waves(world: SimWorld) -> void:
	var rules := world.rules
	var first := rules.seconds_to_ticks(rules.first_wave_time)
	var every := maxi(rules.seconds_to_ticks(rules.wave_interval), 1)
	if world.tick < first or (world.tick - first) % every != 0:
		return
	for team in [0, 1]:
		var side := MatchRules.team_side(team)
		for i in rules.wave_size:
			var x := (i - (rules.wave_size - 1) * 0.5) * 1.2
			world.add_minion(team, Vector3(x, 0, rules.minion_spawn_z * side))


static func _think(world: SimWorld, m: MinionState) -> void:
	var rules := world.rules
	var target := world.unit(m.target_id) if m.target_id != 0 else null
	if not _fightable(world, m, target):
		target = _nearest_enemy(world, m)
		m.target_id = target.entity_id if target != null else 0

	if target != null:
		var to := AbilityUtil.flat(target.position) - AbilityUtil.flat(m.position)
		var gap := to.length() - m.radius - target.radius
		if gap > rules.minion_reach:
			m.move_input = to.normalized()
			return
		m.move_input = Vector2.ZERO
		if to.length_squared() > 0.0001:
			m.facing = atan2(-to.x, -to.y)
		if world.tick >= m.attack_ready and Status.can_act(m, world.tick):
			DamageSystem.deal(world, m.entity_id, target, rules.minion_damage)
			m.attack_ready = world.tick + rules.seconds_to_ticks(rules.minion_attack_interval)
		return

	var enemy := 1 - m.team
	var ahead := world.structure(enemy, StructureState.Kind.TOWER)
	if ahead == null:
		ahead = world.structure(enemy, StructureState.Kind.CORE)
	if ahead != null and AbilityUtil.flat(ahead.position).distance_to(AbilityUtil.flat(m.position)) \
			- ahead.radius <= rules.minion_hold_distance:
		m.move_input = Vector2.ZERO
		return
	var lane := Vector2(-m.position.x * 0.15, -MatchRules.team_side(m.team))
	m.move_input = lane.normalized()


static func _fightable(world: SimWorld, m: MinionState, u: UnitState) -> bool:
	if u == null or u.dead or u is StructureState or not AbilityUtil.is_enemy(m, u):
		return false
	var d := AbilityUtil.flat(u.position).distance_to(AbilityUtil.flat(m.position))
	return d <= world.rules.minion_aggro_range + u.radius


static func _nearest_enemy(world: SimWorld, m: MinionState) -> UnitState:
	var best: UnitState = null
	var best_d := INF
	for u in world.units():
		if not _fightable(world, m, u):
			continue
		var d := AbilityUtil.flat(u.position).distance_to(AbilityUtil.flat(m.position))
		if d < best_d:
			best = u
			best_d = d
	return best
