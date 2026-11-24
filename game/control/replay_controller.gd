## Feeds back one player's recorded commands, tick for tick.
class_name ReplayController
extends Controller

var _by_tick: Dictionary  # tick -> Array of Command dicts


func _init(p_player_id: int, p_team: int, replay: ReplayLog) -> void:
	super(p_player_id, p_team)
	_by_tick = replay.commands_for_player(p_player_id)


func produce_commands(_snapshot: Snapshot, tick: int) -> Array[Command]:
	var out: Array[Command] = []
	for d in _by_tick.get(tick, []):
		out.append(Command.from_dict(d))
	return out
