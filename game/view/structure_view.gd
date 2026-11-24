## Visual for a tower or Power Core: team-colored, with a health label.
## Rubble when destroyed; a core shows "SHIELDED" while its tower stands.
class_name StructureView
extends Node3D

var entity_id: int
var _body := Node3D.new()
var _label := Label3D.new()
var _kind: int
var _team: int


func setup(p_entity_id: int, team: int, kind: int, radius: float) -> void:
	entity_id = p_entity_id
	_team = team
	_kind = kind
	var color: Color = HeroView.TEAM_COLORS[team % HeroView.TEAM_COLORS.size()]
	var stone := Color(0.5, 0.48, 0.45)
	if kind == StructureState.Kind.TOWER:
		var base := CylinderMesh.new()
		base.top_radius = radius * 0.8
		base.bottom_radius = radius
		base.height = 4.0
		ViewParts.add_part(_body, base, Vector3(0, 2.0, 0), stone)
		var top := CylinderMesh.new()
		top.top_radius = radius * 1.05
		top.bottom_radius = radius * 0.9
		top.height = 0.8
		ViewParts.add_part(_body, top, Vector3(0, 4.4, 0), color)
		_label.position = Vector3(0, 5.6, 0)
	else:
		var plinth := CylinderMesh.new()
		plinth.top_radius = radius
		plinth.bottom_radius = radius * 1.1
		plinth.height = 0.8
		ViewParts.add_part(_body, plinth, Vector3(0, 0.4, 0), stone)
		var crystal := SphereMesh.new()
		crystal.radius = radius * 0.75
		crystal.height = radius * 1.6
		var c := ViewParts.add_part(_body, crystal, Vector3(0, 1.9, 0), color)
		(c.material_override as StandardMaterial3D).emission_enabled = true
		(c.material_override as StandardMaterial3D).emission = color * 0.6
		_label.position = Vector3(0, 3.6, 0)
	add_child(_body)
	ViewParts.style_label(_label, 30)
	# Constant on-screen size: a structure's label shouldn't fill the screen
	# when the camera passes right by it.
	_label.fixed_size = true
	_label.pixel_size = 0.0012
	# Far structures are read from the HUD's match bar instead.
	_label.visibility_range_end = 30.0
	add_child(_label)


func render(_prev: Dictionary, cur: Dictionary, _alpha: float, _tick: int, snap: Snapshot) -> void:
	position = cur["position"]
	var dead: bool = cur["dead"]
	_body.scale = Vector3(1, 0.25, 1) if dead else Vector3.ONE
	var name := "Tower" if _kind == StructureState.Kind.TOWER else "Power Core"
	if dead:
		_label.text = "%s destroyed" % name
		return
	var shielded: bool = _kind == StructureState.Kind.CORE \
		and not snap.structure(_team, StructureState.Kind.TOWER).get("dead", true)
	_label.text = "%s %d%s" % [name, cur["hp"], "\nSHIELDED" if shielded else ""]
