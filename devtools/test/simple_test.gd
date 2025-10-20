extends Node

func _ready():
	print("Simple test starting...")
	if BooleanLogicEngine:
		print("BooleanLogicEngine is accessible")
		test_basic_functionality()
	else:
		print("BooleanLogicEngine not found")

func test_basic_functionality():
	# Test basic expression creation
	var expr = BooleanLogicEngine.create_expression("P")
	print("Basic expression test:")
	print("  Created: ", expr.expression_string)
	print("  Valid: ", expr.is_valid)
	print("  Normalized: ", expr.normalized_string)
	
	# Test implication
	var impl = BooleanLogicEngine.create_expression("P → Q")
	print("Implication test:")
	print("  Created: ", impl.expression_string)
	print("  Valid: ", impl.is_valid)
	print("  Normalized: ", impl.normalized_string)
	
	print("Basic functionality test completed")
