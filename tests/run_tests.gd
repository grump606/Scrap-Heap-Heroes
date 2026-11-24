## Headless test runner. No window, no scenes, no audio.
##   godot --headless --path . --import   (once, on a fresh checkout)
##   godot --headless --path . -s res://tests/run_tests.gd
## Exits 0 when every test passes, 1 otherwise.
##
## A test fails if a check fails, or (Godot 4.5+) if it raises a script error,
## push_error or failed assert, which would otherwise end it early but silently.
extends SceneTree

const TEST_FILES := [
	"res://tests/sim/test_command_buffer.gd",
	"res://tests/sim/test_tick_clock.gd",
	"res://tests/sim/test_determinism.gd",
	"res://tests/sim/test_replay.gd",
	"res://tests/sim/test_forms.gd",
	"res://tests/sim/test_core_kit.gd",
	"res://tests/sim/test_sim_isolation.gd",
	"res://tests/sim/test_sim_rng.gd",
]
const ERROR_CAPTURE_PATH := "res://tests/error_capture.gd"


func _initialize() -> void:
	var capture: Object = null
	if ClassDB.class_exists("Logger"):
		capture = load(ERROR_CAPTURE_PATH).new()
		OS.add_logger(capture)
	else:
		print("  NOTE  Godot < 4.5: script errors inside tests are not detected")

	var passed := 0
	var failed := 0
	for path in TEST_FILES:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			failed += 1
			print("  FAIL  %s :: could not load (parse error?)" % path.get_file())
			continue
		for m in script.get_script_method_list():
			var method: String = m["name"]
			if not method.begins_with("test_"):
				continue
			if capture != null:
				capture.take()  # Drop anything logged between tests.
			var t: TestCase = script.new()
			t.call(method)
			var problems: Array[String] = t.failures.duplicate()
			if capture != null:
				var unseen := t.expected_errors.duplicate()
				for e in capture.take():
					var matched := false
					for want in t.expected_errors:
						if e.contains(want):
							matched = true
							unseen.erase(want)
					if not matched:
						problems.append("error: " + e)
				for want in unseen:
					problems.append("expected an error containing '%s'" % want)
			if problems.is_empty():
				passed += 1
				print("  PASS  %s :: %s" % [path.get_file(), method])
			else:
				failed += 1
				print("  FAIL  %s :: %s" % [path.get_file(), method])
				for f in problems:
					print("        - " + f)

	if capture != null:
		OS.remove_logger(capture)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
