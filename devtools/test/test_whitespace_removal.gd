extends SceneTree

# Test script to verify whitespace removal changes
# Tests that the logic engine handles non-spaced expressions correctly

var engine

func _init():
	print("=== Testing Whitespace Removal Changes ===\n")

	# Load the Boolean Logic Engine
	engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	var all_passed = true

	# Test 1: Basic operators without spaces
	print("Test 1: Basic operators without spaces")
	var expr1 = engine.create_expression("P∧Q")
	if expr1.is_valid:
		print("✓ P∧Q is valid")
	else:
		print("✗ P∧Q failed to parse")
		all_passed = false

	# Test 2: Implication without spaces
	print("\nTest 2: Implication without spaces")
	var expr2 = engine.create_expression("P→Q")
	if expr2.is_valid:
		print("✓ P→Q is valid")
	else:
		print("✗ P→Q failed to parse")
		all_passed = false

	# Test 3: Disjunction without spaces
	print("\nTest 3: Disjunction without spaces")
	var expr3 = engine.create_expression("P∨Q")
	if expr3.is_valid:
		print("✓ P∨Q is valid")
	else:
		print("✗ P∨Q failed to parse")
		all_passed = false

	# Test 4: Complex nested expression without spaces
	print("\nTest 4: Complex nested expression")
	var expr4 = engine.create_expression("P∧(P∨Q)")
	if expr4.is_valid:
		print("✓ P∧(P∨Q) is valid")
	else:
		print("✗ P∧(P∨Q) failed to parse")
		all_passed = false

	# Test 5: Negation with operators
	print("\nTest 5: Negation with operators")
	var expr5 = engine.create_expression("¬(P∧Q)")
	if expr5.is_valid:
		print("✓ ¬(P∧Q) is valid")
	else:
		print("✗ ¬(P∧Q) failed to parse")
		all_passed = false

	# Test 6: XOR without spaces
	print("\nTest 6: XOR without spaces")
	var expr6 = engine.create_expression("P⊕Q")
	if expr6.is_valid:
		print("✓ P⊕Q is valid")
	else:
		print("✗ P⊕Q failed to parse")
		all_passed = false

	# Test 7: Biconditional without spaces
	print("\nTest 7: Biconditional without spaces")
	var expr7 = engine.create_expression("P↔Q")
	if expr7.is_valid:
		print("✓ P↔Q is valid")
	else:
		print("✗ P↔Q failed to parse")
		all_passed = false

	# Test 8: Equivalence between spaced and non-spaced
	print("\nTest 8: Equivalence check")
	var spaced = engine.create_expression("P ∧ Q")
	var non_spaced = engine.create_expression("P∧Q")
	if spaced.is_valid and non_spaced.is_valid:
		# Both should tokenize the same way
		print("✓ Both 'P ∧ Q' and 'P∧Q' are valid")
		print("  Spaced normalized: " + spaced.normalized_string)
		print("  Non-spaced normalized: " + non_spaced.normalized_string)
	else:
		print("✗ Equivalence test failed")
		all_passed = false

	# Test 9: Load a level data file and verify premises parse
	print("\nTest 9: Loading level data")
	var level_file = FileAccess.open("res://data/classic/level-1.json", FileAccess.READ)
	if level_file:
		var json_string = level_file.get_as_text()
		level_file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var level_data = json.data
			var first_problem = level_data.problems[0]
			print("  First premise: " + first_problem.premises[0])
			var premise_expr = engine.create_expression(first_problem.premises[0])
			if premise_expr.is_valid:
				print("✓ Level data premise parses correctly")
			else:
				print("✗ Level data premise failed to parse")
				all_passed = false
		else:
			print("✗ Failed to parse level JSON")
			all_passed = false
	else:
		print("✗ Failed to open level file")
		all_passed = false

	# Final result
	print("\n=== Test Results ===")
	if all_passed:
		print("✓ ALL TESTS PASSED")
	else:
		print("✗ SOME TESTS FAILED")

	quit()
