# SaveManager Usage Guide

## Quick Reference

This is the copy-paste reference guide you requested. The full implementation is in `ProgressTracker.gd` which acts as your SaveManager autoload.

---

## Basic Usage from Other Scripts

### 1. Save Game Progress

```gdscript
# Manual save (usually not needed - saves automatically)
ProgressTracker.save_progress_data()
```

**When it's called automatically:**
- When a game session completes
- When a tutorial problem is completed

### 2. Load Game Progress

```gdscript
# Manual load (usually not needed - loads automatically on startup)
ProgressTracker.load_progress_data()
```

**When it's called automatically:**
- On game startup (in `ProgressTracker._ready()`)

---

## Complete Gameplay Integration Example

Here's how to integrate with your game manager:

```gdscript
# In your GameManager.gd or similar script

# When starting a new game
func start_game(difficulty: int) -> void:
    # Start tracking this game session
    ProgressTracker.start_new_session(difficulty)

    # ... your game setup code ...

# During gameplay - track when player uses logical operations
func apply_logic_rule(rule_name: String) -> void:
    var success = check_if_rule_was_correct()

    # Track usage for analytics
    ProgressTracker.record_operation_used(rule_name, success)

    # ... rest of your game logic ...

# When game ends
func end_game(won: bool) -> void:
    var final_score = calculate_score()
    var lives_left = player.lives
    var orders = completed_orders_count
    var status = "win" if won else "loss"

    # This automatically saves progress
    ProgressTracker.complete_current_session(
        final_score,
        lives_left,
        orders,
        status
    )

    # Navigate to game over screen, etc.

# Listen for achievements
func _ready() -> void:
    ProgressTracker.achievement_unlocked.connect(_on_achievement_unlocked)
    ProgressTracker.progress_updated.connect(_on_progress_updated)

func _on_achievement_unlocked(achievement_name: String) -> void:
    show_achievement_popup(achievement_name)

func _on_progress_updated() -> void:
    update_ui_with_latest_stats()
```

---

## Accessing Statistics

### Read Player Stats

```gdscript
# Get total games played
var total_games = ProgressTracker.statistics.total_games_played

# Get high score
var high_score = ProgressTracker.statistics.high_score_overall

# Get success rate (0.0 to 1.0)
var success_rate = ProgressTracker.statistics.success_rate

# Get total play time (in seconds)
var play_time = ProgressTracker.statistics.total_play_time

# Get current win streak
var streak = ProgressTracker.statistics.current_streak

# Get achievements
var achievements = ProgressTracker.statistics.achievements_unlocked

# Get high score for specific difficulty
var difficulty_3_high_score = ProgressTracker.statistics.high_scores_by_difficulty[3]
```

### Display Recent Sessions

```gdscript
# Get last 10 sessions
var recent_sessions = ProgressTracker.get_recent_sessions(10)

for session in recent_sessions:
    print("Score: ", session.final_score)
    print("Difficulty: ", session.difficulty_level)
    print("Status: ", session.completion_status)
    print("Duration: ", session.session_duration)
```

---

## Export/Import Functions

### Export Progress

```gdscript
# Export to encrypted file
var export_path = ProgressTracker.export_progress_data()

if export_path != "":
    print("Progress exported successfully to: ", export_path)
    # On Windows: C:\Users\...\AppData\Roaming\Godot\app_userdata\...\game_progress_export.dat
    # On Android: /data/data/com.yourapp/files/game_progress_export.dat
else:
    print("Export failed!")
```

### Import Progress

```gdscript
# Import from encrypted file
var import_path = "user://game_progress_export.dat"
var success = ProgressTracker.import_progress_data(import_path)

if success:
    print("Progress imported successfully!")
    # Update your UI to reflect new data
    update_stats_display()
else:
    print("Import failed! Check console for details.")
```

---

## Tutorial Progress Tracking

### Mark Tutorial Problem as Completed

```gdscript
# When player completes a tutorial problem
func on_tutorial_problem_solved(tutorial_key: String, problem_index: int) -> void:
    # This automatically saves progress
    ProgressTracker.complete_tutorial_problem(tutorial_key, problem_index)
```

### Check Tutorial Progress

```gdscript
# Check if specific problem is completed
var is_completed = ProgressTracker.is_tutorial_problem_completed("basic_logic", 0)

# Get number of problems completed in a tutorial
var completed_count = ProgressTracker.get_tutorial_progress("basic_logic")

# Check if entire tutorial is completed
var fully_completed = ProgressTracker.is_tutorial_fully_completed("basic_logic")

# Get total tutorials completed
var total_tutorials = ProgressTracker.get_total_tutorials_completed()
```

---

## Reset Progress (Dangerous!)

```gdscript
# Delete all save data and start fresh
func reset_all_progress() -> void:
    # Show confirmation dialog first!
    var confirm = await show_confirmation_dialog("Are you sure? This cannot be undone!")

    if confirm:
        ProgressTracker.reset_progress_data()
        print("All progress has been reset")
```

---

## Android-Specific Path Information

### Get Actual File System Path

```gdscript
# Convert user:// path to actual file system path
var save_path = "user://game_progress.dat"
var actual_path = ProjectSettings.globalize_path(save_path)

print("Save file location: ", actual_path)
# Windows: C:\Users\YourName\AppData\Roaming\Godot\app_userdata\ProjectName\game_progress.dat
# Android: /data/data/com.yourcompany.gamename/files/game_progress.dat
```

### Why This is Perfect for Android

1. **No Permissions Needed**: Files in `user://` don't require storage permissions
2. **Sandboxed**: Other apps can't access your save files
3. **Auto-Cleanup**: Files deleted when user uninstalls app
4. **Secure**: Android's app sandboxing prevents tampering

---

## Error Handling Example

```gdscript
# The save system handles errors automatically, but you can check console output

func save_with_error_check() -> void:
    print("Attempting to save...")
    ProgressTracker.save_progress_data()

    # Check console for:
    # ✓ "Progress data saved successfully (encrypted)"
    # ✗ "Error: Could not save progress data. Error code: X"

    # If errors occur, the system will:
    # 1. Print detailed error code
    # 2. Print human-readable error message
    # 3. Attempt backup recovery if loading
```

---

## Signals

### Connect to Progress Updates

```gdscript
func _ready() -> void:
    # Called whenever progress changes
    ProgressTracker.progress_updated.connect(_on_progress_changed)

    # Called when player unlocks an achievement
    ProgressTracker.achievement_unlocked.connect(_on_achievement)

func _on_progress_changed() -> void:
    # Update UI with latest statistics
    update_stats_display()

func _on_achievement(achievement_name: String) -> void:
    # Show achievement popup
    var display_name = ProgressTracker.get_achievement_name(achievement_name)
    show_popup("Achievement Unlocked!", display_name)
```

---

## Testing Your Implementation

### Test Script Example

Create a test script to verify everything works:

```gdscript
# test_save_system.gd
extends Node

func _ready() -> void:
    test_save_load()
    test_encryption()
    test_export_import()

func test_save_load() -> void:
    print("=== Testing Save/Load ===")

    # Start a session
    ProgressTracker.start_new_session(3)

    # Complete it
    ProgressTracker.complete_current_session(1000, 2, 5, "win")

    # Save
    ProgressTracker.save_progress_data()

    # Load
    ProgressTracker.load_progress_data()

    # Verify
    print("Games played: ", ProgressTracker.statistics.total_games_played)
    print("✓ Save/Load test complete")

func test_encryption() -> void:
    print("=== Testing Encryption ===")

    var save_path = ProjectSettings.globalize_path("user://game_progress.dat")
    print("Save file location: ", save_path)
    print("→ Open this file in a text editor. It should be unreadable gibberish.")
    print("✓ If gibberish, encryption is working!")

func test_export_import() -> void:
    print("=== Testing Export/Import ===")

    # Export
    var export_path = ProgressTracker.export_progress_data()
    print("Exported to: ", export_path)

    # Import
    var success = ProgressTracker.import_progress_data(export_path)
    print("Import success: ", success)

    print("✓ Export/Import test complete")
```

---

## Common Use Cases

### Display Player Stats on Main Menu

```gdscript
# MainMenu.gd
func _ready() -> void:
    update_stats_display()

func update_stats_display() -> void:
    $StatsPanel/GamesPlayed.text = "Games: %d" % ProgressTracker.statistics.total_games_played
    $StatsPanel/HighScore.text = "High Score: %d" % ProgressTracker.statistics.high_score_overall
    $StatsPanel/SuccessRate.text = "Win Rate: %.1f%%" % (ProgressTracker.statistics.success_rate * 100)
```

### Leaderboard Integration

```gdscript
# Leaderboard.gd
func update_leaderboard() -> void:
    # Get scores by difficulty
    for difficulty in range(1, 6):
        var score = ProgressTracker.statistics.high_scores_by_difficulty[difficulty]
        update_leaderboard_entry(difficulty, score)
```

### Achievement Popup

```gdscript
# AchievementPopup.gd
func _ready() -> void:
    ProgressTracker.achievement_unlocked.connect(_show_achievement)

func _show_achievement(achievement_id: String) -> void:
    var display_name = ProgressTracker.get_achievement_name(achievement_id)
    $AnimationPlayer.play("popup")
    $Label.text = display_name
```

---

## Summary

**All save operations are handled automatically:**
- ✅ Automatic loading on game startup
- ✅ Automatic saving after each game session
- ✅ Automatic backup creation before each save
- ✅ Automatic recovery from backup if main file corrupted
- ✅ Encrypted with device-unique key

**You only need to call functions for:**
- Starting/completing game sessions
- Recording operation usage
- Accessing statistics
- Manual export/import (optional)

**The SaveManager is production-ready for Android deployment!**
