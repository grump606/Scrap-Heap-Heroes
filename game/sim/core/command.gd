## One player intent for one tick. Humans, bots, replays and (later) remote
## players all produce these, and the sim only ever changes through them.
class_name Command
extends RefCounted

enum Type { NONE = 0, MOVE = 1, AIM = 2, ABILITY = 3, SWITCH_FORM = 4 }

## Analog input is quantized to this range so commands are small, exact and
## identical on every machine.
const AXIS_MAX := 127

var player_id: int
var tick: int
var type: int
var payload: Dictionary
## Arrival order inside a tick, set by CommandBuffer. Used only as a tiebreak.
var seq: int = 0


func _init(p_player_id: int = 0, p_tick: int = 0, p_type: int = Type.NONE, p_payload: Dictionary = {}) -> void:
	player_id = p_player_id
	tick = p_tick
	type = p_type
	payload = p_payload.duplicate(true)


## A move intent. dir is in world XZ (x = right, y = world Z). Length is clamped to 1.
static func move(p_player_id: int, p_tick: int, dir: Vector2) -> Command:
	var d := dir.limit_length(1.0)
	return Command.new(p_player_id, p_tick, Type.MOVE, {
		"x": int(round(d.x * AXIS_MAX)),
		"z": int(round(d.y * AXIS_MAX)),
	})


func move_dir() -> Vector2:
	return Vector2(float(payload.get("x", 0)) / AXIS_MAX, float(payload.get("z", 0)) / AXIS_MAX)


func to_dict() -> Dictionary:
	return {"player_id": player_id, "tick": tick, "type": type, "payload": payload.duplicate(true)}


static func from_dict(d: Dictionary) -> Command:
	return Command.new(int(d["player_id"]), int(d["tick"]), int(d["type"]), d.get("payload", {}))
