## Guards the core rule: game/sim/ never touches scenes, input, audio,
## frame time or global randomness.
extends TestCase

const FORBIDDEN := [
	"extends Node", "extends Control", "get_tree(", "get_node(", "Input.",
	"AudioStream", "_process(", "_physics_process(", "randf()", "randi()",
	"randomize(", "Time.get_ticks", "OS.get_ticks",
]


func test_sim_has_no_engine_side_effects() -> void:
	var files := _gd_files("res://game/sim")
	check(files.size() > 5, "found sim scripts")
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		for token in FORBIDDEN:
			check(not text.contains(token), "%s uses forbidden '%s'" % [path, token])


func _gd_files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for d in dir.get_directories():
		out.append_array(_gd_files(dir_path.path_join(d)))
	return out
