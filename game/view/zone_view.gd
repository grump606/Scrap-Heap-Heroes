## Visual for a lasting ground area (Hot Spring, Grand Onsen): a tinted
## disc with a bright rim, fading out over its last second. Grand Onsen is
## drawn larger and gold so everyone can read it.
class_name ZoneView
extends Node3D

var entity_id: int
var _disc := MeshInstance3D.new()
var _rim := MeshInstance3D.new()
var _mat: StandardMaterial3D
var _base_alpha := 0.3


func setup(p_entity_id: int, team: int, ability: String, radius: float) -> void:
	entity_id = p_entity_id
	var color: Color = Color(0.55, 0.9, 1.0) if ability == "hot_spring" else Color(1.0, 0.85, 0.35)
	color = color.lerp(HeroView.TEAM_COLORS[team % HeroView.TEAM_COLORS.size()], 0.2)
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = 0.03
	c.radial_segments = 48
	_disc.mesh = c
	_mat = ViewParts.glow(Color(color, _base_alpha))
	_disc.material_override = _mat
	_disc.position.y = 0.03
	add_child(_disc)
	var t := TorusMesh.new()
	t.inner_radius = radius - 0.12
	t.outer_radius = radius
	_rim.mesh = t
	_rim.material_override = ViewParts.glow(Color(color, 0.7))
	_rim.position.y = 0.05
	add_child(_rim)


func render(_prev: Dictionary, cur: Dictionary, _alpha: float, tick: int, _snap: Snapshot) -> void:
	position = cur["position"]
	var left := int(cur["until"]) - tick
	var fade := clampf(left / 60.0, 0.0, 1.0)
	_mat.albedo_color.a = _base_alpha * fade
	_rim.visible = fade > 0.05
