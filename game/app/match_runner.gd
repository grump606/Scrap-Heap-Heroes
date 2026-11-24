## The only node that wires the match to the screen.
##
## Each frame: the clock says how many fixed ticks to run, the MatchSession
## runs them, and the view draws, interpolating between the last two
## snapshots, then shows that frame's events (damage numbers, effects).
class_name MatchRunner
extends Node3D

@export var match_seed: int = 12345
## Practice: you and a wandering bot with training dummies, no structures.
## Otherwise a full 3v3 lane match with bots.
@export var practice: bool = false
## The hero you play: wombat, weasel or capybara. F1/F2/F3 restart as one.
@export var hero: StringName = &"wombat"
## Catch-up cap after a long frame or alt-tab (prevents the spiral of death).
## Frame pacing only: it never changes what the sim computes, so it isn't in MatchRules.
@export var max_ticks_per_frame: int = 5

var session: MatchSession
var clock: TickClock

var _world_view: WorldView
var _camera: CameraRig
var _hud: Hud


func _ready() -> void:
	_start_new()


func _start_new() -> void:
	var rules := MatchSetup.default_rules()
	start_match(MatchSetup.practice(match_seed, rules, hero) if practice else MatchSetup.match_3v3(match_seed, rules, hero))


func start_match(setup: MatchSetup) -> void:
	session = MatchSession.new(setup)
	clock = TickClock.new(setup.rules.tick_rate, max_ticks_per_frame)

	_world_view = WorldView.new()
	add_child(_world_view)
	_world_view.build_arena(setup.rules.arena_half_width, setup.rules.arena_half_length)
	_camera = CameraRig.new()
	add_child(_camera)

	_world_view.render(session.prev_snapshot, session.cur_snapshot, 0.0)
	if session.local != null:
		var me := session.world.hero_for_player(session.local.player_id)
		_camera.target = _world_view.hero_view(me.entity_id)
		_world_view.hero_view(me.entity_id).show_label = false
		_camera.snap_to_target()
		_hud = Hud.new()
		add_child(_hud)
		_hud.setup(setup.rules, me.def)


func _process(delta: float) -> void:
	if session.local != null:
		session.local.camera_yaw = _camera.yaw
		session.local.poll_frame_input()
	for i in clock.advance(delta):
		session.step()
	_world_view.render(session.prev_snapshot, session.cur_snapshot, clock.alpha())
	_world_view.show_events(session.take_events(), session.cur_snapshot, session.world.tick_dt)
	if _hud != null:
		_hud.update(session.cur_snapshot.hero_for_player(session.local.player_id), session.cur_snapshot.tick)
		_hud.update_match(session.cur_snapshot, session.local.team)


const HERO_KEYS := {KEY_F1: &"wombat", KEY_F2: &"weasel", KEY_F3: &"capybara"}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and HERO_KEYS.has(event.keycode):
		hero = HERO_KEYS[event.keycode]
		restart()
		return
	if session != null and session.world.winner != SimWorld.NO_WINNER and event.is_action_pressed("ui_accept"):
		restart()


## Throws the current match away and starts a fresh one with a new seed.
func restart() -> void:
	session.finish()
	for child in get_children():
		child.queue_free()
	_hud = null
	match_seed += 1
	_start_new()


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
