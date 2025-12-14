extends SceneTree

# Debug why expressions aren't semantically equivalent

var engine

func _init():
	print("\n================================================================================")
	print("DEBUGGING DE MORGAN'S EXPRESSION PARSING")
	print("================================================================================\n")

	# Load the implementation directly
	engine = load("res://src/managers/BooleanLogicEngineImpl.gd").new()

	debug_expressions()

	quit()

func debug_expressions():
	# Test the expressions
	var expr1_str = "(¬(P ∨ Q)) ∨ ¬R"
	var expr2_str = "¬(P ∨ Q) ∨ ¬R"

	print("Testing: '%s' vs '%s'" % [expr1_str, expr2_str])
	print()

	var expr1 = engine.create_expression(expr1_str)
	var expr2 = engine.create_expression(expr2_str)

	print("Expression 1:")
	print("  Input:      " + expr1_str)
	print("  Normalized: " + expr1.normalized_string)
	print("  Valid:      " + str(expr1.is_valid))
	print("  Variables:  " + str(expr1.get_variables()))
	print()

	print("Expression 2:")
	print("  Input:      " + expr2_str)
	print("  Normalized: " + expr2.normalized_string)
	print("  Valid:      " + str(expr2.is_valid))
	print("  Variables:  " + str(expr2.get_variables()))
	print()

	# Test evaluation with all possible assignments
	var vars = ["P", "Q", "R"]
	print("Truth table comparison:")
	print("  P | Q | R | Expr1 | Expr2 | Match")
	print("  --|---|---|-------|-------|------")

	var mismatch_count = 0

	for i in range(8):  # 2^3 = 8 combinations
		var assignment = {}
		for j in range(vars.size()):
			assignment[vars[j]] = bool((i >> j) & 1)

		var result1 = expr1.evaluate(assignment)
		var result2 = expr2.evaluate(assignment)
		var match = result1 == result2

		if not match:
			mismatch_count += 1

		var p_val = "T" if assignment["P"] else "F"
		var q_val = "T" if assignment["Q"] else "F"
		var r_val = "T" if assignment["R"] else "F"
		var r1_val = "T" if result1 else "F"
		var r2_val = "T" if result2 else "F"
		var match_str = "✓" if match else "✗"

		print("  %s | %s | %s |   %s   |   %s   |  %s" % [p_val, q_val, r_val, r1_val, r2_val, match_str])

	print()
	if mismatch_count == 0:
		print("✓ All truth assignments match! Expressions are equivalent.")
		print("  (But are_semantically_equivalent returned false - possible bug?)")
	else:
		print("✗ %d mismatches found. Expressions are NOT equivalent." % mismatch_count)

	print("================================================================================")
