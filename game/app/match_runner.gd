## The only node that wires the match to the screen.
##
## Each frame: the clock says how many fixed ticks to run, the MatchSession
## runs them, and the view draws, interpolating between the last two snapshots.
class_name MatchRunner
extends Node3D

@export var match_seed: int = 12345

var session: MatchSession
var clock: TickClock

var _world_view: WorldView
var _camera: CameraRig


func _ready() -> void:
	start_match(MatchSetup.practice(match_seed, MatchSetup.default_rules()))


func start_match(setup: MatchSetup) -> void:
	session = MatchSession.new(setup)
	clock = TickClock.new(setup.rules.tick_rate, setup.rules.max_ticks_per_frame)

	_world_view = WorldView.new()
	add_child(_world_view)
	_world_view.build_arena(setup.rules.arena_half_size)
	_camera = CameraRig.new()
	add_child(_camera)

	_world_view.render(session.prev_snapshot, session.cur_snapshot, 0.0)
	if session.local != null:
		var me := session.world.hero_for_player(session.local.player_id)
		_camera.target = _world_view.hero_view(me.entity_id)


func _process(delta: float) -> void:
	if session.local != null:
		session.local.camera_yaw = _camera.yaw
	for i in clock.advance(delta):
		var _events := session.step()  # Audio/VFX directors will consume these.
	_world_view.render(session.prev_snapshot, session.cur_snapshot, clock.alpha())


func _exit_tree() -> void:
	if session != null:
		session.finish()


func _notification(what: int) -> void:
	if session == null or session.local == null:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Release the mouse and stop held keys from steering the hero.
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			session.local.input_enabled = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			session.local.input_enabled = true
