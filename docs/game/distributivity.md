# Distributivity

## Description
Distributivity allows us to distribute one operator over another. "P and (Q or R)" is equivalent to "(P and Q) or (P and R)". Similarly, "P or (Q and R)" equals "(P or Q) and (P or R)".

## Rule Pattern
P ∧ (Q ∨ R) ⊢ (P ∧ Q) ∨ (P ∧ R)
P ∨ (Q ∧ R) ⊢ (P ∨ Q) ∧ (P ∨ R)

## Problems

### Problem 1 (Difficulty: Easy)
**Premises:**
- P ∧ (Q ∨ R)

**Conclusion:** (P ∧ Q) ∨ (P ∧ R)

**Brief Solution:** Apply Distributivity of AND over OR.

---

### Problem 2 (Difficulty: Easy)
**Premises:**
- A ∨ (B ∧ C)

**Conclusion:** (A ∨ B) ∧ (A ∨ C)

**Brief Solution:** Apply Distributivity of OR over AND.

---

### Problem 3 (Difficulty: Easy)
**Premises:**
- R ∧ (S ∨ T)

**Conclusion:** (R ∧ S) ∨ (R ∧ T)

**Brief Solution:** Direct application of Distributivity.

---

### Problem 4 (Difficulty: Medium)
**Premises:**
- (P ∧ Q) ∨ (P ∧ R)

**Conclusion:** P ∧ (Q ∨ R)

**Brief Solution:** Apply reverse Distributivity (factoring out P).

---

### Problem 5 (Difficulty: Medium)
**Premises:**
- (P ∨ Q) ∧ (P ∨ R)

**Conclusion:** P ∨ (Q ∧ R)

**Brief Solution:** Apply reverse Distributivity (factoring out P).

---

### Problem 6 (Difficulty: Medium)
**Premises:**
- P ∧ (Q ∨ R ∨ S)

**Conclusion:** (P ∧ Q) ∨ (P ∧ R) ∨ (P ∧ S)

**Brief Solution:** Apply Distributivity multiple times.

---

### Problem 7 (Difficulty: Hard)
**Premises:**
- (P ∧ Q) ∨ (R ∧ S)

**Conclusion:** (P ∨ R) ∧ (P ∨ S) ∧ (Q ∨ R) ∧ (Q ∨ S)

**Brief Solution:** Apply Distributivity in both directions to fully expand.

---

### Problem 8 (Difficulty: Hard)
**Premises:**
- P ∧ ((Q ∨ R) ∧ S)

**Conclusion:** (P ∧ Q ∧ S) ∨ (P ∧ R ∧ S)

**Brief Solution:** Apply nested Distributivity.

---

### Problem 9 (Difficulty: Hard)
**Premises:**
- (P ∧ Q) ∨ (P ∧ R)

**Conclusion:** P

**Brief Solution:** Apply reverse Distributivity to get "P ∧ (Q ∨ R)", then Simplification.

---

### Problem 10 (Difficulty: Very Hard)
**Premises:**
- (P ∨ Q) ∧ (R ∨ S)

**Conclusion:** (P ∧ R) ∨ (P ∧ S) ∨ (Q ∧ R) ∨ (Q ∧ S)

**Brief Solution:** Apply Distributivity twice to fully expand the expression.