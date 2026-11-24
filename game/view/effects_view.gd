## Short-lived visuals driven by sim events: damage numbers, area flashes,
## windup telegraphs and eject/slam callouts. Reads events only.
class_name EffectsView
extends Node3D

const AREA_COLOR := Color(1.0, 0.85, 0.4, 0.35)
const TELEGRAPH_COLOR := Color(1.0, 0.3, 0.2, 0.25)


## Called once per frame with the events of every tick that ran. snap gives
## positions for events that don't carry one.
func show_events(events: Array[SimEvent], snap: Snapshot, tick_dt: float) -> void:
	for e in events:
		match e.type:
			SimEvent.Type.HIT:
				_float_text(Vector3(e.data["x"], 2.0, e.data["z"]), "-%d" % e.data["amount"], Color(1, 0.95, 0.8), 44)
			SimEvent.Type.WALL_SLAM:
				_float_text(Vector3(e.data["x"], 2.8, e.data["z"]), "SLAM!", Color(1, 0.5, 0.1), 64)
			SimEvent.Type.EJECT:
				var h: Dictionary = snap.heroes.get(e.entity_id, {})
				if not h.is_empty():
					_float_text(h["position"] + Vector3(0, 2.5, 0), "EJECT!", Color(1, 0.3, 0.3), 56)
			SimEvent.Type.AREA:
				var center := Vector3(e.data["x"], 0.05, e.data["z"])
				if e.data["shape"] == "cone":
					_flash(_cone_mesh(e.data["radius"], e.data["angle"]), center,
						atan2(-e.data["ax"], -e.data["az"]), AREA_COLOR, 0.35)
				else:
					_flash(_disc_mesh(e.data["radius"]), center, 0.0, AREA_COLOR, 0.35)
			SimEvent.Type.ABILITY_CAST:
				# Telegraph a windup so it can be read and dodged.
				var h: Dictionary = snap.heroes.get(e.entity_id, {})
				if int(e.data.get("windup", 0)) > 0 and float(e.data.get("radius", 0.0)) > 0.0 and not h.is_empty():
					var p: Vector3 = h["position"]
					_flash(_disc_mesh(e.data["radius"]), Vector3(p.x, 0.04, p.z), 0.0, TELEGRAPH_COLOR,
						int(e.data["windup"]) * tick_dt)


func _float_text(at: Vector3, text: String, color: Color, size: int) -> void:
	var l := Label3D.new()
	ViewParts.style_label(l, size)
	l.text = text
	l.modulate = color
	l.position = at
	add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", at.y + 1.2, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.chain().tween_callback(l.queue_free)


func _flash(mesh: Mesh, at: Vector3, yaw: float, color: Color, life: float) -> void:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = at
	m.rotation.y = yaw
	var mat := ViewParts.glow(color)
	m.material_override = mat
	add_child(m)
	var tw := m.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, life)
	tw.tween_callback(m.queue_free)


func _disc_mesh(radius: float) -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = 0.02
	c.radial_segments = 48
	return c


## A flat pie slice pointing along -Z, angle_deg wide.
func _cone_mesh(reach: float, angle_deg: float) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := deg_to_rad(angle_deg) * 0.5
	var steps := 16
	for i in steps:
		var a0 := -half + (2.0 * half) * i / steps
		var a1 := -half + (2.0 * half) * (i + 1) / steps
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(-sin(a0), 0, -cos(a0)) * reach)
		st.add_vertex(Vector3(-sin(a1), 0, -cos(a1)) * reach)
	return st.commit()
