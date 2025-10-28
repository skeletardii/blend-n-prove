extends SceneTree

func _init():
	print("================================================================================")
	print("TESTING CONJUNCTION SPACING ISSUE")
	print("================================================================================")

	# Load the BooleanLogicEngine
	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	# Create expressions P and Q
	var p = engine.create_expression("P")
	var q = engine.create_expression("Q")

	print("\nCreated expressions:")
	print("  P: \"" + p.expression_string + "\"")
	print("  Q: \"" + q.expression_string + "\"")

	# Apply conjunction
	var result = engine.apply_conjunction([p, q])

	print("\nAfter applying conjunction:")
	print("  Result expression_string: \"" + result.expression_string + "\"")
	print("  Result normalized_string: \"" + result.normalized_string + "\"")

	# Check what the level 1 JSON expects
	var expected = "(P ∧ Q)"  # From level 1 JSON (FIXED: now with spaces)

	print("\nComparison:")
	print("  Expected: \"" + expected + "\"")
	print("  Got:      \"" + result.expression_string + "\"")
	print("  Match:    " + str(result.expression_string == expected))

	# Try with normalized comparison
	var expected_expr = engine.create_expression(expected)
	print("\nNormalized comparison:")
	print("  Expected normalized: \"" + expected_expr.normalized_string + "\"")
	print("  Got normalized:      \"" + result.normalized_string + "\"")
	print("  Match:    " + str(result.normalized_string == expected_expr.normalized_string))

	# Try strip_edges comparison (what Phase2UI uses)
	print("\nStrip edges comparison (what Phase2UI uses):")
	print("  Expected stripped: \"" + expected.strip_edges() + "\"")
	print("  Got stripped:      \"" + result.expression_string.strip_edges() + "\"")
	print("  Match:    " + str(result.expression_string.strip_edges() == expected.strip_edges()))

	print("\n================================================================================")
	print("CONCLUSION:")
	if result.expression_string.strip_edges() == expected.strip_edges():
		print("✓ Conjunction works correctly!")
	else:
		print("✗ Conjunction is BROKEN - spaces don't match!")
		print("  The create_conjunction_expression function adds spaces around ∧")
		print("  But level 1 JSON expects no spaces: (P∧Q)")
	print("================================================================================")

	quit()
