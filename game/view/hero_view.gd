## Visual for one hero. Holds no gameplay state: it is positioned from
## snapshots and interpolated between the last two ticks.
## Placeholder art: a small capsule for pet form, a chunky box for mech form.
class_name HeroView
extends Node3D

const TEAM_COLORS := [Color(0.25, 0.55, 1.0), Color(1.0, 0.4, 0.25)]
## Scale kick when the form changes, easing back to 1.
const SWITCH_POP := 1.3
const POP_SPEED := 12.0

var entity_id: int

var _pet := Node3D.new()
var _mech := Node3D.new()
var _form: int = -1
var _pop: float = 1.0


func setup(p_entity_id: int, team: int) -> void:
	entity_id = p_entity_id
	var color: Color = TEAM_COLORS[team % TEAM_COLORS.size()]

	var pet_body := CapsuleMesh.new()
	pet_body.radius = 0.4
	pet_body.height = 1.1
	_add_part(_pet, pet_body, Vector3(0, 0.55, 0), color)
	_add_part(_pet, _box(Vector3(0.2, 0.2, 0.4)), Vector3(0, 0.75, -0.45), color)
	add_child(_pet)

	var hull := color.darkened(0.35)
	_add_part(_mech, _box(Vector3(1.3, 1.4, 1.1)), Vector3(0, 1.0, 0), hull)
	_add_part(_mech, _box(Vector3(0.5, 0.35, 0.6)), Vector3(0, 1.35, -0.75), color)  # cockpit / nose
	_add_part(_mech, _box(Vector3(0.35, 0.3, 0.35)), Vector3(-0.4, 0.15, 0), hull)  # feet
	_add_part(_mech, _box(Vector3(0.35, 0.3, 0.35)), Vector3(0.4, 0.15, 0), hull)
	add_child(_mech)


func render(prev: Dictionary, cur: Dictionary, alpha: float) -> void:
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


func _process(delta: float) -> void:
	_pop = lerpf(_pop, 1.0, 1.0 - exp(-POP_SPEED * delta))
	scale = Vector3.ONE * _pop


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _add_part(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	parent.add_child(m)
