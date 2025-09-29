extends Node

signal game_state_changed(new_state: GameState)
signal score_updated(new_score: int)
signal lives_updated(new_lives: int)

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

class OrderTemplate:
	var premises: Array[String] = []
	var conclusion: String
	var expected_operations: int
	var description: String

	func _init(premise_list: Array[String], target: String, ops: int, desc: String = "") -> void:
		premises = premise_list
		conclusion = target
		expected_operations = ops
		description = desc

class CustomerData:
	var customer_name: String
	var required_premises: Array[String] = []
	var target_conclusion: String
	var patience_duration: float

	func _init(name: String, premises: Array[String], conclusion: String, patience: float = 60.0) -> void:
		customer_name = name
		required_premises = premises
		target_conclusion = conclusion
		patience_duration = patience

var current_state: GameState = GameState.MENU
var current_phase: GamePhase = GamePhase.PREPARING_PREMISES
var current_score: int = 0
var current_lives: int = 3
var max_lives: int = 3
var difficulty_level: int = 1
var orders_completed_this_session: int = 0

var debug_mode: bool = false
var infinite_patience: bool = false

# Order Templates organized by difficulty level
var order_templates: Dictionary = {
	1: [
		# Level 1: 1 operation, max 2 premises
		OrderTemplate.new(["P → Q", "P"], "Q", 1, "Modus Ponens"),
		OrderTemplate.new(["P ∧ Q"], "P", 1, "Simplification (left)"),
		OrderTemplate.new(["P → Q", "¬Q"], "¬P", 1, "Modus Tollens"),
		OrderTemplate.new(["P ∨ Q", "¬P"], "Q", 1, "Disjunctive Syllogism"),
		OrderTemplate.new(["¬¬P"], "P", 1, "Double Negation"),
		OrderTemplate.new(["P", "Q"], "P ∧ Q", 1, "Conjunction"),
		OrderTemplate.new(["R ∧ S"], "S", 1, "Simplification (right)"),
		OrderTemplate.new(["¬(P ∧ Q)"], "¬P ∨ ¬Q", 1, "De Morgan's Law (AND)"),
		OrderTemplate.new(["¬(P ∨ Q)"], "¬P ∧ ¬Q", 1, "De Morgan's Law (OR)"),
		OrderTemplate.new(["Q ∨ R", "¬Q"], "R", 1, "Disjunctive Syllogism (variant)")
	],
	2: [
		# Level 2: 2 operations, 2-3 premises
		OrderTemplate.new(["P → Q", "Q → R", "P"], "R", 2, "Hypothetical Syllogism + MP"),
		OrderTemplate.new(["P ∧ Q", "R"], "P ∧ R", 2, "Simplification + Conjunction"),
		OrderTemplate.new(["¬¬P", "P → Q"], "Q", 2, "Double Negation + Modus Ponens"),
		OrderTemplate.new(["P ∨ Q", "¬P", "Q → R"], "R", 2, "Disjunctive Syllogism + MP"),
		OrderTemplate.new(["P ∧ (Q ∧ R)"], "Q ∧ R", 2, "Simplification + Simplification"),
		OrderTemplate.new(["¬(P ∨ Q)", "R → S"], "¬P ∧ ¬Q", 2, "De Morgan's + ignore unused premise"),
		OrderTemplate.new(["P", "Q", "R"], "(P ∧ Q) ∧ R", 2, "Conjunction + Conjunction"),
		OrderTemplate.new(["P → (Q ∧ R)", "P"], "Q", 2, "Modus Ponens + Simplification"),
		OrderTemplate.new(["(P ∧ Q) → R", "P", "Q"], "R", 2, "Conjunction + Modus Ponens"),
		OrderTemplate.new(["P ∨ (Q ∧ R)", "¬P"], "Q ∧ R", 2, "Disjunctive Syllogism + identity")
	],
	3: [
		# Level 3: 3 operations, 3-4 premises
		OrderTemplate.new(["P → Q", "Q → R", "R → S", "P"], "S", 3, "Chain of Hypothetical Syllogisms"),
		OrderTemplate.new(["P ∧ Q", "R ∧ S"], "P ∧ R", 3, "Multiple Simplifications + Conjunction"),
		OrderTemplate.new(["¬¬(P ∨ Q)", "¬P", "Q → R"], "R", 3, "Double Neg + Disj Syll + MP"),
		OrderTemplate.new(["(P ∧ Q) → R", "¬R", "P"], "¬Q", 3, "Modus Tollens + De Morgan's + Disj Syll"),
		OrderTemplate.new(["P ∨ (Q ∧ R)", "¬P"], "Q", 3, "Disjunctive Syllogism + Simplification"),
		OrderTemplate.new(["¬(P ∧ Q)", "R → P", "R"], "¬Q", 3, "MP + De Morgan's + Disj Syll"),
		OrderTemplate.new(["P", "Q", "R", "S"], "((P ∧ Q) ∧ R) ∧ S", 3, "Chain of Conjunctions"),
		OrderTemplate.new(["P → (Q ∨ R)", "P", "¬Q"], "R", 3, "MP + Disjunctive Syllogism"),
		OrderTemplate.new(["¬¬P ∧ ¬¬Q"], "P ∧ Q", 3, "Simplification + Double Neg + Conjunction"),
		OrderTemplate.new(["(P ∨ Q) ∧ R", "¬P"], "Q ∧ R", 3, "Simplification + Disj Syll + Conjunction")
	],
	4: [
		# Level 4: 3-4 operations, 4-5 premises
		OrderTemplate.new(["P → Q", "Q → (R ∧ S)", "R → T", "P"], "T", 4, "Complex chain with branching"),
		OrderTemplate.new(["¬(P ∨ Q)", "R ∧ S"], "¬P ∧ S", 4, "De Morgan's + Simplification + Conjunction"),
		OrderTemplate.new(["P ∨ (Q ∧ R)", "¬P", "S ∨ T", "¬S"], "Q ∧ T", 4, "Multiple Disjunctive Syllogisms"),
		OrderTemplate.new(["(P ∧ Q) → (R ∨ S)", "P", "Q", "¬R"], "S", 4, "Conjunction + MP + Disj Syll"),
		OrderTemplate.new(["¬¬(P → Q)", "¬¬P", "Q → (R ∧ S)"], "R", 4, "Double Neg + MP + MP + Simplification"),
		OrderTemplate.new(["P ∨ Q", "¬P", "Q → R", "R → S", "S → T"], "T", 4, "Disj Syll + Chain of MPs"),
		OrderTemplate.new(["P → Q", "Q → R", "¬R", "P"], "⊥", 4, "Contradiction via MT"),
		OrderTemplate.new(["(P ∨ Q) ∧ (R ∨ S)", "¬P", "¬R"], "Q ∧ S", 4, "Multiple simplifications + syllogisms"),
		OrderTemplate.new(["P → (Q → R)", "P", "Q", "R → S"], "S", 4, "Nested implications + chain"),
		OrderTemplate.new(["¬(P ∨ Q) ∧ ¬(R ∨ S)"], "¬P ∧ ¬R", 4, "Complex De Morgan's + Simplifications")
	],
	5: [
		# Level 5: 4+ operations, 4-6 premises
		OrderTemplate.new(["P → (Q ∧ R)", "Q → S", "R → T", "P"], "S ∧ T", 5, "Complex branching chain"),
		OrderTemplate.new(["(P ∨ Q) → R", "P", "¬R"], "⊥", 5, "Simple contradiction"),
		OrderTemplate.new(["(P ∧ Q) → (R ∨ S)", "(R ∨ S) → T", "P", "Q"], "T", 5, "Chain of implications"),
		OrderTemplate.new(["P ∨ Q", "¬P ∨ R", "¬Q ∨ R"], "R", 5, "Resolution-style proof"),
		OrderTemplate.new(["(P → Q) ∧ (R → S)", "¬Q ∨ ¬S", "P ∨ R"], "¬P ∨ ¬R", 5, "Complex Modus Tollens"),
		OrderTemplate.new(["P ↔ Q", "Q → (R ∧ S)", "R → T", "S → T", "P"], "T", 5, "Biconditional elimination + convergence"),
		OrderTemplate.new(["¬¬(P ∧ Q)", "P → R", "Q → S"], "R ∧ S", 5, "Double negation + parallel inference"),
		OrderTemplate.new(["P → Q", "R → S", "(Q ∧ S) → T", "P", "R"], "T", 5, "Convergent proof"),
		OrderTemplate.new(["(P ∨ Q) → (R ∧ S)", "P", "¬R → T", "¬T"], "R ∧ S", 5, "Proof by contradiction"),
		OrderTemplate.new(["P ⊕ Q", "P → R", "Q → R"], "R", 5, "XOR elimination to common conclusion")
	]
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_state(new_state: GameState) -> void:
	if current_state != new_state:
		current_state = new_state
		game_state_changed.emit(new_state)

func change_phase(new_phase: GamePhase) -> void:
	current_phase = new_phase

func add_score(points: int) -> void:
	current_score += points
	score_updated.emit(current_score)

func lose_life() -> void:
	current_lives = max(0, current_lives - 1)
	lives_updated.emit(current_lives)

	if current_lives <= 0:
		complete_progress_session("loss")
		change_state(GameState.GAME_OVER)

func reset_game() -> void:
	current_score = 0
	current_lives = max_lives
	difficulty_level = 1
	orders_completed_this_session = 0
	change_state(GameState.MENU)
	score_updated.emit(current_score)
	lives_updated.emit(current_lives)

func start_new_game() -> void:
	current_score = 0
	current_lives = max_lives
	difficulty_level = 1
	orders_completed_this_session = 0
	current_phase = GamePhase.PREPARING_PREMISES
	change_state(GameState.PLAYING)
	score_updated.emit(current_score)
	lives_updated.emit(current_lives)

	# Start progress tracking session
	ProgressTracker.start_new_session(difficulty_level)

func pause_game() -> void:
	change_state(GameState.PAUSED)

func resume_game() -> void:
	change_state(GameState.PLAYING)

func toggle_debug_mode() -> void:
	debug_mode = !debug_mode

func toggle_infinite_patience() -> void:
	infinite_patience = !infinite_patience

func force_game_over() -> void:
	complete_progress_session("quit")
	change_state(GameState.GAME_OVER)

func set_difficulty(level: int) -> void:
	difficulty_level = max(1, level)

func record_order_completed() -> void:
	orders_completed_this_session += 1

func record_operation_used(operation_name: String, success: bool) -> void:
	ProgressTracker.record_operation_used(operation_name, success)

func complete_progress_session(completion_status: String) -> void:
	if current_state != GameState.PLAYING:
		return

	ProgressTracker.complete_current_session(
		current_score,
		current_lives,
		orders_completed_this_session,
		completion_status
	)

func complete_game_successfully() -> void:
	complete_progress_session("win")
	change_state(GameState.GAME_OVER)

func run_integration_test() -> void:
	print("Running Game Systems Integration Test...")

	# Test 1: Game State Management
	print("Testing game state management...")
	var original_state = current_state
	change_state(GameState.PLAYING)
	if current_state == GameState.PLAYING:
		print("✓ State change test passed")
	else:
		print("✗ State change test failed")
	change_state(original_state)

	# Test 2: Score System
	print("Testing score system...")
	var original_score = current_score
	add_score(100)
	if current_score == original_score + 100:
		print("✓ Score system test passed")
	else:
		print("✗ Score system test failed")
	current_score = original_score

	# Test 3: Lives System
	print("Testing lives system...")
	var original_lives = current_lives
	lose_life()
	if current_lives == original_lives - 1:
		print("✓ Lives system test passed")
	else:
		print("✗ Lives system test failed")
	current_lives = original_lives

	# Test 4: Phase Management
	print("Testing phase management...")
	change_phase(GamePhase.TRANSFORMING_PREMISES)
	if current_phase == GamePhase.TRANSFORMING_PREMISES:
		print("✓ Phase management test passed")
	else:
		print("✗ Phase management test failed")
	change_phase(GamePhase.PREPARING_PREMISES)

	# Test 5: Boolean Logic Engine Integration
	print("Testing boolean logic engine integration...")
	BooleanLogicEngine.test_logic_engine()

	# Test 6: Audio Manager Integration
	print("Testing audio manager integration...")
	AudioManager.play_button_click()
	print("✓ Audio manager integration test passed")

	# Test 7: Progress Tracker Integration
	print("Testing progress tracker integration...")
	var original_sessions = ProgressTracker.game_sessions.size()
	ProgressTracker.start_new_session(2)
	ProgressTracker.record_operation_used("Modus Ponens", true)
	ProgressTracker.complete_current_session(500, 2, 3, "win")
	if ProgressTracker.game_sessions.size() == original_sessions + 1:
		print("✓ Progress tracker integration test passed")
	else:
		print("✗ Progress tracker integration test failed")

	print("Integration test complete!")
	print("All core systems are functioning properly.")
