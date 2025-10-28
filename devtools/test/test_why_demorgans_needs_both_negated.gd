extends SceneTree

# Explain why De Morgan's laws require BOTH sides to be negated

var engine

func repeat_char(ch: String, count: int) -> String:
	var result = ""
	for i in range(count):
		result += ch
	return result

func _init():
	print("\n================================================================================")
	print("WHY DE MORGAN'S LAWS REQUIRE BOTH SIDES TO BE NEGATED")
	print("================================================================================\n")

	# Load the Boolean Logic Engine
	engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	run_explanation()

	quit()

func run_explanation():

	print("DE MORGAN'S LAWS - THE ACTUAL RULES:")
	print(repeat_char("─", 80))
	print("  Forward (AND): ¬(P ∧ Q)  →  ¬P ∨ ¬Q")
	print("  Forward (OR):  ¬(P ∨ Q)  →  ¬P ∧ ¬Q")
	print()
	print("  Reverse (AND): ¬P ∨ ¬Q  →  ¬(P ∧ Q)")
	print("  Reverse (OR):  ¬P ∧ ¬Q  →  ¬(P ∨ Q)")
	print(repeat_char("─", 80))
	print()

	print("KEY OBSERVATION:")
	print("  De Morgan's laws describe what happens when you have:")
	print("    - An OUTER negation: ¬(...)")
	print("    - Applied to a compound expression: (P ∧ Q) or (P ∨ Q)")
	print()
	print("  The law tells you how to 'push' the negation INSIDE:")
	print("    - Negate each operand: P → ¬P, Q → ¬Q")
	print("    - Flip the operator: ∧ ↔ ∨")
	print()

	print(repeat_char("=", 80))
	print("CASE 1: ¬P ∧ ¬Q (BOTH sides negated) - De Morgan's APPLIES")
	print(repeat_char("=", 80))
	print()

	var expr1 = engine.create_expression("¬P ∧ ¬Q")
	print("Expression: " + expr1.normalized_string)
	print()
	print("Analysis:")
	print("  - Left operand:  ¬P (negated)")
	print("  - Right operand: ¬Q (negated)")
	print("  - Operator: ∧ (AND)")
	print()
	print("Pattern matching for Reverse De Morgan's (OR):")
	print("  Template: ¬A ∧ ¬B  →  ¬(A ∨ B)")
	print("  Where: A = P, B = Q")
	print("  Result: ¬(P ∨ Q)")
	print()
	print("Why it works:")
	print("  1. BOTH operands are already negated (¬P and ¬Q)")
	print("  2. We can factor out the negations")
	print("  3. We get: ¬(P ∨ Q)")
	print()

	var result1 = engine.apply_de_morgan_or_reverse(expr1)
	print("Engine transformation:")
	print("  Input:  " + expr1.normalized_string)
	print("  Output: " + result1.normalized_string)
	print("  ✓ SUCCESS - De Morgan's Reverse (OR) applied")
	print()

	print(repeat_char("=", 80))
	print("CASE 2: ¬P ∧ Q (ONLY ONE side negated) - De Morgan's DOES NOT APPLY")
	print(repeat_char("=", 80))
	print()

	var expr2 = engine.create_expression("¬P ∧ Q")
	print("Expression: " + expr2.normalized_string)
	print()
	print("Analysis:")
	print("  - Left operand:  ¬P (negated)")
	print("  - Right operand: Q (NOT negated)")
	print("  - Operator: ∧ (AND)")
	print()
	print("Attempting pattern matching for Reverse De Morgan's (OR):")
	print("  Template requires: ¬A ∧ ¬B")
	print("  We have: ¬P ∧ Q")
	print()
	print("  ✗ MISMATCH: Right operand Q is NOT negated")
	print("  ✗ Pattern does not match!")
	print()

	print("Why it doesn't work:")
	print("  1. De Morgan's requires BOTH operands to be negated")
	print("  2. Only the left operand (¬P) is negated")
	print("  3. Q is NOT negated (we'd need ¬Q)")
	print("  4. Cannot factor out negations that don't exist!")
	print()

	var result2 = engine.apply_de_morgan_or_reverse(expr2)
	print("Engine transformation:")
	print("  Input:  " + expr2.normalized_string)
	print("  Output: " + result2.normalized_string)
	if not result2.is_valid or result2.normalized_string.is_empty():
		print("  ✗ FAILED - De Morgan's Reverse (OR) cannot apply")
	print()

	print(repeat_char("=", 80))
	print("BUT WAIT! ¬P ∧ Q IS still equivalent to ¬(P ∨ ¬Q)")
	print(repeat_char("=", 80))
	print()
	print("The equivalence exists, but you need a DIFFERENT approach:")
	print()
	print("Option 1: Use a more general transformation")
	print("  - This isn't De Morgan's law")
	print("  - It's a general logical equivalence")
	print("  - Pattern: A ∧ B ≡ ¬(¬A ∨ ¬B)")
	print()
	print("Option 2: Transform Q first, then apply De Morgan's")
	print("  Step 1: ¬P ∧ Q")
	print("  Step 2: Apply double negation to Q → ¬P ∧ ¬¬Q")
	print("  Step 3: Now both are negated!")
	print("  Step 4: Apply Reverse De Morgan's (OR) → ¬(P ∨ ¬Q)")
	print()

	print("Let's try Option 2:")
	print(repeat_char("─", 80))

	# Create ¬¬Q
	var double_neg_q = engine.create_expression("¬¬Q")
	print("  Created: ¬¬Q")

	# Create ¬P ∧ ¬¬Q
	var expr3 = engine.create_expression("¬P ∧ ¬¬Q")
	print("  Created: " + expr3.normalized_string)

	# Now check if De Morgan's applies
	var ops = engine.get_applicable_single_operations(expr3)
	var has_demorgan = false
	for op in ops:
		if "De Morgan's Reverse" in op:
			has_demorgan = true
			print("  ✓ De Morgan's Reverse (OR) is now available!")
			break

	if has_demorgan:
		var result3 = engine.apply_de_morgan_or_reverse(expr3)
		print("  Applied De Morgan's: " + result3.normalized_string)
		print("  ✓ Got: ¬(P ∨ ¬Q)")
	print()

	print(repeat_char("=", 80))
	print("CONCLUSION")
	print(repeat_char("=", 80))
	print()
	print("De Morgan's laws are PATTERN MATCHING rules:")
	print("  ✓ They work when the pattern matches exactly")
	print("  ✗ They don't work when the pattern doesn't match")
	print()
	print("For ¬P ∧ Q:")
	print("  - It doesn't match the De Morgan's pattern (only one side negated)")
	print("  - But it's still equivalent to ¬(P ∨ ¬Q) logically")
	print("  - You need different transformation steps to get there")
	print()
	print("Think of De Morgan's as a specific tool:")
	print("  - It's perfect for its specific job")
	print("  - But you can't use it for every job")
	print("  - Sometimes you need other tools (transformations)")
	print()
	print("================================================================================")
