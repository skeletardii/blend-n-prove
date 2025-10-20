extends Node

func _ready():
	print("=== XOR AND BICONDITIONAL FUNCTIONALITY TEST ===")
	test_xor_functionality()
	test_biconditional_functionality()
	print("=== TESTS COMPLETED ===")

func test_xor_functionality():
	print("\n🔧 Testing XOR Functionality:")
	
	# Test XOR creation
	var xor1 = BooleanLogicEngine.create_expression("P ⊕ Q")
	print("   XOR Expression: valid=%s, is_xor=%s" % [xor1.is_valid, xor1.is_xor()])
	
	# Test ASCII conversion
	var xor2 = BooleanLogicEngine.create_expression("P ^ Q")
	print("   ASCII XOR Conversion: %s" % xor2.normalized_string)
	
	# Test XOR parts
	if xor1.is_xor():
		var parts = xor1.get_xor_parts()
		print("   XOR Parts: %s" % parts.get("valid", false))

func test_biconditional_functionality():
	print("\n↔️ Testing Biconditional Functionality:")
	
	# Test Biconditional creation
	var bi1 = BooleanLogicEngine.create_expression("P ↔ Q")
	print("   Biconditional Expression: valid=%s, is_biconditional=%s" % [bi1.is_valid, bi1.is_biconditional()])
	
	# Test ASCII conversion
	var bi2 = BooleanLogicEngine.create_expression("P <-> Q")
	print("   ASCII Biconditional Conversion: %s" % bi2.normalized_string)
	
	# Test Biconditional parts
	if bi1.is_biconditional():
		var parts = bi1.get_biconditional_parts()
		print("   Biconditional Parts: %s" % parts.get("valid", false))
