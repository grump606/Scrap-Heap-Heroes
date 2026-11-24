## Core kit: mech meter, damage, statuses, Wombat's abilities, dummies,
## death and respawn. Numbers come from the real data files, so these tests
## check behavior and relationships rather than exact balance values.
extends TestCase

const PET := HeroState.Form.PET
const MECH := HeroState.Form.MECH

var wombat: HeroDef = MatchSetup.hero_def(&"wombat")


## A world with Wombat (player 1, team 0) at the origin and an enemy test
## hero (player 2, team 1) parked out of the way. Spawn events flushed.
func _world(enemy_at: Vector3 = Vector3(8, 0, 15)) -> SimWorld:
	var w := SimWorld.new(1, MatchSetup.default_rules())
	w.add_hero(1, 0, wombat, Vector3.ZERO)
	var foe := HeroDef.new()
	foe.id = &"foe"
	w.add_hero(2, 1, foe, enemy_at)
	w.step([])
	return w


func _me(w: SimWorld) -> HeroState:
	return w.hero_for_player(1)


func _step(w: SimWorld, cmds: Array = []) -> Array[SimEvent]:
	var typed: Array[Command] = []
	typed.assign(cmds)
	return w.step(typed)


func _run(w: SimWorld, ticks: int) -> void:
	for i in ticks:
		w.step([])


func _cast(w: SimWorld, slot: int, aim: Vector2 = Vector2(0, -1)) -> Array[SimEvent]:
	return _step(w, [Command.ability(1, w.tick, slot, aim)])


func _to_mech(w: SimWorld) -> void:
	_step(w, [Command.switch_form(1, w.tick, MECH)])


func _slot(form: int, id: StringName) -> int:
	var list := wombat.abilities(form)
	for i in list.size():
		if list[i].id == id:
			return i
	return -1


func _ability(form: int, id: StringName) -> AbilityDef:
	return wombat.abilities(form)[_slot(form, id)]


func _secs(w: SimWorld, s: float) -> int:
	return w.rules.seconds_to_ticks(s)


func _of_type(events: Array[SimEvent], type: int) -> Array[SimEvent]:
	return events.filter(func(e): return e.type == type)


# --- data ---------------------------------------------------------------

func test_wombat_kit_shape() -> void:
	check(wombat != null, "wombat loads")
	check_eq(wombat.pet_abilities.size(), 2, "two pet skills")
	check_eq(wombat.mech_abilities.size(), 4, "three mech skills and an ultimate")
	check(wombat.mech_abilities[3].is_ultimate, "last mech slot is the ultimate")
	check(wombat.flat_reduction > 0, "Heavy Hide gives flat reduction")
	for a in wombat.pet_abilities + wombat.mech_abilities:
		check(AbilityRegistry.KNOWN.has(a.logic), "%s has known logic '%s'" % [a.id, a.logic])


# --- mech meter ---------------------------------------------------------

func test_mech_drains_and_ejects_when_empty() -> void:
	var w := _world()
	_to_mech(w)
	check_eq(_me(w).form, MECH, "in mech")
	var expected := ceili(w.rules.mech_energy_start / w.rules.mech_drain_per_second * w.rules.tick_rate)
	var ejected_at := -1
	for i in expected + 10:
		var events := _step(w)
		if not _of_type(events, SimEvent.Type.EJECT).is_empty():
			ejected_at = i
			break
	check(ejected_at >= expected - 2 and ejected_at <= expected + 1, "ejected after ~%d ticks (got %d)" % [expected, ejected_at])
	check_eq(_me(w).form, PET, "ejected back to pet")
	check(Status.active(_me(w), Status.Kind.VULNERABLE, w.tick), "vulnerable after eject")
	check_eq(DamageSystem.reduction(w, _me(w)), 0, "no reduction while vulnerable")
	_cast(w, 0)
	check_eq(_me(w).pet_ready[0], 0, "can't cast while vulnerable")


func test_pet_refills_and_mech_needs_minimum() -> void:
	var w := _world()
	_me(w).mech_energy = w.rules.mech_min_energy_to_switch - 1.0
	_to_mech(w)
	check_eq(_me(w).form, PET, "below the minimum: switch refused")
	_run(w, w.rules.tick_rate)
	check(_me(w).mech_energy > w.rules.mech_min_energy_to_switch - 1.0, "pet form refills")
	_me(w).mech_energy = w.rules.mech_energy_max
	_run(w, 10)
	check_eq(_me(w).mech_energy, w.rules.mech_energy_max, "refill caps at max")


# --- damage -------------------------------------------------------------

func test_flat_reduction_floor_mech_and_ultimate() -> void:
	var w := _world()
	var r := wombat.flat_reduction
	check_eq(DamageSystem.preview(w, _me(w), 100), 100 - r, "pet: flat reduction")
	check_eq(DamageSystem.preview(w, _me(w), 4), 1, "floor: at least 25%% (ceil)")
	_to_mech(w)
	var mech_r := int(r * w.rules.mech_reduction_multiplier)
	check_eq(DamageSystem.preview(w, _me(w), 100), 100 - mech_r, "mech doubles the flat value")
	var ult_r := int(mech_r * (1.0 - w.rules.ultimate_reduction_ignore))
	check_eq(DamageSystem.preview(w, _me(w), 100, true), 100 - ult_r, "ultimates ignore part of it")


# --- Wombat, pet --------------------------------------------------------

func test_dust_bath_cleanses_self_and_slows_enemies() -> void:
	var w := _world(Vector3(2, 0, 0))
	Status.add(_me(w), Status.Kind.SLOW, w.tick + 500, 0.5)
	Status.add(_me(w), Status.Kind.STUNNED, w.tick + 5)
	_run(w, 6)  # Stun runs out so the cast is allowed; the slow stays.
	check(Status.active(_me(w), Status.Kind.SLOW, w.tick), "slowed before")
	_cast(w, _slot(PET, &"dust_bath"))
	check(not Status.active(_me(w), Status.Kind.SLOW, w.tick), "cleansed")
	check(Status.active(w.hero_for_player(2), Status.Kind.SLOW, w.tick), "nearby enemy slowed")


func test_mud_slide_dashes_and_hardens_hide() -> void:
	var w := _world()
	var a := _ability(PET, &"mud_slide")
	_cast(w, _slot(PET, &"mud_slide"), Vector2(1, 0))
	_run(w, _secs(w, a.dash_duration))
	var expected := a.dash_speed * a.dash_duration
	check(_me(w).position.x > expected * 0.8, "slid about %.1f m (got %.2f)" % [expected, _me(w).position.x])
	check(DamageSystem.reduction(w, _me(w)) > wombat.flat_reduction, "extra hide after sliding")


# --- Wombat, mech -------------------------------------------------------

func test_rump_bump_hits_the_cone_only() -> void:
	var w := _world()
	var front := w.add_dummy(Vector3(0, 0, -2))
	var behind := w.add_dummy(Vector3(0, 0, 2))
	_to_mech(w)
	var events := _cast(w, _slot(MECH, &"rump_bump"), Vector2(0, -1))
	var hit_ids := _of_type(events, SimEvent.Type.HIT).map(func(e): return e.entity_id)
	check(hit_ids.has(front), "dummy in front hit")
	check(not hit_ids.has(behind), "dummy behind not hit")
	var before: float = w.dummies[front].position.z
	_run(w, 10)
	check(w.dummies[front].position.z < before - 0.5, "knocked away from Wombat")


func test_rump_bump_spares_allies() -> void:
	var w := _world()
	var ally := HeroDef.new()
	ally.id = &"ally"
	w.add_hero(3, 0, ally, Vector3(0, 0, -2))
	_to_mech(w)
	_cast(w, _slot(MECH, &"rump_bump"), Vector2(0, -1))
	check_eq(w.hero_for_player(3).hp, w.hero_for_player(3).max_hp, "ally untouched")


func test_wall_crush_slams_into_the_wall() -> void:
	var w := _world()
	var half := w.rules.arena_half_length
	_me(w).position = Vector3(0, 0, -half + 6)
	var near_wall := w.add_dummy(Vector3(0, 0, -half + 3.5))
	var a := _ability(MECH, &"wall_crush")
	_to_mech(w)
	var events: Array[SimEvent] = _cast(w, _slot(MECH, &"wall_crush"), Vector2(0, -1))
	for i in 90:
		events.append_array(_step(w))
	var d: DummyState = w.dummies[near_wall]
	check(not _of_type(events, SimEvent.Type.WALL_SLAM).is_empty(), "slammed into the wall")
	check_eq(d.max_hp - d.hp, a.damage + a.bonus_damage, "contact damage plus the slam bonus")


func test_wall_crush_in_the_open_has_no_slam() -> void:
	var w := _world()
	var open := w.add_dummy(Vector3(0, 0, -3))
	var a := _ability(MECH, &"wall_crush")
	_to_mech(w)
	var events: Array[SimEvent] = _cast(w, _slot(MECH, &"wall_crush"), Vector2(0, -1))
	for i in 60:
		events.append_array(_step(w))
	check(_of_type(events, SimEvent.Type.WALL_SLAM).is_empty(), "no wall, no slam")
	check_eq(w.dummies[open].max_hp - w.dummies[open].hp, a.damage, "contact damage only")


func test_slam_stuns_and_stun_blocks_casting() -> void:
	var w := _world()
	var foe := w.hero_for_player(2)
	var half := w.rules.arena_half_width
	foe.position = Vector3(half - 1.0, 0, 0)
	KnockbackSystem.push(w, foe, Vector2(1, 0), 10.0, 30, 50, _secs(w, 1.0), _me(w).entity_id)
	_run(w, 10)
	check(Status.active(foe, Status.Kind.STUNNED, w.tick), "slammed hero is stunned")
	check(not Status.can_act(foe, w.tick), "stunned hero can't act")


func test_brace_roots_armors_and_ignores_knockback() -> void:
	var w := _world()
	_to_mech(w)
	_cast(w, _slot(MECH, &"brace"))
	check(Status.active(_me(w), Status.Kind.ROOTED, w.tick), "braced")
	check(DamageSystem.reduction(w, _me(w)) > int(wombat.flat_reduction * w.rules.mech_reduction_multiplier), "extra hide")
	check(not KnockbackSystem.push(w, _me(w), Vector2(1, 0), 10.0, 20), "knockback ignored")
	var at := _me(w).position
	_step(w, [Command.move(1, w.tick, Vector2(1, 0))])
	_run(w, 20)
	check_eq(_me(w).position, at, "can't move while braced")


func test_burrow_burst_waits_for_windup_then_bursts() -> void:
	var w := _world()
	var d := w.add_dummy(Vector3(3, 0, 0))
	var a := _ability(MECH, &"burrow_burst")
	_to_mech(w)
	var events: Array[SimEvent] = _cast(w, _slot(MECH, &"burrow_burst"))
	check(_of_type(events, SimEvent.Type.HIT).is_empty(), "no hit on the press")
	var windup := _secs(w, a.windup)
	for i in windup - 1:
		check(_of_type(_step(w), SimEvent.Type.HIT).is_empty(), "no hit during windup")
	_run(w, 2)
	check(w.dummies[d].hp < w.dummies[d].max_hp, "burst landed after the windup")


func test_stun_cancels_a_windup() -> void:
	var w := _world()
	var d := w.add_dummy(Vector3(3, 0, 0))
	_to_mech(w)
	_cast(w, _slot(MECH, &"burrow_burst"))
	Status.add(_me(w), Status.Kind.STUNNED, w.tick + 5)
	_run(w, 60)
	check_eq(w.dummies[d].hp, w.dummies[d].max_hp, "cancelled: no burst")
	check(w.pending_casts.is_empty(), "nothing left pending")


func test_cooldowns_and_wrong_form_slots() -> void:
	var w := _world()
	var d := w.add_dummy(Vector3(0, 0, -2))
	_to_mech(w)
	var bump := _slot(MECH, &"rump_bump")
	_cast(w, bump)
	var hp_after_one: int = w.dummies[d].hp
	_cast(w, bump)
	check_eq(w.dummies[d].hp, hp_after_one, "second press during cooldown does nothing")
	_cast(w, 7)
	check(true, "an out-of-range slot is ignored without errors")


# --- dummies, death, respawn ---------------------------------------------

func test_dummy_resets_after_being_left_alone() -> void:
	var w := _world()
	var id := w.add_dummy(Vector3(0, 0, -2))
	_to_mech(w)
	_cast(w, _slot(MECH, &"rump_bump"))
	var d: DummyState = w.dummies[id]
	check(d.hp < d.max_hp, "damaged")
	_run(w, _secs(w, w.rules.dummy_reset_time) + 30)
	check_eq(d.hp, d.max_hp, "healed")
	check_eq(d.position, d.home, "back home")


func test_hero_dies_and_respawns() -> void:
	var w := _world()
	var foe := w.hero_for_player(2)
	DamageSystem.deal(w, 1, foe, 100000)
	var events := _step(w)
	check(foe.dead, "dead at 0 hp")
	check(not _of_type(events, SimEvent.Type.DEATH).is_empty(), "DEATH event")
	_run(w, _secs(w, w.rules.respawn_time) + 1)
	check(not foe.dead and foe.hp == foe.max_hp, "respawned at full health")
	check_eq(foe.position, foe.spawn, "at its spawn")


# --- input and determinism ----------------------------------------------

func test_local_ability_press_sends_one_command_with_aim() -> void:
	var s := SimHarness.practice(5, true)
	s.local.request_ability(0, Vector2(1, 0))
	s.run(3)
	var found := []
	for d in s.replay.commands:
		if int(d["player_id"]) == 1 and int(d["type"]) == Command.Type.ABILITY:
			found.append(d)
	check_eq(found.size(), 1, "one press, one command")
	if found.size() == 1:
		check_eq(int(found[0]["payload"]["x"]), Command.AXIS_MAX, "aim travels in the command")


func test_casting_match_replays_exactly() -> void:
	var live := SimHarness.practice(21, true)
	var mech_slots := [0, 1, 2, 3, 0, 1]
	for i in 40:
		if i % 4 == 0:
			live.local.request_switch()
		live.local.request_ability(mech_slots[i % mech_slots.size()], Vector2(sin(i), cos(i)))
		live.run(45)
	live.finish()
	var casts := 0
	for d in live.replay.commands:
		if int(d["type"]) == Command.Type.ABILITY:
			casts += 1
	check(casts > 20, "abilities were pressed (%d)" % casts)
	var re := SimHarness.playback(ReplayLog.from_dict(JSON.parse_string(JSON.stringify(live.replay.to_dict()))))
	re.run(40 * 45)
	re.finish()
	check_eq(re.desync_tick, -1, "no desync")
	check_eq(re.world.state_hash(), live.world.state_hash(), "same final state")
