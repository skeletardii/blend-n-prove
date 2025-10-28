extends SceneTree

func _init():
	print("================================================================================")
	print("TESTING IMPLICATION SPACING ISSUE")
	print("================================================================================")

	# Load the BooleanLogicEngine
	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	# Test case 1: Addition (P -> P∨Q)
	print("\n--- Test 1: Addition (P -> P∨Q) ---")
	var p1 = engine.create_expression("P")
	var q1 = engine.create_expression("Q")
	var result1 = engine.apply_addition([p1], q1)
	print("  Input: P, Q")
	print("  Result: \"" + result1.expression_string + "\"")
	print("  Normalized: \"" + result1.normalized_string + "\"")

	var expected1 = "(P∨Q)"
	print("  Expected from JSON: \"" + expected1 + "\"")
	print("  Match: " + str(result1.expression_string.strip_edges() == expected1.strip_edges()))

	# Test case 2: Implication (no direct creation function, but let's test conversion)
	print("\n--- Test 2: Implication Conversion ---")
	var impl = engine.create_expression("P→Q")
	print("  Created implication: \"" + impl.expression_string + "\"")
	print("  Normalized: \"" + impl.normalized_string + "\"")

	var conv_result = engine.apply_implication_conversion(impl)
	print("  After conversion: \"" + conv_result.expression_string + "\"")
	print("  Normalized: \"" + conv_result.normalized_string + "\"")

	var expected2 = "(¬P∨Q)"
	print("  Expected from JSON: \"" + expected2 + "\"")
	print("  Match: " + str(conv_result.expression_string.strip_edges() == expected2.strip_edges()))

	# Test case 3: Contrapositive
	print("\n--- Test 3: Contrapositive ---")
	var impl2 = engine.create_expression("P→Q")
	var contra_result = engine.apply_contrapositive(impl2)
	print("  Input: P→Q")
	print("  Result: \"" + contra_result.expression_string + "\"")
	print("  Normalized: \"" + contra_result.normalized_string + "\"")

	# Check level 1 JSON for all implication-related problems
	print("\n--- Checking Level 1 JSON ---")
	var file = FileAccess.open("res://data/classic/level-1.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()

		if parse_result == OK:
			var data = json.data
			var problems = data.get("problems", [])

			for i in range(problems.size()):
				var problem = problems[i]
				var desc = problem.get("description", "")

				# Look for implication-related problems
				if "Addition" in desc or "Implication" in desc or "Conversion" in desc:
					print("\n  Problem " + str(i + 1) + ": " + desc)
					print("    Premises: " + str(problem.get("premises", [])))
					print("    Conclusion: \"" + str(problem.get("conclusion", "")) + "\"")
		else:
			print("  Failed to parse JSON")
	else:
		print("  Failed to open level-1.json")

	print("\n================================================================================")
	print("ANALYSIS COMPLETE")
	print("================================================================================")

	quit()
