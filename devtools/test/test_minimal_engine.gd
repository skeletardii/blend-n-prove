extends Node

# Minimal test to isolate BooleanLogicEngine issues

func _ready():
	print("Testing minimal Boolean logic functionality...")
	test_basic_expression_creation()

func test_basic_expression_creation():
	print("Creating simple boolean expressions...")
	
	# Test if we can access the BooleanLogicEngine at all
	if has_node("/root/BooleanLogicEngine"):
		print("BooleanLogicEngine node exists")
		var engine = get_node("/root/BooleanLogicEngine")
		print("Engine script: ", engine.get_script())
	else:
		print("BooleanLogicEngine node not found")
	
	# Try direct method call
	var result = null
	if BooleanLogicEngine.has_method("create_expression"):
		print("create_expression method exists")
		result = BooleanLogicEngine.create_expression("P")
		print("Result: ", result)
		if result and result.has_method("is_valid"):
			print("Expression is valid: ", result.is_valid())
		else:
			print("Invalid result or missing methods")
	else:
		print("create_expression method not found")
