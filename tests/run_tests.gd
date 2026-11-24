## Headless test runner. No window, no scenes, no audio.
##   godot --headless --path . -s res://tests/run_tests.gd
## Exits 0 when every test passes, 1 otherwise.
extends SceneTree

const TEST_FILES := [
	"res://tests/sim/test_command_buffer.gd",
	"res://tests/sim/test_tick_clock.gd",
	"res://tests/sim/test_determinism.gd",
	"res://tests/sim/test_replay.gd",
	"res://tests/sim/test_sim_isolation.gd",
]


func _initialize() -> void:
	var passed := 0
	var failed := 0
	for path in TEST_FILES:
		var script: GDScript = load(path)
		for m in script.get_script_method_list():
			var method: String = m["name"]
			if not method.begins_with("test_"):
				continue
			var t: TestCase = script.new()
			t.call(method)
			if t.failures.is_empty():
				passed += 1
				print("  PASS  %s :: %s" % [path.get_file(), method])
			else:
				failed += 1
				print("  FAIL  %s :: %s" % [path.get_file(), method])
				for f in t.failures:
					print("        - " + f)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
