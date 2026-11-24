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
	return s
