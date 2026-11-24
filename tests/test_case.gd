## Minimal base for headless tests. Methods named test_* are run by run_tests.gd.
class_name TestCase
extends RefCounted

var failures: Array[String] = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func check_eq(a: Variant, b: Variant, msg: String) -> void:
	if a != b:
		failures.append("%s (got %s, expected %s)" % [msg, str(a), str(b)])
