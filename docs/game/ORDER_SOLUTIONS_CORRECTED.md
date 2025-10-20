# Boolean Logic Bartender - Corrected Order Solutions Guide

This guide provides step-by-step solutions for all 50 orders in the Boolean Logic Bartender game, using only variables P, Q, R, S, T and valid logical inferences.

## Level 1 Orders (1 Operation, Max 2 Premises)

### Order 1.1: Modus Ponens
**Premises:** P → Q, P
**Conclusion:** Q

**Solution Steps:**
1. Apply Modus Ponens to "P → Q" and "P"
2. Result: Q ✓

---

### Order 1.2: Simplification (Left)
**Premises:** P ∧ Q
**Conclusion:** P

**Solution Steps:**
1. Apply Simplification to "P ∧ Q"
2. Result: P ✓

---

### Order 1.3: Modus Tollens
**Premises:** P → Q, ¬Q
**Conclusion:** ¬P

**Solution Steps:**
1. Apply Modus Tollens to "P → Q" and "¬Q"
2. Result: ¬P ✓

---

### Order 1.4: Disjunctive Syllogism
**Premises:** P ∨ Q, ¬P
**Conclusion:** Q

**Solution Steps:**
1. Apply Disjunctive Syllogism to "P ∨ Q" and "¬P"
2. Result: Q ✓

---

### Order 1.5: Double Negation
**Premises:** ¬¬P
**Conclusion:** P

**Solution Steps:**
1. Apply Double Negation to "¬¬P"
2. Result: P ✓

---

### Order 1.6: Conjunction
**Premises:** P, Q
**Conclusion:** P ∧ Q

**Solution Steps:**
1. Apply Conjunction to "P" and "Q"
2. Result: P ∧ Q ✓

---

### Order 1.7: Simplification (Right)
**Premises:** R ∧ S
**Conclusion:** S

**Solution Steps:**
1. Apply Simplification to "R ∧ S"
2. Result: S ✓

---

### Order 1.8: De Morgan's Law (AND)
**Premises:** ¬(P ∧ Q)
**Conclusion:** ¬P ∨ ¬Q

**Solution Steps:**
1. Apply De Morgan's Law to "¬(P ∧ Q)"
2. Result: ¬P ∨ ¬Q ✓

---

### Order 1.9: De Morgan's Law (OR)
**Premises:** ¬(P ∨ Q)
**Conclusion:** ¬P ∧ ¬Q

**Solution Steps:**
1. Apply De Morgan's Law to "¬(P ∨ Q)"
2. Result: ¬P ∧ ¬Q ✓

---

### Order 1.10: Disjunctive Syllogism (Variant)
**Premises:** Q ∨ R, ¬Q
**Conclusion:** R

**Solution Steps:**
1. Apply Disjunctive Syllogism to "Q ∨ R" and "¬Q"
2. Result: R ✓

---

## Level 2 Orders (2 Operations)

### Order 2.1: Hypothetical Syllogism + MP
**Premises:** P → Q, Q → R, P
**Conclusion:** R

**Solution Steps:**
1. Apply Hypothetical Syllogism to "P → Q" and "Q → R"
2. Get: P → R
3. Apply Modus Ponens to "P → R" and "P"
4. Result: R ✓

---

### Order 2.2: Simplification + Conjunction
**Premises:** P ∧ Q, R
**Conclusion:** P ∧ R

**Solution Steps:**
1. Apply Simplification to "P ∧ Q"
2. Get: P
3. Apply Conjunction to "P" and "R"
4. Result: P ∧ R ✓

---

### Order 2.3: Double Negation + Modus Ponens
**Premises:** ¬¬P, P → Q
**Conclusion:** Q

**Solution Steps:**
1. Apply Double Negation to "¬¬P"
2. Get: P
3. Apply Modus Ponens to "P → Q" and "P"
4. Result: Q ✓

---

### Order 2.4: Disjunctive Syllogism + MP
**Premises:** P ∨ Q, ¬P, Q → R
**Conclusion:** R

**Solution Steps:**
1. Apply Disjunctive Syllogism to "P ∨ Q" and "¬P"
2. Get: Q
3. Apply Modus Ponens to "Q → R" and "Q"
4. Result: R ✓

---

### Order 2.5: Simplification + Simplification
**Premises:** P ∧ (Q ∧ R)
**Conclusion:** Q ∧ R

**Solution Steps:**
1. Apply Simplification to "P ∧ (Q ∧ R)"
2. Result: Q ∧ R ✓ (taking the right side of the conjunction)

---

### Order 2.6: De Morgan's + Ignore Unused
**Premises:** ¬(P ∨ Q), R → S
**Conclusion:** ¬P ∧ ¬Q

**Solution Steps:**
1. Apply De Morgan's Law to "¬(P ∨ Q)"
2. Result: ¬P ∧ ¬Q ✓
3. (R → S is unused premise)

---

### Order 2.7: Conjunction + Conjunction
**Premises:** P, Q, R
**Conclusion:** (P ∧ Q) ∧ R

**Solution Steps:**
1. Apply Conjunction to "P" and "Q"
2. Get: P ∧ Q
3. Apply Conjunction to "P ∧ Q" and "R"
4. Result: (P ∧ Q) ∧ R ✓

---

### Order 2.8: Modus Ponens + Simplification
**Premises:** P → (Q ∧ R), P
**Conclusion:** Q

**Solution Steps:**
1. Apply Modus Ponens to "P → (Q ∧ R)" and "P"
2. Get: Q ∧ R
3. Apply Simplification to "Q ∧ R"
4. Result: Q ✓

---

### Order 2.9: Conjunction + Modus Ponens
**Premises:** (P ∧ Q) → R, P, Q
**Conclusion:** R

**Solution Steps:**
1. Apply Conjunction to "P" and "Q"
2. Get: P ∧ Q
3. Apply Modus Ponens to "(P ∧ Q) → R" and "P ∧ Q"
4. Result: R ✓

---

### Order 2.10: Disjunctive Syllogism + Identity
**Premises:** P ∨ (Q ∧ R), ¬P
**Conclusion:** Q ∧ R

**Solution Steps:**
1. Apply Disjunctive Syllogism to "P ∨ (Q ∧ R)" and "¬P"
2. Result: Q ∧ R ✓

---

## Level 3 Orders (3 Operations)

### Order 3.1: Chain of Hypothetical Syllogisms
**Premises:** P → Q, Q → R, R → S, P
**Conclusion:** S

**Solution Steps:**
1. Apply Hypothetical Syllogism to "P → Q" and "Q → R"
2. Get: P → R
3. Apply Hypothetical Syllogism to "P → R" and "R → S"
4. Get: P → S
5. Apply Modus Ponens to "P → S" and "P"
6. Result: S ✓

---

### Order 3.2: Multiple Simplifications + Conjunction
**Premises:** P ∧ Q, R ∧ S
**Conclusion:** P ∧ R

**Solution Steps:**
1. Apply Simplification to "P ∧ Q"
2. Get: P
3. Apply Simplification to "R ∧ S"
4. Get: R
5. Apply Conjunction to "P" and "R"
6. Result: P ∧ R ✓

---

### Order 3.3: Double Neg + Disj Syll + MP
**Premises:** ¬¬(P ∨ Q), ¬P, Q → R
**Conclusion:** R

**Solution Steps:**
1. Apply Double Negation to "¬¬(P ∨ Q)"
2. Get: P ∨ Q
3. Apply Disjunctive Syllogism to "P ∨ Q" and "¬P"
4. Get: Q
5. Apply Modus Ponens to "Q → R" and "Q"
6. Result: R ✓

---

### Order 3.4: Modus Tollens + De Morgan's + Disj Syll
**Premises:** (P ∧ Q) → R, ¬R, P
**Conclusion:** ¬Q

**Solution Steps:**
1. Apply Modus Tollens to "(P ∧ Q) → R" and "¬R"
2. Get: ¬(P ∧ Q)
3. Apply De Morgan's Law to "¬(P ∧ Q)"
4. Get: ¬P ∨ ¬Q
5. Since we have "P", apply Disjunctive Syllogism to "¬P ∨ ¬Q" and P (which contradicts ¬P)
6. Result: ¬Q ✓

---

### Order 3.5: Disjunctive Syllogism + Simplification
**Premises:** P ∨ (Q ∧ R), ¬P
**Conclusion:** Q

**Solution Steps:**
1. Apply Disjunctive Syllogism to "P ∨ (Q ∧ R)" and "¬P"
2. Get: Q ∧ R
3. Apply Simplification to "Q ∧ R"
4. Result: Q ✓

---

### Order 3.6: MP + De Morgan's + Disj Syll
**Premises:** ¬(P ∧ Q), R → P, R
**Conclusion:** ¬Q

**Solution Steps:**
1. Apply Modus Ponens to "R → P" and "R"
2. Get: P
3. Apply De Morgan's Law to "¬(P ∧ Q)"
4. Get: ¬P ∨ ¬Q
5. Since we have P, apply Disjunctive Syllogism
6. Result: ¬Q ✓

---

### Order 3.7: Chain of Conjunctions
**Premises:** P, Q, R, S
**Conclusion:** ((P ∧ Q) ∧ R) ∧ S

**Solution Steps:**
1. Apply Conjunction to "P" and "Q"
2. Get: P ∧ Q
3. Apply Conjunction to "P ∧ Q" and "R"
4. Get: (P ∧ Q) ∧ R
5. Apply Conjunction to "(P ∧ Q) ∧ R" and "S"
6. Result: ((P ∧ Q) ∧ R) ∧ S ✓

---

### Order 3.8: MP + Disjunctive Syllogism
**Premises:** P → (Q ∨ R), P, ¬Q
**Conclusion:** R

**Solution Steps:**
1. Apply Modus Ponens to "P → (Q ∨ R)" and "P"
2. Get: Q ∨ R
3. Apply Disjunctive Syllogism to "Q ∨ R" and "¬Q"
4. Result: R ✓

---

### Order 3.9: Simplification + Double Neg + Conjunction
**Premises:** ¬¬P ∧ ¬¬Q
**Conclusion:** P ∧ Q

**Solution Steps:**
1. Apply Simplification to "¬¬P ∧ ¬¬Q"
2. Get: ¬¬P and ¬¬Q (separately)
3. Apply Double Negation to "¬¬P"
4. Get: P
5. Apply Double Negation to "¬¬Q"
6. Get: Q
7. Apply Conjunction to "P" and "Q"
8. Result: P ∧ Q ✓

---

### Order 3.10: Simplification + Disj Syll + Conjunction
**Premises:** (P ∨ Q) ∧ R, ¬P
**Conclusion:** Q ∧ R

**Solution Steps:**
1. Apply Simplification to "(P ∨ Q) ∧ R"
2. Get: P ∨ Q and R
3. Apply Disjunctive Syllogism to "P ∨ Q" and "¬P"
4. Get: Q
5. Apply Conjunction to "Q" and "R"
6. Result: Q ∧ R ✓

---

## Level 4 Orders (3-4 Operations)

### Order 4.1: Complex Chain with Branching
**Premises:** P → Q, Q → (R ∧ S), R → T, P
**Conclusion:** T

**Solution Steps:**
1. Apply Modus Ponens to "P → Q" and "P"
2. Get: Q
3. Apply Modus Ponens to "Q → (R ∧ S)" and "Q"
4. Get: R ∧ S
5. Apply Simplification to "R ∧ S"
6. Get: R
7. Apply Modus Ponens to "R → T" and "R"
8. Result: T ✓

---

### Order 4.2: De Morgan's + Simplification + Conjunction
**Premises:** ¬(P ∨ Q), R ∧ S
**Conclusion:** ¬P ∧ S

**Solution Steps:**
1. Apply De Morgan's Law to "¬(P ∨ Q)"
2. Get: ¬P ∧ ¬Q
3. Apply Simplification to "¬P ∧ ¬Q"
4. Get: ¬P
5. Apply Simplification to "R ∧ S"
6. Get: S
7. Apply Conjunction to "¬P" and "S"
8. Result: ¬P ∧ S ✓

---

### Order 4.3: Multiple Disjunctive Syllogisms
**Premises:** P ∨ (Q ∧ R), ¬P, S ∨ T, ¬S
**Conclusion:** Q ∧ T

**Solution Steps:**
1. Apply Disjunctive Syllogism to "P ∨ (Q ∧ R)" and "¬P"
2. Get: Q ∧ R
3. Apply Disjunctive Syllogism to "S ∨ T" and "¬S"
4. Get: T
5. Apply Simplification to "Q ∧ R"
6. Get: Q
7. Apply Conjunction to "Q" and "T"
8. Result: Q ∧ T ✓

---

### Order 4.4: Conjunction + MP + Disj Syll
**Premises:** (P ∧ Q) → (R ∨ S), P, Q, ¬R
**Conclusion:** S

**Solution Steps:**
1. Apply Conjunction to "P" and "Q"
2. Get: P ∧ Q
3. Apply Modus Ponens to "(P ∧ Q) → (R ∨ S)" and "P ∧ Q"
4. Get: R ∨ S
5. Apply Disjunctive Syllogism to "R ∨ S" and "¬R"
6. Result: S ✓

---

### Order 4.5: Double Neg + MP + MP + Simplification
**Premises:** ¬¬(P → Q), ¬¬P, Q → (R ∧ S)
**Conclusion:** R

**Solution Steps:**
1. Apply Double Negation to "¬¬(P → Q)"
2. Get: P → Q
3. Apply Double Negation to "¬¬P"
4. Get: P
5. Apply Modus Ponens to "P → Q" and "P"
6. Get: Q
7. Apply Modus Ponens to "Q → (R ∧ S)" and "Q"
8. Get: R ∧ S
9. Apply Simplification to "R ∧ S"
10. Result: R ✓

---

### Order 4.6: Disj Syll + Chain of MPs
**Premises:** P ∨ Q, ¬P, Q → R, R → S, S → T
**Conclusion:** T

**Solution Steps:**
1. Apply Disjunctive Syllogism to "P ∨ Q" and "¬P"
2. Get: Q
3. Apply Modus Ponens to "Q → R" and "Q"
4. Get: R
5. Apply Modus Ponens to "R → S" and "R"
6. Get: S
7. Apply Modus Ponens to "S → T" and "S"
8. Result: T ✓

---

### Order 4.7: Contradiction via MT
**Premises:** P → Q, Q → R, ¬R, P
**Conclusion:** ⊥ (contradiction)

**Solution Steps:**
1. Apply Hypothetical Syllogism to "P → Q" and "Q → R"
2. Get: P → R
3. Apply Modus Tollens to "P → R" and "¬R"
4. Get: ¬P
5. We have both "P" and "¬P"
6. Result: ⊥ (contradiction) ✓

---

### Order 4.8: Multiple Simplifications + Syllogisms
**Premises:** (P ∨ Q) ∧ (R ∨ S), ¬P, ¬R
**Conclusion:** Q ∧ S

**Solution Steps:**
1. Apply Simplification to "(P ∨ Q) ∧ (R ∨ S)"
2. Get: P ∨ Q and R ∨ S
3. Apply Disjunctive Syllogism to "P ∨ Q" and "¬P"
4. Get: Q
5. Apply Disjunctive Syllogism to "R ∨ S" and "¬R"
6. Get: S
7. Apply Conjunction to "Q" and "S"
8. Result: Q ∧ S ✓

---

### Order 4.9: Nested Implications + Chain
**Premises:** P → (Q → R), P, Q, R → S
**Conclusion:** S

**Solution Steps:**
1. Apply Modus Ponens to "P → (Q → R)" and "P"
2. Get: Q → R
3. Apply Modus Ponens to "Q → R" and "Q"
4. Get: R
5. Apply Modus Ponens to "R → S" and "R"
6. Result: S ✓

---

### Order 4.10: Complex De Morgan's + Simplifications
**Premises:** ¬(P ∨ Q) ∧ ¬(R ∨ S)
**Conclusion:** ¬P ∧ ¬R

**Solution Steps:**
1. Apply Simplification to "¬(P ∨ Q) ∧ ¬(R ∨ S)"
2. Get: ¬(P ∨ Q) and ¬(R ∨ S)
3. Apply De Morgan's Law to "¬(P ∨ Q)"
4. Get: ¬P ∧ ¬Q
5. Apply Simplification to "¬P ∧ ¬Q"
6. Get: ¬P
7. Apply De Morgan's Law to "¬(R ∨ S)"
8. Get: ¬R ∧ ¬S
9. Apply Simplification to "¬R ∧ ¬S"
10. Get: ¬R
11. Apply Conjunction to "¬P" and "¬R"
12. Result: ¬P ∧ ¬R ✓

---

## Level 5 Orders (4+ Operations, Complex)

### Order 5.1: Complex Branching Chain
**Premises:** P → (Q ∧ R), Q → S, R → T, P
**Conclusion:** S ∧ T

**Solution Steps:**
1. Apply Modus Ponens to "P → (Q ∧ R)" and "P"
2. Get: Q ∧ R
3. Apply Simplification to "Q ∧ R"
4. Get: Q and R
5. Apply Modus Ponens to "Q → S" and "Q"
6. Get: S
7. Apply Modus Ponens to "R → T" and "R"
8. Get: T
9. Apply Conjunction to "S" and "T"
10. Result: S ∧ T ✓

---

### Order 5.2: Simple Contradiction
**Premises:** (P ∨ Q) → R, P, ¬R
**Conclusion:** ⊥ (contradiction)

**Solution Steps:**
1. Apply Addition to "P"
2. Get: P ∨ Q (since P is true)
3. Apply Modus Ponens to "(P ∨ Q) → R" and "P ∨ Q"
4. Get: R
5. We have both "R" and "¬R"
6. Result: ⊥ (contradiction) ✓

---

### Order 5.3: Chain of Implications
**Premises:** (P ∧ Q) → (R ∨ S), (R ∨ S) → T, P, Q
**Conclusion:** T

**Solution Steps:**
1. Apply Conjunction to "P" and "Q"
2. Get: P ∧ Q
3. Apply Modus Ponens to "(P ∧ Q) → (R ∨ S)" and "P ∧ Q"
4. Get: R ∨ S
5. Apply Modus Ponens to "(R ∨ S) → T" and "R ∨ S"
6. Result: T ✓

---

### Order 5.4: Resolution-style Proof
**Premises:** P ∨ Q, ¬P ∨ R, ¬Q ∨ R
**Conclusion:** R

**Solution Steps:**
1. Case analysis: Either P or ¬P is true
2. If P is true: From "¬P ∨ R" and P, we get R (by Disjunctive Syllogism with ¬P false)
3. If P is false: From "P ∨ Q" and ¬P, we get Q (by Disjunctive Syllogism)
4. From "¬Q ∨ R" and Q, we get R (by Disjunctive Syllogism with ¬Q false)
5. In both cases, we get R
6. Result: R ✓

---

### Order 5.5: Complex Modus Tollens
**Premises:** (P → Q) ∧ (R → S), ¬Q ∨ ¬S, P ∨ R
**Conclusion:** ¬P ∨ ¬R

**Solution Steps:**
1. Apply Simplification to "(P → Q) ∧ (R → S)"
2. Get: P → Q and R → S
3. From "¬Q ∨ ¬S", either ¬Q or ¬S (or both)
4. If ¬Q: Apply Modus Tollens to "P → Q" and "¬Q" to get ¬P
5. If ¬S: Apply Modus Tollens to "R → S" and "¬S" to get ¬R
6. In either case, we get ¬P or ¬R
7. Result: ¬P ∨ ¬R ✓

---

### Order 5.6: Biconditional Elimination + Convergence
**Premises:** P ↔ Q, Q → (R ∧ S), R → T, S → T, P
**Conclusion:** T

**Solution Steps:**
1. Apply Biconditional Elimination to "P ↔ Q"
2. Get: (P → Q) ∧ (Q → P)
3. Apply Simplification to get: P → Q
4. Apply Modus Ponens to "P → Q" and "P"
5. Get: Q
6. Apply Modus Ponens to "Q → (R ∧ S)" and "Q"
7. Get: R ∧ S
8. Apply Simplification to "R ∧ S"
9. Get: R and S
10. Apply Modus Ponens to "R → T" and "R" (or "S → T" and "S")
11. Result: T ✓

---

### Order 5.7: Double Negation + Parallel Inference
**Premises:** ¬¬(P ∧ Q), P → R, Q → S
**Conclusion:** R ∧ S

**Solution Steps:**
1. Apply Double Negation to "¬¬(P ∧ Q)"
2. Get: P ∧ Q
3. Apply Simplification to "P ∧ Q"
4. Get: P and Q
5. Apply Modus Ponens to "P → R" and "P"
6. Get: R
7. Apply Modus Ponens to "Q → S" and "Q"
8. Get: S
9. Apply Conjunction to "R" and "S"
10. Result: R ∧ S ✓

---

### Order 5.8: Convergent Proof
**Premises:** P → Q, R → S, (Q ∧ S) → T, P, R
**Conclusion:** T

**Solution Steps:**
1. Apply Modus Ponens to "P → Q" and "P"
2. Get: Q
3. Apply Modus Ponens to "R → S" and "R"
4. Get: S
5. Apply Conjunction to "Q" and "S"
6. Get: Q ∧ S
7. Apply Modus Ponens to "(Q ∧ S) → T" and "Q ∧ S"
8. Result: T ✓

---

### Order 5.9: Proof by Contradiction
**Premises:** (P ∨ Q) → (R ∧ S), P, ¬R → T, ¬T
**Conclusion:** R ∧ S

**Solution Steps:**
1. Apply Addition to "P"
2. Get: P ∨ Q (since P is true)
3. Apply Modus Ponens to "(P ∨ Q) → (R ∧ S)" and "P ∨ Q"
4. Get: R ∧ S
5. Verify: If R were false (¬R), then by "¬R → T" we'd get T, but we have ¬T
6. Therefore R must be true, confirming R ∧ S
7. Result: R ∧ S ✓

---

### Order 5.10: XOR Elimination to Common Conclusion
**Premises:** P ⊕ Q, P → R, Q → R
**Conclusion:** R

**Solution Steps:**
1. Apply XOR Elimination to "P ⊕ Q"
2. Get: (P ∨ Q) ∧ ¬(P ∧ Q)
3. Apply Simplification to get: P ∨ Q
4. From XOR, exactly one of P or Q is true
5. Case 1: If P is true, apply Modus Ponens to "P → R" and "P" to get R
6. Case 2: If Q is true, apply Modus Ponens to "Q → R" and "Q" to get R
7. In both cases, we get R
8. Result: R ✓

---

## Summary

This corrected guide covers all 50 unique orders with logically valid conclusions that can be derived from the given premises using standard inference rules. All solutions use only the variables P, Q, R, S, T and proper logical reasoning.