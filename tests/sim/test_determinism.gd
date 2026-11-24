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


func test_human_and_bot_share_one_command_path() -> void:
	var h := SimHarness.practice(5, true)
	h.run(60)
	var by_player := {}
	for d in h.replay.commands:
		by_player[int(d["player_id"])] = true
	check(by_player.has(1), "local controller sent commands through the buffer")
	check(by_player.has(2), "bot sent commands through the buffer")
	var human := h.world.hero_for_player(1)
	check_eq(human.position, Vector3(-5, 0, 5), "idle human stays put with no input")


func test_heroes_stay_in_arena() -> void:
	var h := SimHarness.practice(3)
	var half := h.world.rules.arena_half_size
	for i in 20:
		h.run(100)
		for id in h.world.heroes:
			var p: Vector3 = h.world.heroes[id].position
			check(absf(p.x) <= half and absf(p.z) <= half, "hero %d inside arena at tick %d" % [id, h.world.tick])
