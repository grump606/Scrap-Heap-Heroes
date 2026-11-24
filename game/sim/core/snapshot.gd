## Read-only copy of world state at the end of one tick. This is everything a
## view, a bot or (later) a network client is allowed to see.
class_name Snapshot
extends RefCounted

var tick: int
## entity_id -> Dictionary (see HeroState.to_dict). Plain data, safe to keep.
var heroes: Dictionary = {}
## entity_id -> Dictionary (see DummyState.to_dict).
var dummies: Dictionary = {}
## entity_id -> Dictionary (see MinionState.to_dict).
var minions: Dictionary = {}
## entity_id -> Dictionary (see StructureState.to_dict).
var structures: Dictionary = {}
## SimWorld.NO_WINNER while the match is on.
var winner: int = -1


func _init(p_tick: int = 0, p_heroes: Dictionary = {}, p_dummies: Dictionary = {}) -> void:
	tick = p_tick
	heroes = p_heroes
	dummies = p_dummies


func hero_for_player(player_id: int) -> Dictionary:
	for id in heroes:
		if heroes[id]["player_id"] == player_id:
			return heroes[id]
	return {}


## A team's structure of a kind (alive or not), or {}.
func structure(team: int, kind: int) -> Dictionary:
	for id in structures:
		var s: Dictionary = structures[id]
		if s["team"] == team and s["kind"] == kind:
			return s
	return {}


## The snapshot one team is allowed to see. Vision isn't built yet, so this
## copies everything; once it exists, enemies outside vision are removed here.
## Bots must use this, never the full snapshot.
func for_team(_team: int) -> Snapshot:
	var s := Snapshot.new(tick, heroes.duplicate(true), dummies.duplicate(true))
	s.minions = minions.duplicate(true)
	s.structures = structures.duplicate(true)
	s.winner = winner
	return s
