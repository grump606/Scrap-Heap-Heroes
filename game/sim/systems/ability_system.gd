## Turns ability requests into casts. Stateless: all state is in the world.
##
## A request uses a slot of the hero's current form. It casts when the slot
## exists, its cooldown is over, the hero can act (Status.can_act) and no other
## cast is winding up; otherwise it is dropped. Abilities with a windup root
## the caster and land later; a stun or death in between cancels them.
## Contact dashes (Wall Crush) check for an enemy to hit every tick.
class_name AbilitySystem
extends RefCounted


static func run(world: SimWorld) -> void:
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		var requests := h.ability_requests
		h.ability_requests = []
		for r in requests:
			_try_cast(world, h, r["slot"], r["aim"])
	_resolve_windups(world)
	_run_contact_dashes(world)


static func _try_cast(world: SimWorld, h: HeroState, slot: int, aim: Vector2) -> void:
	var list := h.def.abilities(h.form)
	if slot < 0 or slot >= list.size():
		return
	var ready := h.ready_for(h.form)
	if world.tick < ready[slot] or not Status.can_act(h, world.tick) or world.has_pending_cast(h.entity_id):
		return
	var def := list[slot]
	if aim.length_squared() < 0.000001:
		aim = Vector2(-sin(h.facing), -cos(h.facing))
	ready[slot] = world.tick + world.rules.seconds_to_ticks(def.cooldown)
	h.facing = atan2(-aim.x, -aim.y)
	var windup := world.rules.seconds_to_ticks(def.windup)
	world.emit(SimEvent.new(SimEvent.Type.ABILITY_CAST, world.tick, h.entity_id, {
		"ability": String(def.id), "slot": slot, "windup": windup, "radius": def.radius,
	}))
	if windup > 0:
		world.pending_casts.append({"at": world.tick + windup, "caster": h.entity_id,
			"form": h.form, "slot": slot, "ax": aim.x, "az": aim.y})
		Status.add(h, Status.Kind.ROOTED, world.tick + windup)
		return
	AbilityRegistry.cast(world, h, def, aim)


static func _resolve_windups(world: SimWorld) -> void:
	var still: Array = []
	for p in world.pending_casts:
		var h: HeroState = world.heroes.get(p["caster"])
		if h == null or h.dead or Status.active(h, Status.Kind.STUNNED, world.tick):
			continue  # Cancelled.
		if world.tick < p["at"]:
			still.append(p)
			continue
		var def: AbilityDef = h.def.abilities(p["form"])[p["slot"]]
		AbilityRegistry.cast(world, h, def, Vector2(p["ax"], p["az"]))
	world.pending_casts = still


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
