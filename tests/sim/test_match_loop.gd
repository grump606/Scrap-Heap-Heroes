## Match loop: lane structures, minion waves, towers, basic attacks, base
## healing, the win condition, and full 3v3 bot matches.
extends TestCase

var rules: MatchRules = MatchSetup.default_rules()
var wombat: HeroDef = MatchSetup.hero_def(&"wombat")


## Lane world with towers and cores, and Wombat for player 1 (team 0) and
## player 2 (team 1) at the given spots.
func _world(p1_at: Vector3 = Vector3(0, 0, 10), p2_at: Vector3 = Vector3(5, 0, -10)) -> SimWorld:
	var w := SimWorld.new(1, rules)
	w.add_hero(1, 0, wombat, p1_at)
	w.add_hero(2, 1, wombat, p2_at)
	w.add_lane_objectives()
	return w


func _step(w: SimWorld, cmds: Array = []) -> Array[SimEvent]:
	var typed: Array[Command] = []
	typed.assign(cmds)
	return w.step(typed)


func _run(w: SimWorld, ticks: int) -> Array[SimEvent]:
	var all: Array[SimEvent] = []
	for i in ticks:
		all.append_array(w.step([]))
	return all


func _of_type(events: Array[SimEvent], type: int) -> Array[SimEvent]:
	return events.filter(func(e): return e.type == type)


func _secs(s: float) -> int:
	return rules.seconds_to_ticks(s)


func _attack(w: SimWorld, player: int, aim: Vector2) -> Array[SimEvent]:
	return _step(w, [Command.ability(player, w.tick, Command.ATTACK_SLOT, aim)])


# --- layout and waves ------------------------------------------------------

func test_each_team_has_a_tower_and_core_on_its_side() -> void:
	var w := _world()
	for team in [0, 1]:
		var side := MatchRules.team_side(team)
		var tower := w.structure(team, StructureState.Kind.TOWER)
		var core := w.structure(team, StructureState.Kind.CORE)
		check(tower != null and core != null, "team %d has both" % team)
		if tower != null and core != null:
			check(tower.position.z * side > 0 and core.position.z * side > tower.position.z * side,
				"team %d: tower in front of core, both on its side" % team)


func test_waves_spawn_on_schedule() -> void:
	var w := SimWorld.new(1, rules)
	w.add_lane_objectives()
	_run(w, _secs(rules.first_wave_time))
	check_eq(w.minions.size(), 0, "nothing before the first wave")
	_run(w, 1)
	check_eq(w.minions.size(), rules.wave_size * 2, "first wave, both teams")
	_run(w, _secs(rules.wave_interval))
	check(w.minions.size() > rules.wave_size * 2, "second wave arrived")


func test_minions_meet_and_fight() -> void:
	var w := SimWorld.new(1, rules)
	w.add_lane_objectives()
	var events := _run(w, _secs(rules.first_wave_time + 40.0))
	var minion_hits := _of_type(events, SimEvent.Type.HIT).filter(func(e): return e.data["source"] != 0 and w.structures.get(e.data["source"]) == null)
	check(not minion_hits.is_empty(), "minions hit each other")
	check(not _of_type(events, SimEvent.Type.DEATH).is_empty(), "some minions died")


func test_minions_never_damage_structures() -> void:
	var w := SimWorld.new(1, rules)
	w.add_lane_objectives()
	_run(w, _secs(90.0))
	for id in w.structures:
		var s: StructureState = w.structures[id]
		check_eq(s.hp, s.max_hp, "structure %d untouched by minions" % id)
	var m := w.add_minion(0, Vector3(0, 0, -20))
	check_eq(DamageSystem.deal(w, m, w.structure(1, StructureState.Kind.TOWER), 100), 0, "minion damage to a tower is 0")


func test_minions_hold_outside_enemy_tower() -> void:
	var w := SimWorld.new(1, rules)
	w.add_lane_objectives()
	var m := w.add_minion(0, Vector3(0, 0, -10))
	_run(w, _secs(15.0))
	var tower := w.structure(1, StructureState.Kind.TOWER)
	if w.minions.has(m):
		var gap: float = Vector2(w.minions[m].position.x, w.minions[m].position.z).distance_to(Vector2(tower.position.x, tower.position.z)) - tower.radius
		check(gap >= rules.minion_hold_distance - 0.5, "minion stopped short of the tower (gap %.1f)" % gap)
	check(w.minions.size() <= 1 + rules.wave_size * 2 * 1, "sanity")


# --- towers ------------------------------------------------------------------

func test_tower_shoots_minions_before_heroes() -> void:
	var tz := -rules.tower_z
	var w := _world(Vector3(0, 0, tz + 4.0), Vector3(5, 0, 0))
	var tower := w.structure(1, StructureState.Kind.TOWER)
	var m := w.add_minion(0, Vector3(1, 0, tz + 5.0))
	var shots := _of_type(_run(w, 3), SimEvent.Type.SHOT)
	check(not shots.is_empty(), "tower fired")
	if not shots.is_empty():
		check_eq(Vector2(shots[0].data["tx"], shots[0].data["tz"]), Vector2(1, tz + 5.0), "at the minion, not the hero")
	w.minions.erase(m)
	tower.attack_ready = 0
	var later := _of_type(_run(w, 2), SimEvent.Type.SHOT)
	check(not later.is_empty() and later[0].data["tx"] == 0.0, "then at the hero")


func test_tower_ignores_enemies_out_of_range() -> void:
	var w := _world(Vector3(0, 0, -rules.tower_z + rules.tower_range + 3.0), Vector3(5, 0, 0))
	check(_of_type(_run(w, 120), SimEvent.Type.SHOT).is_empty(), "no shots out of range")


func test_structures_are_solid() -> void:
	var w := _world(Vector3(0, 0, -rules.tower_z + 6.0), Vector3(8, 0, 10))
	var tower := w.structure(1, StructureState.Kind.TOWER)
	_step(w, [Command.move(1, w.tick, Vector2(0, -1))])
	_run(w, _secs(3.0))
	var h := w.hero_for_player(1)
	var d := Vector2(h.position.x, h.position.z).distance_to(Vector2(tower.position.x, tower.position.z))
	check(d >= tower.radius + h.radius - 0.01, "hero can't walk into the tower (%.2f)" % d)
	check(not KnockbackSystem.push(w, tower, Vector2(1, 0), 10.0, 20), "towers ignore knockback")


# --- attacks and structure damage -------------------------------------------

func test_pet_attack_is_weaker_than_mech_attack() -> void:
	check(wombat.pet_attack.damage < wombat.mech_attack.damage, "pet hits lighter")
	var w := _world(Vector3(0, 0, 0), Vector3(0, 0, -1.8))
	var foe := w.hero_for_player(2)
	_attack(w, 1, Vector2(0, -1))
	var pet_dmg := foe.max_hp - foe.hp
	foe.hp = foe.max_hp
	_step(w, [Command.switch_form(1, w.tick, HeroState.Form.MECH)])
	w.hero_for_player(1).attack_ready = 0
	_attack(w, 1, Vector2(0, -1))
	var mech_dmg := foe.max_hp - foe.hp
	check(pet_dmg > 0 and mech_dmg > pet_dmg, "pet %d < mech %d" % [pet_dmg, mech_dmg])


func test_attack_has_a_cooldown_and_needs_a_target_in_front() -> void:
	var w := _world(Vector3(0, 0, 0), Vector3(0, 0, -1.8))
	var foe := w.hero_for_player(2)
	_attack(w, 1, Vector2(0, 1))
	check_eq(foe.hp, foe.max_hp, "swinging the other way misses")
	w.hero_for_player(1).attack_ready = 0
	_attack(w, 1, Vector2(0, -1))
	var once := foe.hp
	_attack(w, 1, Vector2(0, -1))
	check_eq(foe.hp, once, "second swing during cooldown does nothing")


func test_mech_breaks_structures_faster() -> void:
	var w := _world()
	var tower := w.structure(1, StructureState.Kind.TOWER)
	var me := w.hero_for_player(1)
	check_eq(DamageSystem.structure_amount(w, me.entity_id, tower, 100), 100, "pet: normal damage")
	me.apply_form(HeroState.Form.MECH)
	check_eq(DamageSystem.structure_amount(w, me.entity_id, tower, 100), int(100 * rules.mech_structure_multiplier), "mech: bonus")


func test_core_is_shielded_until_its_tower_falls() -> void:
	var w := _world()
	var me := w.hero_for_player(1)
	var tower := w.structure(1, StructureState.Kind.TOWER)
	var core := w.structure(1, StructureState.Kind.CORE)
	check_eq(DamageSystem.deal(w, me.entity_id, core, 500), 0, "shielded")
	tower.hp = 0
	var events := _step(w)
	check(tower.dead, "tower destroyed")
	check(not _of_type(events, SimEvent.Type.DEATH).is_empty(), "DEATH event for the tower")
	check(DamageSystem.deal(w, me.entity_id, core, 500) > 0, "core open once the tower is down")


func test_destroying_the_core_wins_and_freezes_the_match() -> void:
	var w := _world()
	var me := w.hero_for_player(1)
	w.structure(1, StructureState.Kind.TOWER).hp = 0
	_step(w)
	var core := w.structure(1, StructureState.Kind.CORE)
	DamageSystem.deal(w, me.entity_id, core, 1000000)
	var events := _step(w)
	check_eq(w.winner, 0, "team 0 wins")
	check(not _of_type(events, SimEvent.Type.MATCH_END).is_empty(), "MATCH_END event")
	var at := me.position
	_step(w, [Command.move(1, w.tick, Vector2(1, 0))])
	_run(w, 30)
	check_eq(me.position, at, "nothing moves after the match ends")


func test_heroes_heal_at_their_base() -> void:
	var w := _world(Vector3(0, 0, rules.core_z + rules.core_radius + 1.0))
	var me := w.hero_for_player(1)
	me.hp = 200
	_run(w, _secs(1.0))
	check(me.hp > 200, "healed behind own core (%d)" % me.hp)
	me.hp = 200
	me.position = Vector3(4, 0, rules.core_z - 4.0)
	_run(w, _secs(1.0))
	check_eq(me.hp, 200, "no healing in front of the core")
	var foe := w.hero_for_player(2)
	foe.hp = 200
	_run(w, _secs(1.0))
	check_eq(foe.hp, 200, "no healing in the middle of the lane")


# --- bots and whole matches ----------------------------------------------------

func test_bot_match_plays_and_replays_exactly() -> void:
	var live := SimHarness.match_3v3(31)
	var events: Array[SimEvent] = []
	for i in _secs(120.0):
		events.append_array(live.step())
	live.finish()
	var abilities := 0
	var attacks := 0
	var switches := 0
	for d in live.replay.commands:
		match int(d["type"]):
			Command.Type.ABILITY:
				if int(d["payload"]["slot"]) == Command.ATTACK_SLOT:
					attacks += 1
				else:
					abilities += 1
			Command.Type.SWITCH_FORM:
				switches += 1
	check(attacks > 50, "bots attack (%d)" % attacks)
	check(abilities > 5, "bots use their kit (%d)" % abilities)
	check(switches > 2, "bots switch form (%d)" % switches)
	var hero_hits := _of_type(events, SimEvent.Type.HIT).filter(func(e): return live.world.heroes.has(e.entity_id))
	check(not hero_hits.is_empty(), "heroes took damage")
	var re := SimHarness.playback(ReplayLog.from_dict(JSON.parse_string(JSON.stringify(live.replay.to_dict()))))
	re.run(_secs(120.0))
	re.finish()
	check_eq(re.desync_tick, -1, "no desync")
	check_eq(re.world.state_hash(), live.world.state_hash(), "same final state")
