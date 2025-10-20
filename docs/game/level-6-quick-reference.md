# Level 6 Quick Reference Guide

## For Developers Working with Level 6

This is a quick reference for understanding and working with Level 6 natural language translation problems.

## Data Format

### JSON Structure
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
  "description": "Basic Modus Ponens",
  "solution": "Translation and proof explanation",
  "interpretation_hints": ["Identify the conditional", "Find the affirmed antecedent"]
}
```

### Required Fields
- `natural_language_premises` - Array of English sentences
- `hidden_logical_premises` - Array of logical statements (validation)
- `natural_language_conclusion` - English goal sentence
- `hidden_logical_conclusion` - Logical goal (validation)
- `expected_operations` - Number of logical operations needed
- `description` - Problem description
- `solution` - Complete explanation
- `interpretation_hints` - Optional hints array

## Code Architecture

### Key Classes

#### OrderTemplate (GameManager.gd)
```gdscript
class OrderTemplate:
    var is_natural_language: bool = false
    var natural_language_premises: Array[String] = []
    var natural_language_conclusion: String = ""
    var premises: Array[String] = []  # Hidden logical
    var conclusion: String             # Hidden logical
```

#### CustomerData (GameManager.gd)
```gdscript
class CustomerData:
    var is_natural_language: bool = false
    var natural_language_premises: Array[String] = []
    var natural_language_conclusion: String = ""
    var required_premises: Array[String] = []  # Hidden logical
    var target_conclusion: String              # Hidden logical
```

### Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│ GameManager.load_classic_problems()                    │
│ Detects Level 6 by "natural_language_premises" field   │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ GameplayScene.generate_new_customer()                  │
│ Creates CustomerData with natural language data        │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ Phase1UI.set_customer_data()                           │
│ Displays: natural_language_premises                    │
│ Validates against: required_premises (hidden)          │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ Phase2UI.set_premises_and_target_with_display()       │
│ Displays: natural_language_conclusion                  │
│ Validates against: target_conclusion (hidden)          │
└─────────────────────────────────────────────────────────┘
```

## Adding New Problems

### Step 1: Write the Problem
```json
{
  "natural_language_premises": [
    "YOUR ENGLISH SENTENCE HERE",
    "ANOTHER SENTENCE HERE"
  ],
  "hidden_logical_premises": ["P → Q", "P"],
  "natural_language_conclusion": "YOUR GOAL SENTENCE",
  "hidden_logical_conclusion": "Q",
  "expected_operations": 1,
  "description": "Problem type",
  "solution": "Explain translation: P = 'rain', Q = 'ground wet'. Apply MP.",
  "interpretation_hints": ["Hint 1", "Hint 2"]
}
```

### Step 2: Variable Mapping
Assign variables consistently:
- P, Q, R, S, T for basic propositions
- Assign in order of appearance
- Document in solution field

### Step 3: Test
1. Load in game
2. Verify natural language displays
3. Test correct translation validates
4. Test incorrect translation rejects
5. Verify problem is solvable

## Translation Patterns Reference

| English Pattern | Logical Form | Example |
|----------------|--------------|---------|
| If P, then Q | P → Q | "If it rains, then the ground is wet" |
| P and Q | P ∧ Q | "Alice is tall and Bob is smart" |
| Either P or Q | P ∨ Q | "Either the door is open or the window is open" |
| Not P | ¬P | "The alarm is not ringing" |
| P if and only if Q | P ↔ Q | "The button is pressed iff the light is on" |
| Not both P and Q | ¬(P ∧ Q) | "Not the case that both car is red and new" |

## Common Debugging Issues

### Issue: Natural Language Not Displaying
**Check**: `customer.is_natural_language` flag set correctly
**Location**: `GameplayScene.gd:153-157`

### Issue: Validation Failing
**Check**: Hidden logical premises match player input exactly
**Location**: `Phase1UI.gd:115-130`

### Issue: Wrong Conclusion Showing
**Check**: Phase2 receiving `natural_language_conclusion` for display
**Location**: `GameplayScene.gd:115-119`

### Issue: Level 6 Not Loading
**Check**:
1. JSON file exists at `res://data/classic/level-6.json`
2. `load_classic_problems()` range includes level 6
**Location**: `GameManager.gd:95`

## Code Patterns

### Detect Level 6
```gdscript
if customer.is_natural_language:
    # Level 6 specific code
else:
    # Levels 1-5 code
```

### Display Natural Language
```gdscript
if customer.is_natural_language:
    display_text = customer.natural_language_premises[i]
else:
    display_text = customer.required_premises[i]
```

### Validate Translation
```gdscript
# Always validate against hidden logical premises
var is_match = (player_input == customer.required_premises[i])
```

## Testing Commands

### Manual Testing
1. Start game
2. Play through levels 1-5
3. Level 6 should unlock
4. Verify natural language displays
5. Test translation and validation

### Debug Mode
Enable in GameManager:
```gdscript
GameManager.debug_mode = true
GameManager.set_difficulty(6)  # Jump to level 6
```

## Performance Considerations

- Natural language strings are slightly longer than logical symbols
- No performance impact on validation (same logic)
- UI updates are identical to other levels
- JSON parsing handles both formats efficiently

## Accessibility Notes

- Natural language makes logic more accessible to beginners
- Requires English language proficiency
- Could be extended to other languages in future
- Font size should accommodate longer sentences

## Related Files

**Core Implementation**:
- `data/classic/level-6.json` - Problem data
- `src/game/autoloads/GameManager.gd` - Data loading
- `src/ui/GameplayScene.gd` - Game flow
- `src/ui/Phase1UI.gd` - Translation input
- `src/ui/Phase2UI.gd` - Proof solving

**Documentation**:
- `docs/game/level-6-design.md` - Full design spec
- `docs/game/level-6-implementation-summary.md` - Implementation details
- `docs/game/level-6-quick-reference.md` - This file

## Support

For questions or issues:
1. Check `level-6-design.md` for design rationale
2. Review `level-6-implementation-summary.md` for implementation details
3. Examine code comments in modified files
4. Test with debug mode enabled

## Version History

- **v1.0** (2025-10-21) - Initial implementation
  - 10 problems
  - Full natural language support
  - Dual display/validation system
  - Complete documentation

---

**Last Updated**: 2025-10-21
**Status**: ✅ Production Ready
**Maintainer**: Claude Code Implementation Team
