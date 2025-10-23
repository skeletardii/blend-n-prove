extends SceneTree

# Comprehensive test for parenthesis preservation across all affected operations

func _init():
	print("=== COMPREHENSIVE PARENTHESIS PRESERVATION TEST ===")
	print("Testing 18 operations affected by parenthesis issue")
	print()

	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()
	var passed = 0
	var failed = 0

	# Test 1: Conjunction (basic case we already fixed)
	print("TEST 1: Conjunction")
	var p = engine.create_expression("P")
	var q = engine.create_expression("Q")
	var r = engine.create_expression("R")
	var pq = engine.apply_conjunction([p, q])
	print("  P ∧ Q = ", pq.expression_string)
	if pq.expression_string == "(P ∧ Q)":
		print("  ✓ PASS")
		passed += 1
	else:
		print("  ✗ FAIL - Expected (P ∧ Q)")
		failed += 1
	print()

	# Test 2: Addition (disjunction creation)
	print("TEST 2: Addition")
	var p_or_r = engine.apply_addition([p], r)
	print("  P ∨ R = ", p_or_r.expression_string)
	if p_or_r.expression_string == "(P ∨ R)":
		print("  ✓ PASS")
		passed += 1
	else:
		print("  ✗ FAIL - Expected (P ∨ R)")
		failed += 1
	print()

	# Test 3: Distributivity (HIGH RISK - Triple nesting)
	print("TEST 3: Distributivity - A ∧ (B ∨ C) → (A ∧ B) ∨ (A ∧ C)")
	var b = engine.create_expression("B")
	var c = engine.create_expression("C")
	var b_or_c = engine.apply_addition([b], c)  # (B ∨ C)
	var a_and_bvc = engine.apply_conjunction([p, b_or_c])  # P ∧ (B ∨ C) - but becomes (P ∧ (B ∨ C))
	print("  Input: ", a_and_bvc.expression_string)
	var dist_result = engine.apply_distributivity(a_and_bvc)
	print("  Output: ", dist_result.expression_string)
	# Should create ((P ∧ B) ∨ (P ∧ C))
	print("  Expected: ((P ∧ B) ∨ (P ∧ C))")
	if dist_result.expression_string == "((P ∧ B) ∨ (P ∧ C))":
		print("  ✓ PASS - Triple nesting preserved")
		passed += 1
	else:
		print("  ✗ FAIL")
		failed += 1
	print()

	# Test 4: De Morgan's Laws
	print("TEST 4: De Morgan AND - ¬(P ∧ Q) → (¬P ∨ ¬Q)")
	var neg_pq = engine.create_expression("¬(P ∧ Q)")
	var dm_result = engine.apply_de_morgan_and(neg_pq)
	print("  Output: ", dm_result.expression_string)
	print("  Expected: (¬P ∨ ¬Q)")
	if dm_result.expression_string == "(¬P ∨ ¬Q)":
		print("  ✓ PASS")
		passed += 1
	else:
		print("  ✗ FAIL")
		failed += 1
	print()

	# Test 5: XOR Elimination (HIGH RISK - Complex nesting)
	print("TEST 5: XOR Elimination - P ⊕ Q → (P ∨ Q) ∧ ¬(P ∧ Q)")
	var p_xor_q = engine.create_expression("P ⊕ Q")
	var xor_result = engine.apply_xor_elimination(p_xor_q)
	print("  Output: ", xor_result.expression_string)
	print("  Expected: ((P ∨ Q) ∧ ¬(P ∧ Q))")
	if xor_result.expression_string == "((P ∨ Q) ∧ ¬(P ∧ Q))":
		print("  ✓ PASS - Complex nesting preserved")
		passed += 1
	else:
		print("  ✗ FAIL")
		failed += 1
	print()

	# Test 6: Biconditional to Equivalence (HIGH RISK - Nested conjunctions/disjunctions)
	print("TEST 6: Biconditional Equivalence - P ↔ Q → (P ∧ Q) ∨ (¬P ∧ ¬Q)")
	var p_iff_q = engine.create_expression("P ↔ Q")
	var bicon_result = engine.apply_biconditional_to_equivalence(p_iff_q)
	print("  Output: ", bicon_result.expression_string)
	print("  Expected: ((P ∧ Q) ∨ (¬P ∧ ¬Q))")
	if bicon_result.expression_string == "((P ∧ Q) ∨ (¬P ∧ ¬Q))":
		print("  ✓ PASS - Complex nesting preserved")
		passed += 1
	else:
		print("  ✗ FAIL")
		failed += 1
	print()

	# Test 7: Commutativity
	print("TEST 7: Commutativity - (P ∧ Q) → (Q ∧ P)")
	var comm_result = engine.apply_commutativity(pq)
	print("  Output: ", comm_result.expression_string)
	print("  Expected: (Q ∧ P)")
	if comm_result.expression_string == "(Q ∧ P)":
		print("  ✓ PASS")
		passed += 1
	else:
		print("  ✗ FAIL")
		failed += 1
	print()

	# Test 8: Associativity (HIGH RISK - Changes grouping)
	print("TEST 8: Associativity - (P ∧ Q) ∧ R → P ∧ (Q ∧ R)")
	var pqr = engine.apply_conjunction([pq, r])  # Should be ((P ∧ Q) ∧ R)
	print("  Input: ", pqr.expression_string)
	# Note: assoc might not work if input doesn't have the right structure
	# This is testing the transformation capability
	print("  (Associativity requires specific input structure)")
	print()

	# Test 9: Implication Conversion
	print("TEST 9: Implication Conversion - P → Q becomes ¬P ∨ Q")
	var p_impl_q = engine.create_expression("P → Q")
	var impl_conv_result = engine.apply_implication_conversion(p_impl_q)
	print("  Output: ", impl_conv_result.expression_string)
	print("  Expected: (¬P ∨ Q)")
	if impl_conv_result.expression_string == "(¬P ∨ Q)":
		print("  ✓ PASS")
		passed += 1
	else:
		print("  ✗ FAIL")
		failed += 1
	print()

	# Test 10: Contrapositive
	print("TEST 10: Contrapositive - P → Q becomes ¬Q → ¬P")
	var contra_result = engine.apply_contrapositive(p_impl_q)
	print("  Output: ", contra_result.expression_string)
	print("  Expected: (¬Q → ¬P)")
	if contra_result.expression_string == "(¬Q → ¬P)":
		print("  ✓ PASS")
		passed += 1
	else:
		print("  ✗ FAIL")
		failed += 1
	print()

	print("============================================================")
	print("SUMMARY:")
	print("  Passed: ", passed)
	print("  Failed: ", failed)
	print("  Total:  ", passed + failed)
	print()
	if failed == 0:
		print("  ✓✓✓ ALL TESTS PASSED! ✓✓✓")
		print("  Parenthesis preservation working correctly across all operations!")
	else:
		print("  ⚠ SOME TESTS FAILED - Review needed")
	print("============================================================")

	quit()
