## Pet/mech switching and the mech meter. Stateless: all state is in the world.
##
## - A switch request applies when it names the other form, the cooldown has
##   passed, the hero can act (not stunned, ejected or mid-dash/knockback) and,
##   for mech, the meter holds at least mech_min_energy_to_switch. Otherwise it
##   is dropped, not queued, so a press never fires later by surprise.
## - Mech form drains the meter; pet form refills it, unless NO_REFILL (Yuzu Toss).
## - Switching ends any channel (Steam Jet).
## - An empty meter ejects the hero to pet form, briefly vulnerable.
class_name FormSystem
extends RefCounted


static func run(world: SimWorld) -> void:
	var rules := world.rules
	var cooldown := rules.seconds_to_ticks(rules.form_switch_cooldown)
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		var want := h.form_request
		h.form_request = HeroState.NO_REQUEST
		if h.dead:
			continue
		if _can_switch(world, h, want):
			h.stop_channel()
			h.apply_form(want)
			h.switch_ready_tick = world.tick + cooldown
			world.emit(SimEvent.new(SimEvent.Type.FORM_SWITCH, world.tick, h.entity_id, {"form": want}))

		if h.form == HeroState.Form.MECH:
			h.mech_energy -= rules.mech_drain_per_second * world.tick_dt
			if h.mech_energy <= 0.0:
				_eject(world, h, cooldown)
		elif not Status.active(h, Status.Kind.NO_REFILL, world.tick):
			h.mech_energy = minf(h.mech_energy + rules.pet_refill_per_second * world.tick_dt, rules.mech_energy_max)


static func _can_switch(world: SimWorld, h: HeroState, want: int) -> bool:
	if want == HeroState.NO_REQUEST or want == h.form or not HeroState.Form.values().has(want):
		return false
	if world.tick < h.switch_ready_tick or not Status.can_act(h, world.tick):
		return false
	if world.has_pending_cast(h.entity_id):
		return false
	if want == HeroState.Form.MECH and h.mech_energy < world.rules.mech_min_energy_to_switch:
		return false
	return true


static func _eject(world: SimWorld, h: HeroState, cooldown: int) -> void:
	h.mech_energy = 0.0
	h.stop_channel()
	h.apply_form(HeroState.Form.PET)
	h.switch_ready_tick = world.tick + cooldown
	Status.add(h, Status.Kind.VULNERABLE, world.tick + world.rules.seconds_to_ticks(world.rules.eject_vulnerable_time))
	world.emit(SimEvent.new(SimEvent.Type.EJECT, world.tick, h.entity_id))
	world.emit(SimEvent.new(SimEvent.Type.FORM_SWITCH, world.tick, h.entity_id, {"form": HeroState.Form.PET}))
