## Turns this machine's keyboard/gamepad input into commands. It reads Input,
## so it lives outside the sim; the sim only ever sees the resulting commands.
class_name LocalPlayerController
extends Controller

## Input actions for ability slots 0..3 of the current form. Pet form uses
## the first two; mech form uses all four (the last is the ultimate).
const ABILITY_ACTIONS: Array[StringName] = [&"ability_1", &"ability_2", &"ability_3", &"ultimate"]

## Set by the camera rig each frame. Movement and aim are camera-relative,
## but only final world directions travel in commands.
var camera_yaw: float = 0.0
## False while a menu has focus or the window is unfocused.
var input_enabled: bool = true:
	set(v):
		input_enabled = v
		if not v:
			_switch_pressed = false
			_attack_held = false
			_ability_presses.clear()

var _switch_pressed := false
## Basic attack: held, so it repeats at its own cooldown.
var _attack_held := false
var _attack_aim := Vector2.ZERO
## slot -> aim at the moment of the press.
var _ability_presses: Dictionary = {}


## Called once per rendered frame, before any ticks run. Button presses are
## latched here because a frame can run zero ticks (high refresh rate) or
## several (catch-up): sampling them per tick would drop or repeat them.
func poll_frame_input() -> void:
	if not input_enabled:
		return
	if Input.is_action_just_pressed("switch_form"):
		request_switch()
	hold_attack(Input.is_action_pressed("attack"), camera_forward())
	for slot in ABILITY_ACTIONS.size():
		if Input.is_action_just_pressed(ABILITY_ACTIONS[slot]):
			request_ability(slot, camera_forward())


## Queues one form switch for the next tick. Tests call this directly.
func request_switch() -> void:
	_switch_pressed = true


## Holding the attack button: an attack goes out whenever the snapshot says
## it is ready, so held attacks don't send a command every tick. Tests call this.
func hold_attack(held: bool, aim: Vector2) -> void:
	_attack_held = held
	_attack_aim = aim


## Queues one ability press for the next tick. Tests call this directly.
func request_ability(slot: int, aim: Vector2) -> void:
	_ability_presses[slot] = aim


## Where the camera looks, on the ground plane.
func camera_forward() -> Vector2:
	return Vector2(-sin(camera_yaw), -cos(camera_yaw))


func produce_commands(snapshot: Snapshot, tick: int) -> Array[Command]:
	var dir := Vector2.ZERO
	if input_enabled:
		dir = sample_input().rotated(-camera_yaw)
	var out := move_if_changed(tick, dir)
	var me := snapshot.hero_for_player(player_id)
	if _switch_pressed:
		_switch_pressed = false
		if not me.is_empty():
			out.append(Command.switch_form(player_id, tick, HeroState.other_form(me["form"])))
	if _attack_held and not me.is_empty() and not me["dead"] and tick >= int(me["attack_ready"]):
		out.append(Command.ability(player_id, tick, Command.ATTACK_SLOT, _attack_aim))
	var slots := _ability_presses.keys()
	slots.sort()
	for slot in slots:
		out.append(Command.ability(player_id, tick, slot, _ability_presses[slot]))
	_ability_presses.clear()
	return out


## Raw stick/WASD vector, camera-relative. Tests override this.
func sample_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")
