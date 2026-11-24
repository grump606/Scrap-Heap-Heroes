## Owns all gameplay state for one match and advances it one fixed tick at a time.
##
## Rules this class enforces:
## - Pure logic. No Node, scene, Input, audio or frame time ever reaches here.
## - Changes only through step(commands).
## - All randomness comes from rng (seeded per world).
## - Player data lives here, keyed by player_id/entity_id. No globals.
class_name SimWorld
extends RefCounted

const NO_WINNER := -1

var rules: MatchRules
var tick: int = 0
var tick_dt: float
var rng: SimRng
var heroes: Dictionary = {}  # entity_id -> HeroState
var dummies: Dictionary = {}  # entity_id -> DummyState
var minions: Dictionary = {}  # entity_id -> MinionState
var structures: Dictionary = {}  # entity_id -> StructureState
## Abilities waiting out their windup: [{at, caster, form, slot, ax, az}].
var pending_casts: Array = []
## True when towers, cores and minion waves are in play (see add_lane_objectives).
var lane_objectives: bool = false
## Team whose enemy core fell, or NO_WINNER. Once set, the world stops changing.
var winner: int = NO_WINNER

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
	h.facing = 0.0 if team == 0 else PI
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


## Places each team's tower and Power Core and turns on minion waves.
## Call once, before the first step, after heroes are added.
func add_lane_objectives() -> void:
	lane_objectives = true
	for team in [0, 1]:
		var side := MatchRules.team_side(team)
		_add_structure(team, StructureState.Kind.TOWER, Vector3(0, 0, rules.tower_z * side),
			rules.tower_max_hp, rules.tower_radius)
		_add_structure(team, StructureState.Kind.CORE, Vector3(0, 0, rules.core_z * side),
			rules.core_max_hp, rules.core_radius)


func _add_structure(team: int, kind: int, at: Vector3, max_hp: int, radius: float) -> void:
	var s := StructureState.new()
	s.entity_id = next_entity_id()
	s.team = team
	s.kind = kind
	s.position = at
	s.max_hp = max_hp
	s.hp = max_hp
	s.radius = radius
	s.immovable = true
	structures[s.entity_id] = s


func add_minion(team: int, at: Vector3) -> int:
	var m := MinionState.new()
	m.entity_id = next_entity_id()
	m.team = team
	m.position = at
	m.facing = 0.0 if team == 0 else PI
	m.max_hp = rules.minion_max_hp
	m.hp = m.max_hp
	m.radius = rules.minion_radius
	m.move_speed = rules.minion_move_speed
	minions[m.entity_id] = m
	return m.entity_id


## Systems report what happened through this; step() returns the tick's events.
func emit(event: SimEvent) -> void:
	_pending_events.append(event)


func hero_for_player(player_id: int) -> HeroState:
	var id: int = _player_to_entity.get(player_id, -1)
	return heroes.get(id)


func sorted_hero_ids() -> Array:
	return _sorted_keys(heroes)


func sorted_dummy_ids() -> Array:
	return _sorted_keys(dummies)


func sorted_minion_ids() -> Array:
	return _sorted_keys(minions)


func sorted_structure_ids() -> Array:
	return _sorted_keys(structures)


## Every hittable unit (heroes, dummies, minions, structures), by entity id.
func units() -> Array[UnitState]:
	var ids := heroes.keys() + dummies.keys() + minions.keys() + structures.keys()
	ids.sort()
	var out: Array[UnitState] = []
	for id in ids:
		out.append(unit(id))
	return out


func unit(entity_id: int) -> UnitState:
	if heroes.has(entity_id):
		return heroes[entity_id]
	if minions.has(entity_id):
		return minions[entity_id]
	if structures.has(entity_id):
		return structures[entity_id]
	return dummies.get(entity_id)


## A team's living structure of a kind, or null.
func structure(team: int, kind: int) -> StructureState:
	for id in sorted_structure_ids():
		var s: StructureState = structures[id]
		if s.team == team and s.kind == kind and not s.dead:
			return s
	return null


func has_pending_cast(caster_id: int) -> bool:
	for p in pending_casts:
		if p["caster"] == caster_id:
			return true
	return false


## Advances exactly one tick. commands must all be for the current tick and
## already sorted (CommandBuffer.take does both). Returns this tick's events.
## After the match is won, ticks still count but nothing else changes.
func step(commands: Array[Command]) -> Array[SimEvent]:
	if winner == NO_WINNER:
		for cmd in commands:
			if cmd.tick != tick:
				push_warning("dropping command for tick %d at tick %d" % [cmd.tick, tick])
				continue
			_apply(cmd)
		for u in units():
			Status.expire(u, tick)
		FormSystem.run(self)
		AbilitySystem.run(self)
		MinionAiSystem.run(self)
		TowerSystem.run(self)
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
	var s := Snapshot.new(tick, _dicts(heroes), _dicts(dummies))
	s.minions = _dicts(minions)
	s.structures = _dicts(structures)
	s.winner = winner
	return s


## SHA-256 of the full gameplay state. Two worlds with equal hashes are in the
## same state; the determinism tests and (later) desync checks rely on this.
func state_hash() -> String:
	var parts: Array = [tick, _next_entity_id, rng.get_states(), pending_casts, lane_objectives, winner]
	for u in units():
		parts.append(u.hash_fields())
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(var_to_bytes(parts))
	return ctx.finish().hex_encode()


func _dicts(d: Dictionary) -> Dictionary:
	var out := {}
	for id in _sorted_keys(d):
		out[id] = d[id].to_dict()
	return out


static func _sorted_keys(d: Dictionary) -> Array:
	var ids := d.keys()
	ids.sort()
	return ids
