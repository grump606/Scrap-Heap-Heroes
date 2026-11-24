## Collects script errors (and push_error / failed asserts) while tests run, so
## a test that crashes partway through counts as a failure, not a pass.
## Uses Logger, which needs Godot 4.5+; run_tests.gd loads this only when the
## engine has it. No class_name, so older engines never parse it.
extends Logger

var _mutex := Mutex.new()
var _errors: Array[String] = []


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	# Warnings are allowed: some tests trigger them on purpose (rejected replays).
	if error_type == ERROR_TYPE_WARNING:
		return
	var what := rationale if rationale != "" else code
	_mutex.lock()
	_errors.append("%s (%s:%d in %s)" % [what, file.get_file(), line, function])
	_mutex.unlock()


func _log_message(_message: String, _error: bool) -> void:
	pass


## Returns the errors seen since the last call and clears them.
func take() -> Array[String]:
	_mutex.lock()
	var out := _errors.duplicate()
	_errors.clear()
	_mutex.unlock()
	return out
