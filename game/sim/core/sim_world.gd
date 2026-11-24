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
var dummies: Dictionary = {}  # entity_id -> DummyState
## Abilities waiting out their windup: [{at, caster, form, slot, ax, az}].
var pending_casts: Array = []

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


## Returns the new entity id, or -1 if def is missing or the player already
## has a hero. def comes from the app layer (MatchSetup.hero_def); the sim
## never loads files.
func add_hero(player_id: int, team: int, def: HeroDef, spawn: Vector3) -> int:
	if def == null:
		push_error("player %d has no hero definition" % player_id)
		return -1
	if _player_to_entity.has(player_id):
		push_error("player %d already has a hero" % player_id)
		return -1
	var h := HeroState.new()
	h.entity_id = next_entity_id()
	h.player_id = player_id
	h.team = team
	h.hero_id = def.id
	h.def = def
	h.spawn = spawn
	h.position = spawn
	h.max_hp = def.max_hp
	h.hp = h.max_hp
	h.mech_energy = rules.mech_energy_start
	h.apply_form(HeroState.Form.PET)
	h.pet_ready.resize(def.pet_abilities.size())
	h.mech_ready.resize(def.mech_abilities.size())
	heroes[h.entity_id] = h
	_player_to_entity[player_id] = h.entity_id
	emit(SimEvent.new(SimEvent.Type.HERO_SPAWNED, tick, h.entity_id))
	return h.entity_id


func add_dummy(at: Vector3) -> int:
	var d := DummyState.new()
	d.entity_id = next_entity_id()
	d.team = UnitState.TEAM_NEUTRAL
	d.home = at
	d.position = at
	d.max_hp = rules.dummy_max_hp
	d.hp = d.max_hp
	dummies[d.entity_id] = d
	return d.entity_id


## Systems report what happened through this; step() returns the tick's events.
func emit(event: SimEvent) -> void:
	_pending_events.append(event)


func hero_for_player(player_id: int) -> HeroState:
	var id: int = _player_to_entity.get(player_id, -1)
	return heroes.get(id)


func sorted_hero_ids() -> Array:
	var ids := heroes.keys()
	ids.sort()
	return ids


func sorted_dummy_ids() -> Array:
	var ids := dummies.keys()
	ids.sort()
	return ids


## Every hittable unit (heroes and dummies), by entity id.
func units() -> Array[UnitState]:
	var ids := heroes.keys() + dummies.keys()
	ids.sort()
	var out: Array[UnitState] = []
	for id in ids:
		out.append(heroes[id] if heroes.has(id) else dummies[id])
	return out


func has_pending_cast(caster_id: int) -> bool:
	for p in pending_casts:
		if p["caster"] == caster_id:
			return true
	return false


func unit(entity_id: int) -> UnitState:
	if heroes.has(entity_id):
		return heroes[entity_id]
	return dummies.get(entity_id)


## Advances exactly one tick. commands must all be for the current tick and
## already sorted (CommandBuffer.take does both). Returns this tick's events.
func step(commands: Array[Command]) -> Array[SimEvent]:
	for cmd in commands:
		if cmd.tick != tick:
			push_warning("dropping command for tick %d at tick %d" % [cmd.tick, tick])
			continue
		_apply(cmd)
	for u in units():
		Status.expire(u, tick)
	FormSystem.run(self)
	AbilitySystem.run(self)
	MovementSystem.run(self, tick_dt)
	MatchFlowSystem.run(self)
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
		Command.Type.SWITCH_FORM:
			h.form_request = int(cmd.payload.get("form", HeroState.NO_REQUEST))
		Command.Type.ABILITY:
			h.ability_requests.append({"slot": int(cmd.payload.get("slot", -1)), "aim": cmd.aim_dir()})
		_:
			pass


func snapshot() -> Snapshot:
	var hs := {}
	for id in sorted_hero_ids():
		hs[id] = heroes[id].to_dict()
	var ds := {}
	for id in sorted_dummy_ids():
		ds[id] = dummies[id].to_dict()
	return Snapshot.new(tick, hs, ds)


## SHA-256 of the full gameplay state. Two worlds with equal hashes are in the
## same state; the determinism tests and (later) desync checks rely on this.
func state_hash() -> String:
	var parts: Array = [tick, _next_entity_id, rng.get_states(), pending_casts]
	for u in units():
		parts.append(u.hash_fields())
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(var_to_bytes(parts))
	return ctx.finish().hex_encode()
