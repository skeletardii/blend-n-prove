extends Node

## ProgressTracker Proxy - Delegates to implementation loaded from PCK

signal progress_updated
signal achievement_unlocked(achievement_name: String)

# Implementation reference
var _impl: Node = null

func _set_impl(impl: Node) -> void:
	_impl = impl
	# Forward signals
	if _impl.has_signal("progress_updated"):
		_impl.progress_updated.connect(func(): progress_updated.emit())
	if _impl.has_signal("achievement_unlocked"):
		_impl.achievement_unlocked.connect(func(name): achievement_unlocked.emit(name))

func _ready() -> void:
	pass  # Wait for impl injection

# Property forwarding
func _get(property: StringName) -> Variant:
	if _impl:
		return _impl.get(property)
	return null

func _set(property: StringName, value: Variant) -> bool:
	if _impl:
		_impl.set(property, value)
		return true
	return false

# Method forwarding
func start_new_session(difficulty: int, time_limit_seconds: float) -> void:
	if _impl: _impl.start_new_session(difficulty, time_limit_seconds)

func record_operation_used(operation_name: String, success: bool) -> void:
	if _impl: _impl.record_operation_used(operation_name, success)

func complete_current_session(final_score: int, orders_completed: int, completion_status: String, time_remaining_on_quit: float = 0.0, max_active_combo: int = 0, mistakes_count: int = 0) -> void:
	if _impl: _impl.complete_current_session(final_score, orders_completed, completion_status, time_remaining_on_quit, max_active_combo, mistakes_count)

func update_statistics() -> void:
	if _impl: _impl.update_statistics()

func check_achievements() -> void:
	if _impl: _impl.check_achievements()

func save_progress_data() -> void:
	if _impl: _impl.save_progress_data()

func load_progress_data() -> void:
	if _impl: _impl.load_progress_data()

func try_load_backup() -> void:
	if _impl: _impl.try_load_backup()

func get_achievement_name(achievement_id: String) -> String:
	if _impl: return _impl.get_achievement_name(achievement_id)
	return ""

func get_recent_sessions(count: int = 10) -> Array:
	if _impl: return _impl.get_recent_sessions(count)
	return []

func export_progress_data() -> String:
	if _impl: return _impl.export_progress_data()
	return ""

func import_progress_data(file_path: String) -> bool:
	if _impl: return _impl.import_progress_data(file_path)
	return false

func reset_progress_data() -> void:
	if _impl: _impl.reset_progress_data()

func debug_populate_test_data() -> void:
	if _impl: _impl.debug_populate_test_data()

func complete_tutorial_problem(tutorial_key: String, problem_index: int) -> void:
	if _impl: _impl.complete_tutorial_problem(tutorial_key, problem_index)

func check_tutorial_completion(tutorial_key: String) -> void:
	if _impl: _impl.check_tutorial_completion(tutorial_key)

func is_tutorial_fully_completed(tutorial_key: String) -> bool:
	if _impl: return _impl.is_tutorial_fully_completed(tutorial_key)
	return false

func get_tutorial_progress(tutorial_key: String) -> int:
	if _impl: return _impl.get_tutorial_progress(tutorial_key)
	return 0

func is_tutorial_problem_completed(tutorial_key: String, problem_index: int) -> bool:
	if _impl: return _impl.is_tutorial_problem_completed(tutorial_key, problem_index)
	return false

func get_total_tutorials_completed() -> int:
	if _impl: return _impl.get_total_tutorials_completed()
	return 0

func check_tutorial_achievements() -> void:
	if _impl: _impl.check_tutorial_achievements()
