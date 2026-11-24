## A bot is just another client sending commands. It sees only its team's
## snapshot and has no access to SimWorld, exactly like a remote player.
class_name BotController
extends Controller

const ARRIVE_DISTANCE := 1.0
const REPLAN_TICKS := 240

var arena_half_size: float
## The bot's own seeded RNG. Its decisions are recorded as commands, so
## replays don't depend on it, but seeding it keeps live matches repeatable.
var _rng := RandomNumberGenerator.new()
var _waypoint := Vector2.ZERO
var _replan_at: int = 0


func _init(p_player_id: int, p_team: int, match_seed: int, p_arena_half_size: float) -> void:
	super(p_player_id, p_team)
	arena_half_size = p_arena_half_size
	_rng.seed = SimRng.derive_seed(match_seed, 100 + p_player_id)


func produce_commands(snapshot: Snapshot, tick: int) -> Array[Command]:
	var me := snapshot.hero_for_player(player_id)
	if me.is_empty():
		return []
	var pos := Vector2(me["position"].x, me["position"].z)
	if tick >= _replan_at or pos.distance_to(_waypoint) < ARRIVE_DISTANCE:
		_pick_waypoint(tick)
	var dir := (_waypoint - pos)
	if dir.length() > 1.0:
		dir = dir.normalized()
	return move_if_changed(tick, dir)


func _pick_waypoint(tick: int) -> void:
	var m := arena_half_size - 2.0
	_waypoint = Vector2(_rng.randf_range(-m, m), _rng.randf_range(-m, m))
	_replan_at = tick + REPLAN_TICKS
