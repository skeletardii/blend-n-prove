extends SceneTree

func _init():
	print("=== Testing Conjunction Input Handling ===")
	print()

	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	# Test 1: What does conjunction receive as input?
	print("Test 1: Create 'P ∧ Q' (without outer parens)")
	var p_and_q_no_parens = engine.create_expression("P ∧ Q")
	print("  expression_string: '", p_and_q_no_parens.expression_string, "'")
	print("  normalized_string: '", p_and_q_no_parens.normalized_string, "'")
	print()

	print("Test 2: Create '(P ∧ Q)' (with outer parens)")
	var p_and_q_with_parens = engine.create_expression("(P ∧ Q)")
	print("  expression_string: '", p_and_q_with_parens.expression_string, "'")
	print("  normalized_string: '", p_and_q_with_parens.normalized_string, "'")
	print()

	var r = engine.create_expression("R")

	print("Test 3: Apply conjunction to 'P ∧ Q' (no parens) and 'R'")
	var result1 = engine.apply_conjunction([p_and_q_no_parens, r])
	print("  Input 1: '", p_and_q_no_parens.normalized_string, "'")
	print("  Input 2: '", r.normalized_string, "'")
	print("  Result:  '", result1.expression_string, "'")
	print()

	print("Test 4: Apply conjunction to '(P ∧ Q)' (with parens) and 'R'")
	var result2 = engine.apply_conjunction([p_and_q_with_parens, r])
	print("  Input 1: '", p_and_q_with_parens.normalized_string, "'")
	print("  Input 2: '", r.normalized_string, "'")
	print("  Result:  '", result2.expression_string, "'")
	print()

	print("Test 5: What does create_conjunction_expression do?")
	print("  Formula: '(' + left.normalized_string + ' ∧ ' + right.normalized_string + ')'")
	print("  With 'P ∧ Q': '(' + 'P ∧ Q' + ' ∧ ' + 'R' + ')' = '(P ∧ Q ∧ R)'")
	print("  With '(P ∧ Q)': '(' + '(P ∧ Q)' + ' ∧ ' + 'R' + ')' = '((P ∧ Q) ∧ R)'")
	print()

	print("=== Conclusion ===")
	print("The conjunction operation uses the NORMALIZED_STRING of the input,")
	print("which preserves whatever parentheses the expression has!")

	quit()
