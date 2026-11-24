## Base for anything that drives a player: a human, a bot, a replay, or
## (later) a remote player. Controllers only read snapshots and emit commands.
class_name Controller
extends RefCounted

var player_id: int
var team: int


func _init(p_player_id: int, p_team: int) -> void:
	player_id = p_player_id
	team = p_team


## Called once per sim tick, before the tick runs. snapshot is already filtered
## to what this controller's team can see.
func produce_commands(_snapshot: Snapshot, _tick: int) -> Array[Command]:
	return []
