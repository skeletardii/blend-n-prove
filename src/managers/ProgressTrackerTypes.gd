extends RefCounted

## Shared type definitions for ProgressTracker system
## These classes are used by both ProgressTrackerImpl and UI components

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
