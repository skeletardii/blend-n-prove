extends SceneTree

# Test script for negation and XOR combinations

var engine
var passed = 0
var failed = 0

func _init():
	print("\n================================================================================")
	print("TESTING NEGATION AND XOR COMBINATIONS")
	print("================================================================================\n")

	# Load the Boolean Logic Engine
	engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	run_tests()

	quit()

func run_tests():

	# Test 1: ~P ^ Q (should parse as ¬P ∧ Q)
	print("Test 1: ~P ^ Q (should parse as ¬P ∧ Q)")
	var expr1 = engine.create_expression("~P ^ Q")
	print("  Input: ~P ^ Q")
	print("  Normalized: " + expr1.normalized_string)
	print("  Is valid: " + str(expr1.is_valid))
	if expr1.is_valid and expr1.normalized_string == "¬P ∧ Q":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: ¬P ∧ Q, Got: " + expr1.normalized_string + "\n")
		failed += 1

	# Test 2: ~(P ^ Q) (should parse as ¬(P ∧ Q))
	print("Test 2: ~(P ^ Q) (should parse as ¬(P ∧ Q))")
	var expr2 = engine.create_expression("~(P ^ Q)")
	print("  Input: ~(P ^ Q)")
	print("  Normalized: " + expr2.normalized_string)
	print("  Is valid: " + str(expr2.is_valid))
	if expr2.is_valid and expr2.normalized_string == "¬(P ∧ Q)":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: ¬(P ∧ Q), Got: " + expr2.normalized_string + "\n")
		failed += 1

	# Test 3: P ^ ~Q (should parse as P ∧ ¬Q)
	print("Test 3: P ^ ~Q (should parse as P ∧ ¬Q)")
	var expr3 = engine.create_expression("P ^ ~Q")
	print("  Input: P ^ ~Q")
	print("  Normalized: " + expr3.normalized_string)
	print("  Is valid: " + str(expr3.is_valid))
	if expr3.is_valid and expr3.normalized_string == "P ∧ ¬Q":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: P ∧ ¬Q, Got: " + expr3.normalized_string + "\n")
		failed += 1

	# Test 4: ~P ^ ~Q (should parse as ¬P ∧ ¬Q)
	print("Test 4: ~P ^ ~Q (should parse as ¬P ∧ ¬Q)")
	var expr4 = engine.create_expression("~P ^ ~Q")
	print("  Input: ~P ^ ~Q")
	print("  Normalized: " + expr4.normalized_string)
	print("  Is valid: " + str(expr4.is_valid))
	if expr4.is_valid and expr4.normalized_string == "¬P ∧ ¬Q":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: ¬P ∧ ¬Q, Got: " + expr4.normalized_string + "\n")
		failed += 1

	# Test 5: Check if AND is detected (^ now means AND)
	print("Test 5: AND detection in expressions using ^")
	var expr5 = engine.create_expression("P ^ Q")
	print("  Input: P ^ Q")
	print("  Normalized: " + expr5.normalized_string)
	print("  Is conjunction: " + str(expr5.is_conjunction()))
	if expr5.is_valid and expr5.is_conjunction() and expr5.normalized_string == "P ∧ Q":
		print("  ✓ PASSED - AND detected (^ converted to ∧)\n")
		passed += 1
	else:
		print("  ✗ FAILED - AND not detected correctly\n")
		failed += 1

	# Test 6: Complex expression with negation and AND
	print("Test 6: ~(P ^ Q) & R (should parse as ¬(P ∧ Q) ∧ R)")
	var expr6 = engine.create_expression("~(P ^ Q) & R")
	print("  Input: ~(P ^ Q) & R")
	print("  Normalized: " + expr6.normalized_string)
	print("  Is valid: " + str(expr6.is_valid))
	if expr6.is_valid and expr6.normalized_string == "¬(P ∧ Q) ∧ R":
		print("  ✓ PASSED\n")
		passed += 1
	else:
		print("  ✗ FAILED - Expected: ¬(P ∧ Q) ∧ R, Got: " + expr6.normalized_string + "\n")
		failed += 1

	# Summary
	print("================================================================================")
	print("SUMMARY: " + str(passed) + "/" + str(passed + failed) + " tests passed")
	if failed == 0:
		print("✓ ALL TESTS PASSED!")
	else:
		print("✗ " + str(failed) + " tests failed")
	print("================================================================================")
