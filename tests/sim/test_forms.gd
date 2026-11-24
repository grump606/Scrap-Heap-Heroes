extends TestCase


func _def() -> HeroDef:
	var d := HeroDef.new()
	d.id = &"test"
	d.pet_move_speed = 8.0
	d.mech_move_speed = 4.0
	return d


## One hero in pet form, spawn event already flushed. Default MatchRules.
func _world() -> SimWorld:
	var w := SimWorld.new(1)
	w.add_hero(1, 0, _def(), Vector3.ZERO)
	w.step([])
	return w


func _switch(w: SimWorld, form: int) -> Array[SimEvent]:
	var cmds: Array[Command] = [Command.switch_form(1, w.tick, form)]
	return w.step(cmds)


func _cooldown(w: SimWorld) -> int:
	return w.rules.seconds_to_ticks(w.rules.form_switch_cooldown)


func test_switch_to_mech_changes_form_speed_and_emits_event() -> void:
	var w := _world()
	var events := _switch(w, HeroState.Form.MECH)
	var h := w.hero_for_player(1)
	check_eq(h.form, HeroState.Form.MECH, "now in mech form")
	check_eq(h.move_speed, 4.0, "mech move speed")
	check_eq(events.size(), 1, "one event")
	if events.size() == 1:
		check_eq(events[0].type, SimEvent.Type.FORM_SWITCH, "FORM_SWITCH event")
		check_eq(events[0].data.get("form"), HeroState.Form.MECH, "event names the new form")


func test_cooldown_blocks_until_it_expires() -> void:
	var w := _world()
	var switched_at := w.tick
	_switch(w, HeroState.Form.MECH)
	var ready := switched_at + _cooldown(w)
	check_eq(w.hero_for_player(1).switch_ready_tick, ready, "cooldown set")
	_switch(w, HeroState.Form.PET)
	check_eq(w.hero_for_player(1).form, HeroState.Form.MECH, "blocked right after switching")
	while w.tick < ready - 1:
		w.step([])
	_switch(w, HeroState.Form.PET)
	check_eq(w.hero_for_player(1).form, HeroState.Form.MECH, "blocked one tick early")
	_switch(w, HeroState.Form.PET)
	check_eq(w.hero_for_player(1).form, HeroState.Form.PET, "allowed once the cooldown ends")


func test_blocked_requests_are_dropped_not_queued() -> void:
	var w := _world()
	_switch(w, HeroState.Form.MECH)
	_switch(w, HeroState.Form.PET)
	for i in _cooldown(w) + 10:
		w.step([])
	check_eq(w.hero_for_player(1).form, HeroState.Form.MECH, "the blocked request never fired")


func test_requests_for_current_or_unknown_form_are_ignored() -> void:
	var w := _world()
	check(_switch(w, HeroState.Form.PET).is_empty(), "already pet: no event")
	check(_switch(w, 7).is_empty(), "unknown form: no event")
	check_eq(w.hero_for_player(1).switch_ready_tick, 0, "no cooldown started")


func test_mech_is_slower() -> void:
	var pet := _world()
	var mech := _world()
	_switch(mech, HeroState.Form.MECH)
	pet.step([])
	for w in [pet, mech]:
		for i in 120:
			var cmds: Array[Command] = []
			if i == 0:
				cmds.append(Command.move(1, w.tick, Vector2.RIGHT))
			w.step(cmds)
	var px := pet.hero_for_player(1).position.x
	var mx := mech.hero_for_player(1).position.x
	check(px > mx and mx > 0.0, "pet went further than mech (pet %.2f, mech %.2f)" % [px, mx])


func test_local_press_sends_one_switch() -> void:
	var s := SimHarness.practice(5, true)
	s.local.request_switch()
	s.run(5)
	var switches := 0
	for d in s.replay.commands:
		if int(d["player_id"]) == 1 and int(d["type"]) == Command.Type.SWITCH_FORM:
			switches += 1
	check_eq(switches, 1, "one press, one command")
	check_eq(s.world.hero_for_player(1).form, HeroState.Form.MECH, "human switched to mech")


func test_unfocusing_drops_a_pending_press() -> void:
	var s := SimHarness.practice(5, true)
	s.local.request_switch()
	s.local.input_enabled = false
	s.run(5)
	check_eq(s.world.hero_for_player(1).form, HeroState.Form.PET, "no switch after focus loss")


func test_bots_switch_and_replays_keep_it() -> void:
	var live := SimHarness.practice(11)
	live.run(3000)
	live.finish()
	var switches := 0
	for d in live.replay.commands:
		if int(d["type"]) == Command.Type.SWITCH_FORM:
			switches += 1
	check(switches > 0, "bots asked to switch at least once")
	var re := SimHarness.playback(ReplayLog.from_dict(live.replay.to_dict()))
	re.run(3000)
	re.finish()
	check_eq(re.desync_tick, -1, "replay with form switches stays in sync")
	check_eq(re.world.state_hash(), live.world.state_hash(), "same final state")


func test_hero_data_files_match_their_names() -> void:
	var dir := DirAccess.open(MatchSetup.HEROES_DIR)
	check(dir != null, "heroes folder exists")
	if dir == null:
		return
	var count := 0
	for f in dir.get_files():
		if not f.ends_with(".tres"):
			continue
		count += 1
		var id := StringName(f.get_basename())
		var def := MatchSetup.hero_def(id)
		check(def != null and def.id == id, "%s has id '%s'" % [f, id])
		if def != null:
			check(def.pet_move_speed > def.mech_move_speed, "%s: pet is faster than mech" % f)
	check(count >= 2, "found hero files")


func test_unknown_hero_is_reported() -> void:
	expect_error("unknown hero")
	check(MatchSetup.hero_def(&"no_such_hero") == null, "null for an unknown id")
