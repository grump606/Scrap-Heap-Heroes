## One running match: the world, its controllers, the command buffer and the
## replay being recorded. MatchRunner steps it from frame time and the headless
## tests step it directly, so the game and the tests run the same tick code.
##
## Each tick: every controller reads its team's snapshot and emits commands,
## the buffer orders them, they're recorded, and the world steps.
class_name MatchSession
extends RefCounted

var setup: MatchSetup
var world: SimWorld
var buffer := CommandBuffer.new()
var controllers: Array[Controller] = []
## This run, as it happens. During playback it's a fresh recording too.
var replay := ReplayLog.new()
## The human on this machine, if there is one.
var local: LocalPlayerController
var prev_snapshot: Snapshot
var cur_snapshot: Snapshot
## During playback: the first tick whose state didn't match the recording. -1 if none.
var desync_tick: int = -1

var _expected_hashes: Dictionary = {}


func _init(p_setup: MatchSetup) -> void:
	setup = p_setup
	world = SimWorld.new(setup.match_seed, setup.rules)
	replay.match_seed = setup.match_seed
	replay.game_version = MatchSetup.game_version()
	replay.data_version = setup.rules.data_version
	if setup.replay_source != null:
		_expected_hashes = setup.replay_source.hashes_by_tick()

	for slot in setup.slots:
		var def: HeroDef = slot["hero_def"]
		world.add_hero(slot["player_id"], slot["team"], def, slot["spawn"])
		replay.add_slot(slot["player_id"], slot["team"], def.id if def != null else &"", slot["spawn"])
		controllers.append(_make_controller(slot))
	for at in setup.dummies:
		world.add_dummy(at)
		replay.add_dummy(at)

	cur_snapshot = world.snapshot()
	prev_snapshot = cur_snapshot


## Events from every tick run since the last take_events(), for the view.
var _events: Array[SimEvent] = []


func take_events() -> Array[SimEvent]:
	var out := _events
	_events = []
	return out


## Runs one fixed tick and returns its events.
func step() -> Array[SimEvent]:
	var t := world.tick
	for c in controllers:
		buffer.add_all(c.produce_commands(cur_snapshot.for_team(c.team), t))
	var cmds := buffer.take(t)
	replay.record(cmds)
	var events := world.step(cmds)
	_events.append_array(events)
	prev_snapshot = cur_snapshot
	cur_snapshot = world.snapshot()
	if world.tick % ReplayLog.HASH_INTERVAL == 0:
		var h := world.state_hash()
		replay.record_hash(world.tick, h)
		_verify(world.tick, h)
	return events


func run(ticks: int) -> void:
	for i in ticks:
		step()


## Seals the replay with the final state hash. Call once when the match ends.
func finish() -> void:
	var h := world.state_hash()
	replay.finish(world.tick, h)
	_verify(world.tick, h)


func _verify(tick: int, state_hash: String) -> void:
	if desync_tick == -1 and _expected_hashes.has(tick) and _expected_hashes[tick] != state_hash:
		desync_tick = tick
		push_warning("replay desync at tick %d" % tick)


func _make_controller(slot: Dictionary) -> Controller:
	var pid: int = slot["player_id"]
	var team: int = slot["team"]
	match slot["kind"]:
		MatchSetup.SlotKind.HUMAN:
			local = LocalPlayerController.new(pid, team)
			return local
		MatchSetup.SlotKind.BOT:
			return BotController.new(pid, team, setup.match_seed, setup.rules.arena_half_size)
		MatchSetup.SlotKind.REPLAY:
			assert(setup.replay_source != null, "REPLAY slot needs setup.replay_source")
			return ReplayController.new(pid, team, setup.replay_source)
	push_error("unknown slot kind %s" % str(slot["kind"]))
	return Controller.new(pid, team)
