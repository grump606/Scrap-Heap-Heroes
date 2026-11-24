## First three heroes: Weasel's and Capybara's kits, and the systems they
## brought in (healing, shields, zones, channels, crowd-control immunity).
## Numbers come from the real data files, so the checks are relationships.
extends TestCase

const PET := HeroState.Form.PET
const MECH := HeroState.Form.MECH

var rules: MatchRules = MatchSetup.default_rules()
var wombat: HeroDef = MatchSetup.hero_def(&"wombat")
var weasel: HeroDef = MatchSetup.hero_def(&"weasel")
var capybara: HeroDef = MatchSetup.hero_def(&"capybara")


## Player 1 plays `def` (team 0) at the origin. Player 2 is an ally Wombat,
## player 3 an enemy Wombat. Spawn events flushed.
func _world(def: HeroDef, ally_at: Vector3 = Vector3(3, 0, 0), foe_at: Vector3 = Vector3(0, 0, -6)) -> SimWorld:
	var w := SimWorld.new(1, rules)
	w.add_hero(1, 0, def, Vector3.ZERO)
	w.add_hero(2, 0, wombat, ally_at)
	w.add_hero(3, 1, wombat, foe_at)
	w.step([])
	return w


func _step(w: SimWorld, cmds: Array = []) -> Array[SimEvent]:
	var typed: Array[Command] = []
	typed.assign(cmds)
	return w.step(typed)


func _run(w: SimWorld, ticks: int) -> Array[SimEvent]:
	var all: Array[SimEvent] = []
	for i in ticks:
		all.append_array(w.step([]))
	return all


func _secs(s: float) -> int:
	return rules.seconds_to_ticks(s)


func _slot(def: HeroDef, form: int, id: StringName) -> int:
	var list := def.abilities(form)
	for i in list.size():
		if list[i].id == id:
			return i
	return -1


func _ab(def: HeroDef, form: int, id: StringName) -> AbilityDef:
	return def.abilities(form)[_slot(def, form, id)]


func _cast(w: SimWorld, id: StringName, aim: Vector2 = Vector2(0, -1), dist: float = -1.0) -> Array[SimEvent]:
	var me := w.hero_for_player(1)
	return _step(w, [Command.ability(1, w.tick, _slot(me.def, me.form, id), aim, dist)])


func _to_mech(w: SimWorld) -> void:
	_step(w, [Command.switch_form(1, w.tick, MECH)])


func _of_type(events: Array[SimEvent], type: int) -> Array[SimEvent]:
	return events.filter(func(e): return e.type == type)


# --- data ---------------------------------------------------------------------

func test_lineup_is_one_of_each_role() -> void:
	check(weasel != null and capybara != null, "hero files load")
	for def in [wombat, weasel, capybara]:
		check_eq(def.pet_abilities.size(), 2, "%s: two pet skills" % def.id)
		check_eq(def.mech_abilities.size(), 4, "%s: three mech skills and an ultimate" % def.id)
		check(def.mech_abilities[3].is_ultimate, "%s: ultimate last" % def.id)
		for a in def.pet_abilities + def.mech_abilities:
			check(AbilityRegistry.KNOWN.has(a.logic), "%s: logic '%s' is registered" % [a.id, a.logic])
	var s := MatchSetup.match_3v3(1, rules, &"capybara")
	check_eq(s.slots[0]["hero_def"].id, &"capybara", "you play the hero you picked")
	for team in [0, 1]:
		var roles := []
		for slot in s.slots:
			if slot["team"] == team:
				roles.append(slot["hero_def"].role)
		roles.sort()
		check_eq(roles, [HeroDef.Role.TANK, HeroDef.Role.DAMAGE, HeroDef.Role.SUPPORT], "team %d is 1-1-1" % team)


func test_command_carries_a_target_distance() -> void:
	var c := Command.ability(1, 0, 1, Vector2(0, -1), 6.37)
	var back := Command.from_dict(JSON.parse_string(JSON.stringify(c.to_dict())))
	check_eq(back.aim_distance(), 6.4, "tenths of a meter, survives JSON")
	check_eq(Command.ability(1, 0, 1, Vector2(0, -1)).aim_distance(), -1.0, "none given")


# --- shared systems ---------------------------------------------------------------

func test_shields_absorb_before_health() -> void:
	var w := _world(capybara)
	var foe := w.hero_for_player(3)
	HealSystem.shield(w, 0, foe, 100, 60)
	var hp := foe.hp
	DamageSystem.deal(w, 0, foe, 80 + foe.base_reduction())
	check_eq(foe.hp, hp, "all soaked")
	check_eq(HealSystem.shield_left(w, foe), 20, "20 left")
	DamageSystem.deal(w, 0, foe, 70 + foe.base_reduction())
	check_eq(foe.hp, hp - 50, "the rest goes through")
	check_eq(HealSystem.shield_left(w, foe), 0, "shield used up")


func test_heal_caps_and_heal_cut() -> void:
	var w := _world(capybara)
	var ally := w.hero_for_player(2)
	ally.hp = ally.max_hp - 50
	check_eq(HealSystem.heal(w, 0, ally, 200), 50, "capped at max health")
	ally.hp = 100
	Status.add(ally, Status.Kind.HEAL_CUT, w.tick + 60, 0.5)
	check_eq(HealSystem.heal(w, 0, ally, 100), 50, "heal cut halves it")


func test_cc_immunity_blocks_slow_stun_and_knockback() -> void:
	var w := _world(capybara)
	var ally := w.hero_for_player(2)
	Status.add(ally, Status.Kind.CC_IMMUNE, w.tick + 60)
	check(not Status.add_cc(ally, Status.Kind.STUNNED, w.tick, w.tick + 60), "no stun")
	check(not Status.add_cc(ally, Status.Kind.SLOW, w.tick, w.tick + 60, 0.5), "no slow")
	check(not KnockbackSystem.push(w, ally, Vector2(1, 0), 10.0, 20), "no knockback")


# --- Weasel --------------------------------------------------------------------

func test_sprint_speeds_weasel_up() -> void:
	var plain := _world(weasel)
	var fast := _world(weasel)
	_cast(fast, &"sprint")
	for w in [plain, fast]:
		_step(w, [Command.move(1, w.tick, Vector2(1, 0))])
		_run(w, _secs(1.0))
	check(fast.hero_for_player(1).position.x > plain.hero_for_player(1).position.x + 2.0, "sprinting covers more ground")


func test_pounce_leaps_along_the_aim() -> void:
	var w := _world(weasel)
	_cast(w, &"pounce", Vector2(-1, 0))
	var me := w.hero_for_player(1)
	check(me.air_end > me.air_start, "airborne arc for the view")
	_run(w, _secs(0.5))
	var p := _ab(weasel, PET, &"pounce")
	check(me.position.x < -p.dash_speed * p.dash_duration * 0.8, "leapt (%.1f)" % me.position.x)


func test_rocket_boost_stops_on_and_hits_the_first_enemy() -> void:
	var w := _world(weasel, Vector3(8, 0, 8), Vector3(0, 0, -4))
	_to_mech(w)
	var foe := w.hero_for_player(3)
	_cast(w, &"rocket_boost")
	_run(w, _secs(0.5))
	check(foe.hp < foe.max_hp, "hit")
	var me := w.hero_for_player(1)
	check(me.position.z > foe.position.z, "stopped at the enemy, didn't fly past")


func test_dive_bomb_lands_on_the_spot_and_scales_with_distance() -> void:
	var db := _ab(weasel, MECH, &"dive_bomb")
	var damage := []
	for dist in [3.0, db.reach]:
		var w := _world(weasel, Vector3(8, 0, 8), Vector3(0, 0, -dist))
		_to_mech(w)
		var foe := w.hero_for_player(3)
		var events := _cast(w, &"dive_bomb", Vector2(0, -1), dist)
		var casts := _of_type(events, SimEvent.Type.ABILITY_CAST)
		check(not casts.is_empty() and is_equal_approx(casts[0].data["tz"], -dist), "telegraph at the target spot")
		_run(w, _secs(db.windup) - 1)
		check_eq(foe.hp, foe.max_hp, "nothing during the rise")
		_run(w, _secs(db.dash_duration) + 3)
		var me := w.hero_for_player(1)
		check(absf(me.position.z + dist) < 0.3, "landed on the spot (%.2f)" % me.position.z)
		damage.append(foe.max_hp - foe.hp)
	check(damage[0] > 0 and damage[1] > damage[0], "a longer dive hits harder (%s)" % [damage])


func test_rocket_jab_is_a_flurry() -> void:
	var w := _world(weasel, Vector3(8, 0, 8), Vector3(0, 0, -1.5))
	_to_mech(w)
	var foe := w.hero_for_player(3)
	var events := _cast(w, &"rocket_jab")
	events.append_array(_run(w, _secs(0.5)))
	var hits := _of_type(events, SimEvent.Type.HIT).filter(func(e): return e.entity_id == foe.entity_id)
	check_eq(hits.size(), _ab(weasel, MECH, &"rocket_jab").hits, "one hit per punch")


func test_frenzy_run() -> void:
	var w := _world(weasel, Vector3(8, 0, 8), Vector3(0, 0, -6))
	var me := w.hero_for_player(1)
	_to_mech(w)
	me.position = Vector3(0, 0, 0)
	# Outside frenzy, Dive Bomb can be aimed at empty ground.
	var empty_ground := _cast(w, &"dive_bomb", Vector2(1, 0), 4.0)
	check(not _of_type(empty_ground, SimEvent.Type.ABILITY_CAST).is_empty(), "ground dive allowed")
	_run(w, _secs(1.5))
	me.position = Vector3.ZERO
	_cast(w, &"frenzy_run")
	check(Status.active(me, Status.Kind.FRENZY, w.tick), "frenzy on")
	var slot := _slot(weasel, MECH, &"dive_bomb")
	check(me.mech_ready[slot] <= w.tick, "dive bomb ready at once")
	var nothing := _cast(w, &"dive_bomb", Vector2(1, 0), 4.0)
	check(_of_type(nothing, SimEvent.Type.ABILITY_CAST).is_empty(), "frenzy dive needs an enemy hero")
	var end := Status.until_of(me, Status.Kind.FRENZY, w.tick)
	var foe := w.hero_for_player(3)
	_cast(w, &"dive_bomb", Vector2(0, -1))
	_run(w, _secs(1.0))
	check(foe.hp < foe.max_hp, "frenzy dive hit")
	check(me.mech_ready[slot] <= w.tick, "no cooldown during frenzy")
	check(Status.until_of(me, Status.Kind.FRENZY, w.tick) > end, "a new enemy hit extends it")
	me.hp = 100
	check(HealSystem.heal(w, 0, me, 100) < 100, "reduced healing during frenzy")


# --- Capybara ------------------------------------------------------------------

func test_chill_aura_heals_allies_more_when_still() -> void:
	var moving := _world(capybara)
	var still := _world(capybara)
	for w in [moving, still]:
		w.hero_for_player(2).hp = 300
		w.hero_for_player(1).hp = 300
	_step(moving, [Command.move(1, moving.tick, Vector2(0, 1))])
	_step(still)
	# Keep the ally next to the moving Capybara.
	for i in _secs(2.0):
		moving.hero_for_player(2).position = moving.hero_for_player(1).position + Vector3(2, 0, 0)
		_step(moving)
		_step(still)
	var gm := moving.hero_for_player(2).hp - 300
	var gs := still.hero_for_player(2).hp - 300
	check(gm > 0 and gs > gm, "aura heals, more when still (%d vs %d)" % [gm, gs])
	check_eq(still.hero_for_player(1).hp, 300, "not Capybara itself")


func test_yuzu_toss_heals_first_ally_and_pauses_refill() -> void:
	var w := _world(capybara, Vector3(0, 0, -5))
	var ally := w.hero_for_player(2)
	var me := w.hero_for_player(1)
	ally.hp = 300
	_cast(w, &"yuzu_toss")
	check_eq(ally.hp, 300 + _ab(capybara, PET, &"yuzu_toss").heal, "healed")
	var energy := me.mech_energy
	_run(w, _secs(1.0))
	check_eq(me.mech_energy, energy, "refill paused")
	_run(w, _secs(_ab(capybara, PET, &"yuzu_toss").duration))
	check(me.mech_energy > energy, "refill resumes")


func test_calm_pulse_shortens_crowd_control() -> void:
	var w := _world(capybara)
	var ally := w.hero_for_player(2)
	Status.add(ally, Status.Kind.STUNNED, w.tick + 120)
	_cast(w, &"calm_pulse")
	var left := Status.until_of(ally, Status.Kind.STUNNED, w.tick) - w.tick
	check(left > 0 and left <= 61, "stun cut by half (%d ticks left)" % left)


func test_hot_spring_heals_and_shields_once() -> void:
	var w := _world(capybara, Vector3(0, 0, -4))
	_to_mech(w)
	var ally := w.hero_for_player(2)
	ally.hp = 300
	var events := _cast(w, &"hot_spring", Vector2(0, -1), 4.0)
	check_eq(w.zones.size(), 1, "pool placed")
	events.append_array(_run(w, _secs(2.0)))
	check(ally.hp > 300, "healing in the pool")
	var shields := _of_type(events, SimEvent.Type.SHIELD).filter(func(e): return e.entity_id == ally.entity_id)
	check_eq(shields.size(), 1, "one shield per pool")
	w.hero_for_player(1).mech_ready[_slot(capybara, MECH, &"hot_spring")] = 0
	_cast(w, &"hot_spring", Vector2(1, 0), 2.0)
	check_eq(w.zones.size(), 1, "a new pool replaces the old")
	_run(w, _secs(_ab(capybara, MECH, &"hot_spring").duration) + 2)
	check(w.zones.is_empty(), "pool runs out")


func test_steam_jet_channels_and_breaks() -> void:
	var w := _world(capybara, Vector3(0, 0, -4))
	_to_mech(w)
	var me := w.hero_for_player(1)
	var ally := w.hero_for_player(2)
	var slot := _slot(capybara, MECH, &"steam_jet")
	_cast(w, &"steam_jet", Vector2(0, 1))
	check(not me.is_channeling() and me.mech_ready[slot] <= w.tick, "no ally there: nothing, no cooldown")
	ally.hp = 200
	_cast(w, &"steam_jet", Vector2(0, -1))
	check(me.is_channeling(), "channeling at the ally")
	_run(w, _secs(1.0))
	var healed := ally.hp - 200
	check(healed > 0, "heals over time (%d)" % healed)
	ally.position = Vector3(0, 0, -20)
	_run(w, 2)
	check(not me.is_channeling(), "breaks out of range")


func test_bubble_shield_targets_ally_or_self() -> void:
	var w := _world(capybara, Vector3(0, 0, -4))
	_to_mech(w)
	var ally := w.hero_for_player(2)
	_cast(w, &"bubble_shield", Vector2(0, -1))
	check_eq(HealSystem.shield_left(w, ally), _ab(capybara, MECH, &"bubble_shield").shield, "ally bubbled")
	var me := w.hero_for_player(1)
	me.mech_ready[_slot(capybara, MECH, &"bubble_shield")] = 0
	_cast(w, &"bubble_shield", Vector2(0, 1))
	check(HealSystem.shield_left(w, me) > 0, "no ally in front: self")


func test_grand_onsen_protects_allies_and_cuts_enemy_healing() -> void:
	var w := _world(capybara, Vector3(2, 0, 0), Vector3(-2, 0, 0))
	_to_mech(w)
	var ally := w.hero_for_player(2)
	var foe := w.hero_for_player(3)
	ally.hp = 300
	_cast(w, &"grand_onsen")
	_run(w, 2)
	check(Status.active(ally, Status.Kind.CC_IMMUNE, w.tick), "ally can't be crowd controlled")
	check(not KnockbackSystem.push(w, ally, Vector2(1, 0), 12.0, 20), "knockback refused")
	check(Status.active(foe, Status.Kind.HEAL_CUT, w.tick), "enemy heal cut")
	_run(w, _secs(1.0))
	check(ally.hp > 300, "allies heal inside")
	ally.position = Vector3(9, 0, 15)
	_run(w, 3)
	check(not Status.active(ally, Status.Kind.CC_IMMUNE, w.tick), "immunity ends on leaving")


# --- whole matches ----------------------------------------------------------------

func test_bots_play_every_kit_and_replay_exactly() -> void:
	var live := SimHarness.match_3v3(7)
	var events: Array[SimEvent] = []
	for i in _secs(150.0):
		events.append_array(live.step())
	live.finish()
	var used := {}
	for e in _of_type(events, SimEvent.Type.ABILITY_CAST):
		used[e.data["ability"]] = true
	for id in ["rocket_jab", "dive_bomb", "steam_jet", "hot_spring"]:
		check(used.has(id), "bots used %s (used: %s)" % [id, used.keys()])
	check(not _of_type(events, SimEvent.Type.HEAL).is_empty(), "healing happened")
	var re := SimHarness.playback(ReplayLog.from_dict(JSON.parse_string(JSON.stringify(live.replay.to_dict()))))
	re.run(_secs(150.0))
	re.finish()
	check_eq(re.desync_tick, -1, "no desync")
	check_eq(re.world.state_hash(), live.world.state_hash(), "same final state")
