extends SceneTree

# Test script for reverse De Morgan's laws

var engine
var passed = 0
var failed = 0

func _init():
	print("\n================================================================================")
	print("TESTING REVERSE DE MORGAN'S LAWS")
	print("================================================================================\n")

	# Load the Boolean Logic Engine
	engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	run_tests()

	quit()

func run_tests():

	# Test 1: Reverse De Morgan's AND - ¬P ∨ ¬Q → ¬(P ∧ Q)
	print("Test 1: Reverse De Morgan's AND - ¬P ∨ ¬Q → ¬(P ∧ Q)")
	var expr1 = engine.create_expression("¬P ∨ ¬Q")
	print("  Input: " + expr1.normalized_string)
	var result1 = engine.apply_de_morgan_and_reverse(expr1)
	print("  Output: " + result1.normalized_string)
	if result1.is_valid and result1.normalized_string == "¬(P ∧ Q)":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: ¬(P ∧ Q), Got: " + result1.normalized_string + "\n")
		failed += 1

	# Test 2: Reverse De Morgan's OR - ¬P ∧ ¬Q → ¬(P ∨ Q)
	print("Test 2: Reverse De Morgan's OR - ¬P ∧ ¬Q → ¬(P ∨ Q)")
	var expr2 = engine.create_expression("¬P ∧ ¬Q")
	print("  Input: " + expr2.normalized_string)
	var result2 = engine.apply_de_morgan_or_reverse(expr2)
	print("  Output: " + result2.normalized_string)
	if result2.is_valid and result2.normalized_string == "¬(P ∨ Q)":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: ¬(P ∨ Q), Got: " + result2.normalized_string + "\n")
		failed += 1

	# Test 3: Reverse De Morgan's AND with complex expressions
	print("Test 3: Reverse De Morgan's AND - ¬(P ∨ Q) ∨ ¬R → ¬((P ∨ Q) ∧ R)")
	var expr3 = engine.create_expression("¬(P ∨ Q) ∨ ¬R")
	print("  Input: " + expr3.normalized_string)
	var result3 = engine.apply_de_morgan_and_reverse(expr3)
	print("  Output: " + result3.normalized_string)
	if result3.is_valid and (result3.normalized_string == "¬((P ∨ Q) ∧ R)" or result3.normalized_string == "¬(((P ∨ Q)) ∧ (R))"):
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: ¬((P ∨ Q) ∧ R), Got: " + result3.normalized_string + "\n")
		failed += 1

	# Test 4: Reverse De Morgan's OR with complex expressions
	print("Test 4: Reverse De Morgan's OR - ¬P ∧ ¬(Q ∨ R) → ¬(P ∨ (Q ∨ R))")
	var expr4 = engine.create_expression("¬P ∧ ¬(Q ∨ R)")
	print("  Input: " + expr4.normalized_string)
	var result4 = engine.apply_de_morgan_or_reverse(expr4)
	print("  Output: " + result4.normalized_string)
	if result4.is_valid and (result4.normalized_string == "¬(P ∨ (Q ∨ R))" or result4.normalized_string == "¬((P) ∨ ((Q ∨ R)))"):
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: ¬(P ∨ (Q ∨ R)), Got: " + result4.normalized_string + "\n")
		failed += 1

	# Test 5: Forward De Morgan's still works
	print("Test 5: Forward De Morgan's AND - ¬(P ∧ Q) → ¬P ∨ ¬Q")
	var expr5 = engine.create_expression("¬(P ∧ Q)")
	print("  Input: " + expr5.normalized_string)
	var result5 = engine.apply_de_morgan_and(expr5)
	print("  Output: " + result5.normalized_string)
	if result5.is_valid and (result5.normalized_string == "¬P ∨ ¬Q" or result5.normalized_string == "(¬P ∨ ¬Q)"):
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: ¬P ∨ ¬Q, Got: " + result5.normalized_string + "\n")
		failed += 1

	# Test 6: Forward De Morgan's OR still works
	print("Test 6: Forward De Morgan's OR - ¬(P ∨ Q) → ¬P ∧ ¬Q")
	var expr6 = engine.create_expression("¬(P ∨ Q)")
	print("  Input: " + expr6.normalized_string)
	var result6 = engine.apply_de_morgan_or(expr6)
	print("  Output: " + result6.normalized_string)
	if result6.is_valid and (result6.normalized_string == "¬P ∧ ¬Q" or result6.normalized_string == "(¬P ∧ ¬Q)"):
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: ¬P ∧ ¬Q, Got: " + result6.normalized_string + "\n")
		failed += 1

	# Test 7: Detection in available operations
	print("Test 7: Reverse De Morgan's detected in available operations")
	var expr7a = engine.create_expression("¬P ∨ ¬Q")
	var ops7a = engine.get_applicable_single_operations(expr7a)
	print("  Input: ¬P ∨ ¬Q")
	print("  Available ops: " + str(ops7a))
	if "De Morgan's Reverse (AND)" in ops7a:
		print("  ✓ PASSED - Reverse De Morgan's AND detected\n")
		passed += 1
	else:
		print("  ✗ FAILED - Reverse De Morgan's AND not detected\n")
		failed += 1

	var expr7b = engine.create_expression("¬P ∧ ¬Q")
	var ops7b = engine.get_applicable_single_operations(expr7b)
	print("  Input: ¬P ∧ ¬Q")
	print("  Available ops: " + str(ops7b))
	if "De Morgan's Reverse (OR)" in ops7b:
		print("  ✓ PASSED - Reverse De Morgan's OR detected\n")
		passed += 1
	else:
		print("  ✗ FAILED - Reverse De Morgan's OR not detected\n")
		failed += 1

	# Summary
	print("================================================================================")
	print("SUMMARY: " + str(passed) + "/" + str(passed + failed) + " tests passed")
	if failed == 0:
		print("✓ ALL TESTS PASSED!")
	else:
		print("✗ " + str(failed) + " tests failed")
	print("================================================================================")
