## Turns ability requests into casts. Stateless: all state is in the world.
##
## A request uses a slot of the hero's current form. It casts when the slot
## exists, its cooldown is over, the hero can act (Status.can_act), no other
## cast is in progress and, for abilities that need one, a target is found
## (AbilityRegistry.pick_target); otherwise it is dropped and costs nothing.
## Abilities with a windup root the caster and land later; a stun or death in
## between cancels them. Staged abilities (Rocket Jab, Dive Bomb) schedule
## follow-ups the same way.
## Contact dashes (Wall Crush, Rocket Boost) check for an enemy to hit every
## tick, and channels (Steam Jet) tick until they end or break.
class_name AbilitySystem
extends RefCounted


static func run(world: SimWorld) -> void:
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		var requests := h.ability_requests
		h.ability_requests = []
		for r in requests:
			_try_cast(world, h, r["slot"], r["aim"], r.get("dist", -1.0))
	_resolve_pending(world)
	_run_contact_dashes(world)
	_run_channels(world)


## Queues stage `stage` of the ability in `slot` to run `delay` ticks from now.
## A stun or death of the caster before then cancels it.
static func schedule(world: SimWorld, h: HeroState, slot: int, delay: int, ctx: CastContext, stage: int,
		data: Dictionary = {}) -> void:
	world.pending_casts.append({"at": world.tick + delay, "caster": h.entity_id, "form": h.form,
		"slot": slot, "ax": ctx.aim.x, "az": ctx.aim.y, "d": ctx.dist, "target": ctx.target_id,
		"stage": stage, "data": data})


## The slot a def sits in for h's current form, or ATTACK_SLOT for an attack.
static func slot_of(h: HeroState, def: AbilityDef) -> int:
	return h.def.abilities(h.form).find(def)


static func _try_cast(world: SimWorld, h: HeroState, slot: int, aim: Vector2, dist: float) -> void:
	var def: AbilityDef
	var ready_at: int
	if slot == Command.ATTACK_SLOT:
		def = h.def.attack(h.form)
		ready_at = h.attack_ready
	else:
		var list := h.def.abilities(h.form)
		if slot < 0 or slot >= list.size():
			return
		def = list[slot]
		ready_at = h.ready_for(h.form)[slot]
	if def == null or world.tick < ready_at or not Status.can_act(h, world.tick) \
			or world.has_pending_cast(h.entity_id) or h.is_channeling():
		return
	if aim.length_squared() < 0.000001:
		aim = Vector2(-sin(h.facing), -cos(h.facing))
	var ctx := CastContext.new(aim, dist)
	ctx.target_id = AbilityRegistry.pick_target(world, h, def, ctx)
	if ctx.target_id == AbilityRegistry.NO_VALID_TARGET:
		return
	var cooldown := def.cooldown
	if FrenzyRun.waives_cooldown(world, h, def):
		cooldown = 0.0
	var next := world.tick + world.rules.seconds_to_ticks(cooldown)
	if slot == Command.ATTACK_SLOT:
		h.attack_ready = next
	else:
		h.ready_for(h.form)[slot] = next
	h.facing = atan2(-aim.x, -aim.y)
	var windup := world.rules.seconds_to_ticks(def.windup)
	var info := {"ability": String(def.id), "slot": slot, "windup": windup, "radius": def.radius}
	if def.targets_point:
		var p := AbilityRegistry.ground_point(world, h, def, ctx)
		info["tx"] = p.x
		info["tz"] = p.z
	world.emit(SimEvent.new(SimEvent.Type.ABILITY_CAST, world.tick, h.entity_id, info))
	if windup > 0:
		schedule(world, h, slot, windup, ctx, 0)
		Status.add(h, Status.Kind.ROOTED, world.tick + windup)
		AbilityRegistry.on_windup(world, h, def, ctx, windup)
		return
	AbilityRegistry.cast(world, h, def, ctx)


static func _resolve_pending(world: SimWorld) -> void:
	var due: Array = []
	var still: Array = []
	for p in world.pending_casts:
		var h: HeroState = world.heroes.get(p["caster"])
		if h == null or h.dead or Status.active(h, Status.Kind.STUNNED, world.tick):
			continue  # Cancelled.
		if world.tick < p["at"]:
			still.append(p)
		else:
			due.append(p)
	# Casts may schedule follow-ups, so the list is replaced before they run.
	world.pending_casts = still
	for p in due:
		var h: HeroState = world.heroes[p["caster"]]
		var def: AbilityDef = h.def.abilities(p["form"])[p["slot"]]
		var ctx := CastContext.new(Vector2(p["ax"], p["az"]), p["d"], p["target"], p["stage"], p["data"])
		if ctx.stage == 0:
			AbilityRegistry.cast(world, h, def, ctx)
		else:
			AbilityRegistry.follow_up(world, h, def, ctx)


static func _run_contact_dashes(world: SimWorld) -> void:
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		if h.dash_ability == null:
			continue
		if h.dead or not h.is_forced(world.tick):
			h.dash_ability = null
			continue
		var hit := AbilityUtil.first_enemy_touching(world, h, 0.3)
		if hit != null:
			var def := h.dash_ability
			h.dash_ability = null
			h.forced_until = world.tick
			h.velocity = Vector3.ZERO
			AbilityRegistry.on_dash_contact(world, h, def, hit)


static func _run_channels(world: SimWorld) -> void:
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		if not h.is_channeling():
			continue
		var target := world.unit(h.channel_target)
		if h.dead or world.tick >= h.channel_until or target == null \
				or Status.active(h, Status.Kind.STUNNED, world.tick) \
				or not AbilityRegistry.channel_tick(world, h, h.channel_ability, target):
			h.stop_channel()
