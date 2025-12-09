extends Node

## Leaderboard Data Singleton
## Temporary storage for passing score data between scenes
## Used when transitioning from GameOver to HighScoreEntry

var pending_score: int = 0
var pending_duration: float = 0.0
var pending_difficulty: int = 1
var is_pending: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Set pending entry data when transitioning to name entry
func set_pending_entry(score: int, duration: float, difficulty: int) -> void:
	pending_score = score
	pending_duration = duration
	pending_difficulty = difficulty
	is_pending = true
	print("LeaderboardData: Set pending entry - Score: " + str(score) + ", Difficulty: " + str(difficulty))

## Clear pending data after use
func clear_pending() -> void:
	pending_score = 0
	pending_duration = 0.0
	pending_difficulty = 1
	is_pending = false
	print("LeaderboardData: Cleared pending entry")

## Get all pending data as a dictionary
func get_pending_data() -> Dictionary:
	return {
		"score": pending_score,
		"duration": pending_duration,
		"difficulty": pending_difficulty,
		"is_pending": is_pending
	}
