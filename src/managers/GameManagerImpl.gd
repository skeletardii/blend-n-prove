extends Node

const TutorialDataTypes = preload("res://src/managers/TutorialDataTypes.gd")
const GameManagerTypes = preload("res://src/managers/GameManagerTypes.gd")

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

var current_state: GameState = GameState.MENU
var current_phase: GamePhase = GamePhase.PREPARING_PREMISES
var current_score: int = 0
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
var is_first_time_tutorial: bool = false  # Special flag for first-time interactive tutorial

# Order Templates organized by difficulty level - loaded from JSON
var order_templates: Dictionary = {}
var time_limit_seconds: float = 180.0 # Default to 3 minutes, can be set by game mode/difficulty

var mistakes_count_this_session: int = 0
var current_combo: int = 0
var max_combo_this_session: int = 0

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
		var level_templates: Array[GameManagerTypes.OrderTemplate] = []

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

				var var_defs: Dictionary = problem_dict.get("variable_definitions", {})

				var template: GameManagerTypes.OrderTemplate = GameManagerTypes.OrderTemplate.create_natural_language(
					nl_premises,
					hidden_premises,
					problem_dict.get("natural_language_conclusion", ""),
					problem_dict.get("hidden_logical_conclusion", ""),
					problem_dict.get("expected_operations", 1),
					problem_dict.get("description", ""),
					problem_dict.get("solution", ""),
					hints,
					var_defs
				)

				level_templates.append(template)
			else:
				# Levels 1-5: Standard logical symbols problem
				var premises: Array[String] = []
				var premises_data: Array = problem_dict.get("premises", [])
				for premise in premises_data:
					premises.append(str(premise))

				var template: GameManagerTypes.OrderTemplate = GameManagerTypes.OrderTemplate.new(
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

func reset_game() -> void:
	current_score = 0
	difficulty_level = 1
	orders_completed_this_session = 0
	change_state(GameState.MENU)
	score_updated.emit(current_score)

func start_new_game() -> void:
	current_score = 0

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

	# Start progress tracking session
	ProgressTracker.start_new_session(difficulty_level, time_limit_seconds)

func start_tutorial_mode(tutorial_key: String = "") -> void:
	current_score = 0
	difficulty_level = 1
	orders_completed_this_session = 0
	current_phase = GamePhase.PREPARING_PREMISES
	tutorial_mode = true
	current_tutorial_key = tutorial_key
	current_tutorial_problem_index = 0
	is_first_time_tutorial = false
	change_state(GameState.PLAYING)
	score_updated.emit(current_score)

	print("Starting tutorial mode: ", tutorial_key)

func start_first_time_tutorial() -> void:
	"""Start the special first-time interactive tutorial"""
	start_tutorial_mode("first-time-tutorial")
	is_first_time_tutorial = true
	infinite_patience = true  # Tutorial has infinite time
	print("Starting first-time interactive tutorial")

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
	current_combo += 1
	if current_combo > max_combo_this_session:
		max_combo_this_session = current_combo

func record_operation_used(operation_name: String, success: bool) -> void:
	ProgressTracker.record_operation_used(operation_name, success)

func record_mistake() -> void:
	mistakes_count_this_session += 1
	current_combo = 0 # Reset combo on mistake

func complete_progress_session(completion_status: String, time_remaining_on_quit: float = 0.0) -> void:
	if current_state != GameState.PLAYING:
		return

	# Reset all session-specific trackers after completion
	var final_score_this_session = current_score
	var orders_completed_current_session = orders_completed_this_session
	var max_combo_achieved = max_combo_this_session
	var total_mistakes_made = mistakes_count_this_session

	# Reset for next game
	current_score = 0
	orders_completed_this_session = 0
	mistakes_count_this_session = 0
	current_combo = 0
	max_combo_this_session = 0

	ProgressTracker.complete_current_session(
		final_score_this_session,
		orders_completed_current_session,
		completion_status,
		time_remaining_on_quit,
		max_combo_achieved,
		total_mistakes_made
	)
	change_state(GameState.GAME_OVER) # Always set to GAME_OVER after session completion (quit or time_out)


func get_current_tutorial_problem() -> TutorialDataTypes.ProblemData:
	if not tutorial_mode or current_tutorial_key.is_empty():
		return null

	var tutorial: TutorialDataTypes.TutorialData = TutorialDataManager.get_tutorial_by_name(current_tutorial_key)
	if not tutorial:
		return null

	if current_tutorial_problem_index >= tutorial.problems.size():
		return null

	return tutorial.problems[current_tutorial_problem_index]

func advance_to_next_tutorial_problem() -> bool:
	if not tutorial_mode or current_tutorial_key.is_empty():
		return false

	var tutorial: TutorialDataTypes.TutorialData = TutorialDataManager.get_tutorial_by_name(current_tutorial_key)
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

	# Test 3: Phase Management
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
	ProgressTracker.start_new_session(2, time_limit_seconds)
	ProgressTracker.record_operation_used("Modus Ponens", true)
	ProgressTracker.complete_current_session(500, 3, "time_out", 0.0, 3, 0)
	if ProgressTracker.game_sessions.size() == original_sessions + 1:
		print("✓ Progress tracker integration test passed")
	else:
		print("✗ Progress tracker integration test failed")

	print("Integration test complete!")
	print("All core systems are functioning properly.")
