extends TestCase


func test_derived_seeds_do_not_collide() -> void:
	var seen := {}
	for s in [0, 1, 2, 42, 43, 1000003, 1000045, -1]:
		for stream in 8:
			var v := SimRng.derive_seed(s, stream)
			check(not seen.has(v), "seed %d stream %d collides with %s" % [s, stream, str(seen.get(v))])
			seen[v] = [s, stream]


func test_derive_seed_is_stable() -> void:
	check_eq(SimRng.derive_seed(42, 1), SimRng.derive_seed(42, 1), "same inputs, same seed")


func test_streams_are_independent() -> void:
	var a := SimRng.new(7)
	var b := SimRng.new(7)
	# Rolling one stream must not shift another.
	for i in 10:
		a.randf_in(SimRng.Stream.LOOT, 0.0, 1.0)
	check_eq(a.randi_in(SimRng.Stream.GAMEPLAY, 0, 1 << 30), b.randi_in(SimRng.Stream.GAMEPLAY, 0, 1 << 30), "GAMEPLAY unaffected by LOOT rolls")
