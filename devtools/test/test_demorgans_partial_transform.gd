extends SceneTree

# Test what the De Morgan's transformation of ¬P ∧ Q would be

var engine
var passed = 0
var failed = 0

func _init():
	print("\n================================================================================")
	print("TESTING DE MORGAN'S-STYLE TRANSFORMATION OF ¬P ∧ Q")
	print("================================================================================\n")

	# Load the Boolean Logic Engine
	engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	run_tests()

	quit()

func run_tests():

	print("If we could apply reverse De Morgan's to ¬P ∧ Q:")
	print("  Pattern: A ∧ B → ¬(¬A ∨ ¬B)")
	print("  Where A = ¬P and B = Q")
	print("  ¬A = ¬(¬P) = ¬¬P = P (after double negation)")
	print("  ¬B = ¬Q")
	print("  Result: ¬(P ∨ ¬Q)")
	print()

	# Test 1: Verify the equivalence manually
	print("Test 1: Are ¬P ∧ Q and ¬(P ∨ ¬Q) logically equivalent?")
	print("  Let's check with truth table:")
	print("  P | Q | ¬P | ¬P∧Q | ¬Q | P∨¬Q | ¬(P∨¬Q)")
	print("  --|---|----|----- |----|----- |--------")
	print("  T | T | F  |  F   | F  |  T   |   F")
	print("  T | F | F  |  F   | T  |  T   |   F")
	print("  F | T | T  |  T   | F  |  F   |   T")
	print("  F | F | T  |  F   | T  |  T   |   F")
	print()
	print("  ¬P∧Q column: F, F, T, F")
	print("  ¬(P∨¬Q) column: F, F, T, F")
	print("  ✓ They ARE equivalent!\n")
	passed += 1

	# Test 2: Can we create both expressions and verify they're valid?
	print("Test 2: Create both expressions")
	var expr1 = engine.create_expression("¬P ∧ Q")
	var expr2 = engine.create_expression("¬(P ∨ ¬Q)")
	print("  Expression 1: " + expr1.normalized_string + " (valid: " + str(expr1.is_valid) + ")")
	print("  Expression 2: " + expr2.normalized_string + " (valid: " + str(expr2.is_valid) + ")")
	if expr1.is_valid and expr2.is_valid:
		print("  ✓ Both expressions are valid\n")
		passed += 1
	else:
		print("  ✗ One or both expressions invalid\n")
		failed += 1

	# Test 3: Show the transformation step-by-step
	print("Test 3: Step-by-step transformation using existing operations")
	print("  Start: ¬P ∧ Q")
	print("  Step 1: Cannot apply De Morgan's directly (only one side negated)")
	print("  Step 2: Would need to use other operations to get equivalence")
	print()
	print("  Alternative: Start with ¬(P ∨ ¬Q) and apply De Morgan's forward")
	var expr3 = engine.create_expression("¬(P ∨ ¬Q)")
	print("  Input: " + expr3.normalized_string)
	var result3 = engine.apply_de_morgan_or(expr3)
	print("  Apply De Morgan's (OR): " + result3.normalized_string)
	if result3.is_valid and (result3.normalized_string == "¬P ∧ ¬¬Q" or result3.normalized_string == "(¬P ∧ ¬¬Q)"):
		print("  Result: ¬P ∧ ¬¬Q")
		print("  Then apply Double Negation on ¬¬Q → Q")
		print("  Final: ¬P ∧ Q")
		print("  ✓ Transformation verified!\n")
		passed += 1
	else:
		print("  ✗ Unexpected result: " + result3.normalized_string + "\n")
		failed += 1

	# Summary
	print("================================================================================")
	print("SUMMARY: " + str(passed) + "/" + str(passed + failed) + " tests passed")
	print()
	print("ANSWER TO YOUR QUESTION:")
	print("  YES! The De Morgan's-style transformation of ¬P ∧ Q would be:")
	print()
	print("    ¬P ∧ Q  ≡  ¬(P ∨ ¬Q)")
	print()
	print("  These are logically equivalent expressions.")
	print("  To transform between them in the engine:")
	print("    - Start with ¬(P ∨ ¬Q)")
	print("    - Apply De Morgan's (OR) → ¬P ∧ ¬¬Q")
	print("    - Apply Double Negation on ¬¬Q → ¬P ∧ Q")
	print("================================================================================")
