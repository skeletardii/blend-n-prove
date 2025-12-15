# Godot Client Integration Summary

The `SupabaseService` autoload has been updated to support the new Hybrid Architecture.

## Usage Guide

### 1. Arcade Leaderboard (No Login)

**Submitting a Score:**
```gdscript
# Call this when the game ends
SupabaseService.submit_score_arcade("ABC", 1500, 5, 120.5)

# Listen for the result
func _ready():
    SupabaseService.score_submitted.connect(_on_score_submitted)

func _on_score_submitted(rank: int):
    print("New Rank: ", rank)
    # Show "You are #Rank!" UI
```

**Fetching Leaderboard:**
```gdscript
SupabaseService.fetch_leaderboard()

func _ready():
    SupabaseService.leaderboard_loaded.connect(_on_leaderboard_loaded)

func _on_leaderboard_loaded(entries: Array):
    # entries is an Array of Dictionaries: 
    # [{ "three_name": "ABC", "game_score": 1500, "game_level": 5 }]
    update_ui(entries)
```

### 2. Cloud Saves (Requires Login)

**Logging In:**
```gdscript
SupabaseService.login("user@example.com", "password123")

func _ready():
    SupabaseService.login_completed.connect(_on_login_completed)

func _on_login_completed(user, error):
    if error:
        show_error(error)
    else:
        show_main_menu()
```

**Saving Game:**
```gdscript
var save_data = { "level": 5, "items": ["sword", "shield"] }
SupabaseService.save_game_cloud(1, save_data) # Slot 1

func _ready():
    SupabaseService.save_uploaded.connect(_on_save_uploaded)

func _on_save_uploaded(success):
    if success:
        print("Game Saved!")
```

**Downloading Save:**
```gdscript
SupabaseService.download_game_cloud(1) # Slot 1

func _ready():
    SupabaseService.save_downloaded.connect(_on_save_downloaded)

func _on_save_downloaded(data):
    if data.is_empty():
        print("No save found")
    else:
        load_game_state(data)
```
