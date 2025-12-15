# Data & Analytics

Fusion Rush incorporates a robust, production-grade data layer designed to track player progression, ensure the integrity of save data, and facilitate competitive online features. This system is split into local persistence, session analytics, and cloud synchronization.

## 1. Progress Tracking (`ProgressTracker`)
**Script**: `src/managers/ProgressTrackerImpl.gd`

The `ProgressTracker` is the central singleton responsible for aggregating all player data. It maintains the state of the current game session and commits long-term data to storage.

### Session Metrics
During a gameplay session, the tracker records high-resolution telemetry data to feed into the analytics engine and the Difficulty Recommender:
*   **Score**: The final score achieved in the session.
*   **Duration**: The exact time played in seconds.
*   **Mistakes**: A count of every incorrect rule application. This is a critical metric for the Difficulty Recommender.
*   **Combo**: The maximum combo streak achieved.
*   **Operation Usage**: A dictionary tracking proficiency for every single logic rule (e.g., `Modus Ponens`, `Simplification`).
    *   `count`: Total number of attempts.
    *   `successes`: Total number of valid applications.
    *   `rate`: A derived float (Successes / Attempts) representing mastery.
*   **Completion Status**: Categorizes the session outcome as:
    *   `time_out`: Standard completion (ran out of time).
    *   `quit`: Player aborted (forfeit).
    *   `incomplete`: Session crashed or didn't finish.

### Achievements System
The tracker also manages the achievement system, unlocking rewards based on statistical thresholds. Achievements are stored as a list of string keys (`achievements_unlocked`).
*   **Volume Achievements**: Awarded for persistence (e.g., "Logic Master" for 100 games played, "First Steps" for 1 game).
*   **Skill Achievements**: Awarded for peak performance (e.g., "Score Crusher" for 5000+ points, "Flawless Logic" for a zero-mistake game).
*   **Mastery Achievements**: Awarded for demonstrating proficiency with specific rules.
    *   `rule_modus_ponens_5`: "MP Apprentice" (Use Modus Ponens 5 times).
    *   `rule_double_negation_20`: "Double Negation Master".
    *   `survival_5min`: "Five Minute Frenzy" (Survive for 5 minutes in a single run).

## 2. Secure Persistence (Save System)
Given the potential for competitive leaderboards, the save system is designed to be robust against casual tampering and file corruption.

### Storage Location
Files are stored in the `user://` directory, which maps to OS-specific user data paths:
*   **Android**: Internal app-specific storage (sandboxed from other apps).
*   **Windows**: `%APPDATA%\Roaming\Godot\app_userdata\FusionRush`.

### Encryption Strategy
Instead of plain text JSON, the game uses Godot's binary encryption to prevent easy editing of high scores.
*   **Method**: `FileAccess.open_encrypted_with_pass()`.
*   **Key Generation**: A hybrid key is generated at runtime to ensure that save files are bound to the specific device.
    *   `Salt`: A hardcoded string constant `"BlendNProve_2025_SecureSave_v1"`.
    *   `Device ID`: `OS.get_unique_id()`.
    *   `Key`: `SHA256(Salt + Device_Unique_ID)`.
    *   **Result**: If a user tries to copy a save file from one phone to another, it will fail to load because the Device ID component of the key will not match. This prevents simple leaderboard cheating via save sharing.

### Backup & Recovery
To prevent data loss from crashes or write errors (e.g., battery dying while saving), the system implements a "Double-Write" strategy.
1.  **Backup**: Before any write operation, the existing `game_progress.dat` is copied to `game_progress_backup.dat`.
2.  **Write**: The new data is written to the main file.
3.  **Recovery**: On startup, if the main file fails to load (returns error or invalid JSON), the system automatically attempts to load the backup file.

### Save File Schema (JSON)
The save file is a binary-encrypted JSON blob. Here is the unencrypted schema for reference:
```json
{
  "version": "2.0",
  "last_saved": "2025-12-13T10:00:00",
  "statistics": {
    "total_games_played": 42,
    "high_score_overall": 15000,
    "total_play_time": 3600.5,
    "average_score_overall": 4500.0,
    "average_session_duration_overall": 120.5,
    "games_ended_by_time_out": 38,
    "games_ended_by_quit": 4,
    "achievements_unlocked": [
      "first_game", 
      "rule_modus_ponens_5",
      "score_crusher",
      "survival_5min"
    ],
    "operation_proficiency": {
      "Modus Ponens": {
        "count": 50,
        "successes": 48,
        "rate": 0.96
      },
      "Resolution": {
        "count": 10,
        "successes": 4,
        "rate": 0.40
      }
    },
    "tutorials_completed": 5,
    "tutorial_completions": {
      "tutorial_basics": [0, 1, 2],
      "modus_ponens": [0]
    },
    "favorite_difficulty": 3
  },
  "recent_sessions": [
    {
      "timestamp": "2025-12-13T09:30:00",
      "score": 1200,
      "status": "time_out",
      "difficulty": 3,
      "mistakes": 1,
      "duration": 180.0,
      "operations_used": {
          "Modus Ponens": {"count": 2, "successes": 2}
      }
    }
  ]
}
```

## 3. External Services (Cloud & Leaderboards)

### Supabase Integration
**Script**: `src/managers/SupabaseServiceImpl.gd`
The game integrates with a Supabase backend to provide global daily leaderboards.

*   **API Architecture**: The client communicates via REST V1 endpoints (`/rest/v1/leaderboard`).
*   **Platform Specifics**:
    *   **Desktop/Mobile**: Uses the native Godot `HTTPRequest` node for stable, blocking networking.
    *   **Web (HTML5)**: Due to CORS restrictions and gzip compression issues common in Godot Web exports, the web build uses a custom **JavaScript Bridge**. It executes raw JavaScript `fetch()` calls via `JavaScriptBridge.eval()` and passes the JSON response back to Godot via `window` callbacks.
*   **Optimization**: To prevent API rate limiting and reduce lag, the service implements a 30-second client-side cache for leaderboard data.

### GDScript vs JavaScript Bridge
To handle the platform differences, the service detects the OS and swaps logic:

| Feature | Desktop/Mobile (GDScript) | Web (JavaScript Bridge) |
| :--- | :--- | :--- |
| **Request Method** | `HTTPRequest.request()` | `fetch()` via `eval()` |
| **Response Handling** | Signal `request_completed` | Window callback function |
| **CORS Handling** | N/A (Native) | Browser Policy (Requires headers) |
| **Config Source** | `.env` file | `window.SUPABASE_URL` |

### Cloud Synchronization (Planned Feature)
The architecture includes hooks for a future "Cloud Save" feature to allow cross-device progression.
*   **Periodic Uploads**: The game will periodically upload the encrypted `game_progress.dat` blob to a user-specific bucket in Supabase.
*   **Conflict Resolution**: A timestamp comparison logic is planned for the `ManagerBootstrap`.
    *   If `Cloud_Timestamp > Local_Timestamp`: Prompt user to download cloud save.
    *   If `Local_Timestamp > Cloud_Timestamp`: Queue background upload.
*   **Authentication**: This relies on the implementation of the Supabase Auth system to link the device ID to a persistent user account.

## 4. Content Pipeline ("Docs as Code")
To streamline content creation, Fusion Rush decouples data from code. This "Docs as Code" approach allows non-technical team members to contribute.
*   **Authoring**: Game designers write logic puzzles in human-readable Markdown files (`docs/game/*.md`).
*   **Compilation**: A TypeScript tool (`devtools/extract_problems.ts`) parses these files, extracting premises, conclusions, and metadata.
*   **Output**: The tool compiles the data into optimized JSON files (`data/classic/*.json`) that the game loads at runtime.
This allows for rapid iteration on game balance without requiring a rebuild of the game binary.

### Example: Source Markdown vs Output JSON

**Input (`modus_ponens.md`)**:
```markdown
# Modus Ponens
## Problem 1 (Easy)
**Premises:**
- P -> Q
- P
**Conclusion:**
Q
**Solution:**
Apply Modus Ponens.
```

**Output (`level-1.json`)**:
```json
{
  "level": 1,
  "problems": [
    {
      "premises": ["P -> Q", "P"],
      "conclusion": "Q",
      "difficulty": "Easy",
      "solution": "Apply Modus Ponens."
    }
  ]
}
```

### Data Migration Guide
When updating the save schema (e.g., `SAVE_VERSION` 2.0 to 3.0):
1.  **Version Check**: The `load_progress_data` function checks `save_data["version"]`.
2.  **Migration Function**: A private `_migrate_save_data(old_data)` function creates a new dictionary structure, mapping old fields to new ones (e.g., renaming `streaks` to `combo`).
3.  **Defaults**: New fields must have safe defaults (e.g., `0` or `false`) to preventing crashing when loading old saves.

### Privacy & Compliance
*   **GDPR**: The game stores no personally identifiable information (PII) by default. The "Device ID" is hashed before use.
*   **Opt-Out**: Users can disable cloud sync (when implemented), keeping all data strictly local to the device.
*   **Transparency**: The analytics system only uploads gameplay metrics (scores, mistakes), not behavioral data or microphone input.

## Appendix A: Full API Specification
This defines the JSON interface expected by the Supabase Edge Functions.

### Leaderboard POST
**Endpoint**: `/rest/v1/leaderboard`
**Method**: `POST`
**Headers**: `apikey`, `Authorization`
**Body**:
```json
{
  "three_name": "ABC",
  "game_score": 15000,
  "game_time": "PT180S",
  "game_level": 6,
  "device_hash": "a1b2c3d4..."
}
```

### Leaderboard GET
**Endpoint**: `/rest/v1/leaderboard`
**Method**: `GET`
**Query**: `?select=*&order=game_score.desc&limit=10&created_at=gte.TODAY`
**Response**:
```json
[
  {
    "id": 1,
    "three_name": "ACE",
    "game_score": 20000
  },
  {
    "id": 2,
    "three_name": "BOB",
    "game_score": 18500
  }
]
```

### Error Codes
*   **200**: OK.
*   **201**: Created (Score Submitted).
*   **400**: Bad Request (Invalid JSON).
*   **401**: Unauthorized (Bad API Key).
*   **429**: Too Many Requests (Cache Hit required).