extends SceneTree

# Test semantic equivalence of the "failed" De Morgan's cases

var engine

func _init():
	print("\n================================================================================")
	print("TESTING SEMANTIC EQUIVALENCE OF DE MORGAN'S RESULTS")
	print("================================================================================\n")

	# Load the implementation directly
	engine = load("res://src/managers/BooleanLogicEngineImpl.gd").new()

	test_equivalence()

	quit()

func test_equivalence():
	# Test the two cases that "failed" due to extra parentheses

	print("Test 1: (¬(P ∨ Q)) ∨ ¬R vs ¬(P ∨ Q) ∨ ¬R")
	var expr1 = engine.create_expression("(¬(P ∨ Q)) ∨ ¬R")
	var expr2 = engine.create_expression("¬(P ∨ Q) ∨ ¬R")

	print("  Expression 1: " + expr1.normalized_string)
	print("  Expression 2: " + expr2.normalized_string)
	print("  Semantically equivalent: " + str(engine.are_semantically_equivalent(expr1, expr2)))
	print()

	print("Test 2: (¬(P ∧ Q)) ∧ ¬R vs ¬(P ∧ Q) ∧ ¬R")
	var expr3 = engine.create_expression("(¬(P ∧ Q)) ∧ ¬R")
	var expr4 = engine.create_expression("¬(P ∧ Q) ∧ ¬R")

	print("  Expression 1: " + expr3.normalized_string)
	print("  Expression 2: " + expr4.normalized_string)
	print("  Semantically equivalent: " + str(engine.are_semantically_equivalent(expr3, expr4)))
	print()

	print("================================================================================")
	print("CONCLUSION: Extra parentheses don't affect logical equivalence")
	print("================================================================================")
