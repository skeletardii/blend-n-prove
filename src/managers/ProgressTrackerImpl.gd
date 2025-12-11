extends Node

const ProgressTrackerTypes = preload("res://src/managers/ProgressTrackerTypes.gd")

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

# Type aliases for convenience
var game_sessions: Array[ProgressTrackerTypes.GameSession] = []
var statistics: ProgressTrackerTypes.PlayerStatistics = ProgressTrackerTypes.PlayerStatistics.new()
var current_session: ProgressTrackerTypes.GameSession
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

func start_new_session(difficulty: int, time_limit_seconds: float) -> void:
	current_session = ProgressTrackerTypes.GameSession.new(0, difficulty, 0, 0.0, "incomplete", time_limit_seconds)
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

func complete_current_session(final_score: int, orders_completed: int, completion_status: String, time_remaining_on_quit: float = 0.0, max_active_combo: int = 0, mistakes_count: int = 0) -> void:
	if not current_session:
		return

	var current_time_total_seconds = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	var session_duration = current_time_total_seconds - session_start_time
	if session_duration < 0:
		session_duration += 24 * 3600  # Handle day rollover (should not happen for short game sessions)

	current_session.final_score = final_score
	current_session.orders_completed = orders_completed
	
	# Validate completion_status against allowed values
	if completion_status != "time_out" and completion_status != "quit":
		completion_status = "incomplete" # Default to incomplete if invalid status passed
		
	current_session.completion_status = completion_status
	current_session.session_duration = session_duration
	current_session.time_remaining_on_quit = time_remaining_on_quit
	current_session.max_active_combo = max_active_combo
	current_session.mistakes_count = mistakes_count


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

	# Update games ended by time out or quit
	if last_session.completion_status == "time_out":
		statistics.games_ended_by_time_out += 1
	elif last_session.completion_status == "quit":
		statistics.games_ended_by_quit += 1
		# Only average time remaining on quit if it was actually a quit (not 0.0)
		if last_session.time_remaining_on_quit > 0:
			var current_total_time_remaining = statistics.average_time_remaining_on_quit * (statistics.games_ended_by_quit - 1)
			statistics.average_time_remaining_on_quit = (current_total_time_remaining + last_session.time_remaining_on_quit) / statistics.games_ended_by_quit


	# Recalculate global averages based on ALL sessions (excluding incomplete/tutorial, if desired, but for now include all)
	var total_score_sum = 0
	var total_duration_sum = 0.0
	var total_orders_sum = 0
	var session_count_for_averages = 0
	var max_combo_overall = 0
	
	for session in game_sessions:
		# Exclude incomplete sessions from averages
		if session.completion_status != "incomplete":
			total_score_sum += session.final_score
			total_duration_sum += session.session_duration
			total_orders_sum += session.orders_completed
			session_count_for_averages += 1
			
			if session.max_active_combo > max_combo_overall:
				max_combo_overall = session.max_active_combo

	if session_count_for_averages > 0:
		statistics.average_score_overall = float(total_score_sum) / session_count_for_averages
		statistics.average_session_duration_overall = total_duration_sum / session_count_for_averages
		statistics.average_orders_per_game_overall = float(total_orders_sum) / session_count_for_averages
	else:
		statistics.average_score_overall = 0.0
		statistics.average_session_duration_overall = 0.0
		statistics.average_orders_per_game_overall = 0.0
	
	statistics.longest_orders_combo_overall = max_combo_overall

	# Update longest session duration
	if last_session.session_duration > statistics.longest_session_duration_overall:
		statistics.longest_session_duration_overall = last_session.session_duration


	# Update averages by difficulty
	for diff in range(1, 6):
		var difficulty_sessions = game_sessions.filter(func(s): return s.difficulty_level == diff and s.completion_status != "incomplete")
		if difficulty_sessions.size() > 0:
			var diff_total_score = 0
			for session in difficulty_sessions:
				diff_total_score += session.final_score
			statistics.average_scores_by_difficulty[diff] = float(diff_total_score) / float(difficulty_sessions.size())
		else:
			statistics.average_scores_by_difficulty[diff] = 0.0

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
	
	# Update mastery level (highest difficulty with consistent high scores/orders)
	# Redefine mastery based on achieving a high score threshold or orders completed
	for diff in range(5, 0, -1):
		# Let's consider a difficulty mastered if the player has achieved a high score of at least 5000 on it.
		# This is a placeholder and can be refined later.
		if statistics.high_scores_by_difficulty.get(diff, 0) >= 5000:
			statistics.highest_difficulty_mastered = diff
			break
		# Alternatively, consider a threshold for average score or orders completed if a high score isn't enough.
		# For example: if statistics.average_scores_by_difficulty.get(diff, 0) >= 2000:
		# Or if average orders completed is high.


func check_achievements() -> void:
	var new_achievements = []

	# First Game
	if statistics.total_games_played == 1 and "first_game" not in statistics.achievements_unlocked:
		new_achievements.append("first_game")

	# Milestone games (games played remains relevant)
	if statistics.total_games_played >= 3 and "3_games" not in statistics.achievements_unlocked:
		new_achievements.append("3_games")
	for milestone in [10, 50, 100]:
		var achievement_name = str(milestone) + "_games"
		if statistics.total_games_played >= milestone and achievement_name not in statistics.achievements_unlocked:
			new_achievements.append(achievement_name)

	# High score milestones (more relevant now)
	if statistics.high_score_overall >= 500 and "500_score" not in statistics.achievements_unlocked:
		new_achievements.append("500_score")
	for score in [1000, 5000, 10000]:
		var achievement_name = str(score) + "_score"
		if statistics.high_score_overall >= score and achievement_name not in statistics.achievements_unlocked:
			new_achievements.append(achievement_name)

	# Difficulty mastery (redefined)
	for diff in range(1, 6):
		var achievement_name = "master_difficulty_" + str(diff)
		# Mastery could be defined by reaching a certain score on this difficulty
		if statistics.high_scores_by_difficulty.get(diff, 0) >= 5000 and achievement_name not in statistics.achievements_unlocked: # Placeholder score
			new_achievements.append(achievement_name)

	# Rule usage achievements (remain relevant)
	var rules_to_check = {
		"Modus Ponens": {"5": "rule_modus_ponens_5", "20": "rule_modus_ponens_20"},
		"Modus Tollens": {"5": "rule_modus_tollens_5", "20": "rule_modus_tollens_20"},
		"Conjunction": {"5": "rule_conjunction_5", "20": "rule_conjunction_20"},
		"Addition": {"5": "rule_addition_5", "20": "rule_addition_20"},
		"Double Negation": {"5": "rule_double_negation_5", "20": "rule_double_negation_20"}
	}

	for rule_name in rules_to_check:
		var usage_count = statistics.operation_usage_count.get(rule_name, 0)
		for target_count_str in rules_to_check[rule_name]:
			var target_count = int(target_count_str)
			var achievement_id = rules_to_check[rule_name][target_count_str]
			if usage_count >= target_count and achievement_id not in statistics.achievements_unlocked:
				new_achievements.append(achievement_id)

	# New time-based/combo-based achievements (replace old streaks, perfect game)
	var last_session = game_sessions[-1]
	
	# Order combo achievements
	if last_session.max_active_combo >= 3 and "3_streak" not in statistics.achievements_unlocked:
		new_achievements.append("3_streak")
	if last_session.max_active_combo >= 5 and "5_streak" not in statistics.achievements_unlocked:
		new_achievements.append("5_streak")
	if last_session.max_active_combo >= 10 and "10_streak" not in statistics.achievements_unlocked:
		new_achievements.append("10_streak")
	if last_session.max_active_combo >= 20 and "20_streak" not in statistics.achievements_unlocked:
		new_achievements.append("20_streak")
		
	# No mistakes achievement (replaces perfect game)
	if last_session.mistakes_count == 0 and last_session.completion_status == "time_out" and "perfect_game" not in statistics.achievements_unlocked:
		new_achievements.append("perfect_game")
		
	# Survival time achievements (example)
	if last_session.session_duration >= 300 and "survival_5min" not in statistics.achievements_unlocked: # 5 minutes
		new_achievements.append("survival_5min")
	if last_session.session_duration >= 600 and "survival_10min" not in statistics.achievements_unlocked: # 10 minutes
		new_achievements.append("survival_10min")
		
	# Tutorial achievements (remain relevant)
	if statistics.tutorials_completed == 1 and "first_tutorial" not in statistics.achievements_unlocked:
		new_achievements.append("first_tutorial")
	if statistics.tutorials_completed >= 5 and "5_tutorials" not in statistics.achievements_unlocked:
		new_achievements.append("5_tutorials")
	if statistics.tutorials_completed >= 10 and "10_tutorials" not in statistics.achievements_unlocked:
		new_achievements.append("10_tutorials")
	if statistics.tutorials_completed >= 18 and "all_tutorials" not in statistics.achievements_unlocked:
		new_achievements.append("all_tutorials")

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
			var session = ProgressTrackerTypes.GameSession.new()
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
				var session = ProgressTrackerTypes.GameSession.new()
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
		"3_games": "Warming Up", # New
		"10_games": "Getting Started",
		"50_games": "Dedicated Learner",
		"100_games": "Logic Master",
		"3_streak": "Hot Hand", # New
		"5_streak": "On a Roll",
		"10_streak": "Logic Streak",
		"20_streak": "Unstoppable",
		"500_score": "Point Scorer", # New
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
		"all_tutorials": "Logic Master",
		"rule_modus_ponens_5": "MP Apprentice", # New
		"rule_modus_tollens_5": "MT Apprentice", # New
		"rule_conjunction_5": "Conjunction Crafter", # New
		"rule_addition_5": "Addition Artist", # New
		"rule_double_negation_5": "Double Negation Dynamo", # New
		"rule_modus_ponens_20": "MP Journeyman", # New
		"rule_modus_tollens_20": "MT Journeyman", # New
		"rule_conjunction_20": "Conjunction Expert", # New
		"rule_addition_20": "Addition Adept", # New
		"rule_double_negation_20": "Double Negation Master", # New
		"survival_5min": "Five Minute Frenzy", # New
		"survival_10min": "Ten Minute Triumph" # New
	}
	return achievement_names.get(achievement_id, achievement_id)

func get_recent_sessions(count: int = 10) -> Array[ProgressTrackerTypes.GameSession]:
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
			var session = ProgressTrackerTypes.GameSession.new()
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
	statistics = ProgressTrackerTypes.PlayerStatistics.new()
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	if FileAccess.file_exists(BACKUP_FILE_PATH):
		DirAccess.remove_absolute(BACKUP_FILE_PATH)
	if FileAccess.file_exists(EXPORT_FILE_PATH):
		DirAccess.remove_absolute(EXPORT_FILE_PATH)
	progress_updated.emit()
	print("Progress data reset successfully")

func debug_populate_test_data() -> void:
	# Clear existing data
	game_sessions.clear()
	statistics = ProgressTrackerTypes.PlayerStatistics.new()

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Define operations for realistic data
	var operations = ["Modus Ponens", "Modus Tollens", "Conjunction", "Addition", "Double Negation", "Simplification"]

	# Create sessions spanning last 30 days
	var total_sessions = 35
	var now = Time.get_unix_time_from_system()
	var time_out_count = 0
	var quit_count = 0
	var total_quit_time = 0.0
	var longest_duration = 0.0
	var longest_combo = 0
	var difficulty_counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}

	for i in range(total_sessions):
		# Spread sessions over last 30 days
		var days_ago = rng.randi_range(0, 30)
		var session_time = now - (days_ago * 86400) - rng.randi_range(0, 86400)

		# Generate difficulty with progression pattern (start low, get higher)
		var difficulty = 1
		if i < 5:
			difficulty = 1
		elif i < 12:
			difficulty = rng.randi_range(1, 2)
		elif i < 20:
			difficulty = rng.randi_range(2, 3)
		elif i < 28:
			difficulty = rng.randi_range(2, 4)
		else:
			difficulty = rng.randi_range(3, 5)

		difficulty_counts[difficulty] += 1

		# Generate performance that varies but shows some improvement over time
		var base_score = difficulty * 200
		var progression_bonus = int(i * 15)  # Improve over time
		var variance = rng.randi_range(-100, 200)
		var score = max(50, base_score + progression_bonus + variance)

		var orders = rng.randi_range(5, 20)
		var duration = rng.randf_range(120.0, 300.0)
		var time_limit = 300.0

		# Status: 70% complete, 25% quit, 5% incomplete
		var status_roll = rng.randf()
		var status = "time_out"
		var time_remaining = 0.0

		if status_roll < 0.70:
			status = "time_out"
			time_out_count += 1
		elif status_roll < 0.95:
			status = "quit"
			quit_count += 1
			time_remaining = rng.randf_range(30.0, 150.0)
			total_quit_time += time_remaining
			duration = time_limit - time_remaining  # Adjust duration for quit
		else:
			status = "incomplete"

		# Mistakes based on difficulty and session progression (improve over time)
		var base_mistakes = difficulty * 2
		var improvement_factor = max(0, 1.0 - (float(i) / 50.0))  # Fewer mistakes over time
		var mistakes = max(0, int(base_mistakes * improvement_factor + rng.randi_range(-1, 2)))

		# Combo based on performance
		var combo = max(0, orders - mistakes - rng.randi_range(0, 3))
		longest_combo = max(longest_combo, combo)

		# Create session
		var session = ProgressTrackerTypes.GameSession.new(
			score, difficulty, orders, duration, status,
			time_limit, time_remaining, combo, mistakes
		)

		# Set timestamp manually to spread over 30 days
		var datetime = Time.get_datetime_dict_from_unix_time(int(session_time))
		session.timestamp = "%04d-%02d-%02dT%02d:%02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute, datetime.second
		]

		# Populate operations_used for each session
		var ops_in_session = rng.randi_range(3, 6)
		for j in range(ops_in_session):
			var op = operations[rng.randi_range(0, operations.size() - 1)]
			if not session.operations_used.has(op):
				session.operations_used[op] = {"count": 0, "successes": 0}

			var op_count = rng.randi_range(1, 8)
			var success_rate = 0.5 + (float(i) / 70.0) + rng.randf_range(-0.2, 0.2)  # Improve over time
			success_rate = clamp(success_rate, 0.3, 0.98)
			var successes = int(op_count * success_rate)

			session.operations_used[op]["count"] += op_count
			session.operations_used[op]["successes"] += successes

		game_sessions.append(session)
		longest_duration = max(longest_duration, duration)

	# Calculate statistics from actual session data
	statistics.total_games_played = total_sessions

	var total_score = 0
	var total_time = 0.0
	var total_orders = 0

	# Initialize operation tracking
	for op in operations:
		statistics.operation_usage_count[op] = 0
		statistics.operation_proficiency[op] = {"total": 0, "successes": 0, "rate": 0.0}

	for session in game_sessions:
		total_score += session.final_score
		total_time += session.session_duration
		total_orders += session.orders_completed

		# High scores
		if session.final_score > statistics.high_score_overall:
			statistics.high_score_overall = session.final_score

		if session.final_score > statistics.high_scores_by_difficulty.get(session.difficulty_level, 0):
			statistics.high_scores_by_difficulty[session.difficulty_level] = session.final_score

		# Aggregate operations from session
		for op in session.operations_used.keys():
			var op_data = session.operations_used[op]
			statistics.operation_usage_count[op] += op_data["count"]
			statistics.operation_proficiency[op]["total"] += op_data["count"]
			statistics.operation_proficiency[op]["successes"] += op_data["successes"]

	# Calculate operation success rates
	for op in statistics.operation_proficiency.keys():
		var prof = statistics.operation_proficiency[op]
		if prof["total"] > 0:
			prof["rate"] = float(prof["successes"]) / float(prof["total"])
		else:
			prof["rate"] = 0.0

	statistics.total_play_time = total_time
	statistics.total_orders_completed = total_orders
	statistics.average_score_overall = float(total_score) / float(total_sessions) if total_sessions > 0 else 0.0

	# Session-based statistics
	statistics.average_session_duration_overall = total_time / float(total_sessions) if total_sessions > 0 else 0.0
	statistics.longest_session_duration_overall = longest_duration
	statistics.average_orders_per_game_overall = float(total_orders) / float(total_sessions) if total_sessions > 0 else 0.0
	statistics.longest_orders_combo_overall = longest_combo
	statistics.games_ended_by_time_out = time_out_count
	statistics.games_ended_by_quit = quit_count
	statistics.average_time_remaining_on_quit = total_quit_time / float(quit_count) if quit_count > 0 else 0.0

	# Average scores by difficulty
	for diff in range(1, 6):
		var diff_sessions = game_sessions.filter(func(s): return s.difficulty_level == diff)
		if diff_sessions.size() > 0:
			var diff_total = 0
			for s in diff_sessions:
				diff_total += s.final_score
			statistics.average_scores_by_difficulty[diff] = float(diff_total) / float(diff_sessions.size())

	# Favorite difficulty = most played
	var max_count = 0
	var fav_diff = 1
	for diff in difficulty_counts.keys():
		if difficulty_counts[diff] > max_count:
			max_count = difficulty_counts[diff]
			fav_diff = diff
	statistics.favorite_difficulty = fav_diff

	# Highest difficulty mastered (5000+ score)
	statistics.highest_difficulty_mastered = 1
	for diff in range(5, 0, -1):
		if statistics.high_scores_by_difficulty.get(diff, 0) >= 5000:
			statistics.highest_difficulty_mastered = diff
			break

	# Add achievements based on actual data
	statistics.achievements_unlocked.append("first_game")
	if statistics.total_games_played >= 3: statistics.achievements_unlocked.append("3_games")
	if statistics.total_games_played >= 10: statistics.achievements_unlocked.append("10_games")
	if statistics.high_score_overall >= 500: statistics.achievements_unlocked.append("500_score")
	if statistics.high_score_overall >= 1000: statistics.achievements_unlocked.append("1000_score")
	if statistics.high_score_overall >= 5000: statistics.achievements_unlocked.append("5000_score")
	if statistics.longest_orders_combo_overall >= 3: statistics.achievements_unlocked.append("3_streak")
	if statistics.longest_orders_combo_overall >= 5: statistics.achievements_unlocked.append("5_streak")
	if statistics.longest_orders_combo_overall >= 10: statistics.achievements_unlocked.append("10_streak")

	# Operation-based achievements
	for op in ["Modus Ponens", "Modus Tollens", "Conjunction", "Addition", "Double Negation"]:
		var count = statistics.operation_usage_count.get(op, 0)
		var op_key = op.replace(" ", "_").to_lower()
		if count >= 5:
			statistics.achievements_unlocked.append("rule_" + op_key + "_5")
		if count >= 20:
			statistics.achievements_unlocked.append("rule_" + op_key + "_20")

	# Tutorial progress
	statistics.tutorials_completed = 3
	statistics.tutorial_completions["tutorial_basics"] = [0, 1, 2]
	statistics.tutorial_completions["tutorial_logic_gates"] = [0, 1]

	save_progress_data()
	progress_updated.emit()
	print("Debug: Populated test data with ", total_sessions, " sessions over 30 days.")
	print("  → Favorite difficulty: ", statistics.favorite_difficulty)
	print("  → High score: ", statistics.high_score_overall)
	print("  → Achievements: ", statistics.achievements_unlocked.size())

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
