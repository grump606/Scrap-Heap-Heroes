## Visual for one hero. Holds no gameplay state: it is positioned from
## snapshots and interpolated between the last two ticks.
## Placeholder art per hero (a rough silhouette for pet form, a chunky box
## for mech form), a bubble while shielded, a hop for airborne arcs, a steam
## beam while channeling, and a floating label with health and statuses.
class_name HeroView
extends Node3D

const TEAM_COLORS := [Color(0.25, 0.55, 1.0), Color(1.0, 0.4, 0.25)]
## Scale kick when the form changes, easing back to 1.
const SWITCH_POP := 1.3
const POP_SPEED := 12.0
const STATUS_TAGS := {
	Status.Kind.SLOW: "SLOW", Status.Kind.ARMOR: "HIDE+", Status.Kind.ROOTED: "ROOTED",
	Status.Kind.STUNNED: "STUN", Status.Kind.VULNERABLE: "EJECTED", Status.Kind.SHIELD: "SHIELD",
	Status.Kind.HASTE: "FAST", Status.Kind.HEAL_CUT: "HEAL-", Status.Kind.CC_IMMUNE: "CALM",
	Status.Kind.NO_REFILL: "NO REFILL", Status.Kind.FRENZY: "FRENZY",
}
const STEAM_COLOR := Color(0.75, 0.95, 1.0, 0.55)

var entity_id: int
## Off for the local player's own hero: the HUD shows the same thing.
var show_label := true:
	set(v):
		show_label = v
		_label.visible = v

var _pet := Node3D.new()
var _mech := Node3D.new()
var _label := Label3D.new()
var _bubble := MeshInstance3D.new()
var _beam := MeshInstance3D.new()
var _form: int = -1
var _pop: float = 1.0


func setup(p_entity_id: int, team: int, hero_id: StringName = &"") -> void:
	entity_id = p_entity_id
	var color: Color = TEAM_COLORS[team % TEAM_COLORS.size()]
	_build_pet(hero_id, color)
	add_child(_pet)

	var hull := color.darkened(0.35)
	var accent := _accent(hero_id)
	ViewParts.add_part(_mech, ViewParts.box(Vector3(1.3, 1.4, 1.1)), Vector3(0, 1.0, 0), hull)
	ViewParts.add_part(_mech, ViewParts.box(Vector3(0.5, 0.35, 0.6)), Vector3(0, 1.35, -0.75), color)
	ViewParts.add_part(_mech, ViewParts.box(Vector3(0.35, 0.3, 0.35)), Vector3(-0.4, 0.15, 0), hull)
	ViewParts.add_part(_mech, ViewParts.box(Vector3(0.35, 0.3, 0.35)), Vector3(0.4, 0.15, 0), hull)
	# A hero-colored stripe on the hull says who's inside.
	ViewParts.add_part(_mech, ViewParts.box(Vector3(1.34, 0.25, 1.14)), Vector3(0, 1.45, 0), accent)
	if hero_id == &"weasel":
		ViewParts.add_part(_mech, ViewParts.box(Vector3(0.3, 0.7, 0.3)), Vector3(-0.35, 1.1, 0.7), accent)
		ViewParts.add_part(_mech, ViewParts.box(Vector3(0.3, 0.7, 0.3)), Vector3(0.35, 1.1, 0.7), accent)
	add_child(_mech)

	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	_bubble.mesh = sphere
	_bubble.material_override = ViewParts.glow(Color(0.6, 0.85, 1.0, 0.22))
	_bubble.visible = false
	add_child(_bubble)

	var c := CylinderMesh.new()
	c.top_radius = 0.12
	c.bottom_radius = 0.12
	c.height = 1.0
	_beam.mesh = c
	_beam.material_override = ViewParts.glow(STEAM_COLOR)
	_beam.visible = false
	_beam.top_level = true
	add_child(_beam)

	ViewParts.style_label(_label, 40)
	_label.position = Vector3(0, 2.4, 0)
	add_child(_label)


func _build_pet(hero_id: StringName, color: Color) -> void:
	match hero_id:
		&"weasel":
			# Long and low, with a raised head.
			var body := CapsuleMesh.new()
			body.radius = 0.25
			body.height = 1.3
			var b := ViewParts.add_part(_pet, body, Vector3(0, 0.35, 0), color)
			b.rotation.x = PI * 0.5
			ViewParts.add_part(_pet, ViewParts.box(Vector3(0.28, 0.28, 0.35)), Vector3(0, 0.6, -0.7), color)
		&"capybara":
			# A round barrel with a blunt square snout.
			var body := SphereMesh.new()
			body.radius = 0.5
			body.height = 0.9
			ViewParts.add_part(_pet, body, Vector3(0, 0.5, 0), color)
			ViewParts.add_part(_pet, ViewParts.box(Vector3(0.4, 0.35, 0.35)), Vector3(0, 0.6, -0.5), color.darkened(0.15))
			ViewParts.add_part(_pet, ViewParts.box(Vector3(0.25, 0.12, 0.25)), Vector3(0, 1.0, 0), Color(1.0, 0.8, 0.2))
		_:
			var body := CapsuleMesh.new()
			body.radius = 0.4
			body.height = 1.1
			ViewParts.add_part(_pet, body, Vector3(0, 0.55, 0), color)
			ViewParts.add_part(_pet, ViewParts.box(Vector3(0.2, 0.2, 0.4)), Vector3(0, 0.75, -0.45), color)


static func _accent(hero_id: StringName) -> Color:
	match hero_id:
		&"weasel": return Color(0.95, 0.85, 0.2)
		&"capybara": return Color(0.4, 0.9, 0.6)
	return Color(0.6, 0.45, 0.3)


func render(prev: Dictionary, cur: Dictionary, alpha: float, tick: int, snap: Snapshot = null) -> void:
	visible = not cur.get("dead", false)
	if not visible:
		_beam.visible = false
		return
	var a: Vector3 = prev.get("position", cur["position"])
	position = a.lerp(cur["position"], alpha)
	position.y = _air(cur, tick + alpha)
	rotation.y = lerp_angle(prev.get("facing", cur["facing"]), cur["facing"], alpha)
	var form: int = cur["form"]
	if form != _form:
		if _form != -1:
			_pop = SWITCH_POP
		_form = form
		_pet.visible = form == HeroState.Form.PET
		_mech.visible = form == HeroState.Form.MECH
		_label.position.y = 2.6 if form == HeroState.Form.MECH else 1.7
	var statuses: Array = cur.get("statuses", [])
	var shield := shield_left(statuses, tick)
	_bubble.visible = shield > 0
	if _bubble.visible:
		var r: float = float(cur["radius"]) + 0.4
		_bubble.scale = Vector3(r, r * 1.1, r)
		_bubble.position.y = r
	_label.text = "%d%s%s" % [cur["hp"], " +%d" % shield if shield > 0 else "", status_text(statuses, tick)]
	_render_beam(cur, snap)


## Height on an airborne arc (a parabola from air_start to air_end).
static func _air(cur: Dictionary, t: float) -> float:
	var s := float(cur.get("air_start", 0))
	var e := float(cur.get("air_end", 0))
	if e <= s or t < s or t > e:
		return 0.0
	var u := (t - s) / (e - s)
	return 4.0 * float(cur.get("air_height", 0.0)) * u * (1.0 - u)


func _render_beam(cur: Dictionary, snap: Snapshot) -> void:
	var target_id := int(cur.get("channel_target", 0))
	var target: Dictionary = snap.heroes.get(target_id, {}) if snap != null and target_id != 0 else {}
	_beam.visible = not target.is_empty()
	if not _beam.visible:
		return
	var from := global_position + Vector3(0, 1.2, 0)
	var to: Vector3 = target["position"] + Vector3(0, 0.8, 0)
	var length := from.distance_to(to)
	if length < 0.05:
		_beam.visible = false
		return
	var dir := (to - from) / length
	var axis := Vector3.UP.cross(dir)
	var basis := Basis.IDENTITY
	if axis.length() > 0.0001:
		basis = Basis(axis.normalized(), Vector3.UP.angle_to(dir))
	_beam.global_transform = Transform3D(basis * Basis.from_scale(Vector3(1, length, 1)),(from + to) * 0.5)


static func shield_left(statuses: Array, tick: int) -> int:
	var sum := 0
	for s in statuses:
		if int(s["kind"]) == Status.Kind.SHIELD and tick < int(s["until"]):
			sum += int(s["value"])
	return sum


## " SLOW BRACED" etc. for the statuses active at tick.
static func status_text(statuses: Array, tick: int) -> String:
	var tags := []
	for s in statuses:
		var tag: String = STATUS_TAGS.get(int(s["kind"]), "")
		if tick < int(s["until"]) and tag != "" and not tags.has(tag):
			tags.append(tag)
	return "" if tags.is_empty() else "\n" + " ".join(tags)


func _process(delta: float) -> void:
	_pop = lerpf(_pop, 1.0, 1.0 - exp(-POP_SPEED * delta))
	_pet.scale = Vector3.ONE * _pop
	_mech.scale = Vector3.ONE * _pop
