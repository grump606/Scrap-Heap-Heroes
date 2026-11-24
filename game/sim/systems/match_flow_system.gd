## Deaths, respawns and dummy resets. Phases, objectives and the win condition
## join this system with the match loop.
class_name MatchFlowSystem
extends RefCounted


static func run(world: SimWorld) -> void:
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		if not h.dead and h.hp <= 0:
			_die(world, h)
		elif h.dead and world.tick >= h.respawn_tick:
			_respawn(world, h)
	for id in world.sorted_dummy_ids():
		var d: DummyState = world.dummies[id]
		if d.reset_at > 0 and world.tick >= d.reset_at and not d.is_forced(world.tick):
			d.hp = d.max_hp
			d.position = d.home
			d.velocity = Vector3.ZERO
			d.statuses.clear()
			d.reset_at = 0


static func _die(world: SimWorld, h: HeroState) -> void:
	h.dead = true
	h.respawn_tick = world.tick + world.rules.seconds_to_ticks(world.rules.respawn_time)
	h.statuses.clear()
	h.forced_until = 0
	h.velocity = Vector3.ZERO
	h.dash_ability = null
	world.emit(SimEvent.new(SimEvent.Type.DEATH, world.tick, h.entity_id))


static func _respawn(world: SimWorld, h: HeroState) -> void:
	h.dead = false
	h.hp = h.max_hp
	h.position = h.spawn
	h.mech_energy = world.rules.mech_energy_start
	h.apply_form(HeroState.Form.PET)
	world.emit(SimEvent.new(SimEvent.Type.RESPAWN, world.tick, h.entity_id))
