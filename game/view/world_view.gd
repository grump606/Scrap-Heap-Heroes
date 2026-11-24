## Builds and updates everything visible from snapshots. Reads only; never
## writes to the sim.
class_name WorldView
extends Node3D

var effects := EffectsView.new()

var _hero_views: Dictionary = {}  # entity_id -> HeroView
var _dummy_views: Dictionary = {}  # entity_id -> DummyView
var _minion_views: Dictionary = {}  # entity_id -> MinionView
var _structure_views: Dictionary = {}  # entity_id -> StructureView
var _zone_views: Dictionary = {}  # entity_id -> ZoneView


func _ready() -> void:
	add_child(effects)


func build_arena(half_width: float, half_length: float) -> void:
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(half_width * 2.0, half_length * 2.0)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.42, 0.38)
	floor_mesh.material_override = mat
	add_child(floor_mesh)

	# Team-tinted ground at each end so the bases read at a glance.
	for team in [0, 1]:
		var base := MeshInstance3D.new()
		var p := PlaneMesh.new()
		p.size = Vector2(half_width * 2.0, 12.0)
		base.mesh = p
		base.position = Vector3(0, 0.01, (half_length - 6.0) * MatchRules.team_side(team))
		var bm := StandardMaterial3D.new()
		bm.albedo_color = HeroView.TEAM_COLORS[team].lerp(Color(0.45, 0.42, 0.38), 0.75)
		base.material_override = bm
		add_child(base)

	# Low walls on the edge the sim clamps units to, so the boundary is visible.
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.36, 0.33, 0.3)
	var t := 0.5
	var h := 0.8
	for side in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var wall := MeshInstance3D.new()
		var box := BoxMesh.new()
		if side.x != 0:
			box.size = Vector3(t, h, half_length * 2.0 + t * 2.0)
			wall.position = side * (half_width + t * 0.5)
		else:
			box.size = Vector3(half_width * 2.0 + t * 2.0, h, t)
			wall.position = side * (half_length + t * 0.5)
		wall.position.y = h * 0.5
		wall.mesh = box
		wall.material_override = wall_mat
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
	_sync(_hero_views, prev.heroes if prev != null else {}, cur.heroes, alpha, cur,
		func(id, d):
			var v := HeroView.new()
			v.setup(id, d["team"], StringName(d.get("hero_id", "")))
			return v)
	_sync(_dummy_views, prev.dummies if prev != null else {}, cur.dummies, alpha, cur,
		func(id, _d):
			var v := DummyView.new()
			v.setup(id)
			return v)
	_sync(_minion_views, prev.minions if prev != null else {}, cur.minions, alpha, cur,
		func(id, d):
			var v := MinionView.new()
			v.setup(id, d["team"])
			return v)
	_sync(_structure_views, {}, cur.structures, alpha, cur,
		func(id, d):
			var v := StructureView.new()
			v.setup(id, d["team"], d["kind"], d["radius"])
			return v)
	_sync(_zone_views, {}, cur.zones, alpha, cur,
		func(id, d):
			var v := ZoneView.new()
			v.setup(id, d["team"], d["ability"], d["radius"])
			return v)


func show_events(events: Array[SimEvent], snap: Snapshot, tick_dt: float) -> void:
	effects.show_events(events, snap, tick_dt)


func hero_view(entity_id: int) -> HeroView:
	return _hero_views.get(entity_id)


## Creates, updates and removes one kind of view to match the snapshot.
func _sync(views: Dictionary, prev: Dictionary, cur: Dictionary, alpha: float, snap: Snapshot, make: Callable) -> void:
	for id in cur:
		var d: Dictionary = cur[id]
		if not views.has(id):
			var v: Node3D = make.call(id, d)
			add_child(v)
			views[id] = v
		views[id].render(prev.get(id, d), d, alpha, snap.tick, snap)
	for id in views.keys():
		if not cur.has(id):
			views[id].queue_free()
			views.erase(id)
