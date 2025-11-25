extends Node

signal progress_updated
signal achievement_unlocked(achievement_name: String)

## SAVE FILE CONFIGURATION
##
## Why user:// for Android?
## - Internal Storage: Files are saved to Android's internal app-specific directory
## - Sandboxing: Other apps cannot access these files (Android security model)
## - No Permissions: Doesn't require STORAGE permissions in AndroidManifest.xml
## - Auto-cleanup: Files are automatically deleted when app is uninstalled
##
## Security Note:
## This encryption is designed to stop casual cheating (editing save files with text editors).
## It's NOT designed to stop determined hackers or state-level actors. For a mobile game,
## this provides a good balance between security and performance.

const SAVE_FILE_PATH: String = "user://game_progress.dat"  # Changed from .json to .dat for encrypted format
const BACKUP_FILE_PATH: String = "user://game_progress_backup.dat"
const EXPORT_FILE_PATH: String = "user://game_progress_export.dat"

## Encryption salt - This is combined with device-unique ID to create the encryption key.
## WARNING: Changing this will invalidate all existing save files!
const ENCRYPTION_SALT: String = "BlendNProve_2025_SecureSave_v1"

## Current save format version - Increment this when making breaking changes to save structure
const SAVE_VERSION: String = "2.0"  # Version 2.0 = Encrypted saves

## ================================================================================================
## ENCRYPTED SAVE MANAGER - USAGE DOCUMENTATION
## ================================================================================================
##
## This autoload singleton manages player progress with encrypted save files for Android security.
##
## ENCRYPTION DETAILS:
## ------------------
## - Uses Godot 4's FileAccess.open_encrypted_with_pass() for encryption
## - Hybrid key generation: Hardcoded salt + Device ID (OS.get_unique_id())
## - Keys are hashed with SHA-256 for consistent length and good entropy
## - Files use .dat extension instead of .json to discourage manual editing
##
## SAVE FILE LOCATIONS (user:// directory):
## ----------------------------------------
## - Primary save: user://game_progress.dat
## - Backup save:  user://game_progress_backup.dat
## - Export file:  user://game_progress_export.dat
##
## On Android, user:// maps to: /data/data/com.yourcompany.gamepackage/files/
## On Windows, user:// maps to: C:/Users/[USER]/AppData/Roaming/Godot/app_userdata/[PROJECT_NAME]/
##
## FEATURES:
## ---------
## ✓ Automatic save/load on game events
## ✓ Encrypted backup system (creates backup before every save)
## ✓ Automatic recovery from backup if main file is corrupted
## ✓ Version checking for forward/backward compatibility
## ✓ Comprehensive error handling with detailed error codes
## ✓ Export/import functionality (encrypted)
## ✓ Statistics tracking (scores, achievements, play time, etc.)
## ✓ Tutorial progress tracking
##
## USAGE EXAMPLES:
## ---------------
##
## # Automatic save/load (no code needed):
## # - Load happens automatically in _ready()
## # - Save happens automatically when:
## #   * A game session completes
## #   * A tutorial problem is completed
##
## # Manual save:
## ProgressTracker.save_progress_data()
##
## # Manual load:
## ProgressTracker.load_progress_data()
##
## # Start a new game session:
## ProgressTracker.start_new_session(difficulty_level)
##
## # Track operation usage during gameplay:
## ProgressTracker.record_operation_used("AND", true)  # success
## ProgressTracker.record_operation_used("OR", false)  # failure
##
## # Complete a session:
## ProgressTracker.complete_current_session(final_score, lives_remaining, orders_completed, "win")
##
## # Export progress to encrypted file:
## var export_path = ProgressTracker.export_progress_data()
## if export_path != "":
##     print("Exported to: ", export_path)
##
## # Import progress from encrypted file:
## var success = ProgressTracker.import_progress_data("user://game_progress_export.dat")
## if success:
##     print("Import successful!")
##
## # Listen for progress updates:
## ProgressTracker.progress_updated.connect(_on_progress_updated)
## ProgressTracker.achievement_unlocked.connect(_on_achievement_unlocked)
##
## # Access statistics:
## print("Total games played: ", ProgressTracker.statistics.total_games_played)
## print("High score: ", ProgressTracker.statistics.high_score_overall)
## print("Success rate: ", ProgressTracker.statistics.success_rate)
##
## SECURITY NOTES:
## ---------------
## - Saves cannot be transferred between devices (device-unique encryption)
## - Prevents casual editing of save files with text editors
## - NOT designed to stop determined hackers or state-level actors
## - Good balance of security vs. convenience for mobile games
##
## TROUBLESHOOTING:
## ----------------
## - If save fails: Check console for error codes (ERR_FILE_*)
## - If load fails: Backup recovery is attempted automatically
## - If both fail: Progress will start fresh (no data loss from current session)
## - Wrong encryption key errors: Device ID changed or file from different device
##
## ================================================================================================

class GameSession:
	var final_score: int = 0
	var difficulty_level: int = 1
	var lives_remaining: int = 0
	var orders_completed: int = 0
	var session_duration: float = 0.0
	var completion_status: String = "incomplete" # "win", "loss", "quit", "incomplete"
	var timestamp: String = ""
	var operations_used: Dictionary = {}

	func _init(score: int = 0, difficulty: int = 1, lives: int = 0, orders: int = 0, duration: float = 0.0, status: String = "incomplete") -> void:
		final_score = score
		difficulty_level = difficulty
		lives_remaining = lives
		orders_completed = orders
		session_duration = duration
		completion_status = status
		timestamp = Time.get_datetime_string_from_system()
		operations_used = {}

	func to_dict() -> Dictionary:
		return {
			"final_score": final_score,
			"difficulty_level": difficulty_level,
			"lives_remaining": lives_remaining,
			"orders_completed": orders_completed,
			"session_duration": session_duration,
			"completion_status": completion_status,
			"timestamp": timestamp,
			"operations_used": operations_used
		}

	func from_dict(data: Dictionary) -> void:
		final_score = data.get("final_score", 0)
		difficulty_level = data.get("difficulty_level", 1)
		lives_remaining = data.get("lives_remaining", 0)
		orders_completed = data.get("orders_completed", 0)
		session_duration = data.get("session_duration", 0.0)
		completion_status = data.get("completion_status", "incomplete")
		timestamp = data.get("timestamp", "")
		operations_used = data.get("operations_used", {})

class PlayerStatistics:
	var total_games_played: int = 0
	var high_score_overall: int = 0
	var high_scores_by_difficulty: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	var average_score_overall: float = 0.0
	var average_scores_by_difficulty: Dictionary = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0}
	var total_successful_games: int = 0
	var success_rate: float = 0.0
	var total_play_time: float = 0.0
	var highest_difficulty_mastered: int = 1
	var current_streak: int = 0
	var best_streak: int = 0
	var favorite_difficulty: int = 1
	var total_orders_completed: int = 0
	var achievements_unlocked: Array[String] = []

	# Learning analytics
	var operation_proficiency: Dictionary = {}
	var operation_usage_count: Dictionary = {}
	var common_failures: Dictionary = {}

	# Tutorial tracking
	# Format: {"tutorial-key": [0, 1, 2, 3, 4, ...]} where numbers are completed problem indices
	var tutorial_completions: Dictionary = {}
	var tutorials_completed: int = 0

	func to_dict() -> Dictionary:
		return {
			"total_games_played": total_games_played,
			"high_score_overall": high_score_overall,
			"high_scores_by_difficulty": high_scores_by_difficulty,
			"average_score_overall": average_score_overall,
			"average_scores_by_difficulty": average_scores_by_difficulty,
			"total_successful_games": total_successful_games,
			"success_rate": success_rate,
			"total_play_time": total_play_time,
			"highest_difficulty_mastered": highest_difficulty_mastered,
			"current_streak": current_streak,
			"best_streak": best_streak,
			"favorite_difficulty": favorite_difficulty,
			"total_orders_completed": total_orders_completed,
			"achievements_unlocked": achievements_unlocked,
			"operation_proficiency": operation_proficiency,
			"operation_usage_count": operation_usage_count,
			"common_failures": common_failures,
			"tutorial_completions": tutorial_completions,
			"tutorials_completed": tutorials_completed
		}

	func from_dict(data: Dictionary) -> void:
		total_games_played = data.get("total_games_played", 0)
		high_score_overall = data.get("high_score_overall", 0)
		high_scores_by_difficulty = data.get("high_scores_by_difficulty", {1: 0, 2: 0, 3: 0, 4: 0, 5: 0})
		average_score_overall = data.get("average_score_overall", 0.0)
		average_scores_by_difficulty = data.get("average_scores_by_difficulty", {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0})
		total_successful_games = data.get("total_successful_games", 0)
		success_rate = data.get("success_rate", 0.0)
		total_play_time = data.get("total_play_time", 0.0)
		highest_difficulty_mastered = data.get("highest_difficulty_mastered", 1)
		current_streak = data.get("current_streak", 0)
		best_streak = data.get("best_streak", 0)
		favorite_difficulty = data.get("favorite_difficulty", 1)
		total_orders_completed = data.get("total_orders_completed", 0)
		var achievements_data = data.get("achievements_unlocked", [])
		achievements_unlocked.clear()
		for achievement in achievements_data:
			achievements_unlocked.append(achievement)
		operation_proficiency = data.get("operation_proficiency", {})
		operation_usage_count = data.get("operation_usage_count", {})
		common_failures = data.get("common_failures", {})
		tutorial_completions = data.get("tutorial_completions", {})
		tutorials_completed = data.get("tutorials_completed", 0)

var game_sessions: Array[GameSession] = []
var statistics: PlayerStatistics = PlayerStatistics.new()
var current_session: GameSession
var session_start_time: float = 0.0

## Generate encryption key using hybrid approach (hardcoded salt + device ID)
## This provides device-unique encryption while maintaining simplicity.
## Trade-off: Saves cannot be transferred between devices, but this prevents
## simple save file editing and sharing between players.
func _generate_encryption_key() -> String:
	var device_id: String = OS.get_unique_id()

	# Combine salt and device ID, then hash for consistent key length
	var combined: String = ENCRYPTION_SALT + device_id

	# Use SHA-256 hash to create a consistent-length key
	# Godot's FileAccess.open_encrypted_with_pass() accepts any string, but
	# using a hash ensures consistent length and good entropy distribution
	var key: String = combined.sha256_text()

	return key

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_progress_data()

func start_new_session(difficulty: int) -> void:
	current_session = GameSession.new(0, difficulty, 3, 0, 0.0, "incomplete")
	session_start_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second

func record_operation_used(operation_name: String, success: bool) -> void:
	if current_session:
		if not current_session.operations_used.has(operation_name):
			current_session.operations_used[operation_name] = {"count": 0, "successes": 0}

		current_session.operations_used[operation_name]["count"] += 1
		if success:
			current_session.operations_used[operation_name]["successes"] += 1

		# Update global operation tracking
		if not statistics.operation_usage_count.has(operation_name):
			statistics.operation_usage_count[operation_name] = 0
		statistics.operation_usage_count[operation_name] += 1

		if not statistics.operation_proficiency.has(operation_name):
			statistics.operation_proficiency[operation_name] = {"total": 0, "successes": 0, "rate": 0.0}
		statistics.operation_proficiency[operation_name]["total"] += 1
		if success:
			statistics.operation_proficiency[operation_name]["successes"] += 1
		statistics.operation_proficiency[operation_name]["rate"] = float(statistics.operation_proficiency[operation_name]["successes"]) / float(statistics.operation_proficiency[operation_name]["total"])

func complete_current_session(final_score: int, lives_remaining: int, orders_completed: int, completion_status: String) -> void:
	if not current_session:
		return

	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	var session_duration = current_time - session_start_time
	if session_duration < 0:
		session_duration += 24 * 3600  # Handle day rollover

	current_session.final_score = final_score
	current_session.lives_remaining = lives_remaining
	current_session.orders_completed = orders_completed
	current_session.completion_status = completion_status
	current_session.session_duration = session_duration

	game_sessions.append(current_session)
	update_statistics()
	check_achievements()
	save_progress_data()

	progress_updated.emit()
	current_session = null

func update_statistics() -> void:
	if game_sessions.is_empty():
		return

	var last_session = game_sessions[-1]
	statistics.total_games_played += 1
	statistics.total_play_time += last_session.session_duration
	statistics.total_orders_completed += last_session.orders_completed

	# Update high scores
	if last_session.final_score > statistics.high_score_overall:
		statistics.high_score_overall = last_session.final_score

	var difficulty = last_session.difficulty_level
	if last_session.final_score > statistics.high_scores_by_difficulty.get(difficulty, 0):
		statistics.high_scores_by_difficulty[difficulty] = last_session.final_score

	# Update success tracking
	var was_successful = last_session.completion_status == "win"
	if was_successful:
		statistics.total_successful_games += 1
		statistics.current_streak += 1
		if statistics.current_streak > statistics.best_streak:
			statistics.best_streak = statistics.current_streak
	else:
		statistics.current_streak = 0

	statistics.success_rate = float(statistics.total_successful_games) / float(statistics.total_games_played)

	# Update averages
	var total_score = 0
	for session in game_sessions:
		total_score += session.final_score
	statistics.average_score_overall = float(total_score) / float(game_sessions.size())

	# Update averages by difficulty
	for diff in range(1, 6):
		var difficulty_sessions = game_sessions.filter(func(s): return s.difficulty_level == diff)
		if difficulty_sessions.size() > 0:
			var difficulty_total = 0
			for session in difficulty_sessions:
				difficulty_total += session.final_score
			statistics.average_scores_by_difficulty[diff] = float(difficulty_total) / float(difficulty_sessions.size())

	# Update favorite difficulty (most played)
	var difficulty_counts = {}
	for session in game_sessions:
		var diff = session.difficulty_level
		difficulty_counts[diff] = difficulty_counts.get(diff, 0) + 1

	var max_count = 0
	for diff in difficulty_counts:
		if difficulty_counts[diff] > max_count:
			max_count = difficulty_counts[diff]
			statistics.favorite_difficulty = diff

	# Update mastery level (highest difficulty with consistent success)
	for diff in range(5, 0, -1):
		var recent_sessions = game_sessions.slice(-10).filter(func(s): return s.difficulty_level == diff and s.completion_status == "win")
		if recent_sessions.size() >= 3:
			statistics.highest_difficulty_mastered = diff
			break

func check_achievements() -> void:
	var new_achievements = []

	# First Game
	if statistics.total_games_played == 1 and "first_game" not in statistics.achievements_unlocked:
		new_achievements.append("first_game")

	# Perfect Game (no lives lost)
	var last_session = game_sessions[-1]
	if last_session.lives_remaining == 3 and last_session.completion_status == "win" and "perfect_game" not in statistics.achievements_unlocked:
		new_achievements.append("perfect_game")

	# Milestone games
	for milestone in [10, 50, 100]:
		var achievement_name = str(milestone) + "_games"
		if statistics.total_games_played >= milestone and achievement_name not in statistics.achievements_unlocked:
			new_achievements.append(achievement_name)

	# Streak achievements
	for streak in [5, 10, 20]:
		var achievement_name = str(streak) + "_streak"
		if statistics.current_streak >= streak and achievement_name not in statistics.achievements_unlocked:
			new_achievements.append(achievement_name)

	# High score milestones
	for score in [1000, 5000, 10000]:
		var achievement_name = str(score) + "_score"
		if statistics.high_score_overall >= score and achievement_name not in statistics.achievements_unlocked:
			new_achievements.append(achievement_name)

	# Difficulty mastery
	for diff in range(1, 6):
		var achievement_name = "master_difficulty_" + str(diff)
		if statistics.highest_difficulty_mastered >= diff and achievement_name not in statistics.achievements_unlocked:
			new_achievements.append(achievement_name)

	# Add new achievements and emit signals
	for achievement in new_achievements:
		statistics.achievements_unlocked.append(achievement)
		achievement_unlocked.emit(achievement)

func save_progress_data() -> void:
	var save_data = {
		"version": SAVE_VERSION,
		"last_saved": Time.get_datetime_string_from_system(),
		"statistics": statistics.to_dict(),
		"recent_sessions": []
	}

	# Save last 100 sessions to keep file size reasonable
	var sessions_to_save = game_sessions.slice(-100)
	for session in sessions_to_save:
		save_data["recent_sessions"].append(session.to_dict())

	var json_string = JSON.stringify(save_data)
	var encryption_key = _generate_encryption_key()

	# Create encrypted backup before saving
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var backup_file = FileAccess.open_encrypted_with_pass(BACKUP_FILE_PATH, FileAccess.WRITE, encryption_key)
		if backup_file:
			var current_file = FileAccess.open_encrypted_with_pass(SAVE_FILE_PATH, FileAccess.READ, encryption_key)
			if current_file:
				backup_file.store_string(current_file.get_as_text())
				current_file.close()
			else:
				print("Warning: Could not read current save for backup. Error code: ", FileAccess.get_open_error())
			backup_file.close()
		else:
			print("Warning: Could not create backup file. Error code: ", FileAccess.get_open_error())

	# Save main file with encryption
	var file = FileAccess.open_encrypted_with_pass(SAVE_FILE_PATH, FileAccess.WRITE, encryption_key)
	if file:
		file.store_string(json_string)
		file.close()
		print("Progress data saved successfully (encrypted)")
	else:
		var error_code = FileAccess.get_open_error()
		print("Error: Could not save progress data. Error code: ", error_code)
		_print_file_error(error_code)

func load_progress_data() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No progress data found, starting fresh")
		return

	var encryption_key = _generate_encryption_key()
	var file = FileAccess.open_encrypted_with_pass(SAVE_FILE_PATH, FileAccess.READ, encryption_key)

	if not file:
		var error_code = FileAccess.get_open_error()
		print("Error: Could not open progress data file. Error code: ", error_code)
		_print_file_error(error_code)

		# Try backup if main file fails
		if error_code == ERR_FILE_CORRUPT or error_code == ERR_FILE_UNRECOGNIZED:
			print("Main save file may be corrupted or encrypted with wrong key, trying backup...")
			try_load_backup()
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		print("Error: Could not parse progress data JSON. Parse error at line ", json.get_error_line(), ": ", json.get_error_message())
		try_load_backup()
		return

	var save_data = json.data

	# Version checking for future compatibility
	var file_version = save_data.get("version", "1.0")
	if file_version != SAVE_VERSION:
		print("Warning: Save file version mismatch. File version: ", file_version, ", Current version: ", SAVE_VERSION)
		# Handle version migrations here in the future
		# For now, we'll attempt to load anyway since we're only on version 2.0

	if save_data.has("statistics"):
		statistics.from_dict(save_data["statistics"])

	if save_data.has("recent_sessions"):
		game_sessions.clear()
		for session_data in save_data["recent_sessions"]:
			var session = GameSession.new()
			session.from_dict(session_data)
			game_sessions.append(session)

	print("Progress data loaded successfully (version: ", file_version, ")")
	progress_updated.emit()

func try_load_backup() -> void:
	if not FileAccess.file_exists(BACKUP_FILE_PATH):
		print("No backup file found")
		return

	print("Attempting to load from encrypted backup file")
	var encryption_key = _generate_encryption_key()
	var backup_file = FileAccess.open_encrypted_with_pass(BACKUP_FILE_PATH, FileAccess.READ, encryption_key)

	if not backup_file:
		var error_code = FileAccess.get_open_error()
		print("Error: Could not open backup file. Error code: ", error_code)
		_print_file_error(error_code)
		return

	var json_string = backup_file.get_as_text()
	backup_file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		var save_data = json.data

		# Version checking
		var file_version = save_data.get("version", "1.0")
		print("Backup file version: ", file_version)

		if save_data.has("statistics"):
			statistics.from_dict(save_data["statistics"])
		if save_data.has("recent_sessions"):
			game_sessions.clear()
			for session_data in save_data["recent_sessions"]:
				var session = GameSession.new()
				session.from_dict(session_data)
				game_sessions.append(session)
		print("Progress data loaded from backup successfully")
		progress_updated.emit()
	else:
		print("Error: Could not parse backup file JSON. Parse error at line ", json.get_error_line(), ": ", json.get_error_message())

func get_achievement_name(achievement_id: String) -> String:
	var achievement_names = {
		"first_game": "First Steps",
		"perfect_game": "Flawless Logic",
		"10_games": "Getting Started",
		"50_games": "Dedicated Learner",
		"100_games": "Logic Master",
		"5_streak": "On a Roll",
		"10_streak": "Logic Streak",
		"20_streak": "Unstoppable",
		"1000_score": "High Achiever",
		"5000_score": "Score Crusher",
		"10000_score": "Logic Legend",
		"master_difficulty_1": "Novice Bartender",
		"master_difficulty_2": "Skilled Bartender",
		"master_difficulty_3": "Expert Bartender",
		"master_difficulty_4": "Master Bartender",
		"master_difficulty_5": "Legendary Bartender",
		"first_tutorial": "Tutorial Beginner",
		"5_tutorials": "Quick Learner",
		"10_tutorials": "Logic Scholar",
		"all_tutorials": "Logic Master"
	}
	return achievement_names.get(achievement_id, achievement_id)

func get_recent_sessions(count: int = 10) -> Array[GameSession]:
	if game_sessions.size() <= count:
		return game_sessions
	return game_sessions.slice(-count)

func export_progress_data() -> String:
	var export_data = {
		"version": SAVE_VERSION,
		"export_date": Time.get_datetime_string_from_system(),
		"statistics": statistics.to_dict(),
		"all_sessions": []
	}

	for session in game_sessions:
		export_data["all_sessions"].append(session.to_dict())

	var json_string = JSON.stringify(export_data, "\t")
	var encryption_key = _generate_encryption_key()

	# Save export to encrypted file
	var export_file = FileAccess.open_encrypted_with_pass(EXPORT_FILE_PATH, FileAccess.WRITE, encryption_key)
	if export_file:
		export_file.store_string(json_string)
		export_file.close()
		print("Progress data exported successfully to: ", EXPORT_FILE_PATH)
		return EXPORT_FILE_PATH
	else:
		var error_code = FileAccess.get_open_error()
		print("Error: Could not export progress data. Error code: ", error_code)
		_print_file_error(error_code)
		return ""

func import_progress_data(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		print("Error: Import file does not exist: ", file_path)
		return false

	var encryption_key = _generate_encryption_key()
	var import_file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.READ, encryption_key)

	if not import_file:
		var error_code = FileAccess.get_open_error()
		print("Error: Could not open import file. Error code: ", error_code)
		_print_file_error(error_code)
		print("Note: Import files must be encrypted with this device's encryption key")
		return false

	var json_string = import_file.get_as_text()
	import_file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		print("Error: Could not parse import file JSON. Parse error at line ", json.get_error_line(), ": ", json.get_error_message())
		return false

	var import_data = json.data

	# Version checking
	var file_version = import_data.get("version", "1.0")
	print("Importing data from version: ", file_version)

	if file_version != SAVE_VERSION:
		print("Warning: Import file version (", file_version, ") differs from current version (", SAVE_VERSION, ")")
		# Future: Add version migration logic here

	# Import statistics
	if import_data.has("statistics"):
		statistics.from_dict(import_data["statistics"])
		print("Statistics imported successfully")

	# Import sessions (prefer "all_sessions" from export, fallback to "recent_sessions" from regular save)
	var sessions_key = "all_sessions" if import_data.has("all_sessions") else "recent_sessions"
	if import_data.has(sessions_key):
		game_sessions.clear()
		for session_data in import_data[sessions_key]:
			var session = GameSession.new()
			session.from_dict(session_data)
			game_sessions.append(session)
		print("Sessions imported successfully (", game_sessions.size(), " sessions)")

	# Save the imported data
	save_progress_data()
	progress_updated.emit()

	print("Progress data imported successfully from: ", file_path)
	return true

func reset_progress_data() -> void:
	game_sessions.clear()
	statistics = PlayerStatistics.new()
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	if FileAccess.file_exists(BACKUP_FILE_PATH):
		DirAccess.remove_absolute(BACKUP_FILE_PATH)
	if FileAccess.file_exists(EXPORT_FILE_PATH):
		DirAccess.remove_absolute(EXPORT_FILE_PATH)
	progress_updated.emit()
	print("Progress data reset successfully")

## Helper function to print human-readable file error messages
func _print_file_error(error_code: int) -> void:
	match error_code:
		OK:
			print("  → No error (OK)")
		ERR_FILE_NOT_FOUND:
			print("  → File not found")
		ERR_FILE_BAD_DRIVE:
			print("  → Bad drive")
		ERR_FILE_BAD_PATH:
			print("  → Bad path")
		ERR_FILE_NO_PERMISSION:
			print("  → No permission to access file")
		ERR_FILE_ALREADY_IN_USE:
			print("  → File already in use")
		ERR_FILE_CANT_OPEN:
			print("  → Cannot open file")
		ERR_FILE_CANT_WRITE:
			print("  → Cannot write to file")
		ERR_FILE_CANT_READ:
			print("  → Cannot read from file")
		ERR_FILE_UNRECOGNIZED:
			print("  → File format unrecognized (possibly wrong encryption key)")
		ERR_FILE_CORRUPT:
			print("  → File is corrupt or encrypted with wrong key")
		ERR_FILE_EOF:
			print("  → Unexpected end of file")
		_:
			print("  → Unknown error code: ", error_code)

# Tutorial progress tracking functions
func complete_tutorial_problem(tutorial_key: String, problem_index: int) -> void:
	if not statistics.tutorial_completions.has(tutorial_key):
		statistics.tutorial_completions[tutorial_key] = []

	var completed_problems: Array = statistics.tutorial_completions[tutorial_key]
	if not completed_problems.has(problem_index):
		completed_problems.append(problem_index)
		statistics.tutorial_completions[tutorial_key] = completed_problems

		# Check if all problems for this tutorial are completed
		check_tutorial_completion(tutorial_key)

		save_progress_data()
		progress_updated.emit()

func check_tutorial_completion(tutorial_key: String) -> void:
	# Check if this tutorial is fully completed
	var total_problems: int = TutorialDataManager.get_problem_count(tutorial_key)
	var completed_problems: int = get_tutorial_progress(tutorial_key)

	if total_problems > 0 and completed_problems >= total_problems:
		# Tutorial completed! Check if this is a new completion
		var was_completed: bool = is_tutorial_fully_completed(tutorial_key)
		if not was_completed:
			statistics.tutorials_completed += 1
			print("Tutorial completed: ", tutorial_key)

			# Check for tutorial achievements
			check_tutorial_achievements()

func is_tutorial_fully_completed(tutorial_key: String) -> bool:
	var total_problems: int = TutorialDataManager.get_problem_count(tutorial_key)
	var completed_problems: int = get_tutorial_progress(tutorial_key)
	return total_problems > 0 and completed_problems >= total_problems

func get_tutorial_progress(tutorial_key: String) -> int:
	if not statistics.tutorial_completions.has(tutorial_key):
		return 0
	var completed_problems: Array = statistics.tutorial_completions[tutorial_key]
	return completed_problems.size()

func is_tutorial_problem_completed(tutorial_key: String, problem_index: int) -> bool:
	if not statistics.tutorial_completions.has(tutorial_key):
		return false
	var completed_problems: Array = statistics.tutorial_completions[tutorial_key]
	return completed_problems.has(problem_index)

func get_total_tutorials_completed() -> int:
	return statistics.tutorials_completed

func check_tutorial_achievements() -> void:
	var new_achievements = []

	# First tutorial completed
	if statistics.tutorials_completed == 1 and "first_tutorial" not in statistics.achievements_unlocked:
		new_achievements.append("first_tutorial")

	# 5 tutorials completed
	if statistics.tutorials_completed >= 5 and "5_tutorials" not in statistics.achievements_unlocked:
		new_achievements.append("5_tutorials")

	# 10 tutorials completed
	if statistics.tutorials_completed >= 10 and "10_tutorials" not in statistics.achievements_unlocked:
		new_achievements.append("10_tutorials")

	# All tutorials completed
	if statistics.tutorials_completed >= 18 and "all_tutorials" not in statistics.achievements_unlocked:
		new_achievements.append("all_tutorials")

	# Add new achievements and emit signals
	for achievement in new_achievements:
		statistics.achievements_unlocked.append(achievement)
		achievement_unlocked.emit(achievement)
