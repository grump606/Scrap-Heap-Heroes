## Where and at whom one cast is aimed, handed to every ability script.
## aim: world XZ direction. dist: requested ground distance in meters, or -1
## for the ability's full reach. target_id: the unit picked at the press
## (AbilityRegistry.pick_target), 0 if none. stage: 0 for the cast itself,
## 1+ for the follow-ups an ability schedules (AbilitySystem.schedule).
class_name CastContext
extends RefCounted

var aim: Vector2
var dist: float
var target_id: int
var stage: int
## Free-form values a staged ability carries from one stage to the next.
var data: Dictionary


func _init(p_aim: Vector2 = Vector2.ZERO, p_dist: float = -1.0, p_target_id: int = 0,
		p_stage: int = 0, p_data: Dictionary = {}) -> void:
	aim = p_aim
	dist = p_dist
	target_id = p_target_id
	stage = p_stage
	data = p_data


## The ground point this cast aims at from `from`: dist along aim, capped at
## max_reach (the full reach if no dist was asked for).
func point(from: Vector3, max_reach: float) -> Vector3:
	var d := max_reach if dist < 0.0 else clampf(dist, 0.0, max_reach)
	return from + Vector3(aim.x, 0.0, aim.y) * d
