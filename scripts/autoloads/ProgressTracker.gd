extends Node

signal progress_updated
signal achievement_unlocked(achievement_name: String)

const SAVE_FILE_PATH: String = "user://game_progress.json"
const BACKUP_FILE_PATH: String = "user://game_progress_backup.json"

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
			"common_failures": common_failures
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
		achievements_unlocked = data.get("achievements_unlocked", [])
		operation_proficiency = data.get("operation_proficiency", {})
		operation_usage_count = data.get("operation_usage_count", {})
		common_failures = data.get("common_failures", {})

var game_sessions: Array[GameSession] = []
var statistics: PlayerStatistics = PlayerStatistics.new()
var current_session: GameSession
var session_start_time: float = 0.0

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
		"version": "1.0",
		"last_saved": Time.get_datetime_string_from_system(),
		"statistics": statistics.to_dict(),
		"recent_sessions": []
	}

	# Save last 100 sessions to keep file size reasonable
	var sessions_to_save = game_sessions.slice(-100)
	for session in sessions_to_save:
		save_data["recent_sessions"].append(session.to_dict())

	var json_string = JSON.stringify(save_data)

	# Create backup before saving
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var backup_file = FileAccess.open(BACKUP_FILE_PATH, FileAccess.WRITE)
		if backup_file:
			var current_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
			if current_file:
				backup_file.store_string(current_file.get_as_text())
				current_file.close()
			backup_file.close()

	# Save main file
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Progress data saved successfully")
	else:
		print("Error: Could not save progress data")

func load_progress_data() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No progress data found, starting fresh")
		return

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		print("Error: Could not open progress data file")
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		print("Error: Could not parse progress data JSON")
		try_load_backup()
		return

	var save_data = json.data

	if save_data.has("statistics"):
		statistics.from_dict(save_data["statistics"])

	if save_data.has("recent_sessions"):
		game_sessions.clear()
		for session_data in save_data["recent_sessions"]:
			var session = GameSession.new()
			session.from_dict(session_data)
			game_sessions.append(session)

	print("Progress data loaded successfully")
	progress_updated.emit()

func try_load_backup() -> void:
	if not FileAccess.file_exists(BACKUP_FILE_PATH):
		return

	print("Attempting to load from backup file")
	var backup_file = FileAccess.open(BACKUP_FILE_PATH, FileAccess.READ)
	if not backup_file:
		return

	var json_string = backup_file.get_as_text()
	backup_file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		var save_data = json.data
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
		"master_difficulty_5": "Legendary Bartender"
	}
	return achievement_names.get(achievement_id, achievement_id)

func get_recent_sessions(count: int = 10) -> Array[GameSession]:
	if game_sessions.size() <= count:
		return game_sessions
	return game_sessions.slice(-count)

func export_progress_data() -> String:
	var export_data = {
		"export_date": Time.get_datetime_string_from_system(),
		"statistics": statistics.to_dict(),
		"all_sessions": []
	}

	for session in game_sessions:
		export_data["all_sessions"].append(session.to_dict())

	return JSON.stringify(export_data, "\t")

func reset_progress_data() -> void:
	game_sessions.clear()
	statistics = PlayerStatistics.new()
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	if FileAccess.file_exists(BACKUP_FILE_PATH):
		DirAccess.remove_absolute(BACKUP_FILE_PATH)
	progress_updated.emit()
	print("Progress data reset successfully")