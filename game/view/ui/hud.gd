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
var _attack := Label.new()
var _match := Label.new()
var _banner := Label.new()


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
	box.add_child(_attack)
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

	_match.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_match.offset_top = 12
	_match.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_match.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_match.add_theme_font_size_override("font_size", 22)
	add_child(_match)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 64)
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.visible = false
	add_child(_banner)

	var help := Label.new()
	help.text = "WASD move · right-click turn camera · %s attack · %s pet/mech · %s %s %s %s abilities (aim = camera)" % [
		key_name(&"attack"), key_name(&"switch_form"), key_name(&"ability_1"), key_name(&"ability_2"),
		key_name(&"ability_3"), key_name(&"ultimate")]
	help.text += "\nF1 / F2 / F3: restart as Wombat / Weasel / Capybara"
	help.position = Vector2(24, 48)
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

	var atk := _def.attack(form)
	if atk != null:
		var left_atk := int(me["attack_ready"]) - tick
		_attack.text = "[%s] %s%s" % [key_name(&"attack"), atk.display_name, "" if left_atk <= 0 else "  %.1f" % _secs(left_atk)]

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


## Structures, match time, and the result banner. my_team is the local player's.
func update_match(snap: Snapshot, my_team: int) -> void:
	if snap.structures.is_empty():
		_match.text = "Practice"
	else:
		var parts := []
		for team in [my_team, 1 - my_team]:
			var tower := snap.structure(team, StructureState.Kind.TOWER)
			var core := snap.structure(team, StructureState.Kind.CORE)
			parts.append("%s  Tower %s  Core %s" % ["You" if team == my_team else "Enemy",
				_hp_text(tower), _hp_text(core)])
		var secs := snap.tick / _rules.tick_rate
		_match.text = "%s     %d:%02d     %s" % [parts[0], secs / 60, secs % 60, parts[1]]
	_banner.visible = snap.winner != -1
	if _banner.visible:
		_banner.text = "%s\nPress Enter for a new match" % ("VICTORY" if snap.winner == my_team else "DEFEAT")


static func _hp_text(s: Dictionary) -> String:
	if s.is_empty():
		return "-"
	return "down" if s["dead"] else str(s["hp"])


## The key bound to an action, for labels.
static func key_name(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "?"
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return e.as_text_physical_keycode()
		if e is InputEventMouseButton:
			return "LMB" if e.button_index == MOUSE_BUTTON_LEFT else "Mouse %d" % e.button_index
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
