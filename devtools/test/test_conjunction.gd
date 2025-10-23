extends SceneTree

# Test script to verify conjunction works for (P∧Q)∧R scenario

func _init():
	print("=== Testing Conjunction for (P∧Q)∧R ===")
	print()

	# Load the BooleanLogicEngine
	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	# Step 1: Create initial premises P, Q, R
	print("Step 1: Create premises P, Q, R")
	var p = engine.create_expression("P")
	var q = engine.create_expression("Q")
	var r = engine.create_expression("R")

	print("  P is valid: ", p.is_valid, " -> ", p.normalized_string)
	print("  Q is valid: ", q.is_valid, " -> ", q.normalized_string)
	print("  R is valid: ", r.is_valid, " -> ", r.normalized_string)
	print()

	# Step 2: Apply conjunction to P and Q
	print("Step 2: Apply Conjunction to P and Q")
	var p_and_q = engine.apply_conjunction([p, q])
	print("  Result: ", p_and_q.normalized_string)
	print("  Is valid: ", p_and_q.is_valid)
	print("  Is conjunction: ", p_and_q.is_conjunction())
	print()

	# Step 3: Apply conjunction to (P∧Q) and R
	print("Step 3: Apply Conjunction to (P∧Q) and R")
	var final_result = engine.apply_conjunction([p_and_q, r])
	print("  Result: ", final_result.normalized_string)
	print("  Is valid: ", final_result.is_valid)
	print("  Is conjunction: ", final_result.is_conjunction())
	print()

	# Step 4: Verify it matches the goal
	var goal = engine.create_expression("(P ∧ Q) ∧ R")
	print("Step 4: Compare with goal")
	print("  Goal: ", goal.normalized_string)
	print("  Our result: ", final_result.normalized_string)
	print("  Match: ", final_result.normalized_string == goal.normalized_string)
	print()

	# Bonus: Test that we can extract parts back
	print("Bonus: Test extraction via Simplification")
	if final_result.is_conjunction():
		var parts = final_result.get_conjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left")
			var right = parts.get("right")
			print("  Left part: ", left.normalized_string)
			print("  Right part: ", right.normalized_string)

			# Can we extract P and Q from the left part?
			if left.is_conjunction():
				var inner_parts = left.get_conjunction_parts()
				if inner_parts.get("valid", false):
					print("  Inner left: ", inner_parts.get("left").normalized_string)
					print("  Inner right: ", inner_parts.get("right").normalized_string)

	print()
	print("=== Test Complete ===")

	quit()
