## Visual for one hero. Holds no gameplay state: it is positioned from
## snapshots and interpolated between the last two ticks.
## Placeholder art: a small capsule for pet form, a chunky box for mech form,
## and a floating label with health and active statuses.
class_name HeroView
extends Node3D

const TEAM_COLORS := [Color(0.25, 0.55, 1.0), Color(1.0, 0.4, 0.25)]
## Scale kick when the form changes, easing back to 1.
const SWITCH_POP := 1.3
const POP_SPEED := 12.0
const STATUS_TAGS := {
	Status.Kind.SLOW: "SLOW", Status.Kind.ARMOR: "HIDE+", Status.Kind.ROOTED: "ROOTED",
	Status.Kind.STUNNED: "STUN", Status.Kind.VULNERABLE: "EJECTED",
}

var entity_id: int
## Off for the local player's own hero: the HUD shows the same thing.
var show_label := true:
	set(v):
		show_label = v
		_label.visible = v

var _pet := Node3D.new()
var _mech := Node3D.new()
var _label := Label3D.new()
var _form: int = -1
var _pop: float = 1.0


func setup(p_entity_id: int, team: int) -> void:
	entity_id = p_entity_id
	var color: Color = TEAM_COLORS[team % TEAM_COLORS.size()]

	var pet_body := CapsuleMesh.new()
	pet_body.radius = 0.4
	pet_body.height = 1.1
	ViewParts.add_part(_pet, pet_body, Vector3(0, 0.55, 0), color)
	ViewParts.add_part(_pet, ViewParts.box(Vector3(0.2, 0.2, 0.4)), Vector3(0, 0.75, -0.45), color)
	add_child(_pet)

	var hull := color.darkened(0.35)
	ViewParts.add_part(_mech, ViewParts.box(Vector3(1.3, 1.4, 1.1)), Vector3(0, 1.0, 0), hull)
	ViewParts.add_part(_mech, ViewParts.box(Vector3(0.5, 0.35, 0.6)), Vector3(0, 1.35, -0.75), color)
	ViewParts.add_part(_mech, ViewParts.box(Vector3(0.35, 0.3, 0.35)), Vector3(-0.4, 0.15, 0), hull)
	ViewParts.add_part(_mech, ViewParts.box(Vector3(0.35, 0.3, 0.35)), Vector3(0.4, 0.15, 0), hull)
	add_child(_mech)

	ViewParts.style_label(_label, 40)
	_label.position = Vector3(0, 2.4, 0)
	add_child(_label)


func render(prev: Dictionary, cur: Dictionary, alpha: float, tick: int, _snap: Snapshot = null) -> void:
	visible = not cur.get("dead", false)
	if not visible:
		return
	var a: Vector3 = prev.get("position", cur["position"])
	position = a.lerp(cur["position"], alpha)
	rotation.y = lerp_angle(prev.get("facing", cur["facing"]), cur["facing"], alpha)
	var form: int = cur["form"]
	if form != _form:
		if _form != -1:
			_pop = SWITCH_POP
		_form = form
		_pet.visible = form == HeroState.Form.PET
		_mech.visible = form == HeroState.Form.MECH
		_label.position.y = 2.6 if form == HeroState.Form.MECH else 1.7
	_label.text = "%d%s" % [cur["hp"], status_text(cur.get("statuses", []), tick)]


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
