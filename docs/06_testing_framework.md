# Testing Framework

Reliability is paramount for a logic game. If the engine validates a false premise or rejects a true one, the educational value is lost and the player feels cheated. To ensure correctness, Fusion Rush relies on a comprehensive, Godot-native testing framework that allows for integration testing within the actual engine environment.

## 1. The Test Runner
**Scene**: `temp_test_runner.gd`

Unlike external unit testing frameworks (like GUT) that might require separate configuration or plugins, Fusion Rush uses a lightweight, standalone test runner scene. This approach ensures that tests run in the exact same environment (same variable types, same engine version, same singletons) as the actual game.

### Architecture
The runner is a simple `SceneTree` script that acts as an entry point.
1.  **Instantiation**: It instantiates the key system classes to be tested (e.g., `BooleanLogicEngineImpl`, `FuelManager`). It does this manually rather than relying on Autoloads, ensuring a clean state for every test run.
2.  **Execution**: It executes their internal test methods (e.g., `test_logic_engine()`).
3.  **Reporting**: It reports results directly to the Godot Output console using standardized "✓" (Pass) and "✗" (Fail) prefixes for visibility.
4.  **Termination**: It terminates execution automatically (using `quit()`) when finished, allowing it to be used in headless CI/CD pipelines.

**Usage**: Developers can run this scene by pressing `F6` in the Godot Editor. It provides an instant sanity check before committing complex logic changes.

### Sample Output Log
```text
Running Game Systems Integration Test...
Testing game state management...
✓ State change test passed
Testing score system...
✓ Score system test passed
Testing phase management...
✓ Phase management test passed
Testing boolean logic engine integration...
Testing Boolean Logic Engine...
==================================================
✓ Basic expression creation test passed
✓ Expression with operator test passed
✓ Complex expression test passed
✓ Modus Ponens test passed
✓ Double Negation test passed
✓ XOR expression creation test passed
✓ XOR ASCII conversion test passed
...
✓ Biconditional to implications test passed
✓ XOR elimination test passed
✓ Commutativity test passed
✓ Idempotent test passed
...
==================================================
Tests completed: 42/42 passed
🎉 All tests passed! Boolean Logic Engine is FULLY IMPLEMENTED!
```

## 2. Embedded Integration Tests
A key design choice in Fusion Rush is **Co-located Testing**. Instead of keeping tests in a separate `tests/` folder, test suites are often embedded directly within the implementation classes (e.g., inside `BooleanLogicEngineImpl.gd`).

### Why Co-located?
*   **Access to Internals**: Embedded tests can access private variables (`_`) and internal helper functions without needing to expose them in the public API.
*   **Self-Documenting**: The tests serve as live documentation for how the class is intended to be used. A developer reading the code can see exactly what inputs produce what outputs.
*   **Regression Protection**: The class carries its own verification logic. If the file is moved or reused in another project, the tests go with it.

### The Boolean Logic Test Suite
The `BooleanLogicEngine` contains the most extensive suite, with over 40 distinct test cases covering:
*   **Unit Tests**: Verifying basic parsing of strings like `P → Q`.
*   **Rule Validation**: Testing every single inference rule (Modus Ponens, Tollens, Syllogism, etc.) with valid and invalid inputs.
*   **Complex Deductions**: Verifying multi-step chains like `((P → Q) ∧ P) ⊢ Q`.
*   **Edge Case Handling**: Specifically targeting:
    *   Empty strings.
    *   Unbalanced parentheses (e.g., `((P)`).
    *   Invalid characters.
    *   Operator precedence (ensuring `∧` binds tighter than `→`).

## 3. Test Data Generation
To test the "fuzzy" systems like Analytics and Difficulty Recommendation, the game includes a procedural data generator. Since we cannot easily "unit test" whether a difficulty recommendation "feels right", we simulate long-term play.

**Function**: `ProgressTracker.debug_populate_test_data()`

This function simulates a human player playing the game for 30 consecutive days. It algorithmically generates a history of session data to verify that the analytics systems behave correctly over time.

### Simulation Parameters
The generator uses randomization seeded with constraints to create realistic data profiles:
*   **Difficulty Progression**: The generator simulates a learning curve, starting the "player" at Level 1 and gradually improving their performance to Level 5 over the 30-day period.
*   **Realistic Variance**: It doesn't just output perfect data. It adds random noise (Perlin-like variance) to scores and mistake rates to simulate bad days, lucky streaks, and plateaus.
*   **Outcome Distribution**: It randomly assigns session outcomes based on realistic probabilities:
    *   **70%**: `time_out` (Standard completed game).
    *   **25%**: `quit` (Rage quit or interruption).
    *   **5%**: `incomplete` (Crash or battery death).

**Usage**: This data allows developers to instantly visualize how the `DifficultyRecommender` will react to a long-term player profile (e.g., "Will it correctly identify that I'm in a Flow State?") without needing to manually play hundreds of hours of gameplay.

### Manual Test Checklist
For QA purposes, the following manual tests are recommended before release:

#### Persistence & Data
1.  **Save System Resilience**:
    *   Action: Play a game, force-close app (Alt+F4) during gameplay, relaunch.
    *   Expected Result: Last session should be missing or marked "incomplete", but overall progress/settings should be intact (no file corruption).
2.  **Encryption Check**:
    *   Action: Open `game_progress.dat` in a text editor.
    *   Expected Result: The file should be binary gibberish, not readable JSON.
3.  **Reset Logic**:
    *   Action: Click "Reset Progress" in Debug menu.
    *   Expected Result: All stats zeroed, achievements locked, file deleted.

#### Networking
4.  **Network Drop**:
    *   Action: Disconnect internet, try to open Leaderboard.
    *   Expected Result: Graceful error message ("Failed to connect"), game does not crash.
5.  **API Latency**:
    *   Action: Use AI Tutor with slow internet.
    *   Expected Result: "Thinking..." indicator persists, UI does not freeze.

#### Gameplay Integrity
6.  **Tutorial Soft-locks**:
    *   Action: Try to click wrong buttons during the First Time Tutorial overlay.
    *   Expected Result: Input is blocked, nothing happens. Tutorial does not advance until correct action is taken.
7.  **PCK Injection**:
    *   Action: Place a modified `content.pck` in the directory.
    *   Expected Result: New levels/logic load correctly without recompiling the main binary.
8.  **Audio Ducking**:
    *   Action: Go to settings, mute SFX.
    *   Expected Result: Gameplay is silent but Music continues (if Music unmuted).

#### Input & UI
9.  **Input Sanitation**:
    *   Action: In AI Tutor chat, type special characters or JSON syntax.
    *   Expected Result: Chat should not break or interpret user text as commands.
10. **Touch Input**:
    *   Action: Play on mobile device.
    *   Expected Result: Buttons are large enough to hit, no double-tap issues.

## Debugging Guide
When tests fail, follow this protocol:
1.  **Isolate**: Run just the `BooleanLogicEngine.test_logic_engine()` call in `_ready()` to see if the core logic is broken.
2.  **Log**: Enable `debug_mode = true` in `GameManager` to see verbose state transitions in the Output.
3.  **Inspect**: Use the Remote Scene Tree to check if UI nodes are correctly instanced during runtime.
4.  **Data**: Check `user://game_progress.dat` (delete it to reset state) if the game crashes on load.

## Future Automated Testing
We plan to introduce a GitHub Actions pipeline that runs the `temp_test_runner.gd` on every push.
*   **Headless Godot**: Using `godot --headless -s temp_test_runner.gd`.
*   **Report Parsing**: Parsing the "✓/✗" output to fail the build if any regression is detected.
*   **Code Coverage**: Measuring which lines of the logic engine are exercised by the test suite.

## Appendix A: Test Runner Script Pseudocode
This outlines the logic of the `temp_test_runner.gd`.

```gdscript
extends SceneTree

func _init():
    print("Starting Tests...")
    var passed = 0
    var total = 0
    
    # 1. Logic Engine
    var logic = load("res://src/managers/BooleanLogicEngineImpl.gd").new()
    if logic.test_logic_engine():
        passed += 1
    total += 1
    
    # 2. Fuel System
    var fuel_test = load("res://test_fuel_system.gd").new()
    add_child(fuel_test) # Needs to be in tree for timers
    # ... async wait ...
    
    print("Results: %d/%d" % [passed, total])
    if passed == total:
        quit(0)
    else:
        quit(1)
```

## Appendix B: Example CI/CD Configuration (Hypothetical)
How the test runner would be integrated into GitHub Actions.

```yaml
name: Godot CI/CD

on: push

jobs:
  test:
    runs-on: ubuntu-latest
    container: barichello/godot-ci:4.2
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Run Tests
        run: godot --headless --script temp_test_runner.gd
        
      - name: Verify Output
        run: |
          if grep -q "✗" test_output.log; then
            echo "Tests Failed!"
            exit 1
          fi
```

## Appendix C: Known Issues (Bug Tracker)
A list of active low-priority bugs for testers to be aware of:
*   [#102] Particle effects may linger if `queue_free` is interrupted by scene change.
*   [#105] Virtual Keyboard caret position resets on `text_changed` (Workaround: Use `caret_column` setter).
*   [#110] Music loop gap on older Android devices (Ogg vs Mp3 issue).
*   [#115] Phase 2 background scroll stutter on high refresh rate monitors (V-Sync conflict).
*   [#120] AI Tutor sometimes generates duplicate premises if prompt is ambiguous.

## Appendix D: Full Log Output Example (Failure Scenario)
If a test fails, the output will look like this:

```text
Starting Tests...
Testing Boolean Logic Engine...
==================================================
✓ Basic expression creation test passed
✗ Expression with operator test passed
  > Expected: Valid, Actual: Invalid
  > Input: "P -> Q"
✗ Complex expression test passed
  > Expected: Valid, Actual: Invalid
  > Input: "(A ^ B) v C"
...
==================================================
Tests completed: 40/42 passed
⚠️  Some tests failed. Engine needs further debugging.
Results: 0/1
Error: Process exited with code 1.
```

## Appendix E: Performance Benchmark Logs
The following table simulates a stress test of the logic engine:

| Iteration | Expression Complexity | Time (ms) | Result |
| :--- | :--- | :--- | :--- |
| 1 | Simple (P->Q) | 0.01 | PASS |
| 2 | Medium ((P^Q)->R) | 0.05 | PASS |
| 3 | Hard (Resolution) | 0.12 | PASS |
| 4 | Very Hard (CD+DD) | 0.45 | PASS |
| 5 | Extreme (8 Vars) | 12.50 | PASS |
| 6 | Overload (12 Vars) | 350.0 | PASS (Slow) |
