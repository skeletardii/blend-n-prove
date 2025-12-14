# Boolean Logic System

At the heart of Fusion Rush lies the `BooleanLogicEngine`, a fully custom-built mathematical engine responsible for the parsing, validation, representation, and transformation of symbolic logic. Unlike simple string-matching systems that might be found in simpler games, this engine builds a semantic understanding of logic, allowing for complex validation, truth-preservation, and equivalence checking. It is designed to be mathematically rigorous, ensuring that the game teaches *correct* formal logic.

## 1. Expression Parsing & Normalization
The `BooleanExpression` class (`src/game/expressions/BooleanExpression.gd`) is the fundamental data unit of the game. It handles the conversion of raw user input into a standardized, machine-readable format.

### The Normalization Pipeline
Before any logic can be applied, input strings must be normalized. User input can be messy, and different academic traditions use different symbols (e.g., `&` vs `^` vs `∧`). The `parse_expression()` function implements a rigorous replacement pipeline designed to handle various input formats (ASCII vs. Unicode) and prevent parsing ambiguity.

**Critical Replacement Order:**
The engine performs replacements in a specific order, prioritizing longer tokens to avoid partial matches (e.g., replacing `<->` before `->` ensures that a biconditional isn't mangled into an implication).
1.  **Biconditional**: `<->`, `<=>`  ➔  `↔`
2.  **Implication**: `->`, `=>`  ➔  `→`
3.  **Conjunction**: `&&`, `&`  ➔  `∧`
4.  **Disjunction**: `||`, `|`  ➔  `∨`
5.  **Exclusive OR**: `XOR`, `xor`, `^`  ➔  `⊕`
6.  **Negation**: `~`, `!`  ➔  `¬`

### Intelligent Parenthesis Stripping
The parser includes a sophisticated loop to strip redundant outer parentheses while preserving structural integrity. This improves readability for the user.
*   **Algorithm**: It counts parenthesis depth character-by-character. If the depth never hits zero until the final character, the outer pair is deemed redundant and removed.
*   **Example 1**: `((P ∧ Q))` becomes `P ∧ Q` (Outer parens cover the whole string).
*   **Example 2**: `(P) ∧ (Q)` remains unchanged because the depth returns to zero between the two groups. Removing the outer parens here would result in `P) ∧ (Q`, which is invalid.

### Tokenization & Validation
The `tokenize_expression()` function breaks the normalized string into atomic units (`P`, `∧`, `Q`).
*   **Lexical Analysis**: It supports single-letter variables (`P` through `Z`) and boolean constants (`TRUE`, `FALSE`).
*   **Syntax Checking**: The `validate_expression()` method performs checks for:
    *   **Balanced Parentheses**: Ensures every `(` has a matching `)`.
    *   **Empty Groups**: Rejects `()` as invalid.
    *   **Adjacent Operators**: Rejects syntactically invalid constructs like `P ∧ ∨ Q`.
    *   **Boundary Checks**: Ensures expressions don't start or end with binary operators (e.g., `∧ P` or `P →` are rejected).

### Valid Tokens Table
| Token | Type | Meaning |
| :--- | :--- | :--- |
| `P` - `Z` | Variable | A logical proposition |
| `TRUE`, `FALSE` | Constant | Boolean literals |
| `∧` | Operator | AND (Conjunction) |
| `∨` | Operator | OR (Disjunction) |
| `¬` | Operator | NOT (Negation) |
| `→` | Operator | IMPLIES (Implication) |
| `↔` | Operator | IFF (Biconditional) |
| `⊕` | Operator | XOR (Exclusive Or) |
| `(` `)` | Grouping | Precedence control |

## 2. The Inference Engine
The core of the gameplay logic is the `BooleanLogicEngineImpl.gd` script. It implements 13 formal rules of inference as stateless functions. Each function accepts an array of `BooleanExpression` premises and returns a resulting `BooleanExpression` (or an invalid one if the rule cannot apply).

### Double-Premise Rules (Requiring 2 Inputs)
These rules combine two facts to derive a third.
1.  **Modus Ponens (MP)**: Given `P → Q` and `P`, deduces `Q`.
    *   *Implementation*: It parses the implication to isolate antecedent `P` and consequent `Q`, then checks if the second premise semantically equals `P`.
2.  **Modus Tollens (MT)**: Given `P → Q` and `¬Q`, deduces `¬P`.
    *   *Implementation*: Checks if the second premise is the logical negation of the consequent `Q`.
3.  **Hypothetical Syllogism (HS)**: Given `P → Q` and `Q → R`, deduces `P → R`.
    *   *Implementation*: Verifies that the consequent of the first implies the antecedent of the second.
4.  **Disjunctive Syllogism (DS)**: Given `P ∨ Q` and `¬P`, deduces `Q`.
    *   *Implementation*: Handles both orderings (`¬P` implies `Q`; `¬Q` implies `P`).
5.  **Constructive Dilemma (CD)**: Given `(P → Q) ∧ (R → S)` and `P ∨ R`, deduces `Q ∨ S`.
    *   *Implementation*: A complex rule that deconstructs a conjunction of two implications.
6.  **Destructive Dilemma (DD)**: Given `(P → Q) ∧ (R → S)` and `¬Q ∨ ¬S`, deduces `¬P ∨ ¬R`.
7.  **Resolution**: Given `P ∨ Q` and `¬P ∨ R`, deduces `Q ∨ R`.
8.  **Equivalence**: Given `P ↔ Q` and `P`, deduces `Q` (and vice-versa).

### Single-Premise Rules (Requiring 1 Input)
These rules simplify or rearrange a single fact.
1.  **Simplification**: Given `P ∧ Q`, deduces `P` (or `Q` in specific contexts).
2.  **Conjunction**: Given `P` and `Q`, creates `P ∧ Q` (Note: Technically takes 2 inputs but is categorized simply in the UI).
3.  **Addition**: Given `P`, allows the user to construct `P ∨ [ANYTHING]`.
    *   *Implementation*: This requires a specific UI dialog to ask the user "What do you want to add?"
4.  **Double Negation**: Given `¬¬P`, deduces `P`.

### Equivalence Transformations (Laws)
These rules transform an expression into a logically equivalent form, often necessary to make the structure match another rule's requirements.
*   **De Morgan's Laws**: Handles the distribution of negation across conjunctions/disjunctions (`¬(P ∧ Q) ⇔ ¬P ∨ ¬Q`).
*   **Commutativity**: Swaps operands (`P ∧ Q ⇔ Q ∧ P`).
*   **Associativity**: Re-groups parentheses (`(P ∧ Q) ∧ R ⇔ P ∧ (Q ∧ R)`).
*   **Distributivity**: Expands/Factors (`P ∧ (Q ∨ R) ⇔ (P ∧ Q) ∨ (P ∧ R)`).
*   **Idempotence**: Simplifies redundancy (`P ∧ P ⇔ P`).
*   **Absorption**: `P ∧ (P ∨ Q) ⇔ P`.
*   **Implication Conversion**: Converts implications to disjunctions (`P → Q ⇔ ¬P ∨ Q`).
*   **Biconditional Expansion**: Splits biconditionals (`P ↔ Q ⇔ (P → Q) ∧ (Q → P)`).

## 3. Semantic Verification System
To support robust gameplay, the engine cannot rely solely on string matching (syntax). It must understand *meaning* (semantics). For example, `P ∨ Q` is semantically identical to `Q ∨ P`, even if the strings differ.

To solve this, the engine implements a **Truth Table Generator**. This brute-force method ensures mathematical certainty.

*   **Function**: `are_semantically_equivalent(expr1, expr2)`
*   **Algorithm**:
    1.  **Variable Extraction**: Scans both expressions to build a set of all unique variables (e.g., `{P, Q, R}`).
    2.  **Permutation Generation**: Calculates `2^N` possible truth assignments (where N is the number of variables).
    3.  **Recursive Evaluation**: For every assignment (row), it calls `_evaluate_boolean_string()` on both expressions.
        *   This function recursively descends the expression tree, replacing variables with `TRUE`/`FALSE` and evaluating the boolean result using basic Godot logical operators (`and`, `or`, `not`).
    4.  **Verification**: If the boolean results match for *every single row* of the truth table, the expressions are mathematically equivalent.
*   **Performance Constraints**: Generating truth tables is an $O(2^N)$ operation. To ensure the game runs at 60 FPS, this feature is strictly limited to expressions with **8 or fewer variables** (256 rows), which is sufficient for all gameplay scenarios.

## 4. Truth Table Reference
These tables are used by the engine for verification.

### Conjunction (`∧`)
| P | Q | P ∧ Q |
|:-:|:-:|:-----:|
| T | T |   T   |
| T | F |   F   |
| F | T |   F   |
| F | F |   F   |

### Disjunction (`∨`)
| P | Q | P ∨ Q |
|:-:|:-:|:-----:|
| T | T |   T   |
| T | F |   T   |
| F | T |   T   |
| F | F |   F   |

### Implication (`→`)
| P | Q | P → Q |
|:-:|:-:|:-----:|
| T | T |   T   |
| T | F |   F   |
| F | T |   T   |
| F | F |   T   |

### Biconditional (`↔`)
| P | Q | P ↔ Q |
|:-:|:-:|:-----:|
| T | T |   T   |
| T | F |   F   |
| F | T |   F   |
| F | F |   T   |

### Exclusive OR (`⊕`)
| P | Q | P ⊕ Q |
|:-:|:-:|:-----:|
| T | T |   F   |
| T | F |   T   |
| F | T |   T   |
| F | F |   F   |

## 5. Integrated Test Suite
The logic engine includes a comprehensive, embedded test suite (`test_logic_engine()`) that runs within the engine environment. This ensures that any changes to the parsing logic do not break existing rules.
*   **Coverage**: The suite includes 40+ assertion checks covering:
    *   Basic parsing and tokenization.
    *   Every single inference rule (MP, MT, HS, etc.).
    *   Complex nested expressions.
    *   Edge cases like empty strings, unbalanced parentheses, and invalid characters.
    *   Operator precedence verification (e.g., ensuring `∧` binds tighter than `→`).
*   **Runtime Execution**: Developers can trigger this suite via the debug console or the `temp_test_runner.gd` scene, providing instant feedback ("✓" or "✗") on the system's integrity.

## Algorithm Deep Dive: Top-Level Operator Detection
One of the most complex parts of the engine is the `_get_top_level_operator()` function. It determines the "Split Point" of an expression by adhering to operator precedence rules.

**Precedence Order (Lowest to Highest):**
1.  Biconditional `↔`
2.  Implication `→`
3.  XOR `⊕`
4.  Disjunction `∨`
5.  Conjunction `∧`

**The Algorithm:**
1.  Iterate through the precedence list from Lowest to Highest.
2.  For each operator, scan the string.
3.  Track `paren_depth` (increment on `(`, decrement on `)`).
4.  If the operator is found AND `paren_depth == 0`, that is the main operator.
5.  If found, split the string into `left` and `right` operands.

This ensures that `P ∧ Q → R` is correctly parsed as `(P ∧ Q) → R` (Implication is main) rather than `P ∧ (Q → R)` (Conjunction is main).

## Regex Implementation Details
The engine heavily uses regex for token validation and variable replacement.
*   **Variable Extraction**: `RegEx.new().compile("\\b" + var_name + "\\b")`. The `` word boundary is critical. Without it, replacing `P` in the expression `PARENT` would result in `TRUEARENT`.
*   **Parenthesis Removal**: The algorithm manually iterates characters rather than using Regex, as recursion is difficult to handle with standard Regex patterns.
*   **Input Sanitation**: Before parsing, `strip_edges()` is called to remove whitespace, but internal whitespace is preserved for tokenization clarity.

## Historical Context
The system is built upon the foundations of Classical Propositional Logic.
*   **Modus Ponens**: "Mode that affirms". Dates back to Stoic logic.
*   **De Morgan**: Named after Augustus De Morgan (19th century).
*   **Boolean Algebra**: Developed by George Boole, forming the basis of all modern computing and the logic engine used in this game.
The engine strictly adheres to these classical definitions, avoiding deviations like fuzzy logic or multi-valued logic to ensure educational accuracy.

## Appendix A: Common Logical Fallacies (Rejected by Engine)
The engine explicitly rejects common student errors:
1.  **Affirming the Consequent**: `P -> Q`, `Q` => `P`. (Invalid)
2.  **Denying the Antecedent**: `P -> Q`, `~P` => `~Q`. (Invalid)
3.  **Distribution Error**: `~(P ^ Q)` => `~P ^ ~Q`. (Invalid, should be `v`).
4.  **Implication Commutativity**: `P -> Q` => `Q -> P`. (Invalid).

## Appendix B: ASCII Operator Precedence Diagram
Visualizing how the parser splits the string `P ∧ Q ∨ R → S`.

```text
Step 1: Scan for ↔ (None)
Step 2: Scan for → (Found at index 9)
        SPLIT!
       /      \
  (P ∧ Q ∨ R)   (S)
      |          |
      V          V
   Antecedent   Consequent

Step 3: Scan Antecedent for ∨ (Found at index 5)
        SPLIT!
       /      \
   (P ∧ Q)    (R)
      |
      V
Step 4: Scan Left for ∧
        SPLIT!
       /     \
     (P)     (Q)
```

## Appendix C: Performance Metrics
Hypothetical benchmarks for the Truth Table Generator on an average mobile CPU (Snapdragon 855 equivalent).

| Variables | Rows | Time (ms) | Status |
| :--- | :--- | :--- | :--- |
| 2 | 4 | 0.05ms | Instant |
| 4 | 16 | 0.2ms | Instant |
| 6 | 64 | 1.5ms | Fast |
| 8 | 256 | 12.0ms | 1 Frame |
| 10 | 1024 | 55.0ms | **LAG** |
| 12 | 4096 | 300.0ms | **FREEZE** |

*Note: This is why the engine enforces a hard cap of 8 variables.*

## Appendix D: Development Changelog
*   **v0.5**: Initial parsing implementation. Only supported `MP` and `MT`.
*   **v0.6**: Added `Truth Table` verification to catch edge cases.
*   **v0.8**: Added support for `XOR` and `Biconditional`.
*   **v1.0**: Optimized recursive descent parser for mobile performance.

## Appendix E: Full Operator Glossary
*   **Negation (`¬`)**: Reverses truth value. `¬T = F`.
*   **Conjunction (`∧`)**: True only if both inputs are true.
*   **Disjunction (`∨`)**: True if at least one input is true.
*   **Exclusive OR (`⊕`)**: True if inputs differ (one T, one F).
*   **Implication (`→`)**: False only if Antecedent is True and Consequent is False.
*   **Biconditional (`↔`)**: True only if both inputs have the same truth value.