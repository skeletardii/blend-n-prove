# Data, Progress Tracking, and Storage Analysis

This document provides a technical analysis of how the application manages data, tracks player progress, and handles persistent storage.

## 1. Data Structures

The core data structures are defined in `src/managers/ProgressTrackerTypes.gd`.

### 1.1 Game Session (`GameSession`)
Represents a single playthrough session.
- **Metrics:** `final_score`, `difficulty_level`, `lives_remaining`, `orders_completed`, `session_duration`.
- **Status:** `completion_status` (win, loss, quit, incomplete).
- **Metadata:** `timestamp`.
- **Analytics:** `operations_used` (dictionary tracking count and success rate of specific logic operations).

### 1.2 Player Statistics (`PlayerStatistics`)
Aggregates long-term player data.
- **Global Stats:** `total_games_played`, `total_play_time`, `total_orders_completed`.
- **Performance:** `high_score_overall`, `average_score_overall`, `success_rate`.
- **Difficulty Tracking:** `high_scores_by_difficulty`, `average_scores_by_difficulty`, `highest_difficulty_mastered`, `favorite_difficulty`.
- **Streaks:** `current_streak`, `best_streak`.
- **Learning Analytics**:
    - `operation_proficiency`: Tracks success rate for specific logic rules (e.g., Modus Ponens).
    - `common_failures`: Tracks where the player struggles.
- **Progression**:
    - `achievements_unlocked`: List of unlocked achievement IDs.
    - `tutorial_completions`: Dictionary mapping tutorial keys to arrays of completed problem indices.

## 2. Storage & Security

The storage implementation is handled by `src/managers/ProgressTrackerImpl.gd`.

### 2.1 File System
The game uses the `user://` directory, which maps to:
- **Windows:** `%APPDATA%\Godot\app_userdata\[ProjectName]\`
- **Android:** `/data/data/[PackageName]/files/` (internal app storage).

**Files:**
- **Primary Save:** `user://game_progress.dat`
- **Backup Save:** `user://game_progress_backup.dat`
- **Export File:** `user://game_progress_export.dat`

### 2.2 Encryption
To prevent casual tampering, save files are encrypted using Godot's `FileAccess.open_encrypted_with_pass`.
- **Key Generation:** SHA-256 hash of a **hardcoded salt** (`"BlendNProve_2025_SecureSave_v1"`) combined with the **device's unique ID** (`OS.get_unique_id()`)
- **Implication:** Save files are **device-bound**. A file copied to another device will fail to decrypt because the `OS.get_unique_id()` will differ.

### 2.3 Reliability
- **Atomic-like Saves:** The system reads the current valid save and writes it to the *backup* file before overwriting the main save file.
- **Recovery:** If loading the main file fails (corruption or wrong key), the system automatically attempts to load from the backup file.
- **Versioning:** The save data includes a `version` field (currently "2.0") to handle future schema migrations.

## 3. Progress Tracking Lifecycle

### 3.1 Session Lifecycle
1.  **Start:** `GameManager` calls `ProgressTracker.start_new_session(difficulty)`.
2.  **Update:** During gameplay, `ProgressTracker.record_operation_used()` is called to update analytics.
3.  **End:** `GameManager` calls `ProgressTracker.complete_current_session()`.
    - This triggers `update_statistics()` to aggregate the session data into global stats.
    - It runs `check_achievements()` to unlock new milestones.
    - It triggers `save_progress_data()` to write to disk.

### 3.2 Tutorial Progress
- Tracks completion at the *problem* level.
- `ProgressTracker.complete_tutorial_problem(key, index)` updates the `tutorial_completions` map.
- Checks are performed to see if an entire tutorial set is finished (`is_tutorial_fully_completed`).
- Unlocks specific tutorial-related achievements.

### 3.3 Achievements
Achievements are checked automatically at the end of sessions or when tutorials are completed.
- **Criteria:** Games played, perfect games, score thresholds, streaks, difficulty mastery.
- **Notification:** Emits `achievement_unlocked` signal for UI display.

## 4. Game Content Data

### 4.1 Level Data
- **Location:** `res://data/classic/level-*.json`.
- **Format:** JSON files defining logical problems (premises, conclusions, solutions).
- **Loading:** `GameManagerImpl` loads these into `order_templates` at runtime.

### 4.2 Tutorial Data
- **Location:** Inferred to be in `res://data/tutorial/` or similar (managed by `TutorialDataManager`).
- **Structure:** Defined by `TutorialData` and `ProblemData` classes.

## 5. Export & Import
- **Export:** Serializes current state to `user://game_progress_export.dat` (encrypted with the current device's key).
- **Import:** Reads and merges data from an export file.
    - **Limitation:** Since the key is device-specific, the export/import feature is currently only useful for backing up on the *same* device, not transferring between devices (unless the key generation logic is changed).

## 6. Recommendations
1.  **Device Transfer:** The current encryption scheme prevents moving saves between devices. If cloud save or cross-device play is a requirement, the key generation must optionally support a user-provided password or a server-synced key.
2.  **Migration:** The code references "future version migration logic". As the game evolves, implementing specific data transformation functions for version upgrades will be critical.
