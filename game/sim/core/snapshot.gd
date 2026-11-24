## Read-only copy of world state at the end of one tick. This is everything a
## view, a bot or (later) a network client is allowed to see.
class_name Snapshot
extends RefCounted

var tick: int
## entity_id -> Dictionary (see HeroState.to_dict). Plain data, safe to keep.
var heroes: Dictionary = {}


func _init(p_tick: int = 0, p_heroes: Dictionary = {}) -> void:
	tick = p_tick
	heroes = p_heroes


func hero_for_player(player_id: int) -> Dictionary:
	for id in heroes:
		if heroes[id]["player_id"] == player_id:
			return heroes[id]
	return {}


## The snapshot one team is allowed to see. Vision isn't built yet, so this
## copies everything; once it exists, enemies outside vision are removed here.
## Bots must use this, never the full snapshot.
func for_team(_team: int) -> Snapshot:
	return Snapshot.new(tick, heroes.duplicate(true))
