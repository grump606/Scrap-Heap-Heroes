## Visual for a lane minion: a small team-colored scrap bot with a health bar.
class_name MinionView
extends Node3D

const BAR_WIDTH := 0.8

var entity_id: int
var _bar := MeshInstance3D.new()


func setup(p_entity_id: int, team: int) -> void:
	entity_id = p_entity_id
	var color: Color = HeroView.TEAM_COLORS[team % HeroView.TEAM_COLORS.size()]
	ViewParts.add_part(self, ViewParts.box(Vector3(0.6, 0.5, 0.7)), Vector3(0, 0.4, 0), color.darkened(0.2))
	ViewParts.add_part(self, ViewParts.box(Vector3(0.3, 0.2, 0.25)), Vector3(0, 0.55, -0.45), color.lightened(0.3))
	var bar := BoxMesh.new()
	bar.size = Vector3(BAR_WIDTH, 0.08, 0.08)
	_bar.mesh = bar
	_bar.material_override = ViewParts.glow(Color(0.4, 1.0, 0.4, 0.9))
	_bar.position = Vector3(0, 1.0, 0)
	add_child(_bar)


func render(prev: Dictionary, cur: Dictionary, alpha: float, _tick: int, _snap: Snapshot) -> void:
	var a: Vector3 = prev.get("position", cur["position"])
	position = a.lerp(cur["position"], alpha)
	rotation.y = lerp_angle(prev.get("facing", cur["facing"]), cur["facing"], alpha)
	var frac := clampf(float(cur["hp"]) / float(cur["max_hp"]), 0.0, 1.0)
	_bar.scale.x = maxf(frac, 0.01)
	# Billboard-ish: keep the bar level and unrotated relative to the body.
	_bar.rotation.y = -rotation.y
