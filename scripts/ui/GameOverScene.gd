extends Control

@onready var final_score_label: Label = $GameOverContainer/FinalScore

func _ready() -> void:
	AudioManager.stop_music()

	# Display final score
	final_score_label.text = "Final Score: " + str(GameManager.current_score)

	# Connect to game manager for state changes
	GameManager.game_state_changed.connect(_on_game_state_changed)

	# Add progress context
	add_progress_context()

func _on_play_again_button_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.reset_game()
	SceneManager.change_scene("res://scenes/GameplayScene.tscn")
	GameManager.start_new_game()

func _on_main_menu_button_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.reset_game()
	SceneManager.change_scene("res://scenes/MainMenu.tscn")

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	# Handle any state changes if needed
	pass

func add_progress_context() -> void:
	var stats = ProgressTracker.statistics
	var game_over_container = $GameOverContainer
	var current_score = GameManager.current_score

	# Add progress information labels
	var progress_info = VBoxContainer.new()
	progress_info.name = "ProgressInfo"
	game_over_container.add_child(progress_info)

	# High Score Comparison
	var high_score_comparison = Label.new()
	if current_score > stats.high_score_overall:
		high_score_comparison.text = "🎉 NEW HIGH SCORE! 🎉"
		high_score_comparison.modulate = Color.GOLD
	elif current_score > stats.high_score_overall * 0.8:
		high_score_comparison.text = "Great performance! Close to your best: " + str(stats.high_score_overall)
		high_score_comparison.modulate = Color.GREEN
	else:
		high_score_comparison.text = "Your best score: " + str(stats.high_score_overall)
		high_score_comparison.modulate = Color.WHITE
	progress_info.add_child(high_score_comparison)

	# Streak Information
	var streak_info = Label.new()
	if stats.current_streak > 0:
		streak_info.text = "Streak: " + str(stats.current_streak) + " games"
		if stats.current_streak == stats.best_streak:
			streak_info.text += " (Your Best!)"
			streak_info.modulate = Color.GOLD
		else:
			streak_info.modulate = Color.GREEN
	else:
		streak_info.text = "Your best streak: " + str(stats.best_streak) + " games"
		streak_info.modulate = Color.WHITE
	progress_info.add_child(streak_info)

	# Games Played
	var games_info = Label.new()
	games_info.text = "Games played: " + str(stats.total_games_played)
	if stats.total_games_played > 0:
		games_info.text += " | Success rate: %.1f%%" % (stats.success_rate * 100.0)
	progress_info.add_child(games_info)

	# Achievement notifications (if any recent unlocks)
	var recent_achievements = get_recent_achievements()
	if recent_achievements.size() > 0:
		var achievement_label = Label.new()
		achievement_label.text = "🏆 Recent Achievement: " + recent_achievements[0]
		achievement_label.modulate = Color.YELLOW
		progress_info.add_child(achievement_label)

	# Encouragement based on performance
	var encouragement = Label.new()
	if current_score == 0:
		encouragement.text = "Keep practicing! Every expert was once a beginner."
	elif current_score < stats.average_score_overall:
		encouragement.text = "You can do better! Your average is " + str(int(stats.average_score_overall))
	else:
		encouragement.text = "Above your average! Keep up the great work!"
	encouragement.modulate = Color.CYAN
	progress_info.add_child(encouragement)

func get_recent_achievements() -> Array[String]:
	# Get achievements that were unlocked in recent sessions
	# This is a simplified version - could be enhanced to track "new" achievements
	var recent_sessions = ProgressTracker.get_recent_sessions(1)
	if recent_sessions.size() > 0:
		# For now, just return the latest achievement names if any exist
		var stats = ProgressTracker.statistics
		if stats.achievements_unlocked.size() > 0:
			var latest_achievement = stats.achievements_unlocked[-1]
			return [ProgressTracker.get_achievement_name(latest_achievement)]
	return []