extends TestCase


func test_fixed_ticks_from_variable_frames() -> void:
	var c := TickClock.new(60, 5)
	var total := 0
	for i in 60:
		total += c.advance(1.0 / 60.0)
	check(total >= 59 and total <= 60, "about 60 ticks in one second of 60 fps frames (got %d)" % total)


func test_catch_up_is_capped() -> void:
	var c := TickClock.new(60, 5)
	check_eq(c.advance(2.0), 5, "a 2 second hitch runs at most 5 ticks")
	check_eq(c.advance(0.0), 0, "and drops the rest")


func test_pause_stops_ticks() -> void:
	var c := TickClock.new(60, 5)
	c.paused = true
	check_eq(c.advance(1.0), 0, "paused clock runs no ticks")
