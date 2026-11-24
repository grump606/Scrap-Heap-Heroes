## Turns this machine's keyboard/gamepad input into commands. It reads Input,
## so it lives outside the sim; the sim only ever sees the resulting commands.
class_name LocalPlayerController
extends Controller

## Set by the camera rig each frame. Movement is camera-relative, but only the
## final world direction travels in the command.
var camera_yaw: float = 0.0
## False while a menu has focus or the window is unfocused.
var input_enabled: bool = true


func produce_commands(_snapshot: Snapshot, tick: int) -> Array[Command]:
	var dir := Vector2.ZERO
	if input_enabled:
		dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = dir.rotated(-camera_yaw)
	return [Command.move(player_id, tick, dir)]
