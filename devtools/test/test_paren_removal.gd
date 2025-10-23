extends SceneTree

# Test script to verify parenthesis removal behavior

func _init():
	print("=== Testing Parenthesis Removal on ((P∧Q)∧R) ===")
	print()

	# Load the BooleanLogicEngine
	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	# Create the nested conjunction
	var p = engine.create_expression("P")
	var q = engine.create_expression("Q")
	var r = engine.create_expression("R")

	var p_and_q = engine.apply_conjunction([p, q])
	print("Step 1: P ∧ Q")
	print("  Result: ", p_and_q.expression_string)
	print()

	var result = engine.apply_conjunction([p_and_q, r])
	print("Step 2: (P ∧ Q) ∧ R")
	print("  Result BEFORE cleaning: ", result.expression_string)
	print("  Result normalized: ", result.normalized_string)
	print()

	# Now apply parenthesis removal (this is what clean_expression does)
	var cleaned = engine.apply_parenthesis_removal(result)
	print("Step 3: Apply parenthesis removal")
	print("  Result AFTER cleaning: ", cleaned.expression_string)
	print("  Result normalized: ", cleaned.normalized_string)
	print()

	# Try removing again
	var cleaned2 = engine.apply_parenthesis_removal(cleaned)
	print("Step 4: Apply parenthesis removal AGAIN")
	print("  Result: ", cleaned2.expression_string)
	print("  Is it the same? ", cleaned2.expression_string == cleaned.expression_string)
	print()

	print("=== Test Complete ===")

	quit()
