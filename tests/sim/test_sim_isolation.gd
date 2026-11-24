## Guards the core rule: game/sim/ never touches scenes, input, audio, frame
## time, the OS, file IO or global randomness. Comments are ignored.
extends TestCase

## [regex, what it catches, file allowed to use it ("" = none)]
const RULES := [
	["\\bextends\\s+(Node|Control|CanvasItem)", "a Node class", ""],
	["\\bget_(tree|node|viewport)\\(", "scene tree access", ""],
	["\\bInput(Event\\w*)?\\b", "input", ""],
	["\\bAudio\\w*", "audio", ""],
	["\\b_(physics_)?process\\(", "frame callbacks", ""],
	["\\b(Time|OS|Engine|DisplayServer|ProjectSettings)\\.", "engine/OS state or clocks", ""],
	["\\b(FileAccess|DirAccess|ResourceLoader|ResourceSaver)\\b", "file IO (belongs in the app layer)", ""],
	["(?<![\\w.])(pre)?load\\(", "loading resources or scenes", ""],
	# Global random functions. A method call on an RNG (rng.randf_range) is fine.
	["(?<![\\w.])(randf|randi|randfn|randf_range|randi_range|randomize|seed|rand_from_seed)\\(", "global randomness", ""],
	["\\bRandomNumberGenerator\\.new\\(", "an RNG outside SimRng", "sim_rng.gd"],
]


func test_sim_has_no_engine_side_effects() -> void:
	var files := _gd_files("res://game/sim")
	check(files.size() > 5, "found sim scripts")
	for path in files:
		for problem in violations(path.get_file(), FileAccess.get_file_as_string(path)):
			failures.append("%s: %s" % [path, problem])


## The rules themselves must catch what they claim to, or the test above
## passes for the wrong reason.
func test_rules_catch_known_violations() -> void:
	var bad := {
		"extends Node3D": "a Node class",
		"var x := randf_range(0, 1)": "global randomness",
		"randomize()": "global randomness",
		"var t := Time.get_ticks_msec()": "engine/OS state or clocks",
		"var d := Input.get_vector(a, b, c, d)": "input",
		"var s := preload(\"res://x.tscn\")": "loading resources or scenes",
		"var f := FileAccess.open(p, 1)": "file IO (belongs in the app layer)",
		"var r := RandomNumberGenerator.new()": "an RNG outside SimRng",
	}
	for line in bad:
		var found := violations("other.gd", line)
		check(found.size() == 1 and found[0].begins_with(bad[line]), "'%s' should be flagged as %s (got %s)" % [line, bad[line], str(found)])

	var good := [
		"return _streams[stream].randf_range(lo, hi)",
		"h.move_input = cmd.move_dir()",
		"var ok := can_load_replay(r)",
		"# Never call randf() or touch Input. here.",
		"func reload_state() -> void:",
	]
	for line in good:
		check(violations("other.gd", line).is_empty(), "'%s' should be allowed (got %s)" % [line, str(violations("other.gd", line))])

	check(violations("sim_rng.gd", "var r := RandomNumberGenerator.new()").is_empty(), "SimRng may create RNGs")


## Every rule broken by this source, as "what (line N)".
static func violations(file_name: String, source: String) -> Array[String]:
	var out: Array[String] = []
	var lines := source.split("\n")
	for rule in RULES:
		if rule[2] != "" and file_name == rule[2]:
			continue
		var re := RegEx.create_from_string(rule[0])
		for i in lines.size():
			if re.search(_strip_comment(lines[i])) != null:
				out.append("%s (line %d)" % [rule[1], i + 1])
	return out


static func _strip_comment(line: String) -> String:
	var hash_at := line.find("#")
	return line if hash_at == -1 else line.substr(0, hash_at)


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
