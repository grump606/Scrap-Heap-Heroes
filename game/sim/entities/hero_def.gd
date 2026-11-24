## Tunable values for one hero. Pure data; the saved instances live in
## res://data/heroes/<id>.tres. The app layer loads them and hands them to the
## sim, which never loads files itself. Changing a value means bumping
## MatchRules.data_version.
class_name HeroDef
extends Resource

enum Role { TANK = 0, DAMAGE = 1, SUPPORT = 2 }

@export var id: StringName = &""
@export var display_name: String = ""
@export var role: Role = Role.TANK
@export var max_hp: int = 1000
@export var pet_move_speed: float = 7.0
@export var mech_move_speed: float = 4.5


func move_speed(form: int) -> float:
	return mech_move_speed if form == HeroState.Form.MECH else pet_move_speed
