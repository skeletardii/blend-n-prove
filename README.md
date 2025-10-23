# Boolean Logic Bartender

An educational puzzle game that teaches formal boolean logic through engaging gameplay. Master 33+ logical operations across 240+ carefully crafted problems, progressing from basic inference rules to complex natural language reasoning.

![Godot Engine](https://img.shields.io/badge/Godot-4.4-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Status](https://img.shields.io/badge/status-feature--complete-brightgreen.svg)

## Overview

**Boolean Logic Bartender** transforms the learning of formal logic into an interactive experience. Players work through logic puzzles in two phases: first building logical premises, then applying inference rules to reach target conclusions. The game progressively introduces concepts from simple Modus Ponens to advanced natural language translation.

### Educational Objectives

- Master 13 inference rules (Modus Ponens, Hypothetical Syllogism, Resolution, etc.)
- Understand 20+ equivalence laws (De Morgan's, Distributivity, Contrapositive, etc.)
- Practice with 8 boolean operators (AND, OR, XOR, NOT, IMPLIES, BICONDITIONAL, TRUE, FALSE)
- Bridge natural language and formal logic (Level 6)
- Develop logical reasoning and proof construction skills

## Features

### Core Gameplay

- **Two-Phase System**: Build premises, then transform them using logical rules
- **6 Difficulty Levels**: Progressive complexity from 1-operation puzzles to 5+ step proofs
- **240+ Problems**: Across classic mode and tutorial modules
- **Lives & Scoring**: Strategic gameplay with heart-based mistakes and score multipliers
- **Patience Timer**: Timed challenges that increase pressure at higher difficulties

### Logic Engine

- **33+ Boolean Operations**: Comprehensive implementation of formal logic
- **Real-time Validation**: Instant feedback on logical expressions
- **Expression Cleaning**: Automatic removal of unnecessary parentheses
- **Multi-result Operations**: Some rules produce multiple conclusions simultaneously
- **Robust Parsing**: Supports both Unicode symbols and ASCII alternatives (`->` → `→`, `^` → `⊕`)

### Tutorial System

- **18 Complete Modules**: Each covering a specific logical operation
- **180+ Tutorial Problems**: Progressive difficulty from Easy to Very Hard
- **Grid Selection Interface**: 3×6 touch-optimized layout
- **In-game Help**: Context-sensitive hints and rule explanations
- **Progress Tracking**: Per-problem completion and mastery indicators

### Level 6: Natural Language Translation

The game's most innovative feature bridges everyday language and formal logic:

```
Natural Language:
"If it rains (P), then the ground is wet (Q)."
"It is raining (P)."

Formal Logic:
P → Q, P ⊢ Q

Solution: Apply Modus Ponens to conclude Q
```

Players translate English sentences into logical symbols, learning how formal reasoning applies to real-world statements.

### Progress & Analytics

- **Detailed Statistics**: Track high scores, win streaks, and operation proficiency
- **21+ Achievements**: Milestones for games played, win streaks, and tutorial completion
- **Learning Analytics**: Success rates per operation, identifying areas for improvement
- **Persistent Progress**: Auto-save with backup and corruption recovery
- **Session History**: Last 100 games with detailed operation usage

## How to Play

### Phase 1: Premise Building

1. View the customer's required premises in the speech bubble
2. Use the virtual keyboard to construct each logical expression
3. Validate premises against the customer's requirements
4. Progress to Phase 2 when all premises are validated

**Virtual Keyboard Layout:**
```
┌─────┬─────┬─────┬─────┬─────┐
│  P  │  Q  │  R  │  S  │  T  │  Variables
├─────┼─────┼─────┼─────┼─────┤
│  ∧  │  ∨  │  ⊕  │  ↔  │     │  Operators
├─────┼─────┼─────┼─────┼─────┤
│  →  │  (  │  )  │  ¬  │  ⌫  │  Navigation
└─────┴─────┴─────┴─────┴─────┘
```

### Phase 2: Logical Transformation

1. Select an inference rule or equivalence law from the operation panel
2. Choose the required premises from your inventory
3. Apply the rule to generate new conclusions
4. Reach the target conclusion to complete the order

**Available Operations:**
- **Inference Rules**: MP (Modus Ponens), MT (Modus Tollens), HS (Hypothetical Syllogism), DS (Disjunctive Syllogism), and more
- **Equivalence Laws**: Commutativity, Distributivity, De Morgan's Laws, Contrapositive, and more
- **Simplifications**: Extract conjuncts, remove double negations, clean expressions

## Installation

### Requirements

- **Godot Engine 4.4+** ([Download](https://godotengine.org/download))
- Platform: Windows, macOS, Linux, or mobile devices
- Display: 720×1280 recommended (mobile-optimized)

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/boolean-logic-bartender.git
   cd boolean-logic-bartender
   ```

2. **Open in Godot:**
   - Launch Godot Engine
   - Click "Import"
   - Navigate to the cloned directory
   - Select `project.godot`
   - Click "Import & Edit"

3. **Run the game:**
   - Press F5 or click the "Play" button in Godot
   - Alternatively, export for your target platform

## Content Breakdown

### Classic Mode (6 Levels)

| Level | Operations | Premises | Problems | Description |
|-------|-----------|----------|----------|-------------|
| 1 | 1 | 1-2 | 20 | Basic inference rules |
| 2 | 1-2 | 2-3 | ~10 | Rule combinations |
| 3 | 2-3 | 3-4 | ~10 | Intermediate chaining |
| 4 | 3-4 | 3-5 | ~10 | Advanced proofs |
| 5 | 4-5 | 4-6 | ~10 | Expert-level logic |
| 6 | 5+ | 4-7 | 10 | Natural language translation |

### Tutorial Modules (18 Total)

**Inference Rules:**
- Modus Ponens, Modus Tollens, Hypothetical Syllogism
- Disjunctive Syllogism, Simplification, Conjunction
- Addition, Constructive/Destructive Dilemma
- Resolution, De Morgan's Laws, Double Negation

**Equivalence Laws:**
- Commutativity, Associativity, Distributivity
- Idempotent, Absorption, Negation Laws

## Technical Details

### Architecture

```
godot-mcp/
├── src/
│   ├── game/autoloads/        # 7 game manager singletons
│   │   ├── GameManager.gd     # State, scoring, difficulty
│   │   ├── BooleanLogicEngine.gd  # 33+ logic operations
│   │   ├── ProgressTracker.gd # Analytics & persistence
│   │   └── ...
│   ├── ui/                    # UI scene scripts
│   │   ├── Phase1UI.gd        # Premise building
│   │   ├── Phase2UI.gd        # Rule application
│   │   └── ...
│   └── scenes/                # Scene files
├── data/
│   ├── classic/               # 6 level JSON files
│   └── tutorial/              # 18 tutorial JSON files
└── assets/                    # Audio, themes, icons
```

### Game Managers (Autoload Singletons)

- **GameManager**: Game state, scoring, lives, difficulty scaling
- **BooleanLogicEngine**: All 33+ logical operations (1,763 lines)
- **AudioManager**: Sound effects and background music
- **SceneManager**: Scene transitions
- **TutorialManager**: In-game tutorial overlay
- **ProgressTracker**: Statistics, achievements, persistence (509 lines)
- **TutorialDataManager**: Tutorial content loading

### Mobile Optimization

- **Portrait Layout**: 720×1280 (9:16 aspect ratio)
- **Touch Targets**: 44×44px minimum for accessibility
- **Virtual Keyboard**: Optimized for thumb typing
- **Responsive UI**: Scales gracefully across devices

### Performance

- **Logic Engine**: Sub-millisecond expression validation
- **Frame Rate**: 60fps target
- **Memory**: Efficient cleanup between orders
- **Testing**: 34+ comprehensive test cases (100% pass rate)

## Debug Features

Press keyboard shortcuts to access developer tools:

- **D**: Toggle debug panel
- **T**: Run integration tests
- **L**: Run logic engine test suite (34 tests)

**Debug Panel Options:**
- Manual difficulty slider (1-6)
- Infinite patience mode
- Force game over
- Quick stats display

## Development Status

### Completed Features

- ✅ Complete boolean logic engine (33+ operations)
- ✅ Two-phase gameplay system
- ✅ 6 difficulty levels with 240+ problems
- ✅ 18 tutorial modules with 180+ problems
- ✅ Progress tracking and 21+ achievements
- ✅ Audio system (SFX + music)
- ✅ Mobile-optimized UI (Phase 1 & 2)
- ✅ Natural language translation (Level 6)
- ✅ Persistent save system with backup

### Known Limitations

- **Addition Rule (ADD)**: Requires special input dialog (currently returns empty)
- **Menu Music**: Defined but currently disabled
- **Some Audio Files**: May need completion in assets folder

## Contributing

Contributions are welcome! Areas for enhancement:

- Additional tutorial content
- More natural language problems
- Visual proof tree diagrams
- Multiplayer logic races
- Custom problem editor
- Hint system

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- **Engine**: Godot 4.4
- **Logic Engine**: Custom implementation with comprehensive operator support
- **Audio**: 8-bit sound effects and chiptune music
- **Design**: Mobile-first educational game design

## Educational Use

This game is designed for:
- Logic and critical thinking courses
- Computer science discrete mathematics
- Self-study of formal reasoning
- Preparation for logic-intensive fields (programming, law, philosophy)

The progressive difficulty and comprehensive tutorial system make it suitable for learners from high school through university level.

---

**Ready to master boolean logic?** Open the project in Godot and press F5 to start learning!
