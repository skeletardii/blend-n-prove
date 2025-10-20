# Simplification

## Description
Simplification allows us to extract one part of a conjunction. If we know "P and Q" is true, we can conclude either P or Q individually.

## Rule Pattern
P ∧ Q ⊢ P (or P ∧ Q ⊢ Q)

## Problems

### Problem 1 (Difficulty: Easy)
**Premises:**
- P ∧ Q

**Conclusion:** P

**Brief Solution:** Apply Simplification to extract the left conjunct.

---

### Problem 2 (Difficulty: Easy)
**Premises:**
- R ∧ S

**Conclusion:** S

**Brief Solution:** Apply Simplification to extract the right conjunct.

---

### Problem 3 (Difficulty: Easy)
**Premises:**
- A ∧ B

**Conclusion:** A

**Brief Solution:** Direct simplification to get A.

---

### Problem 4 (Difficulty: Medium)
**Premises:**
- (P ∨ Q) ∧ R

**Conclusion:** P ∨ Q

**Brief Solution:** Apply Simplification to extract the disjunction.

---

### Problem 5 (Difficulty: Medium)
**Premises:**
- P ∧ (Q ∧ R)

**Conclusion:** Q ∧ R

**Brief Solution:** Extract the nested conjunction from the right side.

---

### Problem 6 (Difficulty: Medium)
**Premises:**
- (P → Q) ∧ R

**Conclusion:** P → Q

**Brief Solution:** Apply Simplification to extract the implication.

---

### Problem 7 (Difficulty: Hard)
**Premises:**
- (P ∧ Q) ∧ (R ∧ S)

**Conclusion:** R ∧ S

**Brief Solution:** Apply Simplification to extract the right conjunction.

---

### Problem 8 (Difficulty: Hard)
**Premises:**
- P ∧ (Q ∧ R)

**Conclusion:** R

**Brief Solution:** Apply Simplification twice: first to get "Q ∧ R", then again to get R.

---

### Problem 9 (Difficulty: Hard)
**Premises:**
- ((P ∧ Q) ∧ R) ∧ S

**Conclusion:** R

**Brief Solution:** Apply nested Simplification to extract R from the complex conjunction.

---

### Problem 10 (Difficulty: Very Hard)
**Premises:**
- (P ∧ Q) ∧ (R ∧ S)

**Conclusion:** Q

**Brief Solution:** Apply Simplification to get "P ∧ Q", then Simplification again to get Q.