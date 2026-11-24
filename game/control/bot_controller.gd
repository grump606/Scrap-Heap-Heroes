## A bot is just another client sending commands. It sees only its team's
## snapshot and its own hero's data (HeroDef), exactly like a remote player,
## and has no access to SimWorld.
##
## Two modes, picked from the snapshot:
## - Practice (no structures): wander between random waypoints and switch
##   form now and then.
## - Match (lane with structures): push the lane behind its minions, fight
##   the nearest threat with attacks and its kit, stay out of enemy tower
##   range without minion cover, manage the mech meter, retreat to heal.
class_name BotController
extends Controller

const ARRIVE_DISTANCE := 1.0
const REPLAN_TICKS := 240
## Practice: chance of asking for the other form at each new waypoint.
const SWITCH_CHANCE := 0.3
## Match: when to fall back to base, and when to come out again.
const RETREAT_BELOW := 0.25
const RETURN_ABOVE := 0.8
const SIGHT := 11.0
const ENTER_MECH_ENERGY := 55.0
const LEAVE_MECH_ENERGY := 10.0

var rules: MatchRules
var def: HeroDef
## The bot's own seeded RNG. Its decisions are recorded as commands, so
## replays don't depend on it, but seeding it keeps live matches repeatable.
var _rng := RandomNumberGenerator.new()
var _waypoint := Vector2.ZERO
var _replan_at: int = 0
var _want_switch := false
var _retreating := false
## Match: this bot's side-to-side spot in the lane, so bots don't stack.
var _lane_x := 0.0


func _init(p_player_id: int, p_team: int, match_seed: int, p_rules: MatchRules, p_def: HeroDef) -> void:
	super(p_player_id, p_team)
	rules = p_rules
	def = p_def
	_rng.seed = SimRng.derive_seed(match_seed, 100 + p_player_id)
	_lane_x = _rng.randf_range(-0.5, 0.5) * (rules.arena_half_width - 2.0)


func produce_commands(snapshot: Snapshot, tick: int) -> Array[Command]:
	var me := snapshot.hero_for_player(player_id)
	if me.is_empty() or me["dead"] or snapshot.winner != -1:
		return move_if_changed(tick, Vector2.ZERO) if not me.is_empty() else []
	if snapshot.structures.is_empty():
		return _wander(me, tick)
	return _play_lane(snapshot, me, tick)


# --- practice ------------------------------------------------------------

func _wander(me: Dictionary, tick: int) -> Array[Command]:
	var pos := _flat(me["position"])
	if tick >= _replan_at or pos.distance_to(_waypoint) < ARRIVE_DISTANCE:
		var mx := rules.arena_half_width - 2.0
		var mz := minf(rules.arena_half_length - 2.0, 18.0)
		_waypoint = Vector2(_rng.randf_range(-mx, mx), _rng.randf_range(-mz, mz))
		_replan_at = tick + REPLAN_TICKS
		# Asking during cooldown is fine: the sim drops it, as it would a player's.
		_want_switch = _rng.randf() < SWITCH_CHANCE
	var dir := _waypoint - pos
	if dir.length() > 1.0:
		dir = dir.normalized()
	var out := move_if_changed(tick, dir)
	if _want_switch:
		_want_switch = false
		out.append(Command.switch_form(player_id, tick, HeroState.other_form(me["form"])))
	return out


# --- match ----------------------------------------------------------------

func _play_lane(snap: Snapshot, me: Dictionary, tick: int) -> Array[Command]:
	var pos := _flat(me["position"])
	var side := MatchRules.team_side(team)
	var hp_frac := float(me["hp"]) / float(me["max_hp"])
	var mech: bool = me["form"] == HeroState.Form.MECH
	# Behind our own core, where base healing works.
	var home := Vector2(_lane_x * 0.5, (rules.core_z + rules.core_radius + 1.5) * side)
	var out: Array[Command] = []

	if hp_frac < RETREAT_BELOW:
		_retreating = true
	elif hp_frac >= RETURN_ABOVE:
		_retreating = false

	var threat := _nearest(_enemies(snap, true, false), pos, SIGHT)
	var target := _pick_target(snap, me, pos)

	# Form and meter.
	var switch_ready: bool = tick >= int(me["switch_ready_tick"])
	if switch_ready:
		var want_mech: bool = not _retreating and target.size() > 0 and me["mech_energy"] >= ENTER_MECH_ENERGY
		var want_pet: bool = _retreating or me["mech_energy"] < LEAVE_MECH_ENERGY \
			or (target.is_empty() and threat.is_empty() and me["mech_energy"] < 40.0)
		if not mech and want_mech:
			out.append(Command.switch_form(player_id, tick, HeroState.Form.MECH))
		elif mech and want_pet:
			out.append(Command.switch_form(player_id, tick, HeroState.Form.PET))

	if _retreating:
		var away := (home - pos).normalized()
		out.append_array(move_if_changed(tick, away if pos.distance_to(home) > 1.0 else Vector2.ZERO))
		if not threat.is_empty():
			out.append_array(_use(snap, me, tick, &"mud_slide", away))
			out.append_array(_use(snap, me, tick, &"dust_bath", away))
		return out

	if target.is_empty():
		out.append_array(move_if_changed(tick, _lane_step(snap, pos)))
		return out

	var tpos := _flat(target["position"])
	var to := tpos - pos
	var aim := to.normalized() if to.length() > 0.01 else Vector2(0, -side)
	var gap := to.length() - float(me["radius"]) - float(target["radius"])
	var attack := def.attack(me["form"])
	var reach := attack.reach * 0.8 if attack != null else 1.5
	out.append_array(move_if_changed(tick, aim if gap > reach else Vector2.ZERO))
	if attack != null and gap <= attack.reach and tick >= int(me["attack_ready"]):
		out.append(Command.ability(player_id, tick, Command.ATTACK_SLOT, aim))
	out.append_array(_kit(snap, me, tick, pos, target, aim, gap, hp_frac))
	return out


## Uses the hero's kit when it fits the moment. Each check is cheap and only
## sends a command when the ability is off cooldown in the current form.
func _kit(snap: Snapshot, me: Dictionary, tick: int, pos: Vector2, target: Dictionary,
		aim: Vector2, gap: float, hp_frac: float) -> Array[Command]:
	var out: Array[Command] = []
	var is_hero := target.has("player_id")
	var crowd := _enemies(snap, true, true).filter(func(e): return _flat(e["position"]).distance_to(pos) <= 5.0).size()
	if me["form"] == HeroState.Form.MECH:
		if gap <= 2.5:
			out.append_array(_use(snap, me, tick, &"rump_bump", aim))
		if is_hero and gap > 2.5 and gap < 6.0:
			out.append_array(_use(snap, me, tick, &"wall_crush", aim))
		if is_hero and hp_frac < 0.5 and gap < 5.0:
			out.append_array(_use(snap, me, tick, &"brace", aim))
		if crowd >= 3 or (is_hero and gap < 3.5 and float(target["hp"]) < 0.5 * float(target["max_hp"])):
			out.append_array(_use(snap, me, tick, &"burrow_burst", aim))
	else:
		if crowd >= 2 or _active(me, Status.Kind.SLOW, tick):
			out.append_array(_use(snap, me, tick, &"dust_bath", aim))
	return out


## A command for ability `id` if this hero has it in its current form and it is ready.
func _use(_snap: Snapshot, me: Dictionary, tick: int, id: StringName, aim: Vector2) -> Array[Command]:
	var form: int = me["form"]
	var list := def.abilities(form)
	var ready: Array = me["mech_ready" if form == HeroState.Form.MECH else "pet_ready"]
	for i in list.size():
		if list[i].id == id and tick >= int(ready[i]):
			return [Command.ability(player_id, tick, i, aim)]
	return []


## Nearest enemy hero in sight, else the nearest enemy minion, else an enemy
## structure that is safe to hit. {} if nothing.
func _pick_target(snap: Snapshot, me: Dictionary, pos: Vector2) -> Dictionary:
	var hero := _nearest(_enemies(snap, true, false), pos, 7.0)
	if not hero.is_empty():
		return hero
	var minion := _nearest(_enemies(snap, false, true), pos, SIGHT)
	if not minion.is_empty():
		return minion
	var s := _attackable_structure(snap)
	if not s.is_empty() and _covered(snap, s):
		return s
	return {}


## The enemy tower while it stands, then the enemy core.
func _attackable_structure(snap: Snapshot) -> Dictionary:
	var tower := snap.structure(1 - team, StructureState.Kind.TOWER)
	if not tower.is_empty() and not tower["dead"]:
		return tower
	var core := snap.structure(1 - team, StructureState.Kind.CORE)
	return core if not core.is_empty() and not core["dead"] else {}


## True when walking up to s won't mean tanking a tower alone: either no enemy
## tower stands, or an allied minion is inside its range to draw its fire.
func _covered(snap: Snapshot, s: Dictionary) -> bool:
	var tower := snap.structure(1 - team, StructureState.Kind.TOWER)
	if tower.is_empty() or tower["dead"]:
		return true
	var tpos := _flat(tower["position"])
	for id in snap.minions:
		var m: Dictionary = snap.minions[id]
		if m["team"] == team and _flat(m["position"]).distance_to(tpos) <= rules.tower_range:
			return true
	return false


## Where to walk with nothing to fight: a few meters behind the most advanced
## allied minion, or in front of our own tower if there are none. Never into
## an uncovered enemy tower's range.
func _lane_step(snap: Snapshot, pos: Vector2) -> Vector2:
	var side := MatchRules.team_side(team)
	var goal := Vector2(_lane_x, (rules.tower_z - 4.0) * side)
	var front := INF
	for id in snap.minions:
		var m: Dictionary = snap.minions[id]
		if m["team"] != team:
			continue
		var progress: float = -m["position"].z * side  # Larger = deeper into enemy half.
		if front == INF or progress > front:
			front = progress
			goal = Vector2(_lane_x, m["position"].z + 3.0 * side)
	var tower := snap.structure(1 - team, StructureState.Kind.TOWER)
	if not tower.is_empty() and not tower["dead"] and not _covered(snap, tower):
		var tz: float = tower["position"].z
		var limit := tz + (rules.tower_range + 2.0) * side
		if (goal.y - limit) * side < 0.0:
			goal.y = limit
	var d := goal - pos
	return d.normalized() if d.length() > 1.0 else Vector2.ZERO


## Enemy heroes and/or minions that are alive.
func _enemies(snap: Snapshot, heroes: bool, minions: bool) -> Array:
	var out := []
	if heroes:
		for id in snap.heroes:
			var h: Dictionary = snap.heroes[id]
			if h["team"] != team and not h["dead"]:
				out.append(h)
	if minions:
		for id in snap.minions:
			var m: Dictionary = snap.minions[id]
			if m["team"] != team:
				out.append(m)
	return out


func _nearest(list: Array, pos: Vector2, max_d: float) -> Dictionary:
	var best := {}
	var best_d := max_d
	for e in list:
		var d := _flat(e["position"]).distance_to(pos)
		if d <= best_d:
			best = e
			best_d = d
	return best


static func _active(me: Dictionary, kind: int, tick: int) -> bool:
	for s in me["statuses"]:
		if int(s["kind"]) == kind and tick < int(s["until"]):
			return true
	return false


static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
