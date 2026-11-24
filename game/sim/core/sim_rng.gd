## Seeded random numbers owned by one SimWorld. Never use the global random functions or
## a global RNG in gameplay code: they break replays.
##
## Separate streams keep systems independent, so adding a random roll to one
## system doesn't shift every other system's results.
class_name SimRng
extends RefCounted

enum Stream { GAMEPLAY = 0, SPAWNS = 1, MINIONS = 2, LOOT = 3 }

var base_seed: int
var _streams: Dictionary = {}  # Stream -> RandomNumberGenerator


func _init(p_seed: int) -> void:
	base_seed = p_seed
	for s in Stream.values():
		var r := RandomNumberGenerator.new()
		r.seed = derive_seed(p_seed, s)
		_streams[s] = r


## Mixes a base seed with a stream id: the first 8 bytes of SHA-256 over both.
## Nearby seeds or stream ids give unrelated results, no two (seed, stream)
## pairs collide in practice, and there is no integer overflow to worry about.
## Deterministic on every platform.
static func derive_seed(p_seed: int, stream_id: int) -> int:
	var bytes := PackedByteArray()
	bytes.resize(16)
	bytes.encode_s64(0, p_seed)
	bytes.encode_s64(8, stream_id)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().decode_s64(0)


func randf_in(stream: int, lo: float, hi: float) -> float:
	return _streams[stream].randf_range(lo, hi)


func randi_in(stream: int, lo: int, hi: int) -> int:
	return _streams[stream].randi_range(lo, hi)


## Current state of every stream, for snapshots, hashes and save/restore.
func get_states() -> Array:
	var out := []
	for s in Stream.values():
		out.append(_streams[s].state)
	return out


func set_states(states: Array) -> void:
	var i := 0
	for s in Stream.values():
		_streams[s].state = states[i]
		i += 1
