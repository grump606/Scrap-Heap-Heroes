## Minimal base for headless tests. Methods named test_* are run by run_tests.gd.
class_name TestCase
extends RefCounted

var failures: Array[String] = []
## Errors this test triggers on purpose (substrings). The runner ignores a
## logged error that matches one, and fails the test if one never appears.
var expected_errors: Array[String] = []


func expect_error(substring: String) -> void:
	expected_errors.append(substring)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func check_eq(a: Variant, b: Variant, msg: String) -> void:
	if a != b:
		failures.append("%s (got %s, expected %s)" % [msg, str(a), str(b)])
