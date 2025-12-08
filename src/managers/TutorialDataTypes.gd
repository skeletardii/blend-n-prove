extends RefCounted

## Shared type definitions for TutorialDataManager system
## These classes are used by both TutorialDataManagerImpl and UI components

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
