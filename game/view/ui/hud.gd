## Heads-up display for the local hero: health, mech meter, form and switch
## state, and the current form's abilities with their cooldowns.
## Reads the snapshot and the hero's data only; never touches the sim.
class_name Hud
extends CanvasLayer

const SLOT_ACTIONS: Array[StringName] = [&"ability_1", &"ability_2", &"ability_3", &"ultimate"]

var _rules: MatchRules
var _def: HeroDef
var _title := Label.new()
var _status := Label.new()
var _hp := ProgressBar.new()
var _energy := ProgressBar.new()
var _switch := Label.new()
var _slots: Array[Label] = []
var _slot_panels: Array[PanelContainer] = []


func setup(rules: MatchRules, def: HeroDef) -> void:
	_rules = rules
	_def = def
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	root.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_theme_constant_override("margin_left", 24)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(520, 0)
	root.add_child(box)

	_title.add_theme_font_size_override("font_size", 26)
	box.add_child(_title)
	_status.add_theme_color_override("font_color", Color(1, 0.55, 0.4))
	box.add_child(_status)
	box.add_child(_bar_row("HP", _hp, Color(0.35, 0.8, 0.4)))
	box.add_child(_bar_row("Mech", _energy, Color(0.95, 0.75, 0.2)))
	box.add_child(_switch)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for i in SLOT_ACTIONS.size():
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(140, 64)
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		panel.add_child(l)
		row.add_child(panel)
		_slots.append(l)
		_slot_panels.append(panel)

	var help := Label.new()
	help.text = "WASD move · right-click turn camera · %s pet/mech · %s %s %s %s abilities (aim = camera)" % [
		key_name(&"switch_form"), key_name(&"ability_1"), key_name(&"ability_2"),
		key_name(&"ability_3"), key_name(&"ultimate")]
	help.position = Vector2(24, 16)
	help.modulate = Color(1, 1, 1, 0.75)
	add_child(help)


## me: the local hero's snapshot dict.
func update(me: Dictionary, tick: int) -> void:
	if me.is_empty() or _def == null:
		return
	var form: int = me["form"]
	var mech := form == HeroState.Form.MECH
	_title.text = "%s · %s" % [_def.display_name, "MECH" if mech else "PET"]

	if me["dead"]:
		_status.text = "Down. Respawn in %.1f s" % _secs(int(me["respawn_tick"]) - tick)
	else:
		_status.text = HeroView.status_text(me["statuses"], tick).strip_edges()

	_hp.max_value = me["max_hp"]
	_hp.value = me["hp"]
	_energy.max_value = _rules.mech_energy_max
	_energy.value = me["mech_energy"]

	var wait := int(me["switch_ready_tick"]) - tick
	var key := key_name(&"switch_form")
	if wait > 0:
		_switch.text = "[%s] switch form in %.1f s" % [key, _secs(wait)]
	elif not mech and me["mech_energy"] < _rules.mech_min_energy_to_switch:
		_switch.text = "[%s] mech needs %d energy" % [key, int(_rules.mech_min_energy_to_switch)]
	else:
		_switch.text = "[%s] switch to %s" % [key, "pet" if mech else "mech"]

	var abilities := _def.abilities(form)
	var ready: Array = me["mech_ready" if mech else "pet_ready"]
	for i in _slots.size():
		_slot_panels[i].visible = i < abilities.size()
		if i >= abilities.size():
			continue
		var a := abilities[i]
		var left := int(ready[i]) - tick
		var state := "ready" if left <= 0 else "%.1f" % _secs(left)
		_slots[i].text = "[%s] %s\n%s" % [key_name(SLOT_ACTIONS[i]), a.display_name, state]
		_slot_panels[i].modulate = Color(1, 1, 1, 1.0 if left <= 0 else 0.55)
		if a.is_ultimate:
			_slots[i].add_theme_color_override("font_color", Color(1, 0.8, 0.3))


## The key bound to an action, for labels.
static func key_name(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "?"
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return e.as_text_physical_keycode()
	return "?"


func _secs(ticks: int) -> float:
	return maxf(ticks, 0) / float(_rules.tick_rate)


func _bar_row(label: String, bar: ProgressBar, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(60, 0)
	row.add_child(l)
	bar.custom_minimum_size = Vector2(320, 22)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	return row
