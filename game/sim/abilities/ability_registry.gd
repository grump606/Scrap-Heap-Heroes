## Maps AbilityDef.logic to the script that runs it. The sim never loads
## files, so every ability script is listed here by class name.
##
## Adding an ability: write game/sim/abilities/<name>.gd with
## `static func cast(world, caster, def, ctx: CastContext)`, add it to KNOWN
## and to cast() below, and to any of the optional hooks it uses:
## - pick_target: the ability needs a unit picked at the press;
## - on_windup: something happens when the windup starts (Dive Bomb's rise);
## - follow_up: stages it scheduled with AbilitySystem.schedule;
## - on_dash_contact: a contact dash touched an enemy;
## - channel_tick: a channel it started (HeroState.channel_*) ticks;
## - zone_tick: a zone it placed (SimWorld.add_zone) ticks;
## - passive_tick: it is a hero's passive (HeroDef.passive).
class_name AbilityRegistry
extends RefCounted

## pick_target result: the ability needs a target and none was found, so the
## press is dropped. 0 means no target was needed.
const NO_VALID_TARGET := -1

const KNOWN: Array[StringName] = [
	&"basic_attack",
	&"dust_bath", &"mud_slide", &"rump_bump", &"wall_crush", &"brace", &"burrow_burst",
	&"sprint", &"pounce", &"rocket_boost", &"dive_bomb", &"rocket_jab", &"frenzy_run",
	&"chill_aura", &"yuzu_toss", &"calm_pulse", &"hot_spring", &"steam_jet", &"bubble_shield", &"grand_onsen",
]


static func cast(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	match def.logic:
		&"basic_attack": BasicAttack.cast(world, caster, def, ctx)
		&"dust_bath": DustBath.cast(world, caster, def, ctx)
		&"mud_slide": MudSlide.cast(world, caster, def, ctx)
		&"rump_bump": RumpBump.cast(world, caster, def, ctx)
		&"wall_crush": WallCrush.cast(world, caster, def, ctx)
		&"brace": Brace.cast(world, caster, def, ctx)
		&"burrow_burst": BurrowBurst.cast(world, caster, def, ctx)
		&"sprint": Sprint.cast(world, caster, def, ctx)
		&"pounce": Pounce.cast(world, caster, def, ctx)
		&"rocket_boost": RocketBoost.cast(world, caster, def, ctx)
		&"dive_bomb": DiveBomb.cast(world, caster, def, ctx)
		&"rocket_jab": RocketJab.cast(world, caster, def, ctx)
		&"frenzy_run": FrenzyRun.cast(world, caster, def, ctx)
		&"yuzu_toss": YuzuToss.cast(world, caster, def, ctx)
		&"calm_pulse": CalmPulse.cast(world, caster, def, ctx)
		&"hot_spring": HotSpring.cast(world, caster, def, ctx)
		&"steam_jet": SteamJet.cast(world, caster, def, ctx)
		&"bubble_shield": BubbleShield.cast(world, caster, def, ctx)
		&"grand_onsen": GrandOnsen.cast(world, caster, def, ctx)
		_: push_error("ability '%s' has unknown logic '%s'" % [def.id, def.logic])


## The unit an ability is aimed at, picked at the press: an entity id, 0 if
## the ability doesn't need one, or NO_VALID_TARGET.
static func pick_target(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> int:
	match def.logic:
		&"dive_bomb": return DiveBomb.pick_target(world, caster, def, ctx)
		&"steam_jet": return SteamJet.pick_target(world, caster, def, ctx)
		&"bubble_shield": return BubbleShield.pick_target(world, caster, def, ctx)
	return 0


## Where a ground-targeted ability (def.targets_point) will land.
static func ground_point(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> Vector3:
	var target := world.unit(ctx.target_id) if ctx.target_id > 0 else null
	if target != null:
		return target.position
	var p := ctx.point(caster.position, def.reach)
	var r := world.rules
	return Vector3(clampf(p.x, -r.arena_half_width, r.arena_half_width), 0.0,
		clampf(p.z, -r.arena_half_length, r.arena_half_length))


static func on_windup(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext, ticks: int) -> void:
	match def.logic:
		&"dive_bomb": DiveBomb.on_windup(world, caster, def, ctx, ticks)


static func follow_up(world: SimWorld, caster: HeroState, def: AbilityDef, ctx: CastContext) -> void:
	match def.logic:
		&"dive_bomb": DiveBomb.follow_up(world, caster, def, ctx)
		&"rocket_jab": RocketJab.follow_up(world, caster, def, ctx)
		_: push_error("ability '%s' has no follow-up" % def.id)


## A contact dash (see AbilitySystem) touched an enemy.
static func on_dash_contact(world: SimWorld, caster: HeroState, def: AbilityDef, target: UnitState) -> void:
	match def.logic:
		&"wall_crush": WallCrush.on_contact(world, caster, def, target)
		&"rocket_boost": RocketBoost.on_contact(world, caster, def, target)
		_: push_error("ability '%s' has no dash contact" % def.id)


## One tick of a channel. Returns false when the channel breaks.
static func channel_tick(world: SimWorld, caster: HeroState, def: AbilityDef, target: UnitState) -> bool:
	match def.logic:
		&"steam_jet": return SteamJet.channel_tick(world, caster, def, target)
	return false


static func zone_tick(world: SimWorld, zone: ZoneState) -> void:
	match zone.def.logic:
		&"hot_spring": HotSpring.zone_tick(world, zone)
		&"grand_onsen": GrandOnsen.zone_tick(world, zone)


static func passive_tick(world: SimWorld, hero: HeroState, def: AbilityDef) -> void:
	match def.logic:
		&"chill_aura": ChillAura.passive_tick(world, hero, def)
		_: push_error("passive '%s' has unknown logic '%s'" % [def.id, def.logic])
