## Deaths, respawns, base healing, dummy resets, structure destruction and
## the win condition: destroying the enemy Power Core wins the match.
class_name MatchFlowSystem
extends RefCounted


static func run(world: SimWorld) -> void:
	var rules := world.rules
	var heal_now := world.tick % 6 == 0  # Every 0.1 s at 60 Hz.
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		if not h.dead and h.hp <= 0:
			_die(world, h)
		elif h.dead and world.tick >= h.respawn_tick:
			_respawn(world, h)
		elif heal_now and not h.dead and h.hp < h.max_hp and _at_base(world, h):
			var amount := maxi(1, roundi(h.max_hp * rules.base_heal_per_second / 10.0))
			h.hp = mini(h.max_hp, h.hp + amount)

	for id in world.sorted_minion_ids():
		var m: MinionState = world.minions[id]
		if m.hp <= 0:
			world.emit(SimEvent.new(SimEvent.Type.DEATH, world.tick, m.entity_id))
			world.minions.erase(id)

	for id in world.sorted_structure_ids():
		var s: StructureState = world.structures[id]
		if s.dead or s.hp > 0:
			continue
		s.dead = true
		world.emit(SimEvent.new(SimEvent.Type.DEATH, world.tick, s.entity_id, {"kind": s.kind}))
		if s.kind == StructureState.Kind.CORE and world.winner == SimWorld.NO_WINNER:
			world.winner = 1 - s.team
			world.emit(SimEvent.new(SimEvent.Type.MATCH_END, world.tick, s.entity_id, {"winner": world.winner}))

	for id in world.sorted_dummy_ids():
		var d: DummyState = world.dummies[id]
		if d.reset_at > 0 and world.tick >= d.reset_at and not d.is_forced(world.tick):
			d.hp = d.max_hp
			d.position = d.home
			d.velocity = Vector3.ZERO
			d.statuses.clear()
			d.reset_at = 0


## Behind the hero's own living core (farther from the middle than it), within
## base_heal_radius of its back face.
static func _at_base(world: SimWorld, h: HeroState) -> bool:
	var core := world.structure(h.team, StructureState.Kind.CORE)
	if core == null:
		return false
	var behind := (h.position.z - core.position.z) * MatchRules.team_side(h.team)
	return behind >= 0.0 and behind <= core.radius + world.rules.base_heal_radius


static func _die(world: SimWorld, h: HeroState) -> void:
	h.dead = true
	h.respawn_tick = world.tick + world.rules.seconds_to_ticks(world.rules.respawn_time)
	h.statuses.clear()
	h.forced_until = 0
	h.velocity = Vector3.ZERO
	h.dash_ability = null
	h.stop_channel()
	h.frenzy_hits.clear()
	h.air_end = 0
	world.emit(SimEvent.new(SimEvent.Type.DEATH, world.tick, h.entity_id))


static func _respawn(world: SimWorld, h: HeroState) -> void:
	h.dead = false
	h.hp = h.max_hp
	h.position = h.spawn
	h.mech_energy = world.rules.mech_energy_start
	h.apply_form(HeroState.Form.PET)
	world.emit(SimEvent.new(SimEvent.Type.RESPAWN, world.tick, h.entity_id))
