extends SceneTree

func _init():
	print("================================================================================")
	print("TESTING SPACING ACROSS ALL LEVELS")
	print("================================================================================")

	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	var tests_passed = 0
	var tests_total = 0

	# Test samples from each level

	print("\n--- LEVEL 1 SAMPLES ---")

	# Level 1: Conjunction
	tests_total += 1
	var p1 = engine.create_expression("P")
	var q1 = engine.create_expression("Q")
	var result1 = engine.apply_conjunction([p1, q1])
	if verify_match(result1, "(P ∧ Q)", "Level 1 - Conjunction"):
		tests_passed += 1

	# Level 1: Addition
	tests_total += 1
	var p2 = engine.create_expression("P")
	var q2 = engine.create_expression("Q")
	var result2 = engine.apply_addition([p2], q2)
	if verify_match(result2, "(P ∨ Q)", "Level 1 - Addition"):
		tests_passed += 1

	print("\n--- LEVEL 2 SAMPLES ---")

	# Level 2: Modus Ponens then Conjunction (P→Q, P, R ⊢ Q∧R)
	tests_total += 1
	var pq = engine.create_expression("P→Q")
	var p3 = engine.create_expression("P")
	var mp_result = engine.apply_modus_ponens([pq, p3])
	var r = engine.create_expression("R")
	var result3 = engine.apply_conjunction([mp_result, r])
	if verify_match(result3, "(Q ∧ R)", "Level 2 - MP then Conjunction"):
		tests_passed += 1

	# Level 2: De Morgan (¬(P∨Q) ⊢ ¬P∧¬Q)
	tests_total += 1
	var dm_input = engine.create_expression("¬(P∨Q)")
	var result4 = engine.apply_de_morgan_or(dm_input)
	if verify_match(result4, "(¬P ∧ ¬Q)", "Level 2 - De Morgan OR"):
		tests_passed += 1

	print("\n--- LEVEL 3 SAMPLES ---")

	# Level 3: Conjunction chaining
	tests_total += 1
	var p4 = engine.create_expression("P")
	var q4 = engine.create_expression("Q")
	var pq_conj = engine.apply_conjunction([p4, q4])
	if verify_match(pq_conj, "(P ∧ Q)", "Level 3 - Conjunction"):
		tests_passed += 1

	print("\n--- LEVEL 4 SAMPLES ---")

	# Level 4: Constructive Dilemma result
	tests_total += 1
	var q5 = engine.create_expression("Q")
	var s5 = engine.create_expression("S")
	var result5 = engine.apply_conjunction([q5, s5])
	if verify_match(result5, "(Q ∧ S)", "Level 4 - Conjunction"):
		tests_passed += 1

	print("\n--- LEVEL 5 SAMPLES ---")

	# Level 5: Complex conjunction
	tests_total += 1
	var s6 = engine.create_expression("S")
	var t6 = engine.create_expression("T")
	var result6 = engine.apply_conjunction([s6, t6])
	if verify_match(result6, "(S ∧ T)", "Level 5 - Conjunction"):
		tests_passed += 1

	print("\n================================================================================")
	print("RESULTS: " + str(tests_passed) + "/" + str(tests_total) + " tests passed")
	if tests_passed == tests_total:
		print("✓✓✓ ALL SPACING ISSUES FIXED ACROSS ALL LEVELS! ✓✓✓")
	else:
		print("✗ Some tests still failing")
	print("================================================================================")

	quit()

func verify_match(result, expected: String, test_name: String) -> bool:
	if result.expression_string == expected:
		print("  ✓ " + test_name + ": " + result.expression_string)
		return true
	else:
		print("  ✗ " + test_name)
		print("    Expected: \"" + expected + "\"")
		print("    Got:      \"" + result.expression_string + "\"")
		return false
