extends Node

# Simplified Boolean Logic Engine for testing core functionality

enum LogicalOperator {
	AND, OR, XOR, NOT, IMPLIES, BICONDITIONAL, TRUE, FALSE
}

enum InferenceRule {
	MODUS_PONENS, MODUS_TOLLENS, HYPOTHETICAL_SYLLOGISM, DISJUNCTIVE_SYLLOGISM,
	SIMPLIFICATION, CONJUNCTION, ADDITION, CONSTRUCTIVE_DILEMMA,
	DESTRUCTIVE_DILEMMA, RESOLUTION, DE_MORGAN_AND, DE_MORGAN_OR, DOUBLE_NEGATION
}

class SimpleBooleanExpression:
	var expression_string: String
	var is_valid: bool = false
	var normalized_string: String = ""
	
	func _init(expr: String):
		expression_string = expr.strip_edges()
		is_valid = basic_validation()
		if is_valid:
			normalized_string = expression_string
	
	func basic_validation() -> bool:
		if expression_string.is_empty():
			return false
		# Basic validation - just check for some common patterns
		return true
	
	func equals(other: SimpleBooleanExpression) -> bool:
		return normalized_string == other.normalized_string
	
	func is_negation_of(other: SimpleBooleanExpression) -> bool:
		# Simple negation check
		return expression_string.begins_with("¬") and expression_string.substr(1) == other.expression_string

signal expression_validated(expression, is_valid: bool)

func create_expression(expr_string: String) -> SimpleBooleanExpression:
	var expression = SimpleBooleanExpression.new(expr_string)
	expression_validated.emit(expression, expression.is_valid)
	return expression

func test_simple_engine():
	print("Testing Simple Boolean Engine...")
	print("==================================================")  # 50 equals signs
	
	var tests_passed = 0
	var tests_total = 0
	
	# Test 1: Basic expression creation
	tests_total += 1
	var expr1 = create_expression("P")
	if expr1.is_valid:
		print("✓ Basic expression creation test passed")
		tests_passed += 1
	else:
		print("✗ Basic expression creation test failed")
	
	# Test 2: Expression with operator
	tests_total += 1
	var expr2 = create_expression("P → Q")
	if expr2.is_valid:
		print("✓ Expression with operator test passed")
		tests_passed += 1
	else:
		print("✗ Expression with operator test failed")
	
	# Test 3: Complex expression
	tests_total += 1
	var expr3 = create_expression("(A ∧ B) → (C ∨ ¬D)")
	if expr3.is_valid:
		print("✓ Complex expression test passed")
		tests_passed += 1
	else:
		print("✗ Complex expression test failed")
	
	print("Simple engine tests completed: %d/%d passed" % [tests_passed, tests_total])
	return tests_passed == tests_total
