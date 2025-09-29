extends Node

# Minimal Boolean Logic Engine for testing
class SimpleBooleanExpr:
	var text: String
	var valid: bool
	
	func _init(expr: String):
		text = expr.strip_edges()
		valid = not text.is_empty()

func create_simple_expression(expr: String) -> SimpleBooleanExpr:
	return SimpleBooleanExpr.new(expr)

func run_simple_test():
	print("=== SIMPLE BOOLEAN ENGINE TEST ===")
	
	var expr1 = create_simple_expression("P")
	print("Expression 'P': valid=%s, text='%s'" % [expr1.valid, expr1.text])
	
	var expr2 = create_simple_expression("P → Q")
	print("Expression 'P → Q': valid=%s, text='%s'" % [expr2.valid, expr2.text])
	
	var expr3 = create_simple_expression("(A ∧ B) → (C ∨ ¬D)")
	print("Complex: valid=%s, text='%s'" % [expr3.valid, expr3.text])
	
	print("=== TEST COMPLETED ===")
	return true
