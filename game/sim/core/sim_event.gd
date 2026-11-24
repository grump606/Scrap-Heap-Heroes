## Something that happened in the sim this tick. Views use events for sounds,
## VFX and UI; they never change sim state.
class_name SimEvent
extends RefCounted

enum Type { HERO_SPAWNED = 0, HIT = 1, DEATH = 2, FORM_SWITCH = 3, RESPAWN = 4 }

var type: int
var tick: int
var entity_id: int
var data: Dictionary


func _init(p_type: int, p_tick: int, p_entity_id: int, p_data: Dictionary = {}) -> void:
	type = p_type
	tick = p_tick
	entity_id = p_entity_id
	data = p_data.duplicate(true)
