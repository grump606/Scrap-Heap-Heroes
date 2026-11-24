## Everything needed to replay a match exactly: seed, versions, slots (with
## spawns), every command, and state hashes to catch desyncs. File IO lives in
## the app layer; this class is plain data and survives a JSON round trip:
## from_dict restores the ints JSON turns into floats, and the seed is stored
## as a string because JSON numbers lose precision above 2^53.
class_name ReplayLog
extends RefCounted

const FORMAT_VERSION := 4
## A state hash is recorded every this many ticks.
const HASH_INTERVAL := 60

var match_seed: int
var game_version: String
var data_version: int
var slots: Array = []  # [{player_id, team, hero_id: String, spawn: [x, y, z]}]
var dummies: Array = []  # [[x, y, z]] training dummy positions
var commands: Array = []  # Array of Command.to_dict()
var hashes: Array = []  # [[tick, state_hash]], every HASH_INTERVAL ticks
var final_tick: int = 0
var final_hash: String = ""


func add_slot(player_id: int, team: int, hero_id: StringName, spawn: Vector3) -> void:
	slots.append({
		"player_id": player_id,
		"team": team,
		"hero_id": String(hero_id),
		"spawn": [spawn.x, spawn.y, spawn.z],
	})


func add_dummy(at: Vector3) -> void:
	dummies.append([at.x, at.y, at.z])


func record(cmds: Array) -> void:
	for c in cmds:
		commands.append(c.to_dict())


func record_hash(tick: int, state_hash: String) -> void:
	hashes.append([tick, state_hash])


## Seals the log with the state at the end of the match.
func finish(tick: int, state_hash: String) -> void:
	final_tick = tick
	final_hash = state_hash


## tick -> expected state hash, including the final one, for checking a playback.
func hashes_by_tick() -> Dictionary:
	var out := {}
	for e in hashes:
		out[int(e[0])] = str(e[1])
	if final_hash != "":
		out[final_tick] = final_hash
	return out


## Empty when this replay can be played back with these rules on this build,
## otherwise the reason. Exact playback is only reliable on the same build.
func incompatibility(rules: MatchRules, current_game_version: String) -> String:
	if game_version != current_game_version:
		return "recorded with game version %s, this build is %s" % [game_version, current_game_version]
	if data_version != rules.data_version:
		return "recorded with data_version %d, current is %d" % [data_version, rules.data_version]
	if slots.is_empty():
		return "replay has no slots"
	return ""


func commands_for_player(player_id: int) -> Dictionary:
	var by_tick := {}
	for d in commands:
		if int(d["player_id"]) != player_id:
			continue
		var t := int(d["tick"])
		if not by_tick.has(t):
			by_tick[t] = []
		by_tick[t].append(d)
	return by_tick


func to_dict() -> Dictionary:
	return {
		"format": FORMAT_VERSION,
		"seed": str(match_seed),
		"game_version": game_version,
		"data_version": data_version,
		"slots": slots.duplicate(true),
		"dummies": dummies.duplicate(true),
		"commands": commands.duplicate(true),
		"hashes": hashes.duplicate(true),
		"final_tick": final_tick,
		"final_hash": final_hash,
	}


## Returns null for a replay written in another format.
static func from_dict(d: Dictionary) -> ReplayLog:
	var format := int(d.get("format", 0))
	if format != FORMAT_VERSION:
		push_warning("replay format %d not supported (expected %d)" % [format, FORMAT_VERSION])
		return null
	var r := ReplayLog.new()
	r.match_seed = str(d["seed"]).to_int()
	r.game_version = str(d.get("game_version", ""))
	r.data_version = int(d.get("data_version", 0))
	for s in d.get("slots", []):
		var sp: Array = s["spawn"]
		r.slots.append({
			"player_id": int(s["player_id"]),
			"team": int(s["team"]),
			"hero_id": str(s["hero_id"]),
			"spawn": [float(sp[0]), float(sp[1]), float(sp[2])],
		})
	for p in d.get("dummies", []):
		r.dummies.append([float(p[0]), float(p[1]), float(p[2])])
	for c in d.get("commands", []):
		r.commands.append(_normalized_command(c))
	for e in d.get("hashes", []):
		r.hashes.append([int(e[0]), str(e[1])])
	r.final_tick = int(d.get("final_tick", 0))
	r.final_hash = str(d.get("final_hash", ""))
	return r


## Command payloads hold only quantized integers (see Command), so any number
## in one is restored to int.
static func _normalized_command(c: Dictionary) -> Dictionary:
	var payload := {}
	var src: Dictionary = c.get("payload", {})
	for k in src:
		var v: Variant = src[k]
		payload[str(k)] = int(v) if (v is float or v is int) else v
	return {"player_id": int(c["player_id"]), "tick": int(c["tick"]), "type": int(c["type"]), "payload": payload}
