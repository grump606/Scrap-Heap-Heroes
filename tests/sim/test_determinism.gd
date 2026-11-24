extends TestCase

const TICKS := 1000


func test_same_seed_gives_identical_state() -> void:
	var a := SimHarness.practice(42)
	var b := SimHarness.practice(42)
	a.run(TICKS)
	b.run(TICKS)
	check_eq(a.world.tick, TICKS, "ran the expected number of ticks")
	check_eq(a.world.state_hash(), b.world.state_hash(), "same seed, same final state")


func test_different_seed_diverges() -> void:
	var a := SimHarness.practice(42)
	var b := SimHarness.practice(43)
	a.run(TICKS)
	b.run(TICKS)
	check(a.world.state_hash() != b.world.state_hash(), "different seeds should give different matches")


func test_bots_actually_move() -> void:
	var h := SimHarness.practice(7)
	var start := h.world.hero_for_player(2).position
	h.run(120)
	check(h.world.hero_for_player(2).position.distance_to(start) > 1.0, "bot hero moved")


## A LocalPlayerController with scripted input instead of the keyboard.
class ScriptedLocal extends LocalPlayerController:
	var dir := Vector2.ZERO

	func sample_input() -> Vector2:
		return dir


func test_human_and_bot_share_one_command_path() -> void:
	var h := SimHarness.practice(5, true)
	var human_ctrl := ScriptedLocal.new(1, 0)
	h.controllers[0] = human_ctrl
	human_ctrl.dir = Vector2.RIGHT
	h.run(30)
	human_ctrl.dir = Vector2.ZERO
	h.run(30)
	var human_cmds := []
	var bot_sent := false
	for d in h.replay.commands:
		if int(d["player_id"]) == 1:
			human_cmds.append(int(d["tick"]))
		else:
			bot_sent = true
	check_eq(human_cmds, [0, 30], "local controller sent one MOVE per change, through the buffer")
	check(bot_sent, "bot sent commands through the buffer")
	check(h.world.hero_for_player(1).position.x > -5.0, "human moved right while input was held")


func test_idle_human_sends_nothing_and_stays_put() -> void:
	var h := SimHarness.practice(5, true)
	h.run(60)
	for d in h.replay.commands:
		check(int(d["player_id"]) != 1, "idle human sent a command at tick %d" % int(d["tick"]))
	check_eq(h.world.hero_for_player(1).position, Vector3(-5, 0, 5), "idle human stays put with no input")


func test_unchanged_moves_are_not_repeated() -> void:
	var h := SimHarness.practice(8)
	h.run(600)
	var per_player := {}
	for d in h.replay.commands:
		per_player[int(d["player_id"])] = per_player.get(int(d["player_id"]), 0) + 1
	for pid in per_player:
		check(per_player[pid] < 600, "player %d sent %d commands in 600 ticks" % [pid, per_player[pid]])


func test_heroes_stay_in_arena() -> void:
	var h := SimHarness.practice(3)
	var half := h.world.rules.arena_half_size
	for i in 20:
		h.run(100)
		for id in h.world.heroes:
			var p: Vector3 = h.world.heroes[id].position
			check(absf(p.x) <= half and absf(p.z) <= half, "hero %d inside arena at tick %d" % [id, h.world.tick])


func test_second_hero_for_same_player_is_refused() -> void:
	var w := SimWorld.new(1)
	expect_error("already has a hero")
	check(w.add_hero(1, 0, HeroDef.new(), Vector3.ZERO) > 0, "first hero added")
	check_eq(w.add_hero(1, 0, HeroDef.new(), Vector3.ZERO), -1, "second hero refused")
	check_eq(w.heroes.size(), 1, "only one hero exists")
