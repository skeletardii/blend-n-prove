extends Node

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

# Inner classes must be defined in proxy for type compatibility
class OrderTemplate:
	var premises: Array[String] = []
	var conclusion: String
	var expected_operations: int
	var description: String
	var solution: String
	var is_natural_language: bool = false
	var natural_language_premises: Array[String] = []
	var natural_language_conclusion: String = ""
	var interpretation_hints: Array[String] = []

	func _init(premise_list: Array[String], target: String, ops: int, desc: String = "", sol: String = "") -> void:
		premises = premise_list
		conclusion = target
		expected_operations = ops
		description = desc
		solution = sol
		is_natural_language = false

	static func create_natural_language(
		nl_premises: Array[String],
		hidden_premises: Array[String],
		nl_conclusion: String,
		hidden_conclusion: String,
		ops: int,
		desc: String = "",
		sol: String = "",
		hints: Array[String] = []
	) -> OrderTemplate:
		var template = OrderTemplate.new(hidden_premises, hidden_conclusion, ops, desc, sol)
		template.is_natural_language = true
		template.natural_language_premises = nl_premises
		template.natural_language_conclusion = nl_conclusion
		template.interpretation_hints = hints
		return template

class CustomerData:
	var customer_name: String
	var required_premises: Array[String] = []
	var target_conclusion: String
	var patience_duration: float
	var solution: String = ""
	var is_natural_language: bool = false
	var natural_language_premises: Array[String] = []
	var natural_language_conclusion: String = ""

	func _init(name: String, premises: Array[String], conclusion: String, patience: float = 60.0, sol: String = "") -> void:
		customer_name = name
		required_premises = premises
		target_conclusion = conclusion
		patience_duration = patience
		solution = sol
		is_natural_language = false

	func set_natural_language_data(nl_premises: Array[String], nl_conclusion: String) -> void:
		is_natural_language = true
		natural_language_premises = nl_premises
		natural_language_conclusion = nl_conclusion

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

func complete_progress_session(completion_status: String) -> void:
	if _impl: _impl.complete_progress_session(completion_status)

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
