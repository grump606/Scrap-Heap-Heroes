## Pet/mech switching. Stateless: all state is in the world.
##
## A request is applied when it names the other form and the switch cooldown
## has passed. Otherwise it is dropped, not queued, so a press during cooldown
## never fires later by surprise. The mech meter, its drain and the eject
## arrive with the Core kit.
class_name FormSystem
extends RefCounted


static func run(world: SimWorld) -> void:
	var cooldown := world.rules.seconds_to_ticks(world.rules.form_switch_cooldown)
	for id in world.sorted_hero_ids():
		var h: HeroState = world.heroes[id]
		var want := h.form_request
		h.form_request = HeroState.NO_REQUEST
		if want == HeroState.NO_REQUEST or want == h.form or not HeroState.Form.values().has(want):
			continue
		if world.tick < h.switch_ready_tick:
			continue
		h.form = want
		h.move_speed = h.def.move_speed(want)
		h.switch_ready_tick = world.tick + cooldown
		world.emit(SimEvent.new(SimEvent.Type.FORM_SWITCH, world.tick, h.entity_id, {"form": want}))
