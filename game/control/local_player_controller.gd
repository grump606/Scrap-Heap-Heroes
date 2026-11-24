## Turns this machine's keyboard/gamepad input into commands. It reads Input,
## so it lives outside the sim; the sim only ever sees the resulting commands.
class_name LocalPlayerController
extends Controller

## Set by the camera rig each frame. Movement is camera-relative, but only the
## final world direction travels in the command.
var camera_yaw: float = 0.0
## False while a menu has focus or the window is unfocused.
var input_enabled: bool = true:
	set(v):
		input_enabled = v
		if not v:
			_switch_pressed = false

var _switch_pressed := false


## Called once per rendered frame, before any ticks run. Button presses are
## latched here because a frame can run zero ticks (high refresh rate) or
## several (catch-up): sampling them per tick would drop or repeat them.
func poll_frame_input() -> void:
	if input_enabled and Input.is_action_just_pressed("switch_form"):
		request_switch()


## Queues one form switch for the next tick. Tests call this directly.
func request_switch() -> void:
	_switch_pressed = true


func produce_commands(snapshot: Snapshot, tick: int) -> Array[Command]:
	var dir := Vector2.ZERO
	if input_enabled:
		dir = sample_input().rotated(-camera_yaw)
	var out := move_if_changed(tick, dir)
	if _switch_pressed:
		_switch_pressed = false
		var me := snapshot.hero_for_player(player_id)
		if not me.is_empty():
			out.append(Command.switch_form(player_id, tick, HeroState.other_form(me["form"])))
	return out


## Raw stick/WASD vector, camera-relative. Tests override this.
func sample_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")
