# Gameplay Mechanics

Fusion Rush gamifies the abstract, often intimidating concepts of formal logic through a compelling, high-stakes "Bartender" metaphor. Players take on the role of a cosmic bartender piloting a rocket ship through a hazardous asteroid field. Serving drinks to alien customers requires solving complex logical puzzles to "mix" the correct ingredients. The gameplay is strictly phase-based, data-driven, and visually rich, employing particle effects, parallax backgrounds, and dynamic animations to make logic feel tangible and exciting.

## Game Modes

### Classic Mode
The core arcade experience is designed for replayability, flow, and high-score chasing. Players are challenged to serve as many customers (solve puzzles) as possible within a strictly limited time frame (defaulting to **180 seconds**).

*   **Adaptive Difficulty (Levels 1-6)**:
    The game scales complexity not just by adding more rules, but by fundamentally changing the nature of the problems. The content is loaded dynamically from `data/classic/level-N.json`.
    *   **Level 1**: Introduces the basics: Modus Ponens, Modus Tollens, and Simplification. Problems are mostly "Direct Symbol" types, meaning the premises are already translated (e.g., `P → Q`). The cognitive load is focused purely on rule application.
    *   **Level 2**: Adds complexity with De Morgan's Laws and Conjunctions, requiring players to manipulate compound statements and understand negation distribution.
    *   **Level 3**: Increases the chain length, requiring 3+ operations to reach a conclusion. This forces players to plan ahead.
    *   **Level 4**: Introduces branching paths where players must decide between constructive or destructive dilemmas.
    *   **Level 5**: High-complexity puzzles requiring 5+ steps and deep foresight.
    *   **Level 6 ("Master Class")**: The ultimate challenge. This level consists exclusively of **Natural Language** problems. Players must first translate English sentences into logic before they can even begin the deduction process.

### Tutorial Mode
A zero-pressure environment designed for learning. Unlike Classic Mode, there is no time limit and no fuel penalty.
*   **Linear Progression**: Lessons are unlocked one by one, ensuring that players master foundational concepts (like "What is a Premise?") before moving on to advanced rules.
*   **Interactive Overlays**: The game pauses to draw attention to specific UI elements, using a dimming overlay and highlighting boxes to guide the player's clicks.

## The Gameplay Loop

The core loop is defined by the `GameplayScene.gd` script and is strictly divided into two distinct phases to manage cognitive load. This separation is crucial for the educational scaffolding, allowing learners to isolate the skill of "Translation" from the skill of "Deduction".

### Phase 1: Preparation (The Translation Phase)
**Script**: `src/ui/Phase1UI.gd`
**Scene**: `src/ui/Phase1UI.tscn`

This phase is active primarily for **Natural Language** problems (common in Level 6, rare in Levels 1-5). For Direct Symbol problems, the `GameplayScene` detects the problem type and automatically bypasses this phase to keep the arcade pace fast.

*   **Objective**: The player must translate the customer's spoken request (e.g., "If the cat is hungry, it meows") into a formal logical premise (`P → Q`).
*   **Visuals & Feedback**:
    *   **Card Flipping**: Upon entering this phase, the customer card performs a horizontal flip animation (`scale.x` tween from 1.0 to 0.0 and back) to reveal the "Variable Definitions" (e.g., "Let P be 'The cat is hungry'"). This visual cue signals the shift in gameplay focus.
    *   **Virtual Keyboard**: A custom `VirtualKeyboard` UI provides buttons for variables (`P`, `Q`, `R`, `S`) and operators (`∧`, `∨`, `¬`, `→`, `↔`, `⊕`).
    *   **Input Handling**: Symbols are inserted directly at the cursor position in the `LineEdit`. Unlike standard typing, the keyboard does not auto-space, requiring precise control.
*   **Validation Logic**:
    *   When the player clicks "Submit", the `BooleanLogicEngine` parses the string.
    *   If the input matches a required premise (semantically), a **Shatter Effect** (`CPUParticles2D`) triggers on the checklist item, and the premise is added to the valid set.
    *   If incorrect, the player loses a Life (Heart), and the screen shakes. The feedback is specific: "Invalid Syntax" vs "Meaning Mismatch".

### Phase 2: Transformation (The Deduction Phase)
**Script**: `src/ui/Phase2UI.gd`
**Scene**: `src/ui/Phase2UI.tscn`

This is the main puzzle interface where the actual logic deduction occurs. It mimics a workbench where ingredients (Premises) are combined using tools (Rules) to create new compounds (Conclusions).

*   **Rule Engine**: The UI organizes the 13 inference rules into two distinct categories based on their input requirements (`RuleType`), managed by a tabbed interface:
    *   **Double Operations**: Rules that require exactly two premises (e.g., Modus Ponens `P → Q, P`).
    *   **Single Operations**: Rules that require only one premise (e.g., Simplification `P ∧ Q`).
*   **Interaction Flow**:
    1.  **Select Rule**: The player clicks a rule button (e.g., "MP"). The button highlights in yellow to indicate selection.
    2.  **Select Premises**: The player clicks the checkbox on one or two premise cards in their inventory.
    3.  **Auto-Apply**: The system monitors the selection state. As soon as the correct number of premises is selected for the active rule, it attempts to apply the logic instantly.
        *   **Success**: A new card is spawned with the result. A "Speed Boost" popup appears at the card's location.
        *   **Failure**: A visual error message appears (e.g., "Mismatched Antecedent"), and a Fuel Penalty is applied.
*   **Visual Feedback**:
    *   **Parallax Background**: Two layers of space textures scroll horizontally. The speed (`bg_offset`) is dynamically coupled to the game's "Speed Boost" mechanic.
    *   **Rocket Animation**: The player's ship bobs vertically using a sine wave function (`sin(time)`) and drifts horizontally based on the current speed multiplier.
    *   **Damage**: On mistakes, the ship undergoes a "wobble" animation (`tween_property("rocket_wobble_offset")`) and flashes red.

## The Fuel System (Rocket Ship Mechanics)
Instead of a simple countdown timer, Fusion Rush uses a dynamic **Fuel System** managed by `GameplayScene.gd`. This system integrates the "Timer" directly into the narrative of the space ship.

### Fuel Math
*   **Initial Fuel**: 100.0 units.
*   **Base Consumption**: 1.0 unit/sec.
*   **Score Penalty**: `multiplier = 1.0 + (current_score / 5000.0)`.
    *   Example: At 0 score, drain is 1.0/sec.
    *   Example: At 5000 score, drain is 2.0/sec.
    *   Maximum Multiplier: 2.0x.
*   **Mistake Penalty**: `fuel -= fuel * 0.10` (10% current fuel loss).
*   **Refuel Bonus**: `fuel += 50.0` (Cap at 100.0) on order completion.

**Gameplay Implication**:
This system creates a "Rubber Band" effect. As players perform better and their score increases, the game naturally becomes faster and more demanding, requiring them to maintain a higher speed to survive.

### Speed & Scoring Integration
*   The game tracks a `current_speed` variable (Base 1.0).
*   **Clean Solutions** (solving without errors) award "Speed Boosts" that temporarily increase this multiplier up to 5x.
*   **Score Accumulation**: Points are awarded *continuously* based on speed (`delta * speed * 10`). This means maintaining a high speed (by solving quickly and accurately) is exponentially more valuable than just solving problems slowly.
*   **Decay**: Speed boost decays at a rate of `0.5` units per second, encouraging constant successful plays to maintain velocity.

## The Combo System
To reward mastery, the game implements a visual Combo System handled in `Phase2UI.gd`. This system provides immediate, juicy feedback for performing well.

### Visual Progression Table
| Streak | Visual Effect | Particle Type | UI Feedback |
| :--- | :--- | :--- | :--- |
| **0-2x** | None | Normal Smoke | White Text |
| **3x** | Sparkles | `ComboSparkles` (Yellow) | Pop Animation |
| **5x** | Sparks + Blue Trail | `FallingSparks` + `BlueGradient` | Label Glows |
| **8x** | UI Pulse | `CyanGradient` | Full UI Color Pulse |
| **10x** | Fire + Laser | `Fire` + `PurpleGradient` (Laser) | Intense Shake |

### Gameplay Impact
High combos drastically increase the background scroll speed and the rate of score accumulation. A combo of 10x effectively results in 3x visual speed and massive score gains.

## The Failure State (Black Hole)
The "Game Over" sequence is a bespoke animation in `GameplayScene.gd` that triggers when Fuel <= 0.
1.  **Engine Cutoff**: `current_speed` tweens to 0. Flame and Smoke particles stop emitting (`emitting = false`).
2.  **Drift**: The Rocket sprite tweens backward (X position decreases from center to left edge).
3.  **Rotation**: The Rocket rotates 360 degrees (`rotation += 2*PI`), simulating a loss of stabilization.
4.  **Scaling**: The Black Hole sprite scales up (`scale` 1.0 -> 10.0), consuming the screen.
5.  **Fade**: The entire screen fades to black via a `ColorRect` overlay (`modulate.a` -> 1.0).

## Difficulty Recommender
The `DifficultyRecommender` class (`src/managers/DifficultyRecommender.gd`) provides a personalized experience by analyzing player performance data.
*   **Inputs**: It consumes the `PlayerStatistics` resource, looking at:
    *   Average Mistakes per Session.
    *   Completion Rate (% of games finished vs. failed).
    *   High Scores relative to the difficulty tier.
*   **Analysis Window**: It considers only the last 5-10 sessions to reflect current skill level.
*   **Logic Rules**:
    *   **Level Up**: If mistakes < 2 AND completion rate > 80%, it suggests moving up.
    *   **Level Down**: If mistakes > 8 OR completion rate < 30%, it suggests moving down to build confidence.
    *   **Flow State**: If performance is between these extremes, it recommends staying at the current level to maintain the "Flow" state.

## Customer Persona Generation
To make the universe feel alive, customers are generated procedurally with distinct personalities (though functionally identical in terms of logic puzzles).

| ID | Name | Species | Flavor Text |
| :--- | :--- | :--- | :--- |
| 1 | Alice | Human | "Just a regular coffee, please." |
| 2 | Bob | Cyborg | "Something with electrolytes." |
| 3 | Charlie | Martian | "Does this come in liquid form?" |
| 4 | Diana | Lunar | "I need clarity." |
| 5 | Eve | Venusian | "Something hot." |
| 6 | Frank | Jovian | "Heavy on the gas." |
| 7 | Grace | Saturnian | "Spin it fast." |
| 8 | Henry | Neptunian | "Cold as ice." |

## Audio Feedback System
The soundscape is designed to provide immediate reinforcement (`src/managers/AudioManagerImpl.gd`).
*   **Positive**: `Powerup.wav` (Logic Success), `Confirm.wav` (Premise Validated).
*   **Negative**: `Cancel.wav` (Mistake), `Low_Health.wav` (Fuel Warning).
*   **Dynamic Pitch**: The "Score Popup" sound pitch scales with the combo multiplier (1.0x to 1.5x pitch), creating an auditory sense of acceleration.
*   **Ambience**: `Pinball Spring.mp3` provides an energetic, arcade-style backing track.

## Visual Effects Specifications

### Shatter Effect
When a premise is correctly validated in Phase 1, the text doesn't just disappear; it shatters.
*   **Particle Count**: 30 shards.
*   **Spread**: 180 degrees.
*   **Lifetime**: 1.0 seconds.
*   **Scale**: 3.0 to 6.0 (Large shards).
*   **Gravity**: `(0, 200)` (Falls downward).

### Rocket Exhaust
The exhaust is a multi-layered `CPUParticles2D` system.
*   **Layer 1 (Core)**: Bright yellow/white, small scale, high velocity.
*   **Layer 2 (Smoke)**: Dark grey/black, large scale, slow velocity, high damping.
*   **Modulation**: The smoke color changes based on the Combo tier (see Combo System table).

### Star Field (Parallax)
The background consists of two `TextureRect` nodes moving at different speeds to create depth.
*   **Layer 1 (Nebula)**: `speed * 0.5`.
*   **Layer 2 (Stars)**: `speed * 1.0`.
*   **Shader**: A custom `motion_blur.gdshader` is applied to Layer 2 at high speeds (Combo > 8x) to simulate warp speed.

## User Interface Layout

### Top Bar
*   **Left**: Lives (Heart Icons).
*   **Center**: Patience/Fuel Bar (ProgressBar with `TextureRect` overlay).
*   **Right**: Score (Label) and Pause Button.

### Action Area (Phase 1)
*   **Top**: Customer Card (Flippable).
*   **Middle**: Virtual Keyboard (GridContainer).
*   **Bottom**: Input Display (LineEdit) + Submit Button.

### Action Area (Phase 2)
*   **Left**: Premise Inventory (ScrollContainer of Buttons).
*   **Right**: Rule Panel (TabContainer with Single/Double tabs).
*   **Center**: Target Display (Chat bubble style).

## Detailed Interaction Timing
To ensure the game feels responsive, certain interactions have tuned timing windows:
*   **Card Flip**: 0.4 seconds total (0.2s scale down, 0.2s scale up).
*   **Feedback Message**: Displays for 3.0 seconds before auto-hiding.
*   **Score Popup**: Animates upward for 1.0 seconds while fading out.
*   **Black Hole**: Expands over 2.0 seconds during Game Over.
*   **Level Transition**: A 1.5-second delay occurs between verifying the final premise and starting Phase 2 to allow the player to register success.

## Appendix A: Rule Interaction Matrix

This matrix describes valid input combinations for the game's rule engine.

| Rule | Input 1 Type | Input 2 Type | Result Type | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **MP** | Implication (`P → Q`) | Atomic (`P`) | Atomic (`Q`) | Input 2 must match Antecedent |
| **MT** | Implication (`P → Q`) | Negation (`¬Q`) | Negation (`¬P`) | Input 2 must negate Consequent |
| **HS** | Implication (`P → Q`) | Implication (`Q → R`) | Implication (`P → R`) | Chain must link correctly |
| **DS** | Disjunction (`P ∨ Q`) | Negation (`¬P`) | Atomic (`Q`) | Also works with `¬Q` -> `P` |
| **CD** | Conjunction of Impl. | Disjunction (`P ∨ R`) | Disjunction (`Q ∨ S`) | Complex Pattern |
| **DD** | Conjunction of Impl. | Disjunction (`¬Q ∨ ¬S`) | Disjunction (`¬P ∨ ¬R`) | Complex Pattern |
| **RES** | Disjunction (`P ∨ Q`) | Disjunction (`¬P ∨ R`) | Disjunction (`Q ∨ R`) | Must find cancelling pair |
| **SIMP** | Conjunction (`P ∧ Q`) | N/A | Atomic (`P`) | Can extract Left or Right |
| **CONJ** | Any | Any | Conjunction | Always valid |
| **ADD** | Any | N/A (User Input) | Disjunction | Adds arbitrary term |
| **DM** | Negation of Group | N/A | Disjunction/Conj | Flips operator and signs |
| **DN** | Double Negation | N/A | Atomic | Removes `¬¬` |
| **EQ** | Biconditional | Atomic | Atomic | Two-way inference |

## Appendix B: Game Settings Database
Below is a listing of all configurable parameters found in the "Settings" menu or Debug panel.

1.  **Infinite Patience**
    *   *Type*: Boolean
    *   *Effect*: Disables the Fuel/Patience system. Useful for testing or accessibility.
2.  **Debug Mode**
    *   *Type*: Boolean
    *   *Effect*: Shows hidden internal state labels (e.g. current combo multiplier float value).
3.  **Difficulty Mode**
    *   *Options*: Auto (-1), Level 1-6.
    *   *Effect*: Locks the customer generation to a specific difficulty table.
4.  **Master Volume**
    *   *Range*: 0.0 - 1.0
    *   *Effect*: Global audio scaler.
5.  **Music Volume**
    *   *Range*: 0.0 - 1.0
    *   *Effect*: Independent scaler for `AudioStreamPlayer (Music)`.
6.  **SFX Volume**
    *   *Range*: 0.0 - 1.0
    *   *Effect*: Independent scaler for `AudioStreamPlayer (SFX)`.

## Appendix C: Keyboard Shortcuts
For the desktop debug build, the following hotkeys are available in the Main Menu:
*   `KEY_D`: Toggle Debug Panel overlay.
*   `KEY_T`: Run Integration Test (if debug panel is open) or Tutorial Test.
*   `KEY_L`: Run Boolean Logic Engine self-test suite.

## Appendix D: Change Log
A history of mechanical changes during development.
*   **v0.1**: Initial Prototype. Patience Bar was a simple timer.
*   **v0.2**: Added Phase 1. Before this, all problems were direct symbols.
*   **v0.3**: Introduced Fuel System (Rocket Ship) to replace timer.
*   **v0.4**: Added Combo System (Particles).
*   **v0.5**: Implemented Difficulty Recommender.
