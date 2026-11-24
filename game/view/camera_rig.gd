## Third-person camera for one local player. View-only: the sim never knows it
## exists. Right-click captures the mouse for orbiting; Esc releases it.
class_name CameraRig
extends Node3D

@export var distance: float = 9.0
@export var height: float = 5.0
@export var follow_speed: float = 10.0

var yaw: float = 0.0
var target: Node3D
var _camera := Camera3D.new()


func _ready() -> void:
	add_child(_camera)
	_camera.current = true
	_update_camera_offset()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * Settings.mouse_sensitivity
		_update_camera_offset()


func _process(delta: float) -> void:
	if target == null:
		return
	var t := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target.global_position, t)


## Jumps straight to the target, e.g. at match start, instead of easing in.
func snap_to_target() -> void:
	if target != null:
		global_position = target.global_position
		_update_camera_offset()


func _update_camera_offset() -> void:
	var back := Vector3(0, 0, distance).rotated(Vector3.UP, yaw)
	_camera.position = back + Vector3(0, height, 0)
	_camera.look_at(global_position + Vector3(0, 1.0, 0), Vector3.UP)
