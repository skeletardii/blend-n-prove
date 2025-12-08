# Project Summary: Boolean Logic Bartender

## Tech Stack
*   **Game Engine:** Godot Engine 4.5 (Compatible with 4.4+)
*   **Language:** GDScript
*   **Platform:** Mobile-first (Android/iOS), Web, PC (Windows/Linux/macOS)
*   **Rendering:** GL Compatibility (OpenGL ES 3.0 / WebGL 2.0)
*   **Architecture:** Node-based Scene Tree, Autoload Singletons for state management
*   **Data Serialization:** JSON for levels and progress persistence
*   **Backend Service:** Supabase for server connections, user accounts, and stats uploads.
*   **Integration:** Godot MCP (Model Context Protocol) addon for AI/Tool integration
*   **Build System:** Export to Android APK (Base) + Downloadable Content (PCK)

## Essential Transactions or Main Features
*   **Two-Phase Gameplay:**
    1.  **Premise Building:** Constructing logical statements from customer requirements.
    2.  **Logical Transformation:** Applying formal logic rules to derive conclusions.
*   **Logic Puzzle Engine:** Validates 33+ boolean operations in real-time.
*   **PCK Update System:** Splits the app into a lightweight Base APK (~3MB) and a downloadable Content Pack (~31MB) for easier updates.
*   **Natural Language Translation:** Bridge between English sentences and formal logical notation (Level 6).
*   **Save & Resume:** Persistent state tracking with auto-backups and corruption recovery.

## Modules based on Functional Requirements

### Game Engine (Core Systems)
*   **BooleanLogicEngine:** The heart of the game. Handles parsing, validation, and transformation of logical expressions (1,700+ lines).
    *   Supports 8 operators (AND, OR, XOR, NOT, IMPLIES, etc.).
    *   Implements 13 Inference Rules (Modus Ponens, Resolution, etc.).
    *   Implements 20+ Equivalence Laws (De Morgan's, Distributivity, etc.).
*   **GameManager:** State machine handling game flow (Menu -> Playing -> Paused -> Game Over).
*   **UpdateCheckerService:** Manages version checking and downloading of external PCK content.

### Player Controls
*   **Touch Interface:** Optimized for 720x1280 portrait mode.
*   **Phase 1 Controls:** Custom virtual keyboard for entering variables (P, Q, R...) and symbols (∧, ∨, →...).
*   **Phase 2 Controls:** 
    *   **Inventory Grid:** Selectable cards for available premises.
    *   **Operation Panel:** 2-page grid of buttons for logic rules (MP, MT, ADD, etc.).
    *   **Gesture/Tap:** Tap to select, auto-apply when requirements met.

### Customer Interactions
*   **Simulation Metaphor:** Logic puzzles are presented as "drink orders" from customers.
*   **Requests:** Displayed in speech bubbles as a checklist of required premises.
*   **Feedback:** Visual and audio cues for correct/incorrect inputs and order completion.
*   **Patience:** Time constraint represented by a visual bar; customers leave if it depletes.

### Ingredients Interactions
*   **Logical Premises:** Treated as "ingredients".
*   **Combination:** Two premises can be combined (e.g., `P→Q` + `P`) to create a new one (`Q`).
*   **Transformation:** Single premises can be altered (e.g., `P∧Q` -> `P`).
*   **Inventory:** Generated conclusions are added to the player's "bar counter" (inventory) for further use.

### Stage Interactions
*   **Levels:** 6 distinct difficulty stages.
    *   Levels 1-5: Formal symbolic logic.
    *   Level 6: Natural Language Logic.
*   **Order Flow:** Preparation (Phase 1) -> Mixing/Serving (Phase 2).
*   **Transition:** Automatic progression between phases upon validation.

### Difficulty Scaling
*   **Progressive Complexity:**
    *   Level 1: 1 Step operations.
    *   Level 6: 5+ Step proofs + Translation.
*   **Adaptive Mode:** Auto-scales based on player progress.
*   **Manual Mode:** Debug tools allow locking difficulty to a specific level (1-6).

### Progress Tracking
*   **Session Data:** Score, difficulty, lives, time, operations used.
*   **Analytics:**
    *   Win rate & Streak tracking.
    *   Per-operation proficiency (success/fail rate for each rule).
    *   "Favorite" difficulty level.
    *   Analytics are uploaded to Supabase for server-side persistence and leaderboards.
*   **Persistence:** JSON storage (`user://game_progress.json`) with rollback protection.

### Progress Exporting
*   **Data Export:** Capability to export all progress data to JSON.
*   **Backup:** Automatic `game_progress_backup.json` creation to prevent data loss.
*   **Server Sync:** Save data is uploaded to Supabase and linked to user accounts for cloud synchronization.

### Score Trends
*   **High Scores:** Tracked overall and per-difficulty level.
*   **Win Streaks:** Rewards consistency (5, 10, 20 game streaks).
*   **Performance Metrics:** Average score tracking to show improvement over time.

### Score Calculation and Management
*   **Base Score:** +100 points per validated premise/step.
*   **Bonuses:** Speed and efficiency bonuses.
*   **Lives:** 3 "Hearts". Mistakes (syntax errors, invalid logic) deduct lives. 0 Lives = Game Over.

### Tutorial
*   **Structure:** 18 distinct modules covering specific rules (e.g., "Modus Ponens", "De Morgan's").
*   **Content:** ~180 curated problems ranging from Easy to Very Hard.
*   **Interactive Help:** In-game overlay explaining rules during play.

### Rule Demos
*   **Interactive Learning:** Each tutorial acts as a specific demo for a rule.
*   **Visual Feedback:** Highlights valid inputs for the selected rule to guide the player.

### Tutorial Progress Tracking
*   **Completion Status:** Tracks "Completed" state for each of the 18 modules.
*   **Problem Mastery:** Individual checkboxes for every problem within a tutorial.
*   **Achievements:** Unlocks for completing 1, 5, 10, and All tutorials.

### Experimental Mode
*   **Debug/Sandbox:** Accessed via keyboard shortcuts (D).
*   **Features:**
    *   **Infinite Patience:** Removes time pressure.
    *   **Force Difficulty:** Override standard scaling.
    *   **Test Runners:** Execute logic engine tests on the fly.

### Main Menu
*   **Central Hub:** Navigation to all sub-systems.
*   **Dynamic States:** Handles "First Launch" vs "Returning User".
*   **PCK Loader:** Checks for and downloads game content if missing before showing the menu.

### Navigation Buttons
*   **Play:** Start Classic Mode.
*   **Tutorial:** Open Grid Selection.
*   **Progress:** View Stats/Achievements.
*   **Settings:** Audio/Config.
*   **Debug:** (Hidden/Shortcut) Developer tools.

### Scores Display
*   **In-Game HUD:** Real-time score, lives, and level indicator.
*   **Game Over Screen:** Summary of the session performance.
*   **Progress Dashboard:** Detailed statistical breakdown.

### Settings and Other Options
*   **Audio Control:** Master, Music, and SFX volume sliders (linear to decibel conversion).
*   **Mute:** Global toggle.
*   **Reset:** Option to wipe progress.
*   **Version Info:** Displays current App and PCK version.
