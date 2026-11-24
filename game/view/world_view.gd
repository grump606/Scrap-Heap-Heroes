## Builds and updates everything visible from snapshots. Reads only; never
## writes to the sim.
class_name WorldView
extends Node3D

var _hero_views: Dictionary = {}  # entity_id -> HeroView


func build_arena(half_size: float) -> void:
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(half_size * 2.0, half_size * 2.0)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.42, 0.38)
	floor_mesh.material_override = mat
	add_child(floor_mesh)

	# Low walls on the edge the sim clamps heroes to, so the boundary is visible.
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.36, 0.33, 0.3)
	var t := 0.5
	var h := 0.8
	var long := half_size * 2.0 + t * 2.0
	for side in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var wall := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(t, h, long) if side.x != 0 else Vector3(long, h, t)
		wall.mesh = box
		wall.material_override = wall_mat
		# Inner face sits on the clamp line; a hero's body may overlap it slightly.
		wall.position = side * (half_size + t * 0.5) + Vector3(0, h * 0.5, 0)
		add_child(wall)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.85)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	add_child(env)


## prev and cur are the snapshots from the last two ticks; alpha is how far
## the clock is between them.
func render(prev: Snapshot, cur: Snapshot, alpha: float) -> void:
	for id in cur.heroes:
		var d: Dictionary = cur.heroes[id]
		if not _hero_views.has(id):
			var v := HeroView.new()
			v.setup(id, d["team"])
			add_child(v)
			_hero_views[id] = v
		var p: Dictionary = prev.heroes.get(id, d) if prev != null else d
		_hero_views[id].render(p, d, alpha)
	for id in _hero_views.keys():
		if not cur.heroes.has(id):
			_hero_views[id].queue_free()
			_hero_views.erase(id)


func hero_view(entity_id: int) -> HeroView:
	return _hero_views.get(entity_id)
