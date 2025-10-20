# Modus Ponens

## Description
Modus Ponens is one of the most fundamental inference rules in logic. It states: if we have a conditional statement (if P then Q) and we know P is true, we can conclude Q is true.

## Rule Pattern
P → Q, P ⊢ Q

## Problems

### Problem 1 (Difficulty: Easy)
**Premises:**
- P → Q
- P

**Conclusion:** Q

**Brief Solution:** Apply Modus Ponens directly: from "P implies Q" and "P", we conclude "Q".

---

### Problem 2 (Difficulty: Easy)
**Premises:**
- R → S
- R

**Conclusion:** S

**Brief Solution:** Apply Modus Ponens: from "R implies S" and "R", we conclude "S".

---

### Problem 3 (Difficulty: Easy)
**Premises:**
- A → B
- A

**Conclusion:** B

**Brief Solution:** Direct application of Modus Ponens with variables A and B.

---

### Problem 4 (Difficulty: Medium)
**Premises:**
- (P ∧ Q) → R
- P ∧ Q

**Conclusion:** R

**Brief Solution:** Apply Modus Ponens where the antecedent is a conjunction "P ∧ Q".

---

### Problem 5 (Difficulty: Medium)
**Premises:**
- P → (Q ∧ R)
- P

**Conclusion:** Q ∧ R

**Brief Solution:** Apply Modus Ponens: the consequent is a conjunction, so we get "Q ∧ R".

---

### Problem 6 (Difficulty: Medium)
**Premises:**
- (P ∨ Q) → R
- P ∨ Q

**Conclusion:** R

**Brief Solution:** Apply Modus Ponens where the antecedent is a disjunction.

---

### Problem 7 (Difficulty: Hard)
**Premises:**
- P → (Q → R)
- P
- Q

**Conclusion:** R

**Brief Solution:** First apply Modus Ponens to get "Q → R", then apply it again with "Q" to get "R".

---

### Problem 8 (Difficulty: Hard)
**Premises:**
- (P ∧ Q) → (R ∨ S)
- P
- Q

**Conclusion:** R ∨ S

**Brief Solution:** Use Conjunction to combine P and Q into "P ∧ Q", then apply Modus Ponens.

---

### Problem 9 (Difficulty: Hard)
**Premises:**
- P → Q
- Q → R
- P

**Conclusion:** R

**Brief Solution:** Apply Hypothetical Syllogism to get "P → R", then use Modus Ponens with P.

---

### Problem 10 (Difficulty: Very Hard)
**Premises:**
- (P → Q) → R
- P
- ¬¬P → Q

**Conclusion:** R

**Brief Solution:** Apply Double Negation on P to get "¬¬P", then Modus Ponens to get Q, construct "P → Q", finally Modus Ponens to get R.