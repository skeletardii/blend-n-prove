extends Node

func _ready():
	print("Starting comprehensive BooleanLogicEngine test...")
	await get_tree().process_frame
	run_tests()

func run_tests():
	print("Running BooleanLogicEngine.test_logic_engine():")
	BooleanLogicEngine.test_logic_engine()
	
	print("\n==================================================")  # 50 equals signs
	print("ADDITIONAL INDIVIDUAL TESTS:")
	
	# Test expression creation
	print("\nTesting expression creation:")
	var expr1 = BooleanLogicEngine.create_expression("P")
	print("Expression 'P': valid=%s, normalized='%s'" % [expr1.is_valid, expr1.normalized_string])
	
	var expr2 = BooleanLogicEngine.create_expression("P → Q")
	print("Expression 'P → Q': valid=%s, normalized='%s'" % [expr2.is_valid, expr2.normalized_string])
	
	var expr3 = BooleanLogicEngine.create_expression("(A ∧ B) → (C ∨ ¬D)")
	print("Complex expression: valid=%s, normalized='%s'" % [expr3.is_valid, expr3.normalized_string])
	
	# Test pattern matching
	print("\nTesting pattern matching:")
	var impl_match = expr2.matches_pattern("implication")
	print("Implication pattern match: ", impl_match)
	
	# Test inference rules
	print("\nTesting inference rules:")
	var premise1 = BooleanLogicEngine.create_expression("P → Q")
	var premise2 = BooleanLogicEngine.create_expression("P")
	var modus_ponens_result = BooleanLogicEngine.apply_modus_ponens([premise1, premise2])
	print("Modus Ponens result: valid=%s, expression='%s'" % [modus_ponens_result.is_valid, modus_ponens_result.normalized_string])
	
	print("\nAll tests completed!")
