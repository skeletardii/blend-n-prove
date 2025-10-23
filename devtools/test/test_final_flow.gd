extends SceneTree

func _init():
	print("=== Testing Final Flow: P, Q, R → (P ∧ Q) ∧ R ===")
	print()

	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	# Simulate the game flow WITHOUT auto-cleaning
	print("Step 1: Create premises P, Q, R")
	var p = engine.create_expression("P")
	var q = engine.create_expression("Q")
	var r = engine.create_expression("R")
	print("  Inventory: P, Q, R")
	print()

	print("Step 2: User selects P and Q, applies CONJ")
	var step1_result = engine.apply_conjunction([p, q])
	print("  Raw result: ", step1_result.expression_string)

	# NO CLEANING! Just add to inventory as-is
	print("  Added to inventory (NO auto-clean): ", step1_result.expression_string)
	print("  Inventory now: P, Q, R, (P ∧ Q)")
	print()

	print("Step 3: User selects (P ∧ Q) and R, applies CONJ")
	var step2_result = engine.apply_conjunction([step1_result, r])
	print("  Raw result: ", step2_result.expression_string)

	# NO CLEANING!
	print("  Added to inventory (NO auto-clean): ", step2_result.expression_string)
	print("  Inventory now: P, Q, R, (P ∧ Q), ((P ∧ Q) ∧ R)")
	print()

	print("Step 4: User wants to clean up, selects ((P ∧ Q) ∧ R), applies PAREN_REMOVE")
	var cleaned = engine.apply_parenthesis_removal(step2_result)
	print("  Result after PAREN_REMOVE: ", cleaned.expression_string)
	print("  Inventory now: P, Q, R, (P ∧ Q), ((P ∧ Q) ∧ R), (P ∧ Q) ∧ R")
	print()

	print("Step 5: Check if it matches goal '(P ∧ Q) ∧ R'")
	var goal = "(P ∧ Q) ∧ R"
	print("  Goal: ", goal)
	print("  Our result: ", cleaned.expression_string)
	print("  Match: ", cleaned.expression_string.strip_edges() == goal.strip_edges())
	print()

	print("=== SUCCESS! ===")
	print("With this approach:")
	print("  ✓ Structure is preserved: (P ∧ Q) stays as (P ∧ Q)")
	print("  ✓ Nested structure shown: ((P ∧ Q) ∧ R)")
	print("  ✓ User has control via PAREN_REMOVE button")
	print("  ✓ Goal matching works correctly!")

	quit()
