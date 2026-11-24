## Collects commands from every controller and hands them to the sim one tick
## at a time, always in the same order.
class_name CommandBuffer
extends RefCounted

var _by_tick: Dictionary = {}  # tick -> Array[Command]
var _next_seq: int = 0
## Lowest tick still accepted. Commands for ticks already simulated are dropped
## (later, the network layer decides how to handle late commands).
var _min_tick: int = 0


func add(cmd: Command) -> bool:
	if cmd.tick < _min_tick:
		return false
	cmd.seq = _next_seq
	_next_seq += 1
	if not _by_tick.has(cmd.tick):
		_by_tick[cmd.tick] = []
	_by_tick[cmd.tick].append(cmd)
	return true


func add_all(cmds: Array) -> void:
	for c in cmds:
		add(c)


## Removes and returns the commands for one tick, sorted by player_id, then
## type, then arrival order. A fixed order is what keeps replays exact.
func take(tick: int) -> Array[Command]:
	var out: Array[Command] = []
	if _by_tick.has(tick):
		out.assign(_by_tick[tick])
		_by_tick.erase(tick)
	out.sort_custom(_less)
	_min_tick = maxi(_min_tick, tick + 1)
	return out


static func _less(a: Command, b: Command) -> bool:
	if a.player_id != b.player_id:
		return a.player_id < b.player_id
	if a.type != b.type:
		return a.type < b.type
	return a.seq < b.seq
