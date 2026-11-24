## Something that happened in the sim this tick. Views use events for sounds,
## VFX and UI; they never change sim state.
class_name SimEvent
extends RefCounted

enum Type {
	HERO_SPAWNED = 0,
	HIT = 1,            ## data: amount, source, x, z
	DEATH = 2,
	FORM_SWITCH = 3,    ## data: form
	RESPAWN = 4,
	ABILITY_CAST = 5,   ## data: ability, slot, windup (ticks)
	EJECT = 6,          ## empty meter forced the hero out of mech form
	WALL_SLAM = 7,      ## data: amount, x, z
	AREA = 8,           ## an area effect landed. data: shape ("ring"/"cone"), x, z, radius, ax, az, angle
}

var type: int
var tick: int
var entity_id: int
var data: Dictionary


func _init(p_type: int, p_tick: int, p_entity_id: int, p_data: Dictionary = {}) -> void:
	type = p_type
	tick = p_tick
	entity_id = p_entity_id
	data = p_data.duplicate(true)
