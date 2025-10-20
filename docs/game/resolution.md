# Resolution

## Description
Resolution is a powerful inference rule that combines two disjunctions containing complementary literals. If we have "P or Q" and "not P or R", we can conclude "Q or R".

## Rule Pattern
P ∨ Q, ¬P ∨ R ⊢ Q ∨ R

## Problems

### Problem 1 (Difficulty: Easy)
**Premises:**
- P ∨ Q
- ¬P ∨ R

**Conclusion:** Q ∨ R

**Brief Solution:** Apply Resolution to eliminate P and ¬P.

---

### Problem 2 (Difficulty: Easy)
**Premises:**
- A ∨ B
- ¬A ∨ C

**Conclusion:** B ∨ C

**Brief Solution:** Resolve on A to get "B ∨ C".

---

### Problem 3 (Difficulty: Easy)
**Premises:**
- R ∨ S
- ¬R ∨ T

**Conclusion:** S ∨ T

**Brief Solution:** Direct application of Resolution.

---

### Problem 4 (Difficulty: Medium)
**Premises:**
- P ∨ (Q ∧ R)
- ¬P ∨ S

**Conclusion:** (Q ∧ R) ∨ S

**Brief Solution:** Apply Resolution where one disjunct is complex.

---

### Problem 5 (Difficulty: Medium)
**Premises:**
- (P → Q) ∨ R
- ¬(P → Q) ∨ S

**Conclusion:** R ∨ S

**Brief Solution:** Resolve on the implication.

---

### Problem 6 (Difficulty: Medium)
**Premises:**
- P ∨ Q
- ¬P ∨ Q

**Conclusion:** Q

**Brief Solution:** Apply Resolution to get "Q ∨ Q", then Idempotent to simplify to Q.

---

### Problem 7 (Difficulty: Hard)
**Premises:**
- P ∨ Q
- ¬P ∨ R
- ¬Q ∨ S

**Conclusion:** R ∨ S

**Brief Solution:** Apply Resolution twice: first to get "Q ∨ R", then again with the third premise.

---

### Problem 8 (Difficulty: Hard)
**Premises:**
- (P ∧ Q) ∨ R
- ¬(P ∧ Q) ∨ S

**Conclusion:** R ∨ S

**Brief Solution:** Resolve on the conjunction "P ∧ Q".

---

### Problem 9 (Difficulty: Hard)
**Premises:**
- P ∨ Q
- ¬P ∨ R
- ¬R ∨ S

**Conclusion:** Q ∨ S

**Brief Solution:** Apply Resolution twice to chain through the literals.

---

### Problem 10 (Difficulty: Very Hard)
**Premises:**
- P ∨ Q
- ¬P ∨ R
- ¬Q ∨ S
- ¬R ∨ T

**Conclusion:** S ∨ T

**Brief Solution:** Apply Resolution multiple times to build the conclusion.