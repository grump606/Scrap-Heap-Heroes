## Builds headless matches for tests. They run through MatchSession, the same
## tick code MatchRunner uses, with the same rules file.
class_name SimHarness
extends RefCounted


## Two-player practice match from MatchSetup.practice. By default both slots
## are bots; human_slot_uses_local_controller keeps slot 1 as a
## LocalPlayerController (it reads no input when headless, so it sends
## zero-move commands), proving humans and bots share one buffer.
static func practice(p_seed: int, human_slot_uses_local_controller: bool = false) -> MatchSession:
	var setup := MatchSetup.practice(p_seed, MatchSetup.default_rules())
	if not human_slot_uses_local_controller:
		setup.slots[0]["kind"] = MatchSetup.SlotKind.BOT
	return MatchSession.new(setup)


## Plays a recorded match back from a replay. Null if the replay is rejected.
static func playback(replay: ReplayLog) -> MatchSession:
	var setup := MatchSetup.from_replay(replay, MatchSetup.default_rules())
	return MatchSession.new(setup) if setup != null else null
