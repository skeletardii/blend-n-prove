extends RefCounted

## Shared type definitions for GameManager system
## These classes are used by both GameManagerImpl and UI components

class OrderTemplate:
	var premises: Array[String] = []
	var conclusion: String
	var expected_operations: int
	var description: String
	var solution: String
	# Level 6 natural language fields
	var is_natural_language: bool = false
	var natural_language_premises: Array[String] = []
	var variable_definitions: Dictionary = {}
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
		hints: Array[String] = [],
		var_defs: Dictionary = {}
	) -> OrderTemplate:
		var template = OrderTemplate.new(hidden_premises, hidden_conclusion, ops, desc, sol)
		template.is_natural_language = true
		template.natural_language_premises = nl_premises
		template.natural_language_conclusion = nl_conclusion
		template.interpretation_hints = hints
		template.variable_definitions = var_defs
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
	var variable_definitions: Dictionary = {}
	var natural_language_conclusion: String = ""

	func _init(name: String, premises: Array[String], conclusion: String, patience: float = 60.0, sol: String = "") -> void:
		customer_name = name
		required_premises = premises
		target_conclusion = conclusion
		patience_duration = patience
		solution = sol
		is_natural_language = false

	# Set natural language data for Level 6 problems
	func set_natural_language_data(nl_premises: Array[String], nl_conclusion: String, var_defs: Dictionary = {}) -> void:
		is_natural_language = true
		natural_language_premises = nl_premises
		natural_language_conclusion = nl_conclusion
		variable_definitions = var_defs
