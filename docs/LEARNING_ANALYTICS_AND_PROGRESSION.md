# Learning Analytics, Progression, and General Analytics

This document details the systems used to track player skill, game progression, and general usage statistics.

## 1. Learning Analytics
**Goal:** Measure the player's proficiency with specific logic rules to identify strengths and weaknesses.

### How it Works
The system tracks every time a player attempts to use a logic operation (e.g., "Modus Ponens", "AND Introduction").

**Implementation:** `ProgressTrackerImpl.record_operation_used(operation_name, success)`

1.  **Data Capture:**
    *   When a player applies a rule, the `GameManager` calls `record_operation_used`.
    *   It records the **Operation Name** (e.g., "Modus Ponens") and the **Outcome** (`true` for success, `false` for failure).

2.  **Metrics Stored:**
    The data is aggregated in `statistics.operation_proficiency` as a dictionary:
    ```gdscript
    "Modus Ponens": {
        "total": 50,       # Total attempts
        "successes": 45,   # Successful applications
        "rate": 0.9        # 90% proficiency
    }
    ```

3.  **Usage:**
    *   **Immediate Feedback:** Can be used to show "You are struggling with Modus Tollens" hints (future feature).
    *   **Long-term Analysis:** Helps design better tutorials by identifying which rules players find most unintuitive.

## 2. Progression System
**Goal:** Provide a sense of advancement and unlockable milestones.

### 2.1 Achievements
**Implementation:** `ProgressTrackerImpl.check_achievements()`
The system automatically checks for milestones at the end of every session:

*   **Milestones:**
    *   **Firsts:** `first_game`, `first_tutorial`.
    *   **Volume:** 10, 50, 100 games played.
    *   **Skill:** `perfect_game` (no lives lost), win streaks (5, 10, 20).
    *   **Score:** 1000, 5000, 10000 points.
    *   **Mastery:** `master_difficulty_1` through `master_difficulty_5`.

*   **Notification:** Emits the `achievement_unlocked` signal, which the UI listens to for displaying popups.

### 2.2 Tutorial Progression
**Implementation:** `ProgressTrackerImpl.complete_tutorial_problem()`
*   **Granularity:** Tracks progress at the specific *problem* level (e.g., "Tutorial 1, Problem 3").
*   **Completion:** A tutorial set is marked "complete" only when all its constituent problems are solved.
*   **Rewards:** Unlocks specific achievements for completing 1, 5, 10, or all tutorials.

### 2.3 Difficulty Mastery
**Implementation:** `ProgressTrackerImpl.update_statistics()`
The system dynamically calculates a "Mastery Level":
*   **Logic:** It looks at the last 10 games played at a specific difficulty.
*   **Criteria:** If the player has won at least 3 of those games, that difficulty is considered "Mastered".
*   **Usage:** This `highest_difficulty_mastered` stat can be used by the UI to visually badge difficulty levels or gate progress (though strict gating is not currently enforced in the `GameManager`).

## 3. General Analytics
**Goal:** Track high-level engagement and performance metrics.

### 3.1 Session Analytics
Recorded at the end of every game in `ProgressTrackerImpl.complete_current_session()`:
*   **Score:** Final score achieved.
*   **Duration:** Time spent in the session.
*   **Outcome:** Win, Loss, or Quit.
*   **Efficiency:** Lives remaining and orders completed.

### 3.2 Global Statistics
Aggregated in `ProgressTrackerImpl.update_statistics()`:
*   **Volume:** Total games played, total play time.
*   **Performance:**
    *   **High Scores:** Tracked overall and *per difficulty level*.
    *   **Average Scores:** useful for seeing improvement over time.
    *   **Win Rate:** `total_successful_games` / `total_games_played`.
*   **Engagement:**
    *   **Streaks:** Current and best win streaks.
    *   **Favorite Difficulty:** The difficulty level played most frequently.

## 4. Summary of Data Flow
1.  **Gameplay Action:** Player uses a rule -> `GameManager` calls `ProgressTracker`.
2.  **Session Update:** Data is stored in temporary `current_session` object.
3.  **Game End:** `current_session` is finalized -> `Global Statistics` are updated -> `Achievements` checked -> Data saved to disk (encrypted).
