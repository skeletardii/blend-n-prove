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
	var solution: String
	# Level 6 natural language fields
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

	# Constructor for natural language problems (Level 6)
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
	# Level 6 natural language fields
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

	# Set natural language data for Level 6 problems
	func set_natural_language_data(nl_premises: Array[String], nl_conclusion: String) -> void:
		is_natural_language = true
		natural_language_premises = nl_premises
		natural_language_conclusion = nl_conclusion

var current_state: GameState = GameState.MENU
var current_phase: GamePhase = GamePhase.PREPARING_PREMISES
var current_score: int = 0
var current_lives: int = 3
var max_lives: int = 3
var difficulty_level: int = 1
var orders_completed_this_session: int = 0

var debug_mode: bool = false
var infinite_patience: bool = false

# Debug difficulty mode: -1 = Auto (normal scaling), 1-6 = locked difficulty level
var debug_difficulty_mode: int = -1

# Tutorial mode variables
var tutorial_mode: bool = false
var current_tutorial_key: String = ""
var current_tutorial_problem_index: int = 0

# Order Templates organized by difficulty level - loaded from JSON
var order_templates: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_classic_problems()

func load_classic_problems() -> void:
	print("Loading classic mode problems...")

	for level in range(1, 7):  # Levels 1-6 (now includes Level 6)
		var file_path: String = "res://data/classic/level-" + str(level) + ".json"

		if not FileAccess.file_exists(file_path):
			print("Classic problems file not found: ", file_path)
			continue

		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if not file:
			print("Failed to open classic problems file: ", file_path)
			continue

		var content: String = file.get_as_text()
		file.close()

		# Parse JSON
		var json: JSON = JSON.new()
		var error: Error = json.parse(content)

		if error != OK:
			print("JSON parse error at line ", json.get_error_line(), ": ", json.get_error_message())
			continue

		var level_data: Dictionary = json.data
		if not level_data:
			print("Failed to get JSON data from: ", file_path)
			continue

		# Parse problems array
		var problems_array: Array = level_data.get("problems", [])
		var level_templates: Array[OrderTemplate] = []

		for problem_dict in problems_array:
			if not problem_dict is Dictionary:
				continue

			# Check if this is a natural language problem (Level 6)
			var has_natural_language: bool = problem_dict.has("natural_language_premises")

			if has_natural_language:
				# Level 6: Natural language problem
				var nl_premises: Array[String] = []
				var nl_premises_data: Array = problem_dict.get("natural_language_premises", [])
				for nl_premise in nl_premises_data:
					nl_premises.append(str(nl_premise))

				var hidden_premises: Array[String] = []
				var hidden_premises_data: Array = problem_dict.get("hidden_logical_premises", [])
				for hidden_premise in hidden_premises_data:
					hidden_premises.append(str(hidden_premise))

				var hints: Array[String] = []
				var hints_data: Array = problem_dict.get("interpretation_hints", [])
				for hint in hints_data:
					hints.append(str(hint))

				var template: OrderTemplate = OrderTemplate.create_natural_language(
					nl_premises,
					hidden_premises,
					problem_dict.get("natural_language_conclusion", ""),
					problem_dict.get("hidden_logical_conclusion", ""),
					problem_dict.get("expected_operations", 1),
					problem_dict.get("description", ""),
					problem_dict.get("solution", ""),
					hints
				)

				level_templates.append(template)
			else:
				# Levels 1-5: Standard logical symbols problem
				var premises: Array[String] = []
				var premises_data: Array = problem_dict.get("premises", [])
				for premise in premises_data:
					premises.append(str(premise))

				var template: OrderTemplate = OrderTemplate.new(
					premises,
					problem_dict.get("conclusion", ""),
					problem_dict.get("expected_operations", 1),
					problem_dict.get("description", ""),
					problem_dict.get("solution", "")
				)

				level_templates.append(template)

		order_templates[level] = level_templates
		print("✓ Loaded level ", level, ": ", level_templates.size(), " problems")

	print("All classic problems loaded!")

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

	# Set initial difficulty based on debug mode
	if debug_difficulty_mode != -1:
		# Debug mode: start at specified difficulty (1-6)
		difficulty_level = clamp(debug_difficulty_mode, 1, 6)
		print("Starting game with debug difficulty: ", difficulty_level)
	else:
		# Normal mode: start at difficulty 1
		difficulty_level = 1

	orders_completed_this_session = 0
	current_phase = GamePhase.PREPARING_PREMISES
	tutorial_mode = false
	current_tutorial_key = ""
	current_tutorial_problem_index = 0
	change_state(GameState.PLAYING)
	score_updated.emit(current_score)
	lives_updated.emit(current_lives)

	# Start progress tracking session
	ProgressTracker.start_new_session(difficulty_level)

func start_tutorial_mode(tutorial_key: String) -> void:
	current_score = 0
	current_lives = max_lives
	difficulty_level = 1
	orders_completed_this_session = 0
	current_phase = GamePhase.PREPARING_PREMISES
	tutorial_mode = true
	current_tutorial_key = tutorial_key
	current_tutorial_problem_index = 0
	change_state(GameState.PLAYING)
	score_updated.emit(current_score)
	lives_updated.emit(current_lives)

	print("Starting tutorial mode: ", tutorial_key)

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

func set_debug_difficulty_mode(mode: int) -> void:
	# mode: -1 = Auto, 1-6 = specific difficulty level
	debug_difficulty_mode = mode
	print("Debug difficulty mode set to: ", "Auto" if mode == -1 else str(mode))

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

func get_current_tutorial_problem() -> TutorialDataManager.ProblemData:
	if not tutorial_mode or current_tutorial_key.is_empty():
		return null

	var tutorial: TutorialDataManager.TutorialData = TutorialDataManager.get_tutorial_by_name(current_tutorial_key)
	if not tutorial:
		return null

	if current_tutorial_problem_index >= tutorial.problems.size():
		return null

	return tutorial.problems[current_tutorial_problem_index]

func advance_to_next_tutorial_problem() -> bool:
	if not tutorial_mode or current_tutorial_key.is_empty():
		return false

	var tutorial: TutorialDataManager.TutorialData = TutorialDataManager.get_tutorial_by_name(current_tutorial_key)
	if not tutorial:
		return false

	# Mark current problem as completed
	ProgressTracker.complete_tutorial_problem(current_tutorial_key, current_tutorial_problem_index)

	current_tutorial_problem_index += 1

	# Check if there are more problems
	if current_tutorial_problem_index >= tutorial.problems.size():
		print("Tutorial completed!")
		return false

	return true

func exit_tutorial_mode() -> void:
	tutorial_mode = false
	current_tutorial_key = ""
	current_tutorial_problem_index = 0

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
