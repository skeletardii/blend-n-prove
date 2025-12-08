# Tutorial Testing Guide

## Overview

The tutorial testing system validates that all 180 tutorial problems (18 tutorials × 10 problems each) can be solved using the Boolean Logic Engine. This ensures that the tutorial content is correct and playable.

## Running the Tests

### Method 1: From Main Menu (Easiest)
1. Open the project in Godot Editor
2. Run the project (F5)
3. At the Main Menu, press the **'T' key**
4. Check the Output console for test results

### Method 2: Run Test Scene Directly
1. Open `TutorialTestScene.tscn` in Godot Editor
2. Click "Play Scene" (F6)
3. Check the Output console for test results

### Method 3: Attach Script to Any Scene
1. Create a new Node in any scene
2. Attach `test_tutorials.gd` as a script
3. Run the scene
4. The tests will execute automatically

## Understanding Test Results

### Output Format

```
================================================================================
TUTORIAL PROBLEM TESTING SUITE
================================================================================

Testing all tutorials...

--------------------------------------------------------------------------------
Testing: Modus Ponens
--------------------------------------------------------------------------------
  ✓ Problem 1: Q
  ✓ Problem 2: S
  ✓ Problem 3: B
  ...

--------------------------------------------------------------------------------
Testing: Modus Tollens
--------------------------------------------------------------------------------
  ✓ Problem 1: ¬P
  ✗ Problem 2: Could not derive conclusion from premises
  ...

================================================================================
TEST SUMMARY
================================================================================
Total tests: 180
Passed: 175 ✓
Failed: 5 ✗
```

### Success Indicators

- **✓** Green checkmark = Test passed
- **✗** Red X = Test failed

### Failure Details

Failed tests include:
- Test name (tutorial + problem number)
- Reason for failure
- Premises provided
- Expected conclusion
- Solution hint from markdown

## Test Coverage

The testing script validates:

1. **Expression Validity**: All premises and conclusions are valid boolean expressions
2. **Rule Application**: The Boolean Logic Engine can derive the conclusion using the appropriate rule
3. **Expression Matching**: The derived result matches the expected conclusion

## Tested Rules

| Tutorial | Rule | Problems |
|----------|------|----------|
| 1 | Modus Ponens | 10 |
| 2 | Modus Tollens | 10 |
| 3 | Hypothetical Syllogism | 10 |
| 4 | Disjunctive Syllogism | 10 |
| 5 | Simplification | 10 |
| 6 | Conjunction | 10 |
| 7 | Addition | 10 |
| 8 | De Morgan's (AND) | 10 |
| 9 | De Morgan's (OR) | 10 |
| 10 | Double Negation | 10 |
| 11 | Resolution | 10 |
| 12 | Biconditional | 10 |
| 13 | Distributivity | 10 |
| 14 | Commutativity | 10 |
| 15 | Associativity | 10 |
| 16 | Idempotent | 10 |
| 17 | Absorption | 10 |
| 18 | Negation Laws | 10 |

**Total: 180 problems**

## Common Issues and Fixes

### Issue: "Invalid premise" or "Invalid conclusion"

**Cause**: The expression string in the markdown file contains syntax errors

**Fix**:
1. Check the markdown file for typos
2. Ensure proper use of logical symbols: ∧, ∨, →, ↔, ¬, ⊕
3. Verify parentheses are balanced

### Issue: "Could not derive conclusion from premises"

**Cause**: Either:
- The problem is incorrectly designed
- The Boolean Logic Engine doesn't support the required transformation
- The test function for that rule needs improvement

**Fix**:
1. Manually verify the problem can be solved
2. Check if the problem requires multiple steps (some problems may need chaining)
3. Update the test function to handle edge cases

### Issue: Problems requiring multiple rules

**Note**: Some complex problems (especially in "Hard" and "Very Hard" difficulty) may require applying multiple rules in sequence. The current test suite tests each rule in isolation. These problems will still work in the actual game but may show as "failed" in the automated tests.

**Examples**:
- Modus Ponens Problem 7: Requires two applications of Modus Ponens
- Simplification Problem 8: Requires Simplification twice

These are **expected failures** and don't indicate broken tutorials.

## Extending the Tests

To add tests for custom rules or multi-step problems:

1. Open `test_tutorials.gd`
2. Add a new test function following the pattern:
```gdscript
func test_my_custom_rule(premises: Array, conclusion: BooleanExpression) -> bool:
    # Your test logic here
    return result.is_valid and result.equals(conclusion)
```
3. Add the case to the `test_derivation()` match statement

## Best Practices

1. **Run tests after editing tutorial content**: Always test after modifying `.md` files
2. **Check both passed and failed counts**: Some failures are expected for multi-step problems
3. **Review failed test details**: The script shows the first 10 failures with full details
4. **Test in-game**: Even if automated tests fail, manually verify the problem is solvable in the actual game

## Performance

- **Expected runtime**: 2-5 seconds for all 180 tests
- **Output size**: ~200-400 lines in console
- **Memory usage**: Minimal (all expressions are temporary)

## Troubleshooting

### Tests don't run

1. Ensure TutorialDataManager is loaded as an autoload
2. Check that all `.md` files exist in `docs/tutorials/`
3. Verify BooleanLogicEngine is available

### All tests fail

1. Check that tutorial markdown files are properly formatted
2. Ensure BooleanLogicEngine is working (run `BooleanLogicEngine.test_logic_engine()`)
3. Verify file paths are correct

### Tests run but output is not visible

1. Check the Output tab in Godot Editor (not the Debugger tab)
2. Ensure "stdout" is enabled in Editor Settings
3. Run with `--verbose` flag if using command line

## Future Improvements

Potential enhancements to the testing system:

1. **Multi-step problem testing**: Chain multiple rules together
2. **Alternative solution paths**: Test if multiple valid solutions exist
3. **Performance benchmarks**: Measure solve times for each problem
4. **Difficulty validation**: Verify problems are ordered by difficulty
5. **Auto-fix suggestions**: Recommend corrections for failing problems
6. **CI/CD integration**: Automate tests on every commit

## Contributing

When creating new tutorial problems:

1. Write the problem in markdown format
2. Run the test suite to verify it works
3. If the test fails but the problem is correct, document it as a multi-step problem
4. Include the solution hint in the markdown

---

**Last Updated**: 2025-09-30
**Test Suite Version**: 1.0
**Total Test Coverage**: 180/180 problems