class_name DifficultyRecommender
extends RefCounted

## Difficulty Recommender - Analyzes player performance and recommends optimal difficulty
##
## Analyzes last 5-10 sessions to determine if player should:
## - Level up (mastering current difficulty)
## - Level down (struggling too much)
## - Stay at current level (optimal challenge)

const ProgressTrackerTypes = preload("res://src/managers/ProgressTrackerTypes.gd")

## Get difficulty recommendation based on recent performance
## Returns: {"level": int, "reasoning": String, "confidence": String}
static func get_recommendation(stats: ProgressTrackerTypes.PlayerStatistics, sessions: Array) -> Dictionary:
	# Get last 5-10 completed sessions
	var recent_sessions = _get_recent_completed_sessions(sessions, 10)

	if recent_sessions.size() < 3:
		# Not enough data
		return {
			"level": 1,
			"reasoning": "Start with Level 1 to build foundational skills",
			"confidence": "default"
		}

	# Analyze performance metrics
	var avg_mistakes = _calculate_avg_mistakes(recent_sessions)
	var completion_rate = _calculate_completion_rate(recent_sessions)
	var avg_score_efficiency = _calculate_score_efficiency(recent_sessions, stats)
	var current_favorite = stats.favorite_difficulty

	# Recommendation logic
	var recommended_level = current_favorite
	var reasoning = ""
	var confidence = "medium"

	# Rule 1: Too easy (crushing it)
	if avg_mistakes < 2.0 and completion_rate >= 0.8 and avg_score_efficiency > 0.9:
		recommended_level = min(current_favorite + 1, 5)
		reasoning = "You're mastering level " + str(current_favorite) + "! Try level " + str(recommended_level)
		confidence = "high"

	# Rule 2: Too hard (struggling)
	elif avg_mistakes > 8.0 or completion_rate < 0.3:
		recommended_level = max(current_favorite - 1, 1)
		reasoning = "Build confidence at level " + str(recommended_level) + " before advancing"
		confidence = "high"

	# Rule 3: Just right (flow state)
	elif avg_mistakes >= 2.0 and avg_mistakes <= 5.0 and completion_rate >= 0.5:
		recommended_level = current_favorite
		reasoning = "Level " + str(current_favorite) + " is perfect for your current skill level"
		confidence = "high"

	# Rule 4: Mixed performance
	else:
		recommended_level = current_favorite
		reasoning = "Continue practicing level " + str(current_favorite)
		confidence = "medium"

	return {
		"level": recommended_level,
		"reasoning": reasoning,
		"confidence": confidence
	}

## Get recent completed sessions (time_out or quit)
static func _get_recent_completed_sessions(sessions: Array, count: int) -> Array:
	var completed = []
	for session in sessions:
		if session.completion_status == "time_out" or session.completion_status == "quit":
			completed.append(session)

	# Return last N sessions
	if completed.size() > count:
		return completed.slice(-count)
	else:
		return completed

## Calculate average mistakes per session
static func _calculate_avg_mistakes(sessions: Array) -> float:
	if sessions.is_empty():
		return 0.0

	var total = 0.0
	for session in sessions:
		total += session.mistakes_count

	return total / float(sessions.size())

## Calculate completion rate (time_out = completed)
static func _calculate_completion_rate(sessions: Array) -> float:
	if sessions.is_empty():
		return 0.0

	var completed_count = 0
	for session in sessions:
		if session.completion_status == "time_out":
			completed_count += 1

	return float(completed_count) / float(sessions.size())

## Calculate average score efficiency (session_score / high_score_for_difficulty)
static func _calculate_score_efficiency(sessions: Array, stats: ProgressTrackerTypes.PlayerStatistics) -> float:
	if sessions.is_empty():
		return 0.0

	var total_efficiency = 0.0
	for session in sessions:
		var high_score = stats.high_scores_by_difficulty.get(session.difficulty_level, 1)
		var efficiency = float(session.final_score) / float(max(high_score, 1))
		total_efficiency += efficiency

	return total_efficiency / float(sessions.size())
