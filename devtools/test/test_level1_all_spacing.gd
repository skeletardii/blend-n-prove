extends SceneTree

func _init():
	print("================================================================================")
	print("TESTING ALL LEVEL 1 SPACING ISSUES")
	print("================================================================================")

	# Load the BooleanLogicEngine
	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	var tests_passed = 0
	var tests_total = 0

	# Test 1: Conjunction (P, Q -> P ∧ Q)
	tests_total += 1
	var p1 = engine.create_expression("P")
	var q1 = engine.create_expression("Q")
	var result1 = engine.apply_conjunction([p1, q1])
	var expected1 = "(P ∧ Q)"
	if result1.expression_string == expected1:
		print("✓ Test 1 PASSED: Conjunction - " + result1.expression_string)
		tests_passed += 1
	else:
		print("✗ Test 1 FAILED: Conjunction")
		print("  Expected: \"" + expected1 + "\"")
		print("  Got:      \"" + result1.expression_string + "\"")

	# Test 2: De Morgan's AND (¬(P∧Q) -> ¬P ∨ ¬Q)
	tests_total += 1
	var dm_and_input = engine.create_expression("¬(P∧Q)")
	var result2 = engine.apply_de_morgan_and(dm_and_input)
	var expected2 = "(¬P ∨ ¬Q)"
	if result2.expression_string == expected2:
		print("✓ Test 2 PASSED: De Morgan's AND - " + result2.expression_string)
		tests_passed += 1
	else:
		print("✗ Test 2 FAILED: De Morgan's AND")
		print("  Expected: \"" + expected2 + "\"")
		print("  Got:      \"" + result2.expression_string + "\"")

	# Test 3: De Morgan's OR (¬(P∨Q) -> ¬P ∧ ¬Q)
	tests_total += 1
	var dm_or_input = engine.create_expression("¬(P∨Q)")
	var result3 = engine.apply_de_morgan_or(dm_or_input)
	var expected3 = "(¬P ∧ ¬Q)"
	if result3.expression_string == expected3:
		print("✓ Test 3 PASSED: De Morgan's OR - " + result3.expression_string)
		tests_passed += 1
	else:
		print("✗ Test 3 FAILED: De Morgan's OR")
		print("  Expected: \"" + expected3 + "\"")
		print("  Got:      \"" + result3.expression_string + "\"")

	# Test 4: Commutativity AND (P∧Q -> Q ∧ P)
	tests_total += 1
	var comm_and_input = engine.create_expression("P∧Q")
	var result4 = engine.apply_commutativity(comm_and_input)
	var expected4 = "(Q ∧ P)"
	if result4.expression_string == expected4:
		print("✓ Test 4 PASSED: Commutativity AND - " + result4.expression_string)
		tests_passed += 1
	else:
		print("✗ Test 4 FAILED: Commutativity AND")
		print("  Expected: \"" + expected4 + "\"")
		print("  Got:      \"" + result4.expression_string + "\"")

	# Test 5: Commutativity OR (P∨Q -> Q ∨ P)
	tests_total += 1
	var comm_or_input = engine.create_expression("P∨Q")
	var result5 = engine.apply_commutativity(comm_or_input)
	var expected5 = "(Q ∨ P)"
	if result5.expression_string == expected5:
		print("✓ Test 5 PASSED: Commutativity OR - " + result5.expression_string)
		tests_passed += 1
	else:
		print("✗ Test 5 FAILED: Commutativity OR")
		print("  Expected: \"" + expected5 + "\"")
		print("  Got:      \"" + result5.expression_string + "\"")

	# Test 6: Addition 1 (P -> P ∨ Q)
	tests_total += 1
	var p6 = engine.create_expression("P")
	var q6 = engine.create_expression("Q")
	var result6 = engine.apply_addition([p6], q6)
	var expected6 = "(P ∨ Q)"
	if result6.expression_string == expected6:
		print("✓ Test 6 PASSED: Addition (P) - " + result6.expression_string)
		tests_passed += 1
	else:
		print("✗ Test 6 FAILED: Addition (P)")
		print("  Expected: \"" + expected6 + "\"")
		print("  Got:      \"" + result6.expression_string + "\"")

	# Test 7: Addition 2 (R -> R ∨ S)
	tests_total += 1
	var r7 = engine.create_expression("R")
	var s7 = engine.create_expression("S")
	var result7 = engine.apply_addition([r7], s7)
	var expected7 = "(R ∨ S)"
	if result7.expression_string == expected7:
		print("✓ Test 7 PASSED: Addition (R) - " + result7.expression_string)
		tests_passed += 1
	else:
		print("✗ Test 7 FAILED: Addition (R)")
		print("  Expected: \"" + expected7 + "\"")
		print("  Got:      \"" + result7.expression_string + "\"")

	print("\n================================================================================")
	print("RESULTS: " + str(tests_passed) + "/" + str(tests_total) + " tests passed")
	if tests_passed == tests_total:
		print("✓ ALL LEVEL 1 SPACING ISSUES FIXED!")
	else:
		print("✗ Some tests still failing")
	print("================================================================================")

	quit()
