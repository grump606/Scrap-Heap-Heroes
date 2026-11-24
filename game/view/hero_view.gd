## Visual for one hero. Holds no gameplay state: it is positioned from
## snapshots and interpolated between the last two ticks.
class_name HeroView
extends Node3D

const TEAM_COLORS := [Color(0.25, 0.55, 1.0), Color(1.0, 0.4, 0.25)]

var entity_id: int


func setup(p_entity_id: int, team: int) -> void:
	entity_id = p_entity_id
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.5
	capsule.height = 1.6
	body.mesh = capsule
	body.position.y = 0.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = TEAM_COLORS[team % TEAM_COLORS.size()]
	body.material_override = mat
	add_child(body)
	# A nose so facing is readable.
	var nose := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.25, 0.25, 0.5)
	nose.mesh = box
	nose.position = Vector3(0, 1.1, -0.55)
	nose.material_override = mat
	add_child(nose)


func render(prev: Dictionary, cur: Dictionary, alpha: float) -> void:
	var a: Vector3 = prev.get("position", cur["position"])
	position = a.lerp(cur["position"], alpha)
	rotation.y = lerp_angle(prev.get("facing", cur["facing"]), cur["facing"], alpha)
