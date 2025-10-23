extends SceneTree

# Test script to see exactly what gets displayed

func _init():
	print("=== Testing Display Format for P ∧ Q ∧ R ===")
	print()

	# Load the BooleanLogicEngine
	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	# Create the nested conjunction step by step
	var p = engine.create_expression("P")
	var q = engine.create_expression("Q")
	var r = engine.create_expression("R")

	print("Initial premises:")
	print("  P.expression_string = ", p.expression_string)
	print("  Q.expression_string = ", q.expression_string)
	print("  R.expression_string = ", r.expression_string)
	print()

	# First conjunction
	var p_and_q = engine.apply_conjunction([p, q])
	print("After first conjunction (P ∧ Q):")
	print("  expression_string = ", p_and_q.expression_string)
	print("  normalized_string = ", p_and_q.normalized_string)

	# Clean it (this is what Phase2UI does)
	var cleaned1 = engine.apply_parenthesis_removal(p_and_q)
	print("  After clean_expression:")
	print("    expression_string = ", cleaned1.expression_string)
	print("    normalized_string = ", cleaned1.normalized_string)
	print()

	# Second conjunction - using the cleaned version
	var result = engine.apply_conjunction([cleaned1, r])
	print("After second conjunction ((P ∧ Q) ∧ R):")
	print("  expression_string = ", result.expression_string)
	print("  normalized_string = ", result.normalized_string)

	# Clean it (this is what Phase2UI does)
	var cleaned2 = engine.apply_parenthesis_removal(result)
	print("  After clean_expression:")
	print("    expression_string = ", cleaned2.expression_string)
	print("    normalized_string = ", cleaned2.normalized_string)
	print()

	# Let's check what expression_string contains for BooleanExpression
	print("Checking internal structure:")
	print("  cleaned2.expression_string type: ", typeof(cleaned2.expression_string))
	print("  Length: ", cleaned2.expression_string.length())
	print("  Character by character:")
	for i in range(cleaned2.expression_string.length()):
		print("    [", i, "] = '", cleaned2.expression_string[i], "' (", cleaned2.expression_string.unicode_at(i), ")")
	print()

	print("=== Test Complete ===")

	quit()
