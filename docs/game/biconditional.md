# Biconditional (Equivalence)

## Description
A biconditional states that two propositions have the same truth value. "P if and only if Q" means "if P then Q" and "if Q then P". We can use biconditionals to infer one side from the other.

## Rule Pattern
P ↔ Q, P ⊢ Q (or P ↔ Q, Q ⊢ P)

## Problems

### Problem 1 (Difficulty: Easy)
**Premises:**
- P ↔ Q
- P

**Conclusion:** Q

**Brief Solution:** Apply Biconditional elimination from left to right.

---

### Problem 2 (Difficulty: Easy)
**Premises:**
- R ↔ S
- S

**Conclusion:** R

**Brief Solution:** Apply Biconditional elimination from right to left.

---

### Problem 3 (Difficulty: Easy)
**Premises:**
- A ↔ B
- A

**Conclusion:** B

**Brief Solution:** Direct application of Biconditional.

---

### Problem 4 (Difficulty: Medium)
**Premises:**
- P ↔ Q
- Q

**Conclusion:** P

**Brief Solution:** Apply Biconditional in reverse direction.

---

### Problem 5 (Difficulty: Medium)
**Premises:**
- (P ∧ Q) ↔ R
- P ∧ Q

**Conclusion:** R

**Brief Solution:** Apply Biconditional where left side is a conjunction.

---

### Problem 6 (Difficulty: Medium)
**Premises:**
- P ↔ (Q ∨ R)
- P

**Conclusion:** Q ∨ R

**Brief Solution:** Apply Biconditional where right side is a disjunction.

---

### Problem 7 (Difficulty: Hard)
**Premises:**
- P ↔ Q
- Q ↔ R
- P

**Conclusion:** R

**Brief Solution:** Apply Biconditional twice to chain through: P gives Q, Q gives R.

---

### Problem 8 (Difficulty: Hard)
**Premises:**
- P ↔ Q
- P

**Conclusion:** (P → Q) ∧ (Q → P)

**Brief Solution:** Transform the biconditional into its implication form, then apply.

---

### Problem 9 (Difficulty: Hard)
**Premises:**
- (P → Q) ∧ (Q → P)
- P

**Conclusion:** Q

**Brief Solution:** Recognize this as a biconditional, then apply left to right.

---

### Problem 10 (Difficulty: Very Hard)
**Premises:**
- P ↔ Q
- Q ↔ R
- R ↔ S
- P

**Conclusion:** S

**Brief Solution:** Chain multiple biconditionals: P gives Q, Q gives R, R gives S.