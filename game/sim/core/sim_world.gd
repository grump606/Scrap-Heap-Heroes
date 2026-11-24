## Owns all gameplay state for one match and advances it one fixed tick at a time.
##
## Rules this class enforces:
## - Pure logic. No Node, scene, Input, audio or frame time ever reaches here.
## - Changes only through step(commands).
## - All randomness comes from rng (seeded per world).
## - Player data lives here, keyed by player_id/entity_id. No globals.
class_name SimWorld
extends RefCounted

var rules: MatchRules
var tick: int = 0
var tick_dt: float
var rng: SimRng
var heroes: Dictionary = {}  # entity_id -> HeroState

var _next_entity_id: int = 1
var _player_to_entity: Dictionary = {}  # player_id -> entity_id
var _pending_events: Array[SimEvent] = []


func _init(p_seed: int, p_rules: MatchRules = null) -> void:
	rules = p_rules if p_rules != null else MatchRules.new()
	tick_dt = 1.0 / float(rules.tick_rate)
	rng = SimRng.new(p_seed)


## Entity ids come from this counter, never from node creation order.
func next_entity_id() -> int:
	var id := _next_entity_id
	_next_entity_id += 1
	return id


func add_hero(player_id: int, team: int, hero_id: StringName, spawn: Vector3) -> int:
	assert(not _player_to_entity.has(player_id), "player already has a hero")
	var h := HeroState.new()
	h.entity_id = next_entity_id()
	h.player_id = player_id
	h.team = team
	h.hero_id = hero_id
	h.position = spawn
	h.max_hp = rules.hero_max_hp
	h.hp = h.max_hp
	h.move_speed = rules.hero_move_speed
	heroes[h.entity_id] = h
	_player_to_entity[player_id] = h.entity_id
	_pending_events.append(SimEvent.new(SimEvent.Type.HERO_SPAWNED, tick, h.entity_id))
	return h.entity_id


func hero_for_player(player_id: int) -> HeroState:
	var id: int = _player_to_entity.get(player_id, -1)
	return heroes.get(id)


func sorted_hero_ids() -> Array:
	var ids := heroes.keys()
	ids.sort()
	return ids


## Advances exactly one tick. commands must all be for the current tick and
## already sorted (CommandBuffer.take does both). Returns this tick's events.
func step(commands: Array[Command]) -> Array[SimEvent]:
	for cmd in commands:
		if cmd.tick != tick:
			push_warning("dropping command for tick %d at tick %d" % [cmd.tick, tick])
			continue
		_apply(cmd)
	MovementSystem.run(self, tick_dt)
	tick += 1
	var events := _pending_events
	_pending_events = []
	return events


func _apply(cmd: Command) -> void:
	var h := hero_for_player(cmd.player_id)
	if h == null:
		return
	match cmd.type:
		Command.Type.MOVE:
			h.move_input = cmd.move_dir().limit_length(1.0)
		_:
			pass  # AIM, ABILITY, SWITCH_FORM arrive with the ability and form systems.


func snapshot() -> Snapshot:
	var out := {}
	for id in sorted_hero_ids():
		out[id] = heroes[id].to_dict()
	return Snapshot.new(tick, out)


## SHA-256 of the full gameplay state. Two worlds with equal hashes are in the
## same state; the determinism tests and (later) desync checks rely on this.
func state_hash() -> String:
	var parts: Array = [tick, _next_entity_id, rng.get_states()]
	for id in sorted_hero_ids():
		parts.append(heroes[id].hash_fields())
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(var_to_bytes(parts))
	return ctx.finish().hex_encode()
