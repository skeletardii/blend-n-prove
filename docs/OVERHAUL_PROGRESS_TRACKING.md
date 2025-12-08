## Revised Proposal: Overhauling Progress Tracking for a High-Score "Time-Out" Game

## 1. Core Philosophy Shift

The game's primary objective is to maximize score and successfully solve as many logical problems as possible *before a set time limit expires*. The concept of "hearts" or "lives" is eliminated. Game over occurs exclusively when time runs out.

## 2. Revised Session Completion Logic

A game session now ends primarily under two conditions:

1.  **Time Out:** The session clock reaches zero. This is the natural "Game Over" state.
2.  **Quit:** The player manually exits the session before the time limit expires.

The `completion_status` in `GameSession` will therefore primarily be `time_out` or `quit`.

## 3. Data to Track per Session (`GameSession` - `ProgressTrackerTypes.gd`)

The `GameSession` class needs to be updated to capture metrics relevant to a high-score, time-constrained game:

### Existing (Keep & Re-evaluate):
-   `final_score: int = 0`: This remains the paramount metric.
-   `difficulty_level: int = 1`: Essential for difficulty-specific high scores.
-   `orders_completed: int = 0`: How many problems/orders were successfully processed in this session.
-   `session_duration: float = 0.0`: The actual time played in the session.
-   `completion_status: String = "time_out"`: (Updated to accept `"time_out"` or `"quit"`).
-   `timestamp: String = ""`: (Keep).
-   `operations_used: Dictionary = {}`: (Keep - crucial for learning analytics, detailed explanation below).

### New (Add):
-   `time_limit_seconds: float = 0.0`: The initial time given for this session's game mode.
-   `time_remaining_on_quit: float = 0.0`: Only relevant if `completion_status` is `"quit"`.
-   `max_active_combo: int = 0`: The highest combo achieved within this session (consecutive successful problem solutions).
-   `mistakes_count: int = 0`: Total number of incorrect rule applications or critical errors leading to penalties.

### Remove:
-   `lives_remaining`, `hearts_lost_this_session`, `initial_hearts`, `hearts_remaining_at_quit` and any other heart-related properties.

## 4. Analytics & Statistics: Deriving Insights and Tracking Player Performance

The `update_statistics()` method in `ProgressTrackerImpl.gd` will be heavily modified to calculate new aggregate statistics reflecting score and time-based performance.

### 4.1 Player Statistics (`PlayerStatistics` - `ProgressTrackerTypes.gd`)

The `PlayerStatistics` class needs significant revision:

#### Existing (Keep & Refine):
-   `total_games_played: int = 0`: (Keep).
-   `high_score_overall: int = 0`: (Keep, highest score achieved before time ran out or quitting).
-   `high_scores_by_difficulty: Dictionary`: (Keep, stores highest score per difficulty).
-   `average_score_overall: float = 0.0`: (Re-calculated based on all sessions).
-   `average_scores_by_difficulty: Dictionary`: (Re-calculated).
-   `total_play_time: float = 0.0`: (Keep, total accumulated play time).
-   `highest_difficulty_mastered: int = 1`: (Keep, re-defined based on score/time thresholds).
-   `favorite_difficulty: int = 1`: (Keep).
-   `total_orders_completed: int = 0`: (Keep as a global aggregate).
-   `achievements_unlocked: Array[String] = []`: (Keep).
-   `tutorial_completions: Dictionary`: (Keep).
-   `tutorials_completed: int = 0`: (Keep).

#### Remove:
-   `total_successful_games`, `success_rate`, `current_streak`, `best_streak` (as they were tied to "win/loss").

#### New (Add):
-   `average_session_duration_overall: float = 0.0`
-   `longest_session_duration_overall: float = 0.0` (How long a player survived before time ran out or quit).
-   `average_orders_per_game_overall: float = 0.0`
-   `longest_orders_combo_overall: int = 0`: The highest number of consecutive problems solved in any single game session.
-   `games_ended_by_time_out: int = 0`
-   `games_ended_by_quit: int = 0`
-   `average_time_remaining_on_quit: float = 0.0` (useful to know if players quit near the end or early).

## 5. Progression: Achievements & Mastery

### 5.1 Achievements (`check_achievements()` - `ProgressTrackerImpl.gd`)
Achievements will be revised to reward high scores, efficient play, and endurance against the clock.

#### Existing (Re-evaluate/Rename):
-   `"first_game"`: Still applicable.
-   `"perfect_game"`: Can be redefined as "Reach X score with 0 mistakes" or "Complete X problems with 0 mistakes".
-   `*_games` milestones (e.g., `10_games`): Still applicable.
-   `*_streak` achievements: Can be re-imagined as "Longest Order Combo" (consecutive problems solved within a session).
-   `*_score` milestones (e.g., `500_score`, `1000_score`): Even more relevant now.
-   `master_difficulty_*`: Can be redefined as "Reach X score on Difficulty Y" or "Complete X orders on Difficulty Y" before time runs out.
-   Tutorial achievements: Still applicable.
-   Rule usage achievements: Still applicable and very valuable for learning analytics.

#### New Achievement Ideas (Time & Efficiency Focused):
-   **Survival Time:** "Survive for 5 minutes in a single game", "Survive for 10 minutes".
-   **Order Count:** "Complete 10 orders in a single game", "Complete 20 orders".
-   **No Quit:** "Play 5 games until time runs out".
-   **Efficiency:** "Complete X problems in Y seconds."
-   **Combo Master:** "Achieve a combo of X orders."
-   **Speed Demon:** "Solve a problem in under X seconds (average)."

### 5.2 Difficulty Mastery (`highest_difficulty_mastered`)
-   **Logic Change:** Instead of "3 wins in the last 10 sessions", mastery could be defined by consistently achieving a *high score threshold*, a *high orders completed threshold*, or a *survival duration threshold* on a given difficulty.
-   **Example:** `highest_difficulty_mastered` = Difficulty `X` if player has achieved `Y` score or completed `Z` orders on `X` difficulty in their top 3 recent `time_out` sessions.

## 6. Implementation Impact

### `ProgressTrackerTypes.gd`
-   Update `GameSession` and `PlayerStatistics` classes with new fields and remove irrelevant ones.

### `ProgressTrackerImpl.gd`
-   **`start_new_session()`**: Potentially add `time_limit_seconds` parameter.
-   **`complete_current_session()`**:
    -   Update `completion_status` to only accept `time_out` or `quit`.
    -   Pass `final_score`, `orders_completed`, `session_duration`, `time_remaining_on_quit` (if quit), and `mistakes_count`.
-   **`update_statistics()`**: This function will require a complete rewrite to:
    -   Increment `games_ended_by_time_out` or `games_ended_by_quit`.
    -   Update all new average, longest, and total statistics.
    -   Remove `current_streak`, `best_streak`, `total_successful_games`, `success_rate` calculations.
    -   Redefine how `highest_difficulty_mastered` is calculated.
-   **`check_achievements()`**: Update the logic to reflect the new achievement criteria and add new achievement checks.

### `GameManagerImpl.gd`
-   **`start_new_game()`**: Will need to set up the `time_limit_seconds` for the session.
-   **`complete_progress_session()`**: Must correctly pass the new `completion_status` (`time_out` or `quit`) and new time-related metrics to `ProgressTracker`.
-   **Timer Logic**: Ensure that when the session timer runs out, `complete_progress_session("time_out")` is called.
-   `record_operation_used()`: Keep as is (relevant for operation proficiency).

---

## Detailed Explanation of Existing Operation Proficiency Tracking

The game already includes a robust system for tracking a player's proficiency with specific logical operations, which is a key component of the "learning analytics." This system operates independently of the game's overall "win" or "loss" state, making it highly suitable for your revised "time-out" game.

### How it Works (`ProgressTrackerImpl.gd` `record_operation_used` function):

1.  **Triggering the Tracking:**
    *   In the `Phase2UI.gd` script (which handles the core gameplay logic for applying rules), whenever a player successfully applies a logical rule (e.g., Modus Ponens, Conjunction, Addition), the `ProgressTracker.record_operation_used()` function is called.
    *   This call includes two crucial pieces of information:
        *   `operation_name: String`: The name of the logical rule that was just attempted (e.g., "Modus Ponens", "Conjunction").
        *   `success: bool`: A boolean indicating whether the application of that rule was successful (`true`) or resulted in a failure/error (`false`).

2.  **Updating Global Usage Count (`statistics.operation_usage_count`):**
    *   The `record_operation_used` function first increments a global counter for each `operation_name` in `statistics.operation_usage_count`. This gives a raw count of how many times a player has *attempted* to use a particular rule across all sessions.

3.  **Updating Proficiency (`statistics.operation_proficiency`):**
    *   Next, the system updates `statistics.operation_proficiency`. This is a dictionary where each key is an `operation_name`, and its value is another dictionary containing detailed statistics for that rule:
        *   `"total"`: The total number of times the rule has been *attempted*.
        *   `"successes"`: The number of times the rule has been *successfully applied*.
        *   `"rate"`: A calculated floating-point value representing the success rate (`successes / total`).

    *   **Example Structure:**
        ```gdscript
        statistics.operation_proficiency = {
            "Modus Ponens": {
                "total": 50,
                "successes": 45,
                "rate": 0.90
            },
            "Conjunction": {
                "total": 30,
                "successes": 25,
                "rate": 0.83
            },
            # ... and so on for all tracked operations
        }
        ```

### Purpose and Benefits:

*   **Identifies Strengths & Weaknesses:** This data directly shows which logical rules the player understands well (high success rate) and which ones they struggle with (low success rate).
*   **Personalized Feedback:** Future UI elements could use this information to give tailored advice, suggest practicing specific rules, or highlight areas for improvement.
*   **Game Design Insights:** Developers can analyze aggregated player data (if collected) to identify rules that are inherently difficult or confusing for the player base, informing future tutorial design or rule rebalancing.
*   **Achievement Opportunities:** As demonstrated by the rule-specific achievements I added, this tracking allows for rewarding players for mastering individual logic operations.

This system provides valuable fine-grained data about a player's understanding of the game's core mechanics, which is highly beneficial for both player experience and game development.