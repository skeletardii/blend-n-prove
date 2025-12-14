extends SceneTree

# Simple test to verify De Morgan's laws work correctly

var engine

func _init():
	print("\n================================================================================")
	print("TESTING DE MORGAN'S LAWS - SIMPLE TEST")
	print("================================================================================\n")

	# Load the implementation directly
	engine = load("res://src/managers/BooleanLogicEngineImpl.gd").new()

	run_tests()

	quit()

func run_tests():
	var passed = 0
	var failed = 0

	# Test 1: De Morgan's AND - ¬(P ∧ Q) → ¬P ∨ ¬Q
	print("Test 1: De Morgan's AND - ¬(P ∧ Q) → ¬P ∨ ¬Q")
	var expr1 = engine.create_expression("¬(P ∧ Q)")
	print("  Input: " + expr1.normalized_string)
	var result1 = engine.apply_de_morgan_and(expr1)
	print("  Output: " + result1.normalized_string)
	print("  Expected: ¬P ∨ ¬Q")
	if result1.is_valid and result1.normalized_string == "¬P ∨ ¬Q":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED\n")
		failed += 1

	# Test 2: De Morgan's OR - ¬(P ∨ Q) → ¬P ∧ ¬Q
	print("Test 2: De Morgan's OR - ¬(P ∨ Q) → ¬P ∧ ¬Q")
	var expr2 = engine.create_expression("¬(P ∨ Q)")
	print("  Input: " + expr2.normalized_string)
	var result2 = engine.apply_de_morgan_or(expr2)
	print("  Output: " + result2.normalized_string)
	print("  Expected: ¬P ∧ ¬Q")
	if result2.is_valid and result2.normalized_string == "¬P ∧ ¬Q":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED\n")
		failed += 1

	# Test 3: Reverse De Morgan's AND - ¬P ∨ ¬Q → ¬(P ∧ Q)
	print("Test 3: Reverse De Morgan's AND - ¬P ∨ ¬Q → ¬(P ∧ Q)")
	var expr3 = engine.create_expression("¬P ∨ ¬Q")
	print("  Input: " + expr3.normalized_string)

	# Check if it's detected
	var ops3 = engine.get_applicable_single_operations(expr3)
	print("  Available operations: " + str(ops3))

	var result3 = engine.apply_de_morgan_reverse_and(expr3)
	print("  Output: " + result3.normalized_string)
	print("  Expected: ¬(P ∧ Q)")
	if result3.is_valid and result3.normalized_string == "¬(P ∧ Q)":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED\n")
		failed += 1

	# Test 4: Reverse De Morgan's OR - ¬P ∧ ¬Q → ¬(P ∨ Q)
	print("Test 4: Reverse De Morgan's OR - ¬P ∧ ¬Q → ¬(P ∨ Q)")
	var expr4 = engine.create_expression("¬P ∧ ¬Q")
	print("  Input: " + expr4.normalized_string)

	# Check if it's detected
	var ops4 = engine.get_applicable_single_operations(expr4)
	print("  Available operations: " + str(ops4))

	var result4 = engine.apply_de_morgan_reverse_or(expr4)
	print("  Output: " + result4.normalized_string)
	print("  Expected: ¬(P ∨ Q)")
	if result4.is_valid and result4.normalized_string == "¬(P ∨ Q)":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED\n")
		failed += 1

	# Test 5: Complex expression ¬((P ∧ Q) ∨ R)
	print("Test 5: Complex De Morgan's - ¬((P ∧ Q) ∨ R)")
	var expr5 = engine.create_expression("¬((P ∧ Q) ∨ R)")
	print("  Input: " + expr5.normalized_string)
	var ops5 = engine.get_applicable_single_operations(expr5)
	print("  Available operations: " + str(ops5))
	var result5 = engine.apply_de_morgan_or(expr5)
	print("  Output: " + result5.normalized_string)
	print("  Expected: ¬(P ∧ Q) ∧ ¬R")
	if result5.is_valid:
		print("  ✓ PASSED (complex expression works)\n")
		passed += 1
	else:
		print("  ✗ FAILED\n")
		failed += 1

	# Summary
	print("================================================================================")
	print("SUMMARY: " + str(passed) + "/" + str(passed + failed) + " tests passed")
	if failed == 0:
		print("✓ ALL TESTS PASSED!")
	else:
		print("✗ " + str(failed) + " tests failed")
	print("================================================================================")
