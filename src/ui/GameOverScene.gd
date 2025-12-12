extends Control

const ProgressTrackerTypes = preload("res://src/managers/ProgressTrackerTypes.gd")
const GradeBadge = preload("res://src/ui/GradeBadge.gd")

@onready var final_score_label: Label = $GameOverPanel/GameOverContainer/FinalScore

# Store leaderboard qualification status
var qualifies_for_leaderboard: bool = false
var leaderboard_button: Button = null

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

	# Add grade display (hero badge)
	var recent_sessions = ProgressTracker.get_recent_sessions(1)
	if recent_sessions.size() > 0:
		var grade_section = VBoxContainer.new()
		grade_section.alignment = BoxContainer.ALIGNMENT_CENTER
		grade_section.add_theme_constant_override("separation", 12)
		game_over_container.add_child(grade_section)

		var grade_title = Label.new()
		grade_title.text = "Your Grade"
		grade_title.add_theme_font_size_override("font_size", 36)
		grade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grade_title.modulate = Color.BLACK
		grade_section.add_child(grade_title)

		# Calculate grade
		var grade = ProgressTrackerTypes.GradeCalculator.calculate_session_grade(
			recent_sessions[0], stats
		)

		# Create hero badge (120x120px)
		var badge = GradeBadge.new()
		badge.set_grade(grade)
		badge.custom_minimum_size = Vector2(120, 120)
		grade_section.add_child(badge)

		# Grade description
		var grade_desc = Label.new()
		grade_desc.text = ProgressTrackerTypes.GradeCalculator.get_grade_description(grade)
		grade_desc.add_theme_font_size_override("font_size", 24)
		grade_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grade_desc.modulate = Color.BLACK
		grade_section.add_child(grade_desc)

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
	# Calculate completion rate (time_out = completed successfully)
	if stats.total_games_played > 0:
		var completion_rate = (float(stats.games_ended_by_time_out) / float(stats.total_games_played)) * 100.0
		games_info.text += " | Completion rate: %.1f%%" % completion_rate
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

	# Always show progress context first
	# If score is 0, skip leaderboard check
	if current_score <= 0:
		qualifies_for_leaderboard = false
		add_progress_context()
		return

	# Show progress context immediately (with grade)
	add_progress_context()

	# Add checking message at the bottom
	var game_over_container = $GameOverPanel/GameOverContainer
	var checking_label = Label.new()
	checking_label.text = "Checking leaderboard..."
	checking_label.add_theme_font_size_override("font_size", 20)
	checking_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checking_label.modulate = Color(0.5, 0.5, 0.5, 1)
	game_over_container.add_child(checking_label)

	# Check if score qualifies for top 10
	var qualifies = await SupabaseService.check_qualifies_for_top_10(current_score)

	# Remove checking label
	checking_label.queue_free()

	# Store qualification status
	qualifies_for_leaderboard = qualifies

	# Add leaderboard button if qualified
	if qualifies:
		add_leaderboard_button()

func add_leaderboard_button() -> void:
	var game_over_container = $GameOverPanel/GameOverContainer

	# Add spacer before button
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	game_over_container.add_child(spacer)

	# Add celebration message
	var qualify_label = Label.new()
	qualify_label.text = "🎉 YOU MADE THE TOP 10! 🎉"
	qualify_label.add_theme_font_size_override("font_size", 32)
	qualify_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qualify_label.modulate = Color(0.9, 0.6, 0.0)  # Gold/orange color
	game_over_container.add_child(qualify_label)

	# Add small spacer
	var small_spacer = Control.new()
	small_spacer.custom_minimum_size = Vector2(0, 10)
	game_over_container.add_child(small_spacer)

	# Create leaderboard button
	leaderboard_button = Button.new()
	leaderboard_button.custom_minimum_size = Vector2(400, 70)
	leaderboard_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	leaderboard_button.add_theme_font_size_override("font_size", 28)
	leaderboard_button.text = "SUBMIT HIGH SCORE"
	leaderboard_button.pressed.connect(_on_submit_high_score_pressed)
	game_over_container.add_child(leaderboard_button)

func _on_submit_high_score_pressed() -> void:
	AudioManager.play_button_click()
	transition_to_high_score_entry()

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
