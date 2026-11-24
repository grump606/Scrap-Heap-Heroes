## Visual for a training dummy: a post with a target and its health above.
class_name DummyView
extends Node3D

var entity_id: int
var _label := Label3D.new()


func setup(p_entity_id: int) -> void:
	entity_id = p_entity_id
	var wood := Color(0.55, 0.42, 0.28)
	var post := CylinderMesh.new()
	post.top_radius = 0.12
	post.bottom_radius = 0.15
	post.height = 1.4
	ViewParts.add_part(self, post, Vector3(0, 0.7, 0), wood)
	var body := CylinderMesh.new()
	body.top_radius = 0.45
	body.bottom_radius = 0.45
	body.height = 0.9
	ViewParts.add_part(self, body, Vector3(0, 1.3, 0), Color(0.85, 0.8, 0.65))
	var stripe := CylinderMesh.new()
	stripe.top_radius = 0.47
	stripe.bottom_radius = 0.47
	stripe.height = 0.15
	ViewParts.add_part(self, stripe, Vector3(0, 1.3, 0), Color(0.8, 0.15, 0.15))
	ViewParts.style_label(_label, 36)
	_label.position = Vector3(0, 2.2, 0)
	add_child(_label)


func render(prev: Dictionary, cur: Dictionary, alpha: float, tick: int, _snap: Snapshot = null) -> void:
	var a: Vector3 = prev.get("position", cur["position"])
	position = a.lerp(cur["position"], alpha)
	_label.text = "%d / %d%s" % [cur["hp"], cur["max_hp"], HeroView.status_text(cur.get("statuses", []), tick)]
