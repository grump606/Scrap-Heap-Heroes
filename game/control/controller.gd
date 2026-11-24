## Base for anything that drives a player: a human, a bot, a replay, or
## (later) a remote player. Controllers only read snapshots and emit commands.
class_name Controller
extends RefCounted

var player_id: int
var team: int

## Quantized payload of the last MOVE sent. The sim holds move input until the
## next MOVE, so repeating an unchanged one only bloats replays (and, later,
## network traffic).
var _last_move: Dictionary = {"x": 0, "z": 0}


func _init(p_player_id: int, p_team: int) -> void:
	player_id = p_player_id
	team = p_team


## Called once per sim tick, before the tick runs. snapshot is already filtered
## to what this controller's team can see.
func produce_commands(_snapshot: Snapshot, _tick: int) -> Array[Command]:
	return []


## A MOVE for dir if it differs from the last one sent (after quantizing),
## otherwise nothing. Heroes start with zero move input, so idle sends nothing.
func move_if_changed(tick: int, dir: Vector2) -> Array[Command]:
	var cmd := Command.move(player_id, tick, dir)
	if cmd.payload == _last_move:
		return []
	_last_move = cmd.payload.duplicate()
	return [cmd]
