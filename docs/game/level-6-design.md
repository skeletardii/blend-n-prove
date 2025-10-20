# Level 6 Design: Natural Language to Logic Translation

## Overview

Level 6 introduces the ultimate challenge in the Boolean Logic Bartender game: **Natural Language to Logic Translation**. Unlike levels 1-5 where logical symbols are explicitly shown, Level 6 presents problems entirely in natural language. Players must interpret sentences, translate them into logical statements, and then solve the proof - all while the logical symbols remain hidden.

## Design Philosophy

### Educational Objectives

1. **Critical Reading**: Players develop the ability to parse natural language for logical structure
2. **Abstraction Skills**: Learn to identify logical patterns in everyday statements
3. **Formal Translation**: Practice converting informal reasoning to formal logic
4. **Meta-Cognition**: Understand that logical reasoning underlies natural communication

### Difficulty Progression

Level 6 is designed as the highest difficulty tier:

- **Levels 1-2**: Learn basic logical operations (1-2 operations)
- **Levels 3-4**: Apply multiple operations in sequence (3 operations)
- **Level 5**: Complex proofs with multiple premises (4+ operations)
- **Level 6**: All of the above PLUS natural language interpretation (5+ operations)

## Data Structure

### JSON Format

Level 6 problems use an extended data format that includes both natural language and hidden logical representations:

```json
{
  "natural_language_premises": [
    "If it rains, then the ground is wet.",
    "It is raining."
  ],
  "hidden_logical_premises": ["P → Q", "P"],
  "natural_language_conclusion": "The ground is wet.",
  "hidden_logical_conclusion": "Q",
  "expected_operations": 1,
  "description": "Basic Modus Ponens with natural language",
  "solution": "Translation and proof explanation",
  "interpretation_hints": ["Helpful tips for translation"]
}
```

### Field Descriptions

- **natural_language_premises**: Array of English sentences shown to player
- **hidden_logical_premises**: Logical statements NOT shown to player (used for validation)
- **natural_language_conclusion**: English sentence for target goal
- **hidden_logical_conclusion**: Logical conclusion (hidden, used for validation)
- **expected_operations**: Number of logical operations needed to solve
- **description**: Short description of problem type
- **solution**: Complete explanation of translation + proof steps
- **interpretation_hints**: Optional array of hints to help players translate

## Translation Patterns

### Common Natural Language Patterns

| Natural Language | Logical Symbol | Notes |
|-----------------|----------------|-------|
| "If P, then Q" | P → Q | Standard conditional |
| "P only if Q" | P → Q | Conditional (reversed phrasing) |
| "P if Q" | Q → P | Conditional (antecedent second) |
| "Either P or Q" | P ∨ Q | Inclusive OR (disjunction) |
| "P and Q" | P ∧ Q | Conjunction |
| "Not P" | ¬P | Negation |
| "It is not the case that P" | ¬P | Negation (formal) |
| "P if and only if Q" | P ↔ Q | Biconditional |
| "P unless Q" | ¬Q → P | Unless pattern |
| "Not both P and Q" | ¬(P ∧ Q) | Negated conjunction |
| "Neither P nor Q" | ¬P ∧ ¬Q | Double negation |

### Sentence Structure Analysis

#### Simple Conditionals
```
Natural: "If it rains, then the ground is wet."
Analysis:
  - "If" clause = antecedent (P)
  - "then" clause = consequent (Q)
  - Pattern: P → Q
```

#### Compound Statements
```
Natural: "If the power is on, then both the lights work and the computer works."
Analysis:
  - Antecedent: "power is on" (P)
  - Consequent: "lights work AND computer works" (Q ∧ R)
  - Pattern: P → (Q ∧ R)
```

#### Negations
```
Natural: "It is not the case that both the car is red and the car is new."
Analysis:
  - Core statement: "car is red AND car is new" (P ∧ Q)
  - Negation wrapper: "It is not the case that..."
  - Pattern: ¬(P ∧ Q)
```

## Problem Design Guidelines

### Difficulty Tiers

#### Easy (Operations: 1-2)
- Single conditional statements
- Clear "if...then" structure
- Minimal negations
- Examples: Problems #1-4 in level-6.json

#### Medium (Operations: 2-3)
- Chain of two conditionals
- One level of negation
- Compound consequents
- Examples: Problems #5-7 in level-6.json

#### Hard (Operations: 3-4)
- Biconditionals ("if and only if")
- Multiple negations
- Nested logical structures
- Examples: Problems #8-9 in level-6.json

#### Very Hard (Operations: 5+)
- Proof by contradiction
- Multiple disjunctions and conditionals
- Complex logical dependencies
- Example: Problem #10 in level-6.json

### Content Themes

To make problems engaging and relatable, use varied contexts:

1. **Weather & Nature**: Rain, sun, wind (Problem #1, #9)
2. **Technology**: Computers, alarms, lights (Problem #2, #7, #8)
3. **Home & Objects**: Doors, windows, cars (Problem #3, #6)
4. **People & Activities**: Students, work, beach (Problem #4, #5, #10)
5. **Abstract Logic**: Pure logical exercises when appropriate

### Avoiding Ambiguity

Natural language can be ambiguous. Follow these principles:

1. **Use Standard Phrasings**: Stick to well-known logical patterns
2. **Clear Atomic Propositions**: Make each basic statement unambiguous
3. **Explicit Connectives**: Use "and", "or", "if...then" clearly
4. **Avoid Informal Logic**: Don't use conversational implications
5. **Test Readability**: Ensure sentences have one clear interpretation

## Game Mechanics

### Phase 1: Translation & Input

1. Player sees natural language premises (e.g., "If it rains, then the ground is wet")
2. Player uses virtual keyboard to input logical translation (e.g., "P → Q")
3. System validates against hidden_logical_premises
4. Feedback:
   - ✓ "Correct translation!" (if matches)
   - ✗ "That doesn't match the sentence meaning" (if incorrect)

### Phase 2: Logical Proof

1. Player sees natural language conclusion goal
2. Available premises show player's translated statements
3. Player applies logical operations as in other levels
4. Target validated against hidden_logical_conclusion

### Hints System (Optional Enhancement)

Players can request hints that reveal:
- What logical connectives to look for
- Which parts of the sentence map to which variables
- Example translations of similar sentences

## Implementation Details

### File Locations

- **Data**: `data/classic/level-6.json`
- **Documentation**: `docs/game/level-6-design.md`
- **Code Changes**:
  - `src/game/autoloads/GameManager.gd`: Load level 6
  - `src/ui/GameplayScene.gd`: Display natural language
  - `src/ui/Phase1UI.gd`: Validate natural language translations
  - `src/ui/Phase2UI.gd`: Show natural language goals

### Variable Naming Convention

For consistency across problems:
- Use P, Q, R, S, T for basic propositions
- Assign in order of appearance in natural language
- Document mapping in solution field

Example:
```
Sentence: "If it rains, then the ground is wet."
Mapping:
  P = "it rains"
  Q = "the ground is wet"
Translation: P → Q
```

## Testing & Validation

### Test Cases

For each problem, verify:

1. **Translation Uniqueness**: Only one logical form matches the natural language
2. **Proof Solvability**: Problem can be solved with available operations
3. **Hint Accuracy**: Hints guide toward correct translation without giving it away
4. **Difficulty Calibration**: Expected_operations matches actual solution complexity

### Player Testing Checklist

- [ ] Can players understand the natural language?
- [ ] Are translation patterns learnable?
- [ ] Is the difficulty appropriate for level 6?
- [ ] Do solutions feel rewarding?
- [ ] Are error messages helpful?

## Educational Value

### Skills Developed

1. **Logical Reading**: Extract logical structure from prose
2. **Pattern Recognition**: Identify "if...then", "and", "or" patterns
3. **Formalization**: Convert informal to formal logic
4. **Precision**: Understand importance of exact logical meaning
5. **Bi-directional Translation**: Read and write logical statements

### Real-World Applications

- **Programming**: Conditional logic in code
- **Law**: Understanding legal conditionals
- **Mathematics**: Reading formal theorems
- **Critical Thinking**: Analyzing arguments
- **Communication**: Precise expression of ideas

## Future Enhancements

### Potential Additions

1. **Variable Naming**: Let players assign their own variable names
2. **Multiple Valid Translations**: Accept equivalent logical forms
3. **Translation Tutorial**: Dedicated mode teaching translation patterns
4. **Progressive Hints**: Hint system with escalating detail
5. **Custom Problems**: Player-created natural language puzzles

### Advanced Features

- **Natural Language Generation**: Procedurally generate problems
- **Complexity Metrics**: Analyze sentence complexity automatically
- **Learning Analytics**: Track which translation patterns players struggle with
- **Adaptive Difficulty**: Adjust based on player performance

## Conclusion

Level 6 represents the culmination of the Boolean Logic Bartender learning experience. By combining natural language interpretation with formal logical reasoning, it bridges the gap between everyday communication and rigorous logical thinking. This level transforms players from logic learners into logic translators, equipped to recognize and formalize logical patterns in the world around them.

---

## Appendix A: Complete Problem Set

The level-6.json file contains 10 carefully designed problems:

1. **Modus Ponens** (1 op): Simple conditional
2. **Modus Tollens** (1 op): Negated consequent
3. **Disjunctive Syllogism** (1 op): Either/or reasoning
4. **Conjunction** (1 op): Combining facts
5. **Chain Reasoning** (2 ops): Multiple conditionals
6. **De Morgan's Law** (2 ops): Negated conjunction
7. **Complex Consequent** (2 ops): Compound results
8. **Biconditional** (2 ops): If and only if
9. **Long Chain** (3 ops): Extended implications
10. **Contradiction** (5 ops): Proof by impossibility

## Appendix B: Sample Gameplay Flow

```
[Level 6 - Problem #1]

CUSTOMER: "Alice wants a drink!"

ORDER:
Premise 1: "If it rains, then the ground is wet."
Premise 2: "It is raining."
Target: "The ground is wet."

--- Phase 1: Translation ---

Player sees: "If it rains, then the ground is wet."
Player inputs: P → Q
System checks against: "P → Q" ✓ Correct!

Player sees: "It is raining."
Player inputs: P
System checks against: "P" ✓ Correct!

All premises validated → Advance to Phase 2

--- Phase 2: Logical Proof ---

Available: P → Q, P
Target: Q
Player selects: Modus Ponens
Result: Q ✓ Target reached!

Order complete! 🎉
```

## Appendix C: Translation Reference Card

```
╔════════════════════════════════════════════════════╗
║        NATURAL LANGUAGE → LOGIC PATTERNS           ║
╠════════════════════════════════════════════════════╣
║ "If P, then Q"             →  P → Q                ║
║ "P and Q"                  →  P ∧ Q                ║
║ "P or Q"                   →  P ∨ Q                ║
║ "Not P"                    →  ¬P                   ║
║ "P if and only if Q"       →  P ↔ Q                ║
║ "Not both P and Q"         →  ¬(P ∧ Q)             ║
║ "Neither P nor Q"          →  ¬P ∧ ¬Q              ║
║ "If not P, then Q"         →  ¬P → Q               ║
║ "P unless Q"               →  ¬Q → P               ║
║ "Either P or Q (not both)" →  P ⊕ Q                ║
╚════════════════════════════════════════════════════╝
```
