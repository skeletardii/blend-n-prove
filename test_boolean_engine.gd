extends Node

func _ready():
	print("Testing BooleanLogicEngine access...")
	# Try to access the autoload
	if BooleanLogicEngine:
		print("BooleanLogicEngine autoload is accessible")
		test_basic_functionality()
	else:
		print("BooleanLogicEngine autoload not found")

func test_basic_functionality():
	print("Testing basic functionality...")
	
	# Test expression creation
	var expr = BooleanLogicEngine.create_expression("P")
	print("Created expression 'P'")
	print("Is valid: ", expr.is_valid)
	print("Expression string: ", expr.expression_string)
	
	# Test the main test function
	print("\nRunning BooleanLogicEngine.test_logic_engine():")
	BooleanLogicEngine.test_logic_engine()
