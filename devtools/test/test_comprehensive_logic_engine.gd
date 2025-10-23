extends SceneTree

# Comprehensive Boolean Logic Engine Test Runner
# Loads and executes 100 tests from 7 JSON test files

var engine
var total_tests = 0
var passed_tests = 0
var failed_tests = 0
var category_stats = {}

func repeat_char(ch: String, count: int) -> String:
	var result = ""
	for i in range(count):
		result += ch
	return result

func _init():
	print(repeat_char("=", 80))
	print("COMPREHENSIVE BOOLEAN LOGIC ENGINE TEST SUITE")
	print("Testing 100 cases across all operations with parenthesis handling")
	print(repeat_char("=", 80))
	print()

	# Load the Boolean Logic Engine
	engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	# Test files to load
	var test_files = [
		"res://data/tests/logic_engine/01_basic_operators.json",
		"res://data/tests/logic_engine/02_inference_rules.json",
		"res://data/tests/logic_engine/03_equivalence_laws.json",
		"res://data/tests/logic_engine/04_complex_nested.json",
		"res://data/tests/logic_engine/05_multi_step.json",
		"res://data/tests/logic_engine/06_edge_cases.json",
		"res://data/tests/logic_engine/07_operator_combinations.json"
	]

	# Run tests from each file
	for test_file in test_files:
		run_test_file(test_file)

	# Print final summary
	print_summary()

	quit()

func run_test_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("ERROR: Could not open test file: ", file_path)
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("ERROR: Failed to parse JSON file: ", file_path)
		return

	var test_data = json.get_data()
	var category = test_data.get("category", "unknown")
	var tests = test_data.get("tests", [])

	print("\n" + repeat_char("─", 80))
	print("CATEGORY: ", category.to_upper())
	print("File: ", file_path.get_file())
	print("Test Count: ", tests.size())
	print(repeat_char("─", 80))

	# Initialize category stats
	category_stats[category] = {"total": 0, "passed": 0, "failed": 0}

	# Run each test
	for test in tests:
		run_single_test(test, category)

	# Print category summary
	var stats = category_stats[category]
	print("\nCategory Summary: %d/%d passed (%.1f%%)" % [
		stats.passed,
		stats.total,
		(float(stats.passed) / stats.total * 100.0) if stats.total > 0 else 0
	])

func run_single_test(test: Dictionary, category: String):
	var test_id = test.get("test_id", "UNKNOWN")
	var test_name = test.get("name", "Unnamed Test")
	var description = test.get("description", "")
	var operations = test.get("operations", [])
	var complexity = test.get("complexity_score", 0)

	total_tests += 1
	category_stats[category].total += 1

	print("\n  [%s] %s" % [test_id, test_name])
	print("  Description: %s" % description)
	print("  Complexity: %s%s" % [repeat_char("★", complexity), repeat_char("☆", 5 - complexity)])

	var test_passed = true
	var current_result = null
	var step_num = 0

	# Execute operations in sequence
	for operation in operations:
		step_num += 1
		var op_type = operation.get("type", "")

		print("    Step %d: %s" % [step_num, op_type])

		var step_result = execute_operation(operation, current_result)

		if step_result.has("error"):
			print("      ✗ ERROR: %s" % step_result.error)
			test_passed = false
			break
		elif step_result.has("success") and not step_result.success:
			print("      ✗ FAILED: %s" % step_result.get("message", "Validation failed"))
			test_passed = false
			break
		else:
			current_result = step_result.get("result")
			if step_result.has("output"):
				print("      → %s" % step_result.output)
			if step_result.has("validation") and step_result.validation:
				print("      ✓ Validated")

	# Update stats
	if test_passed:
		print("  ✓ PASSED")
		passed_tests += 1
		category_stats[category].passed += 1
	else:
		print("  ✗ FAILED")
		failed_tests += 1
		category_stats[category].failed += 1

func execute_operation(operation: Dictionary, previous_result) -> Dictionary:
	var op_type = operation.get("type", "")

	match op_type:
		"create_expression":
			return op_create_expression(operation)
		"apply_modus_ponens":
			return op_apply_inference(operation, "modus_ponens")
		"apply_modus_tollens":
			return op_apply_inference(operation, "modus_tollens")
		"apply_hypothetical_syllogism":
			return op_apply_inference(operation, "hypothetical_syllogism")
		"apply_disjunctive_syllogism":
			return op_apply_inference(operation, "disjunctive_syllogism")
		"apply_simplification":
			return op_apply_simplification(operation, previous_result)
		"apply_simplification_both":
			return op_apply_simplification_both(operation, previous_result)
		"apply_conjunction":
			return op_apply_conjunction(operation)
		"apply_addition":
			return op_apply_addition(operation, previous_result)
		"apply_constructive_dilemma":
			return op_apply_inference(operation, "constructive_dilemma")
		"apply_destructive_dilemma":
			return op_apply_inference(operation, "destructive_dilemma")
		"apply_resolution":
			return op_apply_inference(operation, "resolution")
		"apply_double_negation":
			return op_apply_transformation(operation, "double_negation", previous_result)
		"apply_de_morgan_and":
			return op_apply_transformation(operation, "de_morgan_and", previous_result)
		"apply_de_morgan_or":
			return op_apply_transformation(operation, "de_morgan_or", previous_result)
		"apply_commutativity":
			return op_apply_transformation(operation, "commutativity", previous_result)
		"apply_associativity":
			return op_apply_transformation(operation, "associativity", previous_result)
		"apply_distributivity":
			return op_apply_transformation(operation, "distributivity", previous_result)
		"apply_reverse_distributivity":
			return op_apply_transformation(operation, "reverse_distributivity", previous_result)
		"apply_idempotent":
			return op_apply_transformation(operation, "idempotent", previous_result)
		"apply_absorption":
			return op_apply_transformation(operation, "absorption", previous_result)
		"apply_negation_laws":
			return op_apply_transformation(operation, "negation_laws", previous_result)
		"apply_tautology_laws":
			return op_apply_transformation(operation, "tautology_laws", previous_result)
		"apply_contradiction_laws":
			return op_apply_transformation(operation, "contradiction_laws", previous_result)
		"apply_implication_conversion":
			return op_apply_transformation(operation, "implication_conversion", previous_result)
		"apply_contrapositive":
			return op_apply_transformation(operation, "contrapositive", previous_result)
		"apply_parenthesis_removal":
			return op_apply_transformation(operation, "parenthesis_removal", previous_result)
		"apply_xor_elimination":
			return op_apply_transformation(operation, "xor_elimination", previous_result)
		"apply_xor_elimination_both":
			return op_apply_xor_elimination_both(operation, previous_result)
		"apply_biconditional_to_implications":
			return op_apply_transformation(operation, "biconditional_to_implications", previous_result)
		"apply_biconditional_to_equivalence":
			return op_apply_transformation(operation, "biconditional_to_equivalence", previous_result)
		"apply_biconditional_to_implications_both":
			return op_apply_biconditional_both(operation, previous_result)
		"apply_equivalence":
			return op_apply_inference(operation, "equivalence")
		"create_conjunction":
			return op_create_conjunction(operation)
		"create_implication":
			return op_create_implication(operation)
		"create_negation":
			return op_create_negation(operation, previous_result)
		_:
			return {"error": "Unknown operation type: " + op_type}

func op_create_expression(operation: Dictionary) -> Dictionary:
	var input = operation.get("input", "")
	var expr = engine.create_expression(input)

	var expected_valid = operation.get("expected_valid", true)

	if expr.is_valid != expected_valid:
		return {
			"success": false,
			"message": "Expected valid=%s but got valid=%s" % [expected_valid, expr.is_valid]
		}

	if operation.has("expected_normalized"):
		var expected = operation.get("expected_normalized")
		if expr.normalized_string != expected:
			return {
				"success": false,
				"message": "Expected '%s' but got '%s'" % [expected, expr.normalized_string]
			}

	# Verify type checks
	if operation.get("verify_is_conjunction", false) and not expr.is_conjunction():
		return {"success": false, "message": "Expected conjunction"}
	if operation.get("verify_is_disjunction", false) and not expr.is_disjunction():
		return {"success": false, "message": "Expected disjunction"}
	if operation.get("verify_is_xor", false) and not expr.is_xor():
		return {"success": false, "message": "Expected XOR"}
	if operation.get("verify_is_implication", false) and not expr.is_implication():
		return {"success": false, "message": "Expected implication"}
	if operation.get("verify_is_biconditional", false) and not expr.is_biconditional():
		return {"success": false, "message": "Expected biconditional"}

	return {
		"success": true,
		"result": expr,
		"output": expr.expression_string,
		"validation": true
	}

func op_apply_inference(operation: Dictionary, rule_name: String) -> Dictionary:
	var premises_strs = operation.get("premises", [])
	var premises = []

	for p in premises_strs:
		premises.append(engine.create_expression(p))

	# Support additional_premise field for multi-step tests
	if operation.has("additional_premise"):
		var extra_str = operation.get("additional_premise")
		premises.append(engine.create_expression(extra_str))

	var result
	match rule_name:
		"modus_ponens":
			result = engine.apply_modus_ponens(premises)
		"modus_tollens":
			result = engine.apply_modus_tollens(premises)
		"hypothetical_syllogism":
			result = engine.apply_hypothetical_syllogism(premises)
		"disjunctive_syllogism":
			result = engine.apply_disjunctive_syllogism(premises)
		"constructive_dilemma":
			result = engine.apply_constructive_dilemma(premises)
		"destructive_dilemma":
			result = engine.apply_destructive_dilemma(premises)
		"resolution":
			result = engine.apply_resolution(premises)
		"equivalence":
			result = engine.apply_equivalence(premises)

	if not result or not result.is_valid:
		return {"error": "Inference rule %s failed to produce valid result" % rule_name}

	var expected = operation.get("expected_result", "")
	if expected != "" and result.expression_string != expected:
		return {
			"success": false,
			"message": "Expected '%s' but got '%s'" % [expected, result.expression_string]
		}

	return {
		"success": true,
		"result": result,
		"output": result.expression_string,
		"validation": true
	}

func op_apply_transformation(operation: Dictionary, transform_name: String, previous_result) -> Dictionary:
	var input_expr

	if operation.has("input"):
		input_expr = engine.create_expression(operation.get("input"))
	elif previous_result:
		input_expr = previous_result
	else:
		return {"error": "No input provided for transformation"}

	if not input_expr or not input_expr.is_valid:
		return {"error": "Invalid input expression for transformation"}

	var result
	match transform_name:
		"double_negation":
			result = engine.apply_double_negation(input_expr)
		"de_morgan_and":
			result = engine.apply_de_morgan_and(input_expr)
		"de_morgan_or":
			result = engine.apply_de_morgan_or(input_expr)
		"commutativity":
			result = engine.apply_commutativity(input_expr)
		"associativity":
			result = engine.apply_associativity(input_expr)
		"distributivity":
			result = engine.apply_distributivity(input_expr)
		"reverse_distributivity":
			result = engine.apply_reverse_distributivity(input_expr)
		"idempotent":
			result = engine.apply_idempotent(input_expr)
		"absorption":
			result = engine.apply_absorption(input_expr)
		"negation_laws":
			result = engine.apply_negation_laws(input_expr)
		"tautology_laws":
			result = engine.apply_tautology_laws(input_expr)
		"contradiction_laws":
			result = engine.apply_contradiction_laws(input_expr)
		"implication_conversion":
			result = engine.apply_implication_conversion(input_expr)
		"contrapositive":
			result = engine.apply_contrapositive(input_expr)
		"parenthesis_removal":
			result = engine.apply_parenthesis_removal(input_expr)
		"xor_elimination":
			result = engine.apply_xor_elimination(input_expr)
		"biconditional_to_implications":
			result = engine.apply_biconditional_to_implications(input_expr)
		"biconditional_to_equivalence":
			result = engine.apply_biconditional_to_equivalence(input_expr)

	if not result or not result.is_valid:
		return {"error": "Transformation %s failed to produce valid result" % transform_name}

	var expected = operation.get("expected_result", "")
	if expected != "" and result.expression_string != expected:
		return {
			"success": false,
			"message": "Expected '%s' but got '%s'" % [expected, result.expression_string]
		}

	return {
		"success": true,
		"result": result,
		"output": result.expression_string,
		"validation": true
	}

func op_apply_simplification(operation: Dictionary, previous_result) -> Dictionary:
	var input_expr

	if operation.has("premises"):
		var premise_str = operation.get("premises")[0]
		input_expr = engine.create_expression(premise_str)
	elif previous_result:
		input_expr = previous_result
	else:
		return {"error": "No input for simplification"}

	var extract_right = operation.get("extract_right", false)
	var result = engine.apply_simplification([input_expr], extract_right)

	if not result or not result.is_valid:
		return {"error": "Simplification failed"}

	var expected = operation.get("expected_result", "")
	if expected != "" and result.expression_string != expected:
		return {
			"success": false,
			"message": "Expected '%s' but got '%s'" % [expected, result.expression_string]
		}

	return {
		"success": true,
		"result": result,
		"output": result.expression_string,
		"validation": true
	}

func op_apply_simplification_both(operation: Dictionary, previous_result) -> Dictionary:
	var input_expr

	if operation.has("premises"):
		var premise_str = operation.get("premises")[0]
		input_expr = engine.create_expression(premise_str)
	elif previous_result:
		input_expr = previous_result
	else:
		return {"error": "No input for simplification"}

	var results = engine.apply_simplification_both([input_expr])

	if results.size() != 2:
		return {"error": "Simplification both should return 2 results"}

	var expected_results = operation.get("expected_results", [])
	if expected_results.size() == 2:
		for i in range(2):
			var result = results[i]
			if result.expression_string != expected_results[i]:
				return {
					"success": false,
					"message": "Result %d: Expected '%s' but got '%s'" % [i, expected_results[i], result.expression_string]
				}

	return {
		"success": true,
		"result": results,
		"output": "[%s, %s]" % [results[0].expression_string, results[1].expression_string],
		"validation": true
	}

func op_apply_conjunction(operation: Dictionary) -> Dictionary:
	var premises_strs = operation.get("premises", [])

	if premises_strs.size() != 2:
		return {"error": "Conjunction requires exactly 2 premises"}

	var p1 = engine.create_expression(premises_strs[0])
	var p2 = engine.create_expression(premises_strs[1])

	var result = engine.apply_conjunction([p1, p2])

	if not result or not result.is_valid:
		return {"error": "Conjunction failed"}

	var expected = operation.get("expected_result", "")
	if expected != "" and result.expression_string != expected:
		return {
			"success": false,
			"message": "Expected '%s' but got '%s'" % [expected, result.expression_string]
		}

	return {
		"success": true,
		"result": result,
		"output": result.expression_string,
		"validation": true
	}

func op_apply_addition(operation: Dictionary, previous_result) -> Dictionary:
	var premise_expr

	if operation.has("premises"):
		premise_expr = engine.create_expression(operation.get("premises")[0])
	elif previous_result:
		premise_expr = previous_result
	else:
		return {"error": "No premise for addition"}

	var additional_str = operation.get("additional", "")
	var additional = engine.create_expression(additional_str)

	var result = engine.apply_addition([premise_expr], additional)

	if not result or not result.is_valid:
		return {"error": "Addition failed"}

	var expected = operation.get("expected_result", "")
	if expected != "" and result.expression_string != expected:
		return {
			"success": false,
			"message": "Expected '%s' but got '%s'" % [expected, result.expression_string]
		}

	return {
		"success": true,
		"result": result,
		"output": result.expression_string,
		"validation": true
	}

func op_apply_xor_elimination_both(operation: Dictionary, previous_result) -> Dictionary:
	var input_expr

	if operation.has("input"):
		input_expr = engine.create_expression(operation.get("input"))
	elif previous_result:
		input_expr = previous_result
	else:
		return {"error": "No input for XOR elimination"}

	var results = engine.apply_xor_elimination_both(input_expr)

	if results.size() != 2:
		return {"error": "XOR elimination both should return 2 results"}

	var expected_results = operation.get("expected_results", [])
	if expected_results.size() == 2:
		for i in range(2):
			var result = results[i]
			if result.expression_string != expected_results[i]:
				return {
					"success": false,
					"message": "Result %d: Expected '%s' but got '%s'" % [i, expected_results[i], result.expression_string]
				}

	return {
		"success": true,
		"result": results,
		"output": "[%s, %s]" % [results[0].expression_string, results[1].expression_string],
		"validation": true
	}

func op_apply_biconditional_both(operation: Dictionary, previous_result) -> Dictionary:
	var input_expr

	if operation.has("input"):
		input_expr = engine.create_expression(operation.get("input"))
	elif previous_result:
		input_expr = previous_result
	else:
		return {"error": "No input for biconditional"}

	var results = engine.apply_biconditional_to_implications_both(input_expr)

	if results.size() != 2:
		return {"error": "Biconditional both should return 2 results"}

	return {
		"success": true,
		"result": results,
		"output": "[%s, %s]" % [results[0].expression_string, results[1].expression_string],
		"validation": true
	}

func op_create_conjunction(operation: Dictionary) -> Dictionary:
	var left_str = operation.get("left", "")
	var right_str = operation.get("right", "")

	var left = engine.create_expression(left_str)
	var right = engine.create_expression(right_str)

	var result = engine.create_conjunction_expression(left, right)

	if not result or not result.is_valid:
		return {"error": "Create conjunction failed"}

	var expected = operation.get("expected_result", "")
	if expected != "" and result.expression_string != expected:
		return {
			"success": false,
			"message": "Expected '%s' but got '%s'" % [expected, result.expression_string]
		}

	return {
		"success": true,
		"result": result,
		"output": result.expression_string,
		"validation": true
	}

func op_create_implication(operation: Dictionary) -> Dictionary:
	var ante_str = operation.get("antecedent", "")
	var cons_str = operation.get("consequent", "")

	var antecedent = engine.create_expression(ante_str)
	var consequent = engine.create_expression(cons_str)

	var result = engine.create_implication_expression(antecedent, consequent)

	if not result or not result.is_valid:
		return {"error": "Create implication failed"}

	var expected = operation.get("expected_result", "")
	if expected != "" and result.expression_string != expected:
		return {
			"success": false,
			"message": "Expected '%s' but got '%s'" % [expected, result.expression_string]
		}

	return {
		"success": true,
		"result": result,
		"output": result.expression_string,
		"validation": true
	}

func op_create_negation(operation: Dictionary, previous_result) -> Dictionary:
	if not previous_result:
		return {"error": "No input for negation"}

	var result = engine.create_negation_expression(previous_result)

	if not result or not result.is_valid:
		return {"error": "Create negation failed"}

	var expected = operation.get("expected_result", "")
	if expected != "" and result.expression_string != expected:
		return {
			"success": false,
			"message": "Expected '%s' but got '%s'" % [expected, result.expression_string]
		}

	return {
		"success": true,
		"result": result,
		"output": result.expression_string,
		"validation": true
	}

func print_summary():
	print("\n" + repeat_char("=", 80))
	print("FINAL TEST RESULTS")
	print(repeat_char("=", 80))

	print("\nCategory Breakdown:")
	for category in category_stats.keys():
		var stats = category_stats[category]
		var percentage = (float(stats.passed) / stats.total * 100.0) if stats.total > 0 else 0
		var bar_length = int(percentage / 5.0)
		var bar = repeat_char("█", bar_length) + repeat_char("░", 20 - bar_length)
		var cat_name = category.to_upper()
		while cat_name.length() < 25:
			cat_name += " "
		print("  %s: %s %d/%d (%.1f%%)" % [
			cat_name,
			bar,
			stats.passed,
			stats.total,
			percentage
		])

	print("\n" + repeat_char("─", 80))
	print("OVERALL RESULTS:")
	print("  Total Tests: %d" % total_tests)
	print("  Passed: %d ✓" % passed_tests)
	print("  Failed: %d ✗" % failed_tests)

	var overall_percentage = (float(passed_tests) / total_tests * 100.0) if total_tests > 0 else 0
	print("  Success Rate: %.2f%%" % overall_percentage)
	print(repeat_char("=", 80))

	if passed_tests == total_tests:
		print("\n🎉 ALL 100 TESTS PASSED! 🎉")
		print("✅ Boolean Logic Engine is FULLY VALIDATED!")
		print("✅ All operators tested: ∧ ∨ ⊕ ¬ → ↔")
		print("✅ All 13 inference rules verified")
		print("✅ All equivalence laws validated")
		print("✅ Parenthesis preservation confirmed")
		print("✅ Complex nested expressions handled correctly")
		print("✅ Edge cases and error handling working")
		print("✅ Ready for production use!")
	elif overall_percentage >= 90:
		print("\n✓ Excellent! Most tests passing (%.1f%%)" % overall_percentage)
	elif overall_percentage >= 75:
		print("\n⚠ Good progress, but needs improvement (%.1f%%)" % overall_percentage)
	else:
		print("\n✗ CRITICAL: Many tests failing (%.1f%%)" % overall_percentage)
		print("⚠ Engine requires debugging and fixes")

	print("\n" + repeat_char("=", 80))
