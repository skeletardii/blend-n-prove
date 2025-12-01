extends Node

# Explicit preload to ensure BooleanExpression type is available
const BooleanExpression = preload("res://src/game/expressions/BooleanExpression.gd")

# Tutorial Testing Script
# Tests all tutorial problems to ensure they can be solved with the Boolean Logic Engine
#
# To run this test:
# 1. Open Godot Editor
# 2. Open TutorialTestScene.tscn
# 3. Click "Play Scene" (F6)
# OR
# 4. From main menu, press 'T' key to run tests

var tests_passed: int = 0
var tests_failed: int = 0
var failed_tests: Array[Dictionary] = []

func _ready() -> void:
	print("\n" + "="*80)
	print("TUTORIAL PROBLEM TESTING SUITE")
	print("="*80 + "\n")

	# Wait for tutorials to load
	if TutorialDataManager.tutorials_loaded:
		run_all_tests()
	else:
		TutorialDataManager.all_tutorials_loaded.connect(run_all_tests)

func run_all_tests() -> void:
	print("Testing all tutorials...\n")

	var tutorial_keys: Array = TutorialDataManager.get_all_tutorial_keys()

	for tutorial_key in tutorial_keys:
		test_tutorial(tutorial_key)

	print_summary()

	# Exit after testing
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func test_tutorial(tutorial_key: String) -> void:
	var tutorial: TutorialDataManager.TutorialData = TutorialDataManager.get_tutorial_by_name(tutorial_key)

	if not tutorial:
		print("✗ Failed to load tutorial: ", tutorial_key)
		return

	print("\n" + "-"*80)
	print("Testing: ", tutorial.rule_name)
	print("-"*80)

	for i in range(tutorial.problems.size()):
		var problem: TutorialDataManager.ProblemData = tutorial.problems[i]
		test_problem(tutorial, problem, i)

func test_problem(tutorial: TutorialDataManager.TutorialData, problem: TutorialDataManager.ProblemData, index: int) -> void:
	var test_name: String = tutorial.rule_name + " - Problem " + str(problem.problem_number) + " (" + problem.difficulty + ")"

	# Create boolean expressions from premises
	var premise_expressions: Array[BooleanExpression] = []
	for premise_str in problem.premises:
		var expr: BooleanExpression = BooleanLogicEngine.create_expression(premise_str)
		if not expr.is_valid:
			record_failure(test_name, "Invalid premise: " + premise_str, problem)
			return
		premise_expressions.append(expr)

	# Create conclusion expression
	var conclusion_expr: BooleanExpression = BooleanLogicEngine.create_expression(problem.conclusion)
	if not conclusion_expr.is_valid:
		record_failure(test_name, "Invalid conclusion: " + problem.conclusion, problem)
		return

	# Try to derive the conclusion from premises
	var result: bool = test_derivation(tutorial.tutorial_key, premise_expressions, conclusion_expr)

	if result:
		tests_passed += 1
		print("  ✓ Problem ", problem.problem_number, ": ", problem.conclusion)
	else:
		record_failure(test_name, "Could not derive conclusion from premises", problem)

func test_derivation(tutorial_key: String, premises: Array[BooleanExpression], conclusion: BooleanExpression) -> bool:
	# Test based on tutorial type
	match tutorial_key:
		"modus-ponens":
			return test_modus_ponens(premises, conclusion)
		"modus-tollens":
			return test_modus_tollens(premises, conclusion)
		"hypothetical-syllogism":
			return test_hypothetical_syllogism(premises, conclusion)
		"disjunctive-syllogism":
			return test_disjunctive_syllogism(premises, conclusion)
		"simplification":
			return test_simplification(premises, conclusion)
		"conjunction":
			return test_conjunction(premises, conclusion)
		"addition":
			return test_addition(premises, conclusion)
		"de-morgans-and":
			return test_de_morgans_and(premises, conclusion)
		"de-morgans-or":
			return test_de_morgans_or(premises, conclusion)
		"double-negation":
			return test_double_negation(premises, conclusion)
		"resolution":
			return test_resolution(premises, conclusion)
		"biconditional":
			return test_biconditional(premises, conclusion)
		"distributivity":
			return test_distributivity(premises, conclusion)
		"commutativity":
			return test_commutativity(premises, conclusion)
		"associativity":
			return test_associativity(premises, conclusion)
		"idempotent":
			return test_idempotent(premises, conclusion)
		"absorption":
			return test_absorption(premises, conclusion)
		"negation-laws":
			return test_negation_laws(premises, conclusion)

	return false

# Individual rule tests
func test_modus_ponens(premises: Array, conclusion: BooleanExpression) -> bool:
	var result: BooleanExpression = BooleanLogicEngine.apply_modus_ponens(premises)
	return result.is_valid and result.equals(conclusion)

func test_modus_tollens(premises: Array, conclusion: BooleanExpression) -> bool:
	var result: BooleanExpression = BooleanLogicEngine.apply_modus_tollens(premises)
	return result.is_valid and result.equals(conclusion)

func test_hypothetical_syllogism(premises: Array, conclusion: BooleanExpression) -> bool:
	var result: BooleanExpression = BooleanLogicEngine.apply_hypothetical_syllogism(premises)
	return result.is_valid and result.equals(conclusion)

func test_disjunctive_syllogism(premises: Array, conclusion: BooleanExpression) -> bool:
	var result: BooleanExpression = BooleanLogicEngine.apply_disjunctive_syllogism(premises)
	return result.is_valid and result.equals(conclusion)

func test_simplification(premises: Array, conclusion: BooleanExpression) -> bool:
	var result: BooleanExpression = BooleanLogicEngine.apply_simplification(premises)
	if result.is_valid and result.equals(conclusion):
		return true
	# Try right simplification if left didn't work
	if premises.size() == 1 and premises[0].is_conjunction():
		var conj_parts = premises[0].get_conjunction_parts()
		if conj_parts.get("valid", false):
			var right = conj_parts.get("right") as BooleanExpression
			return right and right.equals(conclusion)
	return false

func test_conjunction(premises: Array, conclusion: BooleanExpression) -> bool:
	var result: BooleanExpression = BooleanLogicEngine.apply_conjunction(premises)
	return result.is_valid and result.equals(conclusion)

func test_addition(premises: Array, conclusion: BooleanExpression) -> bool:
	# Addition is tricky - we need to extract what to add from the conclusion
	if premises.size() != 1 or not conclusion.is_disjunction():
		return false

	var disj_parts = conclusion.get_disjunction_parts()
	if not disj_parts.get("valid", false):
		return false

	var left = disj_parts.get("left") as BooleanExpression
	var right = disj_parts.get("right") as BooleanExpression

	# Check if premise matches either side
	return (premises[0].equals(left) or premises[0].equals(right))

func test_de_morgans_and(premises: Array, conclusion: BooleanExpression) -> bool:
	if premises.size() != 1:
		return false
	var result: BooleanExpression = BooleanLogicEngine.apply_de_morgan_and(premises[0])
	return result.is_valid and result.equals(conclusion)

func test_de_morgans_or(premises: Array, conclusion: BooleanExpression) -> bool:
	if premises.size() != 1:
		return false
	var result: BooleanExpression = BooleanLogicEngine.apply_de_morgan_or(premises[0])
	return result.is_valid and result.equals(conclusion)

func test_double_negation(premises: Array, conclusion: BooleanExpression) -> bool:
	if premises.size() != 1:
		return false
	var result: BooleanExpression = BooleanLogicEngine.apply_double_negation(premises[0])
	return result.is_valid and result.equals(conclusion)

func test_resolution(premises: Array, conclusion: BooleanExpression) -> bool:
	var result: BooleanExpression = BooleanLogicEngine.apply_resolution(premises)
	return result.is_valid and result.equals(conclusion)

func test_biconditional(premises: Array, conclusion: BooleanExpression) -> bool:
	var result: BooleanExpression = BooleanLogicEngine.apply_equivalence(premises)
	return result.is_valid and result.equals(conclusion)

func test_distributivity(premises: Array, conclusion: BooleanExpression) -> bool:
	if premises.size() != 1:
		return false
	var result: BooleanExpression = BooleanLogicEngine.apply_distributivity(premises[0])
	return result.is_valid and result.equals(conclusion)

func test_commutativity(premises: Array, conclusion: BooleanExpression) -> bool:
	if premises.size() != 1:
		return false
	var result: BooleanExpression = BooleanLogicEngine.apply_commutativity(premises[0])
	return result.is_valid and result.equals(conclusion)

func test_associativity(premises: Array, conclusion: BooleanExpression) -> bool:
	if premises.size() != 1:
		return false
	var result: BooleanExpression = BooleanLogicEngine.apply_associativity(premises[0])
	return result.is_valid and result.equals(conclusion)

func test_idempotent(premises: Array, conclusion: BooleanExpression) -> bool:
	if premises.size() != 1:
		return false
	var result: BooleanExpression = BooleanLogicEngine.apply_idempotent(premises[0])
	return result.is_valid and result.equals(conclusion)

func test_absorption(premises: Array, conclusion: BooleanExpression) -> bool:
	if premises.size() != 1:
		return false
	var result: BooleanExpression = BooleanLogicEngine.apply_absorption(premises[0])
	return result.is_valid and result.equals(conclusion)

func test_negation_laws(premises: Array, conclusion: BooleanExpression) -> bool:
	if premises.size() != 1:
		return false
	var result: BooleanExpression = BooleanLogicEngine.apply_negation_laws(premises[0])
	return result.is_valid and result.equals(conclusion)

func record_failure(test_name: String, reason: String, problem: TutorialDataManager.ProblemData) -> void:
	tests_failed += 1
	print("  ✗ Problem ", problem.problem_number, ": ", reason)

	failed_tests.append({
		"test": test_name,
		"reason": reason,
		"premises": problem.premises,
		"conclusion": problem.conclusion,
		"solution": problem.solution
	})

func print_summary() -> void:
	print("\n" + "="*80)
	print("TEST SUMMARY")
	print("="*80)
	print("Total tests: ", tests_passed + tests_failed)
	print("Passed: ", tests_passed, " ✓")
	print("Failed: ", tests_failed, " ✗")

	if tests_failed > 0:
		print("\n" + "-"*80)
		print("FAILED TESTS DETAILS")
		print("-"*80)
		for i in range(min(failed_tests.size(), 10)):  # Show first 10 failures
			var test = failed_tests[i]
			print("\n", i + 1, ". ", test["test"])
			print("   Reason: ", test["reason"])
			print("   Premises: ", test["premises"])
			print("   Expected: ", test["conclusion"])
			print("   Solution: ", test["solution"])

		if failed_tests.size() > 10:
			print("\n   ... and ", failed_tests.size() - 10, " more failures")

	print("\n" + "="*80)

	if tests_failed == 0:
		print("🎉 ALL TESTS PASSED!")
	else:
		print("⚠️  SOME TESTS FAILED - Review and fix tutorial problems")

	print("="*80 + "\n")