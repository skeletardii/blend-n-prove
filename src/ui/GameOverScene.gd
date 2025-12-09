extends Control

@onready var final_score_label: Label = $GameOverPanel/GameOverContainer/FinalScore

func _ready() -> void:
	# Wait a brief moment before stopping music to avoid cutting off game over sound
	await get_tree().create_timer(0.2).timeout
	AudioManager.stop_music()

	# Display final score
	final_score_label.text = "Final Score: " + str(GameManager.current_score)

	# Connect to game manager for state changes
	GameManager.game_state_changed.connect(_on_game_state_changed)

	# Check for leaderboard qualification FIRST
	await check_leaderboard_qualification()

func _on_play_again_button_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.reset_game()
	SceneManager.change_scene("res://src/scenes/GameplayScene.tscn")
	GameManager.start_new_game()

func _on_main_menu_button_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.reset_game()
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	# Handle any state changes if needed
	pass

func add_progress_context() -> void:
	var stats = ProgressTracker.statistics
	var game_over_container = $GameOverPanel/GameOverContainer
	var current_score = GameManager.current_score

	# Add spacer before progress info
	var spacer_before = Control.new()
	spacer_before.custom_minimum_size = Vector2(0, 20)
	game_over_container.add_child(spacer_before)

	# Add progress information labels
	var progress_info = VBoxContainer.new()
	progress_info.name = "ProgressInfo"
	progress_info.add_theme_constant_override("separation", 15)
	game_over_container.add_child(progress_info)

	# High Score Comparison
	var high_score_comparison = Label.new()
	high_score_comparison.add_theme_font_size_override("font_size", 28)
	high_score_comparison.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if current_score > stats.high_score_overall:
		high_score_comparison.text = "🎉 NEW HIGH SCORE! 🎉"
		high_score_comparison.modulate = Color.BLACK
	elif current_score > stats.high_score_overall * 0.8:
		high_score_comparison.text = "Great performance! Close to your best: " + str(stats.high_score_overall)
		high_score_comparison.modulate = Color.BLACK
	else:
		high_score_comparison.text = "Your best score: " + str(stats.high_score_overall)
		high_score_comparison.modulate = Color.BLACK
	progress_info.add_child(high_score_comparison)

	# Games Played
	var games_info = Label.new()
	games_info.add_theme_font_size_override("font_size", 24)
	games_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	games_info.text = "Games played: " + str(stats.total_games_played)
	if stats.total_games_played > 0:
		games_info.text += " | Success rate: %.1f%%" % (stats.success_rate * 100.0)
	progress_info.add_child(games_info)

	# Achievement notifications (if any recent unlocks)
	var recent_achievements = get_recent_achievements()
	if recent_achievements.size() > 0:
		var achievement_label = Label.new()
		achievement_label.add_theme_font_size_override("font_size", 24)
		achievement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		achievement_label.text = "🏆 Recent Achievement: " + recent_achievements[0]
		achievement_label.modulate = Color.BLACK
		progress_info.add_child(achievement_label)

	# Encouragement based on performance
	var encouragement = Label.new()
	encouragement.add_theme_font_size_override("font_size", 24)
	encouragement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if current_score == 0:
		encouragement.text = "Keep practicing! Every expert was once a beginner."
	elif current_score < stats.average_score_overall:
		encouragement.text = "You can do better! Your average is " + str(int(stats.average_score_overall))
	else:
		encouragement.text = "Above your average! Keep up the great work!"
	encouragement.modulate = Color.BLACK
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

func check_leaderboard_qualification() -> void:
	var current_score = GameManager.current_score

	# Skip leaderboard check if score is 0
	if current_score <= 0:
		add_progress_context()
		return

	# Add checking message
	var game_over_container = $GameOverPanel/GameOverContainer
	var checking_label = Label.new()
	checking_label.text = "Checking leaderboard..."
	checking_label.add_theme_font_size_override("font_size", 24)
	checking_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checking_label.modulate = Color(0.7, 0.7, 0.7, 1)
	game_over_container.add_child(checking_label)

	# Check if score qualifies for top 10
	var qualifies = await SupabaseService.check_qualifies_for_top_10(current_score)

	# Remove checking label
	checking_label.queue_free()

	if qualifies:
		# Transition to high score entry scene
		transition_to_high_score_entry()
	else:
		# Show normal game over
		add_progress_context()

func transition_to_high_score_entry() -> void:
	# Get session data
	var session_duration = 0.0
	var difficulty = GameManager.difficulty_level if GameManager else 1

	# Try to get session duration from ProgressTracker
	var recent_sessions = ProgressTracker.get_recent_sessions(1)
	if recent_sessions.size() > 0:
		session_duration = recent_sessions[0].session_duration

	# Store pending entry data
	LeaderboardData.set_pending_entry(
		GameManager.current_score,
		session_duration,
		difficulty
	)

	# Transition to high score entry scene
	await get_tree().create_timer(0.3).timeout
	SceneManager.change_scene("res://src/ui/HighScoreEntryScene.tscn")