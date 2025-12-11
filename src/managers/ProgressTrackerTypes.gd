extends RefCounted

## Shared type definitions for ProgressTracker system
## These classes are used by both ProgressTrackerImpl and UI components

class GameSession:
	var final_score: int = 0
	var difficulty_level: int = 1
	var orders_completed: int = 0
	var session_duration: float = 0.0
	var completion_status: String = "incomplete" # "time_out", "quit"
	var timestamp: String = ""
	var operations_used: Dictionary = {}
	var time_limit_seconds: float = 0.0 # New
	var time_remaining_on_quit: float = 0.0 # New
	var max_active_combo: int = 0 # New
	var mistakes_count: int = 0 # New

	func _init(score: int = 0, difficulty: int = 1, orders: int = 0, duration: float = 0.0, status: String = "incomplete", time_limit: float = 0.0, time_remaining: float = 0.0, combo: int = 0, mistakes: int = 0) -> void:
		final_score = score
		difficulty_level = difficulty
		orders_completed = orders
		session_duration = duration
		completion_status = status
		timestamp = Time.get_datetime_string_from_system()
		operations_used = {}
		time_limit_seconds = time_limit
		time_remaining_on_quit = time_remaining
		max_active_combo = combo
		mistakes_count = mistakes

	func to_dict() -> Dictionary:
		return {
			"final_score": final_score,
			"difficulty_level": difficulty_level,
			"orders_completed": orders_completed,
			"session_duration": session_duration,
			"completion_status": completion_status,
			"timestamp": timestamp,
			"operations_used": operations_used,
			"time_limit_seconds": time_limit_seconds,
			"time_remaining_on_quit": time_remaining_on_quit,
			"max_active_combo": max_active_combo,
			"mistakes_count": mistakes_count
		}

	func from_dict(data: Dictionary) -> void:
		final_score = data.get("final_score", 0)
		difficulty_level = data.get("difficulty_level", 1)
		orders_completed = data.get("orders_completed", 0)
		session_duration = data.get("session_duration", 0.0)
		completion_status = data.get("completion_status", "incomplete")
		timestamp = data.get("timestamp", "")
		operations_used = data.get("operations_used", {})
		time_limit_seconds = data.get("time_limit_seconds", 0.0)
		time_remaining_on_quit = data.get("time_remaining_on_quit", 0.0)
		max_active_combo = data.get("max_active_combo", 0)
		mistakes_count = data.get("mistakes_count", 0)

class PlayerStatistics:
	var total_games_played: int = 0
	var high_score_overall: int = 0
	var high_scores_by_difficulty: Dictionary = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	var average_score_overall: float = 0.0
	var average_scores_by_difficulty: Dictionary = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0}
	var total_play_time: float = 0.0
	var highest_difficulty_mastered: int = 1
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
	
	# New time-based and high-score focused aggregate statistics
	var average_session_duration_overall: float = 0.0
	var longest_session_duration_overall: float = 0.0
	var average_orders_per_game_overall: float = 0.0
	var longest_orders_combo_overall: int = 0
	var games_ended_by_time_out: int = 0
	var games_ended_by_quit: int = 0
	var average_time_remaining_on_quit: float = 0.0

	func to_dict() -> Dictionary:
		return {
			"total_games_played": total_games_played,
			"high_score_overall": high_score_overall,
			"high_scores_by_difficulty": high_scores_by_difficulty,
			"average_score_overall": average_score_overall,
			"average_scores_by_difficulty": average_scores_by_difficulty,
			"total_play_time": total_play_time,
			"highest_difficulty_mastered": highest_difficulty_mastered,
			"favorite_difficulty": favorite_difficulty,
			"total_orders_completed": total_orders_completed,
			"achievements_unlocked": achievements_unlocked,
			"operation_proficiency": operation_proficiency,
			"operation_usage_count": operation_usage_count,
			"common_failures": common_failures,
			"tutorial_completions": tutorial_completions,
			"tutorials_completed": tutorials_completed,
			# New stats
			"average_session_duration_overall": average_session_duration_overall,
			"longest_session_duration_overall": longest_session_duration_overall,
			"average_orders_per_game_overall": average_orders_per_game_overall,
			"longest_orders_combo_overall": longest_orders_combo_overall,
			"games_ended_by_time_out": games_ended_by_time_out,
			"games_ended_by_quit": games_ended_by_quit,
			"average_time_remaining_on_quit": average_time_remaining_on_quit
		}

	func from_dict(data: Dictionary) -> void:
		total_games_played = data.get("total_games_played", 0)
		high_score_overall = data.get("high_score_overall", 0)
		high_scores_by_difficulty = data.get("high_scores_by_difficulty", {1: 0, 2: 0, 3: 0, 4: 0, 5: 0})
		average_score_overall = data.get("average_score_overall", 0.0)
		average_scores_by_difficulty = data.get("average_scores_by_difficulty", {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0})
		total_play_time = data.get("total_play_time", 0.0)
		highest_difficulty_mastered = data.get("highest_difficulty_mastered", 1)
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
		# New stats
		average_session_duration_overall = data.get("average_session_duration_overall", 0.0)
		longest_session_duration_overall = data.get("longest_session_duration_overall", 0.0)
		average_orders_per_game_overall = data.get("average_orders_per_game_overall", 0.0)
		longest_orders_combo_overall = data.get("longest_orders_combo_overall", 0)
		games_ended_by_time_out = data.get("games_ended_by_time_out", 0)
		games_ended_by_quit = data.get("games_ended_by_quit", 0)
		average_time_remaining_on_quit = data.get("average_time_remaining_on_quit", 0.0)

## GradeCalculator - Static utility class for calculating session grades
class GradeCalculator:
	## Calculate letter grade (A-F) for a game session
	## Grading components:
	## - Score percentile vs personal best (40% weight)
	## - Accuracy: 1 - (mistakes / max(10, orders)) (40% weight)
	## - Completion quality (20% weight)
	static func calculate_session_grade(session: GameSession, stats: PlayerStatistics) -> String:
		var grade_score: float = 0.0

		# Component 1: Score Percentile (40% weight)
		var difficulty: int = session.difficulty_level
		var high_score: int = stats.high_scores_by_difficulty.get(difficulty, 0)

		var score_percentile: float = 0.0
		if high_score > 0:
			score_percentile = float(session.final_score) / float(high_score)
			score_percentile = clamp(score_percentile, 0.0, 1.0)

		# Component 2: Accuracy (40% weight)
		# Accuracy = 1 - (mistakes / max(10, orders_completed))
		var max_expected_orders: float = max(10.0, float(session.orders_completed))
		var accuracy: float = 1.0 - (float(session.mistakes_count) / max_expected_orders)
		accuracy = clamp(accuracy, 0.0, 1.0)

		# Component 3: Completion Quality (20% weight)
		var completion_quality: float = 0.0
		if session.completion_status == "time_out":
			# Timed out = full points for completion
			completion_quality = 1.0
		elif session.completion_status == "quit":
			# Quit = partial credit based on time played
			if session.time_limit_seconds > 0:
				var time_played_ratio: float = 1.0 - (session.time_remaining_on_quit / session.time_limit_seconds)
				completion_quality = time_played_ratio * 0.5  # Max 50% credit for quit
			else:
				completion_quality = 0.0
		else:
			# Incomplete = 0 points
			completion_quality = 0.0

		# Calculate weighted grade score (0-100)
		grade_score = (score_percentile * 40.0) + (accuracy * 40.0) + (completion_quality * 20.0)

		# Convert to letter grade
		if grade_score >= 90.0:
			return "A"
		elif grade_score >= 80.0:
			return "B"
		elif grade_score >= 70.0:
			return "C"
		elif grade_score >= 60.0:
			return "D"
		else:
			return "F"

	## Get color for a letter grade
	static func get_grade_color(grade: String) -> Color:
		match grade:
			"A":
				return Color(0.2, 0.8, 0.2)  # GREEN - excellent
			"B":
				return Color(0.2, 0.8, 0.8)  # CYAN - very good
			"C":
				return Color(0.9, 0.9, 0.2)  # YELLOW - average
			"D":
				return Color(0.9, 0.6, 0.2)  # ORANGE - below average
			"F":
				return Color(0.9, 0.2, 0.2)  # RED - needs work
			_:
				return Color.GRAY

	## Get description text for a letter grade
	static func get_grade_description(grade: String) -> String:
		match grade:
			"A":
				return "Excellent Performance!"
			"B":
				return "Great Job!"
			"C":
				return "Good Effort"
			"D":
				return "Keep Practicing"
			"F":
				return "Room for Improvement"
			_:
				return ""
