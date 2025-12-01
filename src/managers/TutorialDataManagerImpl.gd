extends Node

signal tutorial_loaded(tutorial_name: String)
signal all_tutorials_loaded()

class ProblemData:
	var problem_number: int = 0
	var difficulty: String = ""
	var premises: Array[String] = []
	var conclusion: String = ""
	var expected_operations: int = 0
	var solution: String = ""
	var description: String = ""
	var problem_title: String = ""
	var hints: Array[String] = []
	var hidden_premises: Array[String] = []
	var hidden_conclusion: String = ""
	var interpretation_hints: Array[String] = []

	func _init(num: int = 0, diff: String = "", prems: Array[String] = [], concl: String = "", sol: String = "",
	           desc: String = "", title: String = "", hint_list: Array[String] = [], exp_ops: int = 0,
	           hidden_prems: Array[String] = [], hidden_concl: String = "", interpret_hints: Array[String] = []) -> void:
		problem_number = num
		difficulty = diff
		premises = prems.duplicate()
		conclusion = concl
		expected_operations = exp_ops
		solution = sol
		description = desc
		problem_title = title
		hints = hint_list.duplicate()
		hidden_premises = hidden_prems.duplicate()
		hidden_conclusion = hidden_concl
		interpretation_hints = interpret_hints.duplicate()

class TutorialData:
	var rule_name: String = ""
	var description: String = ""
	var rule_pattern: String = ""
	var problems: Array[ProblemData] = []
	var file_path: String = ""
	var tutorial_key: String = ""

	func _init(name: String = "", desc: String = "", pattern: String = "", path: String = "", key: String = "") -> void:
		rule_name = name
		description = desc
		rule_pattern = pattern
		file_path = path
		tutorial_key = key
		problems = []

# Dictionary mapping tutorial key to TutorialData
var tutorials: Dictionary = {}

# Mapping from button index (1-18) to tutorial key
var button_tutorial_map: Dictionary = {
	1: "modus-ponens",
	2: "modus-tollens",
	3: "hypothetical-syllogism",
	4: "disjunctive-syllogism",
	5: "simplification",
	6: "conjunction",
	7: "addition",
	8: "de-morgans-and",
	9: "de-morgans-or",
	10: "double-negation",
	11: "resolution",
	12: "biconditional",
	13: "distributivity",
	14: "commutativity",
	15: "associativity",
	16: "idempotent",
	17: "absorption",
	18: "negation-laws"
}

# Tutorial display names
var tutorial_display_names: Dictionary = {
	"modus-ponens": "Modus Ponens",
	"modus-tollens": "Modus Tollens",
	"hypothetical-syllogism": "Hypothetical Syllogism",
	"disjunctive-syllogism": "Disjunctive Syllogism",
	"simplification": "Simplification",
	"conjunction": "Conjunction",
	"addition": "Addition",
	"de-morgans-and": "De Morgan's (AND)",
	"de-morgans-or": "De Morgan's (OR)",
	"double-negation": "Double Negation",
	"resolution": "Resolution",
	"biconditional": "Biconditional",
	"distributivity": "Distributivity",
	"commutativity": "Commutativity",
	"associativity": "Associativity",
	"idempotent": "Idempotent",
	"absorption": "Absorption",
	"negation-laws": "Negation Laws"
}

var tutorials_loaded: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_all_tutorials()

func load_all_tutorials() -> void:
	print("Loading all tutorials...")

	for tutorial_key in button_tutorial_map.values():
		var file_path: String = "res://data/tutorial/" + tutorial_key + ".json"
		var tutorial: TutorialData = load_tutorial(file_path, tutorial_key)

		if tutorial:
			tutorials[tutorial_key] = tutorial
			tutorial_loaded.emit(tutorial_key)
			print("✓ Loaded tutorial: ", tutorial.rule_name)
		else:
			print("✗ Failed to load tutorial: ", tutorial_key)

	tutorials_loaded = true
	all_tutorials_loaded.emit()
	print("All tutorials loaded!")

func load_tutorial(file_path: String, tutorial_key: String) -> TutorialData:
	if not FileAccess.file_exists(file_path):
		print("Tutorial file not found: ", file_path)
		return null

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open tutorial file: ", file_path)
		return null

	var content: String = file.get_as_text()
	file.close()

	return parse_tutorial_json(content, file_path, tutorial_key)

func parse_tutorial_json(content: String, file_path: String, tutorial_key: String) -> TutorialData:
	var json: JSON = JSON.new()
	var error: Error = json.parse(content)

	if error != OK:
		print("JSON parse error at line ", json.get_error_line(), ": ", json.get_error_message())
		return null

	var data: Dictionary = json.data
	if not data:
		print("Failed to get JSON data from: ", file_path)
		return null

	# Create tutorial data from JSON
	var tutorial: TutorialData = TutorialData.new(
		data.get("rule_name", ""),
		data.get("description", ""),
		data.get("rule_pattern", ""),
		file_path,
		tutorial_key
	)

	# Parse problems array
	var problems_array: Array = data.get("problems", [])
	for problem_dict in problems_array:
		if not problem_dict is Dictionary:
			continue

		# Convert premises array
		var premises: Array[String] = []
		var premises_data: Array = problem_dict.get("premises", [])
		for premise in premises_data:
			premises.append(str(premise))

		# Create problem data
		var problem: ProblemData = ProblemData.new(
			problem_dict.get("problem_number", 0),
			problem_dict.get("difficulty", "Easy"),
			premises,
			problem_dict.get("conclusion", ""),
			problem_dict.get("solution", "")
		)

		tutorial.problems.append(problem)

	return tutorial

func get_tutorial_by_name(tutorial_key: String) -> TutorialData:
	return tutorials.get(tutorial_key, null)

func get_tutorial_by_button_index(button_index: int) -> TutorialData:
	var tutorial_key: String = button_tutorial_map.get(button_index, "")
	if tutorial_key.is_empty():
		return null
	return get_tutorial_by_name(tutorial_key)

func get_display_name(tutorial_key: String) -> String:
	return tutorial_display_names.get(tutorial_key, tutorial_key)

func get_tutorial_count() -> int:
	return tutorials.size()

func get_problem_count(tutorial_key: String) -> int:
	var tutorial: TutorialData = get_tutorial_by_name(tutorial_key)
	if tutorial:
		return tutorial.problems.size()
	return 0

func get_tutorial_progress(tutorial_key: String) -> int:
	# Query ProgressTracker for completion count
	return ProgressTracker.get_tutorial_progress(tutorial_key)

func get_tutorial_completion_percentage(tutorial_key: String) -> float:
	var total: int = get_problem_count(tutorial_key)
	if total == 0:
		return 0.0
	var completed: int = get_tutorial_progress(tutorial_key)
	return (float(completed) / float(total)) * 100.0

func is_tutorial_completed(tutorial_key: String) -> bool:
	var total: int = get_problem_count(tutorial_key)
	var completed: int = get_tutorial_progress(tutorial_key)
	return total > 0 and completed >= total

func is_tutorial_problem_completed(tutorial_key: String, problem_index: int) -> bool:
	return ProgressTracker.is_tutorial_problem_completed(tutorial_key, problem_index)

func get_all_tutorial_keys() -> Array:
	return tutorials.keys()

func debug_print_tutorial(tutorial_key: String) -> void:
	var tutorial: TutorialData = get_tutorial_by_name(tutorial_key)
	if not tutorial:
		print("Tutorial not found: ", tutorial_key)
		return

	print("\n=== Tutorial: ", tutorial.rule_name, " ===")
	print("Description: ", tutorial.description)
	print("Pattern: ", tutorial.rule_pattern)
	print("Problems: ", tutorial.problems.size())

	for problem in tutorial.problems:
		print("\nProblem ", problem.problem_number, " (", problem.difficulty, ")")
		print("  Premises: ", problem.premises)
		print("  Conclusion: ", problem.conclusion)
		print("  Solution: ", problem.solution)