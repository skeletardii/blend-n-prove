extends Control

@onready var total_games_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/TotalGamesValue
@onready var high_score_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/HighScoreValue
@onready var success_rate_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/SuccessRateValue
@onready var current_streak_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/CurrentStreakValue
@onready var back_button: Button = $ButtonContainer/BackButton

func _ready() -> void:
	# Connect button
	back_button.pressed.connect(_on_back_button_pressed)

	# Connect to progress tracker updates
	ProgressTracker.progress_updated.connect(_on_progress_updated)
	ProgressTracker.achievement_unlocked.connect(_on_achievement_unlocked)

	# Initial update
	update_statistics()

func _on_back_button_pressed() -> void:
	AudioManager.play_button_click()
	SceneManager.change_scene("res://scenes/MainMenu.tscn")

func _on_progress_updated() -> void:
	update_statistics()

func _on_achievement_unlocked(achievement_name: String) -> void:
	var display_name = ProgressTracker.get_achievement_name(achievement_name)
	print("🏆 Achievement Unlocked: " + display_name)
	# TODO: Could add a popup or notification here

func update_statistics() -> void:
	var stats = ProgressTracker.statistics

	# Update basic stats
	total_games_value.text = str(stats.total_games_played)
	high_score_value.text = str(stats.high_score_overall)

	if stats.total_games_played > 0:
		success_rate_value.text = "%.1f%%" % (stats.success_rate * 100.0)
	else:
		success_rate_value.text = "0.0%"

	current_streak_value.text = str(stats.current_streak)

	# Could add more detailed statistics here
	update_detailed_stats()

func update_detailed_stats() -> void:
	var stats = ProgressTracker.statistics
	var stats_container = $MainScrollContainer/StatsContainer

	# Remove existing detailed sections (if any) to rebuild them
	for child in stats_container.get_children():
		if child.name.begins_with("DetailedSection"):
			child.queue_free()

	# Add achievements section
	if stats.achievements_unlocked.size() > 0:
		add_achievements_section(stats)

	# Add difficulty breakdown
	add_difficulty_breakdown_section(stats)

	# Add recent sessions
	add_recent_sessions_section()

func add_achievements_section(stats: ProgressTracker.PlayerStatistics) -> void:
	var stats_container = $MainScrollContainer/StatsContainer

	var separator = HSeparator.new()
	separator.name = "DetailedSectionSeparator1"
	stats_container.add_child(separator)

	var section = VBoxContainer.new()
	section.name = "DetailedSectionAchievements"
	stats_container.add_child(section)

	var title = Label.new()
	title.text = "Achievements Unlocked (" + str(stats.achievements_unlocked.size()) + ")"
	section.add_child(title)

	var achievements_grid = GridContainer.new()
	achievements_grid.columns = 1
	section.add_child(achievements_grid)

	for achievement_id in stats.achievements_unlocked:
		var achievement_label = Label.new()
		achievement_label.text = "🏆 " + ProgressTracker.get_achievement_name(achievement_id)
		achievements_grid.add_child(achievement_label)

func add_difficulty_breakdown_section(stats: ProgressTracker.PlayerStatistics) -> void:
	var stats_container = $MainScrollContainer/StatsContainer

	var separator = HSeparator.new()
	separator.name = "DetailedSectionSeparator2"
	stats_container.add_child(separator)

	var section = VBoxContainer.new()
	section.name = "DetailedSectionDifficulty"
	stats_container.add_child(section)

	var title = Label.new()
	title.text = "Performance by Difficulty"
	section.add_child(title)

	var difficulty_grid = GridContainer.new()
	difficulty_grid.columns = 3
	section.add_child(difficulty_grid)

	# Headers
	var header1 = Label.new()
	header1.text = "Level"
	difficulty_grid.add_child(header1)

	var header2 = Label.new()
	header2.text = "High Score"
	difficulty_grid.add_child(header2)

	var header3 = Label.new()
	header3.text = "Average"
	difficulty_grid.add_child(header3)

	for difficulty in range(1, 6):
		var level_label = Label.new()
		level_label.text = str(difficulty)
		difficulty_grid.add_child(level_label)

		var high_score_label = Label.new()
		high_score_label.text = str(stats.high_scores_by_difficulty.get(difficulty, 0))
		difficulty_grid.add_child(high_score_label)

		var avg_score_label = Label.new()
		var avg_score = stats.average_scores_by_difficulty.get(difficulty, 0.0)
		avg_score_label.text = "%.0f" % avg_score if avg_score > 0 else "-"
		difficulty_grid.add_child(avg_score_label)

func add_recent_sessions_section() -> void:
	var stats_container = $MainScrollContainer/StatsContainer

	var separator = HSeparator.new()
	separator.name = "DetailedSectionSeparator3"
	stats_container.add_child(separator)

	var section = VBoxContainer.new()
	section.name = "DetailedSectionRecentSessions"
	stats_container.add_child(section)

	var title = Label.new()
	title.text = "Recent Games"
	section.add_child(title)

	var recent_sessions = ProgressTracker.get_recent_sessions(5)
	if recent_sessions.is_empty():
		var no_games_label = Label.new()
		no_games_label.text = "No games played yet"
		section.add_child(no_games_label)
		return

	var sessions_grid = GridContainer.new()
	sessions_grid.columns = 4
	section.add_child(sessions_grid)

	# Headers
	var header1 = Label.new()
	header1.text = "Score"
	sessions_grid.add_child(header1)

	var header2 = Label.new()
	header2.text = "Difficulty"
	sessions_grid.add_child(header2)

	var header3 = Label.new()
	header3.text = "Result"
	sessions_grid.add_child(header3)

	var header4 = Label.new()
	header4.text = "Date"
	sessions_grid.add_child(header4)

	for session in recent_sessions:
		var score_label = Label.new()
		score_label.text = str(session.final_score)
		sessions_grid.add_child(score_label)

		var difficulty_label = Label.new()
		difficulty_label.text = str(session.difficulty_level)
		sessions_grid.add_child(difficulty_label)

		var result_label = Label.new()
		match session.completion_status:
			"win":
				result_label.text = "✓ Win"
				result_label.modulate = Color.GREEN
			"loss":
				result_label.text = "✗ Loss"
				result_label.modulate = Color.RED
			"quit":
				result_label.text = "⊘ Quit"
				result_label.modulate = Color.YELLOW
			_:
				result_label.text = "? Incomplete"
				result_label.modulate = Color.GRAY
		sessions_grid.add_child(result_label)

		var date_label = Label.new()
		# Extract just the date part from timestamp
		var timestamp_parts = session.timestamp.split("T")
		date_label.text = timestamp_parts[0] if timestamp_parts.size() > 0 else session.timestamp
		sessions_grid.add_child(date_label)