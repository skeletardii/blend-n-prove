extends SceneTree

# Test De Morgan's tutorial problems

var engine

func repeat_str(s: String, count: int) -> String:
	var result = ""
	for i in range(count):
		result += s
	return result

func _init():
	print("\n================================================================================")
	print("TESTING DE MORGAN'S TUTORIAL PROBLEMS")
	print("================================================================================\n")

	# Load the implementation directly
	engine = load("res://src/managers/BooleanLogicEngineImpl.gd").new()

	run_tests()

	quit()

func run_tests():
	var passed = 0
	var failed = 0

	# Test De Morgan's AND tutorial problems
	print(repeat_str("=", 80))
	print("DE MORGAN'S AND TUTORIAL PROBLEMS")
	print(repeat_str("=", 80) + "\n")

	var and_problems = [
		{"premise": "¬(P ∧ Q)", "conclusion": "¬P ∨ ¬Q"},
		{"premise": "¬(R ∧ S)", "conclusion": "¬R ∨ ¬S"},
		{"premise": "¬(A ∧ B)", "conclusion": "¬A ∨ ¬B"},
		{"premise": "¬((P ∨ Q) ∧ R)", "conclusion": "¬(P ∨ Q) ∨ ¬R"},
	]

	for i in range(and_problems.size()):
		var problem = and_problems[i]
		print("Problem %d: %s → %s" % [i + 1, problem.premise, problem.conclusion])

		var premise_expr = engine.create_expression(problem.premise)
		var result = engine.apply_de_morgan_and(premise_expr)
		var expected = engine.create_expression(problem.conclusion)

		print("  Input: " + premise_expr.normalized_string)
		print("  Output: " + result.normalized_string)
		print("  Expected: " + expected.normalized_string)

		if result.is_valid and result.normalized_string == expected.normalized_string:
			print("  ✓ PASSED\n")
			passed += 1
		else:
			# Check semantic equivalence
			if engine.are_semantically_equivalent(result, expected):
				print("  ✓ PASSED (semantically equivalent)\n")
				passed += 1
			else:
				print("  ✗ FAILED\n")
				failed += 1

	# Test De Morgan's OR tutorial problems
	print(repeat_str("=", 80))
	print("DE MORGAN'S OR TUTORIAL PROBLEMS")
	print(repeat_str("=", 80) + "\n")

	var or_problems = [
		{"premise": "¬(P ∨ Q)", "conclusion": "¬P ∧ ¬Q"},
		{"premise": "¬(R ∨ S)", "conclusion": "¬R ∧ ¬S"},
		{"premise": "¬(A ∨ B)", "conclusion": "¬A ∧ ¬B"},
		{"premise": "¬((P ∧ Q) ∨ R)", "conclusion": "¬(P ∧ Q) ∧ ¬R"},
	]

	for i in range(or_problems.size()):
		var problem = or_problems[i]
		print("Problem %d: %s → %s" % [i + 1, problem.premise, problem.conclusion])

		var premise_expr = engine.create_expression(problem.premise)
		var result = engine.apply_de_morgan_or(premise_expr)
		var expected = engine.create_expression(problem.conclusion)

		print("  Input: " + premise_expr.normalized_string)
		print("  Output: " + result.normalized_string)
		print("  Expected: " + expected.normalized_string)

		if result.is_valid and result.normalized_string == expected.normalized_string:
			print("  ✓ PASSED\n")
			passed += 1
		else:
			# Check semantic equivalence
			if engine.are_semantically_equivalent(result, expected):
				print("  ✓ PASSED (semantically equivalent)\n")
				passed += 1
			else:
				print("  ✗ FAILED\n")
				failed += 1

	# Test that De Morgan's FAILS on incorrect patterns
	print(repeat_str("=", 80))
	print("DE MORGAN'S SHOULD FAIL ON INCORRECT PATTERNS")
	print(repeat_str("=", 80) + "\n")

	var invalid_patterns = [
		{"premise": "P ∧ Q", "name": "No negation"},
		{"premise": "¬P ∧ Q", "name": "Only one operand negated"},
		{"premise": "P ∨ Q", "name": "No negation (OR)"},
		{"premise": "¬P", "name": "Single negated variable"},
	]

	for i in range(invalid_patterns.size()):
		var problem = invalid_patterns[i]
		print("Test %d: %s (%s)" % [i + 1, problem.premise, problem.name])

		var premise_expr = engine.create_expression(problem.premise)
		var result1 = engine.apply_de_morgan_and(premise_expr)
		var result2 = engine.apply_de_morgan_or(premise_expr)

		print("  Input: " + premise_expr.normalized_string)
		print("  De Morgan AND result: " + str(result1.normalized_string if result1.is_valid else "INVALID"))
		print("  De Morgan OR result: " + str(result2.normalized_string if result2.is_valid else "INVALID"))

		if not result1.is_valid and not result2.is_valid:
			print("  ✓ PASSED (correctly rejected)\n")
			passed += 1
		else:
			print("  ✗ FAILED (should have been rejected)\n")
			failed += 1

	# Summary
	print(repeat_str("=", 80))
	print("SUMMARY: %d/%d tests passed" % [passed, passed + failed])
	if failed == 0:
		print("✓ ALL TESTS PASSED!")
	else:
		print("✗ %d tests failed" % failed)
	print(repeat_str("=", 80))
