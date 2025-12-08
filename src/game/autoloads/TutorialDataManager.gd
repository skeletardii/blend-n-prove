extends Node

const TutorialDataTypes = preload("res://src/managers/TutorialDataTypes.gd")

## TutorialDataManager Proxy - Delegates to implementation loaded from PCK

signal tutorial_loaded(tutorial_name: String)
signal all_tutorials_loaded()

# Implementation reference
var _impl: Node = null

func _set_impl(impl: Node) -> void:
	_impl = impl
	# Forward signals
	if _impl.has_signal("tutorial_loaded"):
		_impl.tutorial_loaded.connect(func(name): tutorial_loaded.emit(name))
	if _impl.has_signal("all_tutorials_loaded"):
		_impl.all_tutorials_loaded.connect(func(): all_tutorials_loaded.emit())

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
func load_all_tutorials() -> void:
	if _impl: _impl.load_all_tutorials()

func load_tutorial(file_path: String, tutorial_key: String) -> TutorialDataTypes.TutorialData:
	if _impl: return _impl.load_tutorial(file_path, tutorial_key)
	return null

func parse_tutorial_json(content: String, file_path: String, tutorial_key: String) -> TutorialDataTypes.TutorialData:
	if _impl: return _impl.parse_tutorial_json(content, file_path, tutorial_key)
	return null

func get_tutorial_by_name(tutorial_key: String) -> TutorialDataTypes.TutorialData:
	if _impl: return _impl.get_tutorial_by_name(tutorial_key)
	return null

func get_tutorial_by_button_index(button_index: int) -> TutorialDataTypes.TutorialData:
	if _impl: return _impl.get_tutorial_by_button_index(button_index)
	return null

func get_display_name(tutorial_key: String) -> String:
	if _impl: return _impl.get_display_name(tutorial_key)
	return ""

func get_tutorial_count() -> int:
	if _impl: return _impl.get_tutorial_count()
	return 0

func get_problem_count(tutorial_key: String) -> int:
	if _impl: return _impl.get_problem_count(tutorial_key)
	return 0

func get_tutorial_progress(tutorial_key: String) -> int:
	if _impl: return _impl.get_tutorial_progress(tutorial_key)
	return 0

func get_tutorial_completion_percentage(tutorial_key: String) -> float:
	if _impl: return _impl.get_tutorial_completion_percentage(tutorial_key)
	return 0.0

func is_tutorial_completed(tutorial_key: String) -> bool:
	if _impl: return _impl.is_tutorial_completed(tutorial_key)
	return false

func is_tutorial_problem_completed(tutorial_key: String, problem_index: int) -> bool:
	if _impl: return _impl.is_tutorial_problem_completed(tutorial_key, problem_index)
	return false

func get_all_tutorial_keys() -> Array:
	if _impl: return _impl.get_all_tutorial_keys()
	return []

func debug_print_tutorial(tutorial_key: String) -> void:
	if _impl: _impl.debug_print_tutorial(tutorial_key)
