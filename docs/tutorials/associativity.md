# Associativity

## Description
Associativity allows us to regroup operations. "(P and Q) and R" is the same as "P and (Q and R)". This applies to AND and OR operations.

## Rule Pattern
(P ∧ Q) ∧ R ⊢ P ∧ (Q ∧ R)
(P ∨ Q) ∨ R ⊢ P ∨ (Q ∨ R)

## Problems

### Problem 1 (Difficulty: Easy)
**Premises:**
- (P ∧ Q) ∧ R

**Conclusion:** P ∧ (Q ∧ R)

**Brief Solution:** Apply Associativity to regroup the conjunction.

---

### Problem 2 (Difficulty: Easy)
**Premises:**
- (A ∨ B) ∨ C

**Conclusion:** A ∨ (B ∨ C)

**Brief Solution:** Apply Associativity to regroup the disjunction.

---

### Problem 3 (Difficulty: Easy)
**Premises:**
- R ∧ (S ∧ T)

**Conclusion:** (R ∧ S) ∧ T

**Brief Solution:** Apply reverse Associativity.

---

### Problem 4 (Difficulty: Medium)
**Premises:**
- ((P ∧ Q) ∧ R) ∧ S

**Conclusion:** P ∧ (Q ∧ (R ∧ S))

**Brief Solution:** Apply Associativity multiple times to regroup.

---

### Problem 5 (Difficulty: Medium)
**Premises:**
- (P ∨ Q) ∨ (R ∨ S)

**Conclusion:** P ∨ (Q ∨ (R ∨ S))

**Brief Solution:** Apply Associativity to flatten the disjunction.

---

### Problem 6 (Difficulty: Medium)
**Premises:**
- P ∧ (Q ∧ R)

**Conclusion:** (P ∧ Q) ∧ R

**Brief Solution:** Apply reverse Associativity to change grouping.

---

### Problem 7 (Difficulty: Hard)
**Premises:**
- (P ∧ Q) ∧ R

**Conclusion:** Q ∧ R

**Brief Solution:** Apply Associativity to get "P ∧ (Q ∧ R)", then Simplification.

---

### Problem 8 (Difficulty: Hard)
**Premises:**
- ((P ∧ Q) ∧ R) ∧ S

**Conclusion:** R ∧ S

**Brief Solution:** Apply Associativity and Simplification to extract inner terms.

---

### Problem 9 (Difficulty: Hard)
**Premises:**
- P ∨ ((Q ∨ R) ∨ S)

**Conclusion:** (P ∨ Q) ∨ (R ∨ S)

**Brief Solution:** Apply Associativity multiple times to rebalance.

---

### Problem 10 (Difficulty: Very Hard)
**Premises:**
- (((P ∧ Q) ∧ R) ∧ S) ∧ T

**Conclusion:** P ∧ (Q ∧ (R ∧ (S ∧ T)))

**Brief Solution:** Apply Associativity repeatedly to fully right-associate.