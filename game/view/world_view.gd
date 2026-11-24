## Builds and updates everything visible from snapshots. Reads only; never
## writes to the sim.
class_name WorldView
extends Node3D

var effects := EffectsView.new()

var _hero_views: Dictionary = {}  # entity_id -> HeroView
var _dummy_views: Dictionary = {}  # entity_id -> DummyView


func _ready() -> void:
	add_child(effects)


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
	_sync(_hero_views, prev.heroes if prev != null else {}, cur.heroes, alpha, cur.tick,
		func(id, d):
			var v := HeroView.new()
			v.setup(id, d["team"])
			return v)
	_sync(_dummy_views, prev.dummies if prev != null else {}, cur.dummies, alpha, cur.tick,
		func(id, _d):
			var v := DummyView.new()
			v.setup(id)
			return v)


func show_events(events: Array[SimEvent], snap: Snapshot, tick_dt: float) -> void:
	effects.show_events(events, snap, tick_dt)


func hero_view(entity_id: int) -> HeroView:
	return _hero_views.get(entity_id)


## Creates, updates and removes one kind of view to match the snapshot.
func _sync(views: Dictionary, prev: Dictionary, cur: Dictionary, alpha: float, tick: int, make: Callable) -> void:
	for id in cur:
		var d: Dictionary = cur[id]
		if not views.has(id):
			var v: Node3D = make.call(id, d)
			add_child(v)
			views[id] = v
		views[id].render(prev.get(id, d), d, alpha, tick)
	for id in views.keys():
		if not cur.has(id):
			views[id].queue_free()
			views.erase(id)
