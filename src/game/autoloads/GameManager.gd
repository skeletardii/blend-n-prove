extends Node

const GameManagerTypes = preload("res://src/managers/GameManagerTypes.gd")

## GameManager Proxy - Delegates to implementation loaded from PCK

signal game_state_changed(new_state: GameState)
signal score_updated(new_score: int)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

enum GamePhase {
	PREPARING_PREMISES,
	TRANSFORMING_PREMISES
}

# Implementation reference
var _impl: Node = null

func _set_impl(impl: Node) -> void:
	_impl = impl
	# Forward signals from implementation
	if _impl.has_signal("game_state_changed"):
		_impl.game_state_changed.connect(func(state): game_state_changed.emit(state))
	if _impl.has_signal("score_updated"):
		_impl.score_updated.connect(func(score): score_updated.emit(score))

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
func load_classic_problems() -> void:
	if _impl: _impl.load_classic_problems()

func change_state(new_state: GameState) -> void:
	if _impl: _impl.change_state(new_state)

func change_phase(new_phase: GamePhase) -> void:
	if _impl: _impl.change_phase(new_phase)

func add_score(points: int) -> void:
	if _impl: _impl.add_score(points)

func reset_game() -> void:
	if _impl: _impl.reset_game()

func start_new_game() -> void:
	if _impl: _impl.start_new_game()

func start_tutorial_mode(tutorial_key: String = "") -> void:
	if _impl: _impl.start_tutorial_mode(tutorial_key)

func start_first_time_tutorial() -> void:
	if _impl: _impl.start_first_time_tutorial()

func pause_game() -> void:
	if _impl: _impl.pause_game()

func resume_game() -> void:
	if _impl: _impl.resume_game()

func toggle_debug_mode() -> void:
	if _impl: _impl.toggle_debug_mode()

func toggle_infinite_patience() -> void:
	if _impl: _impl.toggle_infinite_patience()

func force_game_over() -> void:
	if _impl: _impl.force_game_over()

func set_difficulty(level: int) -> void:
	if _impl: _impl.set_difficulty(level)

func set_debug_difficulty_mode(mode: int) -> void:
	if _impl: _impl.set_debug_difficulty_mode(mode)

func record_order_completed() -> void:
	if _impl: _impl.record_order_completed()

func record_operation_used(operation_name: String, success: bool) -> void:
	if _impl: _impl.record_operation_used(operation_name, success)

func record_mistake() -> void:
	if _impl: _impl.record_mistake()

func complete_progress_session(completion_status: String, time_remaining_on_quit: float = 0.0) -> void:
	if _impl: _impl.complete_progress_session(completion_status, time_remaining_on_quit)

func complete_game_successfully() -> void:
	if _impl: _impl.complete_game_successfully()

func get_current_tutorial_problem():
	if _impl: return _impl.get_current_tutorial_problem()
	return null

func advance_to_next_tutorial_problem() -> bool:
	if _impl: return _impl.advance_to_next_tutorial_problem()
	return false

func exit_tutorial_mode() -> void:
	if _impl: _impl.exit_tutorial_mode()

func run_integration_test() -> void:
	if _impl: _impl.run_integration_test()

func record_mistake() -> void:
	if _impl: _impl.record_mistake()
