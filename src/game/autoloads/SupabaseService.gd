extends Node

## Supabase Service Proxy
## This is a proxy autoload that forwards calls to SupabaseServiceImpl
## Following the proxy pattern used in this project

signal leaderboard_loaded(entries: Array)
signal leaderboard_error(error_message: String)
signal score_submitted(success: bool)

var _impl: Node = null

func _ready() -> void:
	# Implementation will be loaded by ManagerBootstrap
	pass

func _set_impl(impl: Node) -> void:
	_impl = impl
	# Forward signals
	if _impl.leaderboard_loaded.connect(_on_leaderboard_loaded) != OK:
		print("Warning: Could not connect leaderboard_loaded signal")
	if _impl.leaderboard_error.connect(_on_leaderboard_error) != OK:
		print("Warning: Could not connect leaderboard_error signal")
	if _impl.score_submitted.connect(_on_score_submitted) != OK:
		print("Warning: Could not connect score_submitted signal")

func _on_leaderboard_loaded(entries: Array) -> void:
	leaderboard_loaded.emit(entries)

func _on_leaderboard_error(error_message: String) -> void:
	leaderboard_error.emit(error_message)

func _on_score_submitted(success: bool) -> void:
	score_submitted.emit(success)

## Fetch top 10 scores from the last 24 hours
func fetch_top_10_today() -> Array:
	if _impl:
		return await _impl.fetch_top_10_today()
	print("Error: SupabaseService implementation not loaded")
	return []

## Submit a new score to the leaderboard
func submit_score(player_name: String, score: int, duration: float, difficulty: int) -> bool:
	if _impl:
		return await _impl.submit_score(player_name, score, duration, difficulty)
	print("Error: SupabaseService implementation not loaded")
	return false

## Check if a score qualifies for the top 10
func check_qualifies_for_top_10(score: int) -> bool:
	if _impl:
		return await _impl.check_qualifies_for_top_10(score)
	print("Error: SupabaseService implementation not loaded")
	return false

## Clear the cache
func clear_cache() -> void:
	if _impl:
		_impl.clear_cache()
