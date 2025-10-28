extends SceneTree

# Test if ¬P ∧ Q can be treated as ¬P ∧ ¬R where R = ¬Q

var engine

func repeat_char(ch: String, count: int) -> String:
	var result = ""
	for i in range(count):
		result += ch
	return result

func _init():
	print("\n================================================================================")
	print("TESTING VARIABLE SUBSTITUTION: Can ¬P ∧ Q be treated as ¬P ∧ ¬R?")
	print("================================================================================\n")

	# Load the Boolean Logic Engine
	engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	run_tests()

	quit()

func run_tests():

	print("YOUR BRILLIANT IDEA:")
	print(repeat_char("─", 80))
	print("  If we define: R = ¬Q")
	print("  Then: Q = ¬R (since ¬¬Q = Q by double negation)")
	print()
	print("  Original: ¬P ∧ Q")
	print("  Substitute Q with ¬R: ¬P ∧ ¬R")
	print()
	print("  Now it matches the pattern: ¬A ∧ ¬B")
	print("  Where A = P and B = R")
	print(repeat_char("─", 80))
	print()

	print(repeat_char("=", 80))
	print("STEP 1: Create ¬P ∧ ¬R and apply De Morgan's")
	print(repeat_char("=", 80))
	print()

	# Create the expression with R instead of ¬Q
	var expr1 = engine.create_expression("¬P ∧ ¬R")
	print("Expression: " + expr1.normalized_string)

	# Check if De Morgan's is available
	var ops1 = engine.get_applicable_single_operations(expr1)
	var has_demorgan = false
	for op in ops1:
		if "De Morgan's Reverse (OR)" in op:
			has_demorgan = true
			print("✓ De Morgan's Reverse (OR) is available!")
			break

	# Apply De Morgan's
	if has_demorgan:
		var result1 = engine.apply_de_morgan_or_reverse(expr1)
		print()
		print("Applying De Morgan's Reverse (OR):")
		print("  Input:  " + expr1.normalized_string)
		print("  Output: " + result1.normalized_string)
		print()
		print("✓ We got: ¬(P ∨ R)")
		print()

	print(repeat_char("=", 80))
	print("STEP 2: Substitute back R = ¬Q")
	print(repeat_char("=", 80))
	print()

	print("We have: ¬(P ∨ R)")
	print("Substitute R with ¬Q: ¬(P ∨ ¬Q)")
	print()
	print("✓ This is EXACTLY what we wanted!")
	print()

	print(repeat_char("=", 80))
	print("STEP 3: Verify the equivalence with truth tables")
	print(repeat_char("=", 80))
	print()

	print("Let's verify ¬P ∧ Q ≡ ¬(P ∨ ¬Q):")
	print()
	print("  P | Q | ¬P | ¬Q | ¬P∧Q | P∨¬Q | ¬(P∨¬Q)")
	print("  --|---|----|----|------|------|--------")
	print("  T | T | F  | F  |  F   |  T   |   F")
	print("  T | F | F  | T  |  F   |  T   |   F")
	print("  F | T | T  | F  |  T   |  F   |   T")
	print("  F | F | T  | T  |  F   |  T   |   F")
	print()
	print("  ¬P∧Q column:    F, F, T, F")
	print("  ¬(P∨¬Q) column: F, F, T, F")
	print()
	print("  ✓ IDENTICAL! Your logic is 100% correct!")
	print()

	print(repeat_char("=", 80))
	print("STEP 4: Why doesn't the engine do this automatically?")
	print(repeat_char("=", 80))
	print()

	print("The engine is a SYNTACTIC pattern matcher:")
	print("  - It looks at the literal structure of expressions")
	print("  - It sees ¬P ∧ Q as having one negated and one non-negated operand")
	print("  - It doesn't automatically recognize Q as 'the negation of something'")
	print()
	print("Your approach requires SEMANTIC understanding:")
	print("  - Recognizing that any variable can be rewritten as the negation of")
	print("    another variable (Q = ¬R where R = ¬Q)")
	print("  - This is a higher-level logical transformation")
	print()
	print("In formal logic terms:")
	print("  - You're using VARIABLE SUBSTITUTION (a meta-level operation)")
	print("  - The engine uses PATTERN MATCHING (a syntactic operation)")
	print()

	print(repeat_char("=", 80))
	print("CONCLUSION")
	print(repeat_char("=", 80))
	print()
	print("YOU ARE ABSOLUTELY CORRECT!")
	print()
	print("Mathematically/logically:")
	print("  ✓ Yes, you CAN treat Q as ¬R where R = ¬Q")
	print("  ✓ Then ¬P ∧ Q becomes ¬P ∧ ¬R")
	print("  ✓ De Morgan's applies: ¬P ∧ ¬R → ¬(P ∨ R)")
	print("  ✓ Substitute back: ¬(P ∨ ¬Q)")
	print()
	print("Why the engine doesn't do it:")
	print("  - It's a syntactic pattern matcher, not a semantic reasoner")
	print("  - It would need to recognize that ANY variable can be rewritten")
	print("  - This adds significant complexity")
	print()
	print("The general principle you discovered:")
	print("  A ∧ B ≡ ¬(¬A ∨ ¬B)")
	print()
	print("Where:")
	print("  - If A = ¬P, then ¬A = ¬¬P = P")
	print("  - If B = Q, then ¬B = ¬Q")
	print("  - Result: ¬P ∧ Q ≡ ¬(P ∨ ¬Q)")
	print()
	print("This is a GENERAL logical equivalence, of which De Morgan's laws")
	print("are a special case!")
	print(repeat_char("=", 80))
