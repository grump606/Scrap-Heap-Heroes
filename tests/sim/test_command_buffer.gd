extends TestCase


func test_orders_by_player_then_type_then_arrival() -> void:
	var b := CommandBuffer.new()
	b.add(Command.new(3, 0, Command.Type.MOVE))
	b.add(Command.new(1, 0, Command.Type.ABILITY, {"n": 1}))
	b.add(Command.new(1, 0, Command.Type.MOVE))
	b.add(Command.new(1, 0, Command.Type.ABILITY, {"n": 2}))
	var out := b.take(0)
	var got := []
	for c in out:
		got.append([c.player_id, c.type, c.payload.get("n", 0)])
	check_eq(got, [[1, Command.Type.MOVE, 0], [1, Command.Type.ABILITY, 1], [1, Command.Type.ABILITY, 2], [3, Command.Type.MOVE, 0]], "command order")


func test_late_commands_are_dropped() -> void:
	var b := CommandBuffer.new()
	b.take(0)
	check(not b.add(Command.new(1, 0, Command.Type.MOVE)), "command for a finished tick is rejected")
	check(b.add(Command.new(1, 1, Command.Type.MOVE)), "command for the next tick is accepted")


func test_move_is_quantized_and_clamped() -> void:
	var c := Command.move(1, 0, Vector2(3, 0))
	check_eq(c.payload["x"], Command.AXIS_MAX, "length clamped to 1")
	var back := Command.from_dict(c.to_dict())
	check_eq(back.move_dir(), c.move_dir(), "survives a round trip")
