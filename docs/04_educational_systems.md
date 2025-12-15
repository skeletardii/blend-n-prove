# Educational Systems

Fusion Rush is designed not just as a game, but as a serious educational tool suitable for introducing students to formal logic and computer science concepts. To achieve its learning objectives, it employs a sophisticated "Dual-Layer" educational architecture. This approach combines a structured, deterministic curriculum (for introducing concepts) with an open-ended, AI-driven sandbox (for mastery and conceptual exploration).

## 1. First Time Tutorial (The Onboarding System)
**Manager Script**: `src/game/FirstTimeTutorialManager.gd`
**Overlay Script**: `src/ui/TutorialOverlay.gd`

The entry point for every new player is the "First Time Tutorial". This is a strictly scripted, linear experience designed to familiarize the player with the unique UI paradigms of the game (the "Bartender" metaphor, the Virtual Keyboard, and the Rule Panel) without the pressure of time limits or scores.

### Interactive Overlay Architecture
The tutorial does not rely on simple text popups, which users often ignore. Instead, it uses a dedicated `TutorialOverlay` scene that actively manipulates the game state to focus attention.
*   **Screen Dimming**: A global `ColorRect` overlay dims the entire game view (`modulate.a = 0.5`), reducing visual noise.
*   **Dynamic Highlighting**: The system calculates the global screen coordinates of specific UI nodes (e.g., the "Submit" button or the "Modus Ponens" rule button) and effectively cuts a "hole" in the dimming layer or draws a bright border around them. This unambiguous visual cue guides the player exactly where to click.
*   **Input Blocking**: To prevent frustration, the overlay blocks input to all non-essential UI elements. If the tutorial asks the player to click "P", clicking "Q" or "submit" will be ignored.

### The Curriculum State Machine
The tutorial progression is managed by a strict `TutorialStep` enum state machine, ensuring the player cannot get stuck or skip ahead:
1.  `WELCOME_AND_ORDER`: Introduces the customer and the goal (serving a drink = solving a puzzle).
2.  `KEYBOARD_BASICS`: Highlights the input variables (`P`, `Q`) on the virtual keyboard and explains their relation to the sentence.
3.  `TYPE_FIRST_PREMISE`: Waits for the `text_changed` signal to ensure the player is typing.
4.  `SUBMIT_PREMISE`: Waits for the `premise_validated` signal to confirm successful translation of `P → Q`.
5.  `PHASE2_INTRO`: Handles the transition from the Translation Phase to the Deduction Phase, explaining the UI shift.
6.  `RULE_BUTTONS_OVERVIEW`: Explains the distinction between "Single" and "Double" operation tabs.
7.  `APPLY_FIRST_RULE`: Forces the player to execute a specific logical deduction (e.g., Modus Ponens) by highlighting the rule button, then the premises.
8.  `REACH_TARGET`: Concludes only when the `target_reached` signal is emitted, ensuring the player has actually solved the puzzle.

### Example Dialogue Script
The tutorial script is carefully written to be concise yet informative:
> **Step 1:** "Welcome! You'll solve logic puzzles by translating statements into logical form and proving conclusions. Your goal is to prove: **The cat meows (Q)**."
> **Step 3:** "Try it now! Translate 'If the cat is hungry (P), then it meows (Q)' into logical form. Click: **P → Q**"
> **Step 6:** "These buttons apply logical inference rules. There are two pages: **Double Operations** (need 2 premises) and **Single Operations** (need 1 premise)."

## 2. AI Tutor Mode (The Logic Sandbox)
**Scene**: `src/ui/AITutorScene.tscn`
**Script**: `src/ui/AITutorScene.gd`

For players who want to deepen their understanding or practice specific concepts without the time pressure of the arcade mode, the **AI Tutor Mode** offers an advanced, free-form learning environment. This mode leverages Large Language Models (LLMs) via the OpenRouter API to act as a personalized logic coach.

### Technical Architecture
The AI Tutor combines two distinct interface paradigms into a single cohesive experience:

#### A. The Chat Interface (Tutor Persona)
This is a standard chat window where the user interacts with the AI.
*   **Service Integration**: It uses the `OpenRouterService` to send stateless JSON requests.
*   **System Prompt (`BASE_SYSTEM_CONTEXT`)**: The AI is initialized with a constant prompt. This prompt strictly defines the rules of the game's logic system, listing all 13 valid inference rules and the allowed variable set (`P, Q, R, S, T`). This ensures the AI speaks the "language" of the game and doesn't hallucinate invalid rules.
*   **Capabilities**:
    *   **Topic Generation**: The user can ask for specific practice problems (e.g., "Give me a hard Constructive Dilemma problem").
    *   **Concept Explanation**: The user can ask theoretical questions (e.g., "Why is P -> Q equivalent to ~P v Q?").
    *   **Feedback**: The AI provides natural language explanations of logic errors.

#### B. The Step-by-Step Solver (Constructed Response)
Unlike the main game's click-based interface, the AI Tutor includes a "Solver Panel" that requires **Constructed Response**. This is a more rigorous educational method where students must explicitly state their reasoning.
*   **Manual Entry**: Players must type out each step of their derivation (`P`, `¬Q`).
*   **Explicit Justification**: For every step, the player must select the specific rule used (e.g., "Modus Ponens") and cite the specific source lines (e.g., "Lines 1 and 2").
*   **Data Structure**: Steps are stored as `SolverStepRow` nodes, creating a structured data object that can be serialized and sent to the AI for validation.

### The "Tutor Loop"
The interaction flow is designed to mimic a real tutoring session:
1.  **Request (`AWAITING_TOPIC`)**: The user asks for a topic. The system sends a `generate_problem` request.
2.  **Generation (`GENERATING_PROBLEM`)**: The AI generates a problem definition in JSON format:
    ```json
    {
      "type": "problem",
      "topic": "Modus Tollens",
      "premises": ["P → Q", "¬Q"],
      "target": "¬P",
      "difficulty": "medium",
      "hint": "Look for a negation."
    }
    ```
3.  **Display**: The game parses this JSON and renders the problem in the Solver Panel.
4.  **Solution (`AWAITING_SOLUTION`)**: The player works through the problem, adding steps row-by-row.
5.  **Submission**: The player clicks "Submit for Feedback".
6.  **Validation (`PROVIDING_FEEDBACK`)**: The client serializes the player's full solution history (premises + steps + justification) and sends a `validate_solution` request.
7.  **Analysis**: The AI analyzes the logic step-by-step. It identifies the *exact* step where the logic flawed (if any) and returns a JSON response containing specific feedback, which is then displayed in the chat.

## 3. Standard Tutorial Library
**Data Source**: `data/tutorial/*.json`

Complementing the dynamic AI Tutor is a library of "Classic" static tutorials.
*   **Manager**: `TutorialManager` (Proxy) / `TutorialManagerImpl` (Impl).
*   **Design**: These are short, pre-defined puzzles designed to isolate a single mechanic. For example, the "Resolution" tutorial will present a problem that *cannot* be solved without using the Resolution rule, forcing the player to learn it.
*   **Progression**: Tutorials are unlocked in a linear sequence to ensure foundational competence before advanced concepts are introduced.

### Lesson Plan Overview
The following modules act as the "Textbook" for the game:

| Tutorial ID | Rule Focus | Key Concept | Difficulty |
| :--- | :--- | :--- | :--- |
| `tutorial_basics` | UI Basics | Phase 1 vs Phase 2 | Easy |
| `modus_ponens` | Modus Ponens (MP) | Basic Implication (`→`) | Easy |
| `modus_tollens` | Modus Tollens (MT) | Negation Reversal | Medium |
| `conjunction` | Conjunction (CONJ) | Combining Facts (`∧`) | Easy |
| `simplification` | Simplification (SIMP) | Extracting Facts | Easy |
| `hypothetical_syllogism` | Hyp. Syllogism (HS) | Chaining Logic | Medium |
| `disjunctive_syllogism` | Disj. Syllogism (DS) | Elimination (`∨`) | Medium |
| `de_morgans_and` | De Morgan's (AND) | Negated Conjunctions | Hard |
| `de_morgans_or` | De Morgan's (OR) | Negated Disjunctions | Hard |
| `double_negation` | Double Negation (DN) | Simplifying `¬¬` | Easy |
| `constructive_dilemma` | Constructive Dilemma | Branching Logic | Hard |
| `resolution` | Resolution (RES) | Advanced Disjunction | Hard |
| `biconditional` | Equivalence (EQ) | Two-way Logic (`↔`) | Medium |
| `distributivity` | Distributivity | Expanding Factors | Hard |
| `commutativity` | Commutativity | Order Independence | Easy |
| `associativity` | Associativity | Grouping Independence | Easy |
| `idempotent` | Idempotence | Redundancy Removal | Easy |
| `absorption` | Absorption | Complex Reduction | Medium |
| `negation_laws` | Negation Laws | Contradiction/Tautology | Medium |

### Prompt Engineering: The AI System Context
The robustness of the AI Tutor depends on its System Prompt. Below is the exact definition used to constrain the LLM:

```text
You are an expert tutor for boolean logic and formal reasoning.

Available Inference Rules:
- Modus Ponens (MP): P, P → Q ⊢ Q
- Modus Tollens (MT): P → Q, ¬Q ⊢ ¬P
- Hypothetical Syllogism (HS): P → Q, Q → R ⊢ P → R
- Disjunctive Syllogism (DS): P ∨ Q, ¬P ⊢ Q
- Simplification (SIMP): P ∧ Q ⊢ P (or Q)
- Conjunction (CONJ): P, Q ⊢ P ∧ Q
- Addition (ADD): P ⊢ P ∨ Q
- Constructive Dilemma (CD): (P → Q) ∧ (R → S), P ∨ R ⊢ Q ∨ S
- Destructive Dilemma (DD): (P → Q) ∧ (R → S), ¬Q ∨ ¬S ⊢ ¬P ∨ ¬R
- Resolution (RES): P ∨ Q, ¬P ∨ R ⊢ Q ∨ R

Available Equivalence Laws:
- Commutativity: P ∧ Q ≡ Q ∧ P, P ∨ Q ≡ Q ∨ P
- Associativity: (P ∧ Q) ∧ R ≡ P ∧ (Q ∧ R)
- Distributivity: P ∧ (Q ∨ R) ≡ (P ∧ Q) ∨ (P ∧ R)
- De Morgan's Laws: ¬(P ∧ Q) ≡ ¬P ∨ ¬Q, ¬(P ∨ Q) ≡ ¬P ∧ ¬Q
- Double Negation: ¬¬P ≡ P
- Implication: P → Q ≡ ¬P ∨ Q
- Contrapositive: P → Q ≡ ¬Q → ¬P
- Idempotence: P ∧ P ≡ P, P ∨ P ≡ P
- Absorption: P ∧ (P ∨ Q) ≡ P, P ∨ (P ∧ Q) ≡ P

Use only variables: P, Q, R, S, T
Use operators: ∧ (AND), ∨ (OR), ⊕ (XOR), ¬ (NOT), → (implies), ↔ (biconditional)
```

This rigorous definition prevents the AI from suggesting rules that don't exist in the game (like "Exportation" or "Material Equivalence") or using symbols that the game's parser cannot read (like `&` or `~`). It also acts as a handy reference for developers maintaining the backend.

### Sample Transcript
A hypothetical interaction with the AI Tutor:

**User**: "Can I practice Modus Tollens?"
**AI**: "Certainly. Here is a problem: Premises: `P → Q`, `¬Q`. Target: `¬P`."
**User**: (Enters Solution: Step 1: `¬P`, Rule: `MP`, Sources: `1, 2`)
**AI Validation**: "Incorrect. You cited Modus Ponens (MP), but the correct rule for deriving the negation of the antecedent is Modus Tollens (MT). MP applies when you have `P`, not `¬Q`."

## Appendix A: Full Tutorial Text Transcript
This appendix contains the complete text strings used in the `FirstTimeTutorialManager` script.

1.  `WELCOME_AND_ORDER`: "[b]Welcome![/b]\n\nYou'll solve logic puzzles by translating statements into logical form and proving conclusions.\n\nYour goal is to prove: [b]The cat meows (Q)[/b]\n\nLet's learn how!"
2.  `PATIENCE_BAR_EXPLAINED`: "[b]Patience Bar[/b]\n\nThis shows how much time you have. Don't worry though - for this tutorial, you have [b]infinite time[/b]!"
3.  `KEYBOARD_BASICS`: "[b]Virtual Keyboard[/b]\n\nUse these buttons to build logical expressions.\n\nGiven: \"If the cat is hungry (P), then it meows (Q).\"\n\nYou need to translate this to: [b]P → Q[/b]"
4.  `OPERATORS_INTRO`: "[b]Logical Operators[/b]\n\n[b]∧[/b] = AND\n[b]∨[/b] = OR\n[b]→[/b] = Implies (\"If...then\")\n[b]¬[/b] = NOT\n\nFor \"If P then Q\", use the → operator: [b]P → Q[/b]"
5.  `TYPE_FIRST_PREMISE`: "[b]Try it now![/b]\n\nTranslate \"If the cat is hungry (P), then it meows (Q)\" into logical form.\n\nClick: [b]P → Q[/b]"
6.  `SUBMIT_PREMISE`: "[b]Great![/b]\n\nNow click the [b]Submit[/b] button to validate this premise."
7.  `COMPLETE_ALL_PREMISES`: "[b]Excellent![/b]\n\nYou translated the first statement. Now translate the second: \"The cat is hungry (P)\".\n\nThis is just: [b]P[/b]"
8.  `PHASE2_INTRO`: "[b]Phase 2: Transformation![/b]\n\nGreat! You translated both statements:\n• [b]P → Q[/b] (If hungry, then meows)\n• [b]P[/b] (The cat is hungry)\n\nNow use logic rules to prove: [b]Q[/b] (The cat meows)!"
9.  `PREMISE_SELECTION`: "[b]Logic Rules[/b]\n\nThese buttons apply logical inference rules. Each rule transforms premises in a specific way.\n\nThere are two pages: [b]Double Operations[/b] (need 2 premises) and [b]Single Operations[/b] (need 1 premise)."
10. `RULE_BUTTONS_OVERVIEW`: "[b]Page Toggle[/b]\n\nThis button switches between Single and Double operations.\n\nThe [b]MP[/b] (Modus Ponens) rule is on the Double Operations page (shown by default)."
11. `PAGE_TOGGLE`: "[b]Select Operation First[/b]\n\nClick the [b]MP[/b] button to select this operation. Modus Ponens: from \"P → Q\" and \"P\", conclude \"Q\".\n\n[i]Important: Always select the operation BEFORE selecting premises![/i]"
12. `APPLY_FIRST_RULE`: "[b]Now Select Premises[/b]\n\nAfter clicking MP (Modus Ponens), select:\n\n1. [b]P → Q[/b]\n2. [b]P[/b]\n\nThe rule will automatically conclude [b]Q[/b]!"
13. `TARGET_EXPLANATION`: "[b]Target Goal[/b]\n\nThis shows what you're trying to prove. When you create an expression that matches this exactly, you win!"
14. `REACH_TARGET`: "[b]Almost there![/b]\n\nApply the MP (Modus Ponens) rule to prove that the cat meows!\n\nSelect [b]P → Q[/b] and [b]P[/b] to conclude [b]Q[/b]."
15. `BONUS_SCORE_EXPLANATION`: "[b]🎉 Puzzle Solved![/b]\n\n[b]Bonus Score Tip:[/b] The faster you solve puzzles, the more bonus points you earn based on remaining time!\n\nYou also get bonuses for:\n• Using fewer operations\n• Solving without hints"

## Appendix B: Future Curriculum Roadmap
Ideas for post-release content updates.

*   **Logic Level 7**: Quantifiers (For All `∀`, There Exists `∃`).
*   **Logic Level 8**: Modal Logic (Necessity `□`, Possibility `◇`).
*   **Logic Level 9**: Temporal Logic (Next `○`, Until `U`).

## Appendix C: Glossary of Terms
For students and developers.
*   **Proposition**: A statement that can be true or false.
*   **Atomic**: A single variable (`P`).
*   **Compound**: Multiple variables connected by operators (`P ^ Q`).
*   **Tautology**: True in all cases.
*   **Contradiction**: False in all cases.
*   **Contingent**: True in some cases, false in others.

## Appendix D: Localization Keys (JSON)
The following keys are used for internationalization (`en.json`).
*   `TUTORIAL_WELCOME`: "Welcome! You'll solve logic puzzles..."
*   `TUTORIAL_PATIENCE`: "Patience Bar..."
*   `TUTORIAL_KEYBOARD`: "Virtual Keyboard..."
*   `TUTORIAL_TRY_IT`: "Try it now!..."
*   `TUTORIAL_GREAT`: "Great!..."
*   `TUTORIAL_PHASE2`: "Phase 2: Transformation!..."

## Appendix E: Full AI System Prompt
The following prompt is injected at the start of every AI session:

```json
{
  "role": "system",
  "content": "You are an expert tutor for boolean logic and formal reasoning.\n\nAvailable Inference Rules:\n- Modus Ponens (MP): P, P → Q ⊢ Q\n- Modus Tollens (MT): P → Q, ¬Q ⊢ ¬P\n- Hypothetical Syllogism (HS): P → Q, Q → R ⊢ P → R\n- Disjunctive Syllogism (DS): P ∨ Q, ¬P ⊢ Q\n- Simplification (SIMP): P ∧ Q ⊢ P (or Q)\n- Conjunction (CONJ): P, Q ⊢ P ∧ Q\n- Addition (ADD): P ⊢ P ∨ Q\n- Constructive Dilemma (CD): (P → Q) ∧ (R → S), P ∨ R ⊢ Q ∨ S\n- Destructive Dilemma (DD): (P → Q) ∧ (R → S), ¬Q ∨ ¬S ⊢ ¬P ∨ ¬R\n- Resolution (RES): P ∨ Q, ¬P ∨ R ⊢ Q ∨ R\n\nAvailable Equivalence Laws:\n- Commutativity: P ∧ Q ≡ Q ∧ P, P ∨ Q ≡ Q ∨ P\n- Associativity: (P ∧ Q) ∧ R ≡ P ∧ (Q ∧ R)\n- Distributivity: P ∧ (Q ∨ R) ≡ (P ∧ Q) ∨ (P ∧ R)\n- De Morgan's Laws: ¬(P ∧ Q) ≡ ¬P ∨ ¬Q, ¬(P ∨ Q) ≡ ¬P ∧ ¬Q\n- Double Negation: ¬¬P ≡ P\n- Implication: P → Q ≡ ¬P ∨ Q\n- Contrapositive: P → Q ≡ ¬Q → ¬P\n- Idempotence: P ∧ P ≡ P, P ∨ P ≡ P\n- Absorption: P ∧ (P ∨ Q) ≡ P, P ∨ (P ∧ Q) ≡ P\n\nUse only variables: P, Q, R, S, T\nUse operators: ∧ (AND), ∨ (OR), ⊕ (XOR), ¬ (NOT), → (implies), ↔ (biconditional)"
}
```

## Appendix F: Pedagogical Framework (Bloom's Taxonomy)
The game levels align with Bloom's learning stages:
1.  **Remember**: Recognizing symbols (Level 1).
2.  **Understand**: Translating English to Logic (Level 6 / Phase 1).
3.  **Apply**: Using MP/MT rules correctly (Level 2).
4.  **Analyze**: Breaking down complex proofs (Level 4).
5.  **Evaluate**: Finding errors in the AI Tutor's validation (Advanced).
6.  **Create**: Constructing own proofs in the AI Sandbox (AI Tutor Mode).

## Appendix G: Common Student Pitfalls
The AI Tutor is specifically trained to catch these common errors:
1.  **Denying the Antecedent**: Assuming `~P` leads to `~Q` from `P->Q`.
2.  **Affirming the Consequent**: Assuming `P` from `Q` and `P->Q`.
3.  **Order of Operations**: Confusing `P ^ Q -> R` with `P ^ (Q -> R)`.
4.  **De Morgan's Sign Errors**: Failing to flip the operator AND the signs.

## Appendix H: Accessibility Features
To ensure the game is playable by a wide audience, the following features are implemented or planned:
1.  **High Contrast Mode**: All UI text uses black-on-white or white-on-dark themes.
2.  **Screen Reader Compatibility**: The `Phase1UI` and `Phase2UI` expose accessibility hints for TTS systems.
3.  **Infinite Patience**: A toggle in Settings to disable the fuel/timer mechanic for stress-free play.
4.  **Colorblind Support**: Vital game states (Health, Fuel) use distinct shapes/icons in addition to color coding.
5.  **Input Scaling**: All buttons have a minimum touch target size of 60x60 pixels for motor accessibility.
6.  **Font Scaling**: The game supports dynamic font scaling based on device DPI settings.
7.  **Keyboard Navigation**: Full support for arrow-key navigation in menus (future update).
8.  **Reduced Motion**: Option to disable parallax backgrounds and screen shake effects.
9.  **Audio Cues**: Critical visual cues (like Low Fuel) are always accompanied by distinct sound effects for visually impaired users.
10. **Dyslexia Friendly Font**: The `Museo Sans Rounded` font was chosen for its high legibility and clear character distinction.