extends Node

## TutorialManager Proxy - Delegates to implementation loaded from PCK

signal tutorial_step_completed(step_index: int)

# Implementation reference
var _impl: Node = null

func _set_impl(impl: Node) -> void:
	_impl = impl
	# Forward signals
	if _impl.has_signal("tutorial_step_completed"):
		_impl.tutorial_step_completed.connect(func(step): tutorial_step_completed.emit(step))

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
func start_tutorial() -> void:
	if _impl: _impl.start_tutorial()

func create_tutorial_overlay() -> void:
	if _impl: _impl.create_tutorial_overlay()

func show_tutorial_step(step: int) -> void:
	if _impl: _impl.show_tutorial_step(step)

func end_tutorial() -> void:
	if _impl: _impl.end_tutorial()

func skip_tutorial() -> void:
	if _impl: _impl.skip_tutorial()
