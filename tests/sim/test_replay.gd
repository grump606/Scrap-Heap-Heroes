extends TestCase

const TICKS := 1000


## A finished live match, for the tests below to play back.
func _recorded(p_seed: int) -> MatchSession:
	var live := SimHarness.practice(p_seed)
	live.run(TICKS)
	live.finish()
	return live


func test_replay_rebuilds_match_from_log_alone() -> void:
	var live := _recorded(99)
	var saved := ReplayLog.from_dict(live.replay.to_dict())
	var re := SimHarness.playback(saved)
	check(re != null, "replay accepted")
	if re == null:
		return
	re.run(TICKS)
	re.finish()
	check_eq(re.world.state_hash(), live.world.state_hash(), "replay matches live match")
	check_eq(re.desync_tick, -1, "no desync reported")
	check(saved.hashes.size() >= TICKS / ReplayLog.HASH_INTERVAL, "periodic hashes recorded")


func test_replay_survives_json() -> void:
	var live := _recorded(17)
	var text := JSON.stringify(live.replay.to_dict())
	var saved := ReplayLog.from_dict(JSON.parse_string(text))
	var re := SimHarness.playback(saved)
	check(re != null, "replay accepted after JSON")
	if re == null:
		return
	re.run(TICKS)
	re.finish()
	check_eq(re.world.state_hash(), live.world.state_hash(), "JSON replay matches live match")
	check_eq(re.desync_tick, -1, "no desync reported")


func test_tampered_replay_reports_desync() -> void:
	var live := _recorded(5)
	var saved := ReplayLog.from_dict(live.replay.to_dict())
	# Flip one of player 2's moves partway through.
	for d in saved.commands:
		if int(d["player_id"]) == 2 and int(d["tick"]) == 500:
			var x := int(d["payload"].get("x", 0))
			d["payload"] = {"x": -Command.AXIS_MAX if x > 0 else Command.AXIS_MAX, "z": 0}
			break
	var re := SimHarness.playback(saved)
	re.run(TICKS)
	re.finish()
	check(re.desync_tick > 500, "desync detected after the changed tick (got %d)" % re.desync_tick)


func test_replay_with_other_data_version_is_rejected() -> void:
	var saved := ReplayLog.from_dict(_recorded(1).replay.to_dict())
	saved.data_version += 1
	check(MatchSetup.from_replay(saved, MatchSetup.default_rules()) == null, "old balance data rejected")


func test_replay_from_other_build_is_rejected() -> void:
	var saved := ReplayLog.from_dict(_recorded(1).replay.to_dict())
	saved.game_version = "not-" + saved.game_version
	check(MatchSetup.from_replay(saved, MatchSetup.default_rules()) == null, "other build rejected")


func test_unknown_format_is_rejected() -> void:
	var d := _recorded(1).replay.to_dict()
	d["format"] = ReplayLog.FORMAT_VERSION + 1
	check(ReplayLog.from_dict(d) == null, "future format rejected")
