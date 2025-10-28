extends SceneTree

# Test De Morgan's with partially negated expressions

var engine
var passed = 0
var failed = 0

func _init():
	print("\n================================================================================")
	print("TESTING DE MORGAN'S WITH PARTIALLY NEGATED EXPRESSIONS")
	print("Testing: ¬P ∧ Q (NOT P AND Q)")
	print("================================================================================\n")

	# Load the Boolean Logic Engine
	engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	run_tests()

	quit()

func run_tests():

	# Test 1: Check what operations are available for ¬P ∧ Q
	print("Test 1: What operations are available for ¬P ∧ Q?")
	var expr1 = engine.create_expression("¬P ∧ Q")
	print("  Expression: " + expr1.normalized_string)
	var ops1 = engine.get_applicable_single_operations(expr1)
	print("  Available operations:")
	for op in ops1:
		print("    - " + op)

	if "De Morgan's Reverse (OR)" in ops1:
		print("  ✗ De Morgan's Reverse (OR) is available (should NOT be - only one side negated)")
		failed += 1
	else:
		print("  ✓ De Morgan's Reverse (OR) correctly NOT available\n")
		passed += 1

	# Test 2: Check ¬P ∧ ¬Q (both negated - De Morgan's should work)
	print("Test 2: What operations are available for ¬P ∧ ¬Q?")
	var expr2 = engine.create_expression("¬P ∧ ¬Q")
	print("  Expression: " + expr2.normalized_string)
	var ops2 = engine.get_applicable_single_operations(expr2)
	print("  Available operations:")
	for op in ops2:
		print("    - " + op)

	if "De Morgan's Reverse (OR)" in ops2:
		print("  ✓ De Morgan's Reverse (OR) is available (both sides negated)\n")
		passed += 1
	else:
		print("  ✗ De Morgan's Reverse (OR) should be available for ¬P ∧ ¬Q\n")
		failed += 1

	# Test 3: Apply De Morgan's to ¬P ∧ ¬Q
	print("Test 3: Apply De Morgan's Reverse (OR) to ¬P ∧ ¬Q")
	var expr3 = engine.create_expression("¬P ∧ ¬Q")
	print("  Input: " + expr3.normalized_string)
	var result3 = engine.apply_de_morgan_or_reverse(expr3)
	print("  Output: " + result3.normalized_string)
	if result3.is_valid and result3.normalized_string == "¬(P ∨ Q)":
		print("  ✓ PASSED - Correctly transforms to ¬(P ∨ Q)\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected ¬(P ∨ Q), got: " + result3.normalized_string + "\n")
		failed += 1

	# Test 4: Check ¬(P ∧ Q) - forward De Morgan's
	print("Test 4: Apply forward De Morgan's to ¬(P ∧ Q)")
	var expr4 = engine.create_expression("¬(P ∧ Q)")
	print("  Input: " + expr4.normalized_string)
	var result4 = engine.apply_de_morgan_and(expr4)
	print("  Output: " + result4.normalized_string)
	if result4.is_valid and (result4.normalized_string == "¬P ∨ ¬Q" or result4.normalized_string == "(¬P ∨ ¬Q)"):
		print("  ✓ PASSED - Correctly transforms to ¬P ∨ ¬Q\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected ¬P ∨ ¬Q, got: " + result4.normalized_string + "\n")
		failed += 1

	# Test 5: Can we negate ¬P ∧ Q to get ¬(¬P ∧ Q) and then apply De Morgan's?
	print("Test 5: Negate ¬P ∧ Q, then apply De Morgan's")
	var expr5 = engine.create_expression("¬(¬P ∧ Q)")
	print("  Input: " + expr5.normalized_string)
	var result5 = engine.apply_de_morgan_and(expr5)
	print("  Output: " + result5.normalized_string)
	if result5.is_valid and (result5.normalized_string == "¬¬P ∨ ¬Q" or result5.normalized_string == "(¬¬P ∨ ¬Q)"):
		print("  ✓ PASSED - Correctly transforms to ¬¬P ∨ ¬Q\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected ¬¬P ∨ ¬Q, got: " + result5.normalized_string + "\n")
		failed += 1

	# Summary
	print("================================================================================")
	print("SUMMARY: " + str(passed) + "/" + str(passed + failed) + " tests passed")
	if failed == 0:
		print("✓ ALL TESTS PASSED!")
		print("\nCONCLUSION: De Morgan's laws require BOTH sides to be negated.")
		print("  - ¬P ∧ Q: De Morgan's does NOT apply (only one side negated)")
		print("  - ¬P ∧ ¬Q: De Morgan's DOES apply → ¬(P ∨ Q)")
		print("  - To use De Morgan's on ¬P ∧ Q, negate first: ¬(¬P ∧ Q) → ¬¬P ∨ ¬Q")
	else:
		print("✗ " + str(failed) + " tests failed")
	print("================================================================================")
