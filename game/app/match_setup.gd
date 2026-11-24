## Who is in a match and how it starts. Plain data.
class_name MatchSetup
extends RefCounted

enum SlotKind { HUMAN = 0, BOT = 1, REPLAY = 2 }

const DEFAULT_RULES_PATH := "res://data/match_rules.tres"
const HEROES_DIR := "res://data/heroes/"

var match_seed: int
var rules: MatchRules
## [{player_id, team, hero_def: HeroDef, kind, spawn}]
var slots: Array = []
## Towers, cores and minion waves (a real match) or not (practice).
var lane_objectives: bool = false
## Training dummy positions.
var dummies: Array[Vector3] = []
## Where REPLAY slots get their commands. Null for a live match.
var replay_source: ReplayLog


static func default_rules() -> MatchRules:
	return load(DEFAULT_RULES_PATH)


## The definition for a hero id, from data/heroes/<id>.tres. Null if unknown.
static func hero_def(hero_id: StringName) -> HeroDef:
	var path := HEROES_DIR + String(hero_id) + ".tres"
	if not ResourceLoader.exists(path):
		push_error("unknown hero '%s' (no %s)" % [hero_id, path])
		return null
	return load(path)


## This build's version, stamped on replays (application/config/version).
static func game_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev"))


## First-step practice match: one human and one bot, one hero each.
static func practice(p_seed: int, p_rules: MatchRules) -> MatchSetup:
	var s := MatchSetup.new()
	s.match_seed = p_seed
	s.rules = p_rules
	s.slots = [
		{"player_id": 1, "team": 0, "hero_def": hero_def(&"wombat"), "kind": SlotKind.HUMAN, "spawn": Vector3(-5, 0, 5)},
		{"player_id": 2, "team": 1, "hero_def": hero_def(&"weasel"), "kind": SlotKind.BOT, "spawn": Vector3(5, 0, -5)},
	]
	# One dummy in the open, one by the west wall for Wall Crush.
	s.dummies = [Vector3(0, 0, -4), Vector3(-8.5, 0, -1)]
	return s


## A 3v3 match on the lane: you (Wombat) with a Weasel and a Wombat bot,
## against the same three as bots. Players 1-3 are team 0, 4-6 team 1.
static func match_3v3(p_seed: int, p_rules: MatchRules) -> MatchSetup:
	var s := MatchSetup.new()
	s.match_seed = p_seed
	s.rules = p_rules
	s.lane_objectives = true
	var lineup := [&"wombat", &"weasel", &"wombat"]
	var xs := [0.0, -3.0, 3.0]
	for team in [0, 1]:
		var z := p_rules.hero_spawn_z * MatchRules.team_side(team)
		for i in 3:
			var human: bool = team == 0 and i == 0
			s.slots.append({
				"player_id": team * 3 + i + 1,
				"team": team,
				"hero_def": hero_def(lineup[i]),
				"kind": SlotKind.HUMAN if human else SlotKind.BOT,
				"spawn": Vector3(xs[i], 0, z),
			})
	return s


## Rebuilds a recorded match for playback, every slot driven by the replay.
## Returns null (with a warning) if the replay doesn't fit these rules or this build.
static func from_replay(replay: ReplayLog, p_rules: MatchRules) -> MatchSetup:
	var problem := replay.incompatibility(p_rules, game_version())
	if problem != "":
		push_warning("replay rejected: " + problem)
		return null
	var s := MatchSetup.new()
	s.match_seed = replay.match_seed
	s.rules = p_rules
	s.replay_source = replay
	s.lane_objectives = replay.lane_objectives
	for slot in replay.slots:
		var sp: Array = slot["spawn"]
		var def := hero_def(StringName(slot["hero_id"]))
		if def == null:
			push_warning("replay rejected: unknown hero '%s'" % slot["hero_id"])
			return null
		s.slots.append({
			"player_id": int(slot["player_id"]),
			"team": int(slot["team"]),
			"hero_def": def,
			"kind": SlotKind.REPLAY,
			"spawn": Vector3(sp[0], sp[1], sp[2]),
		})
	for p in replay.dummies:
		s.dummies.append(Vector3(p[0], p[1], p[2]))
	return s
