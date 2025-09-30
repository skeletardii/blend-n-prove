extends Node

signal tutorial_loaded(tutorial_name: String)
signal all_tutorials_loaded()

class ProblemData:
	var problem_number: int = 0
	var difficulty: String = ""
	var premises: Array[String] = []
	var conclusion: String = ""
	var solution: String = ""

	func _init(num: int = 0, diff: String = "", prems: Array[String] = [], concl: String = "", sol: String = "") -> void:
		problem_number = num
		difficulty = diff
		premises = prems.duplicate()
		conclusion = concl
		solution = sol

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
		var file_path: String = "res://docs/tutorials/" + tutorial_key + ".md"
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

	return parse_tutorial_markdown(content, file_path, tutorial_key)

func parse_tutorial_markdown(content: String, file_path: String, tutorial_key: String) -> TutorialData:
	var lines: PackedStringArray = content.split("\n")
	var tutorial: TutorialData = TutorialData.new("", "", "", file_path, tutorial_key)

	var current_section: String = ""
	var current_problem: ProblemData = null
	var current_field: String = ""
	var problem_count: int = 0

	for line in lines:
		var trimmed: String = line.strip_edges()

		# Parse title (first line starting with #)
		if trimmed.begins_with("# ") and tutorial.rule_name.is_empty():
			tutorial.rule_name = trimmed.substr(2).strip_edges()
			continue

		# Parse sections
		if trimmed.begins_with("## Description"):
			current_section = "description"
			continue
		elif trimmed.begins_with("## Rule Pattern"):
			current_section = "pattern"
			continue
		elif trimmed.begins_with("## Problems"):
			current_section = "problems"
			continue

		# Parse subsections (problems)
		if trimmed.begins_with("### Problem"):
			# Save previous problem if exists
			if current_problem:
				tutorial.problems.append(current_problem)

			problem_count += 1
			# Extract difficulty from parentheses
			var difficulty: String = "Easy"
			if "(" in trimmed and ")" in trimmed:
				var start: int = trimmed.find("(")
				var end: int = trimmed.find(")")
				var diff_text: String = trimmed.substr(start + 1, end - start - 1)
				if ":" in diff_text:
					difficulty = diff_text.split(":")[1].strip_edges()

			current_problem = ProblemData.new(problem_count, difficulty, [], "", "")
			current_field = ""
			continue

		# Parse problem fields
		if current_section == "problems" and current_problem:
			if trimmed.begins_with("**Premises:**"):
				current_field = "premises"
				continue
			elif trimmed.begins_with("**Conclusion:**"):
				current_field = "conclusion"
				continue
			elif trimmed.begins_with("**Brief Solution:**"):
				current_field = "solution"
				continue
			elif trimmed == "---" or trimmed.is_empty():
				current_field = ""
				continue

			# Add content to current field
			if current_field == "premises":
				if trimmed.begins_with("- "):
					current_problem.premises.append(trimmed.substr(2).strip_edges())
			elif current_field == "conclusion":
				if not trimmed.begins_with("**"):
					current_problem.conclusion = trimmed
			elif current_field == "solution":
				if not trimmed.begins_with("**"):
					current_problem.solution = trimmed

		# Parse description
		elif current_section == "description":
			if not trimmed.is_empty() and not trimmed.begins_with("#"):
				if not tutorial.description.is_empty():
					tutorial.description += " "
				tutorial.description += trimmed

		# Parse pattern
		elif current_section == "pattern":
			if not trimmed.is_empty() and not trimmed.begins_with("#"):
				tutorial.rule_pattern = trimmed

	# Save last problem
	if current_problem:
		tutorial.problems.append(current_problem)

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