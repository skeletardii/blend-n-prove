extends Control

const ProgressTrackerTypes = preload("res://src/managers/ProgressTrackerTypes.gd")
const PieChart = preload("res://src/ui/PieChart.gd")
const CircleGraph = preload("res://src/ui/CircleGraph.gd")
const ScoreTrendGraph = preload("res://src/ui/ScoreTrendGraph.gd")
const GradeBadge = preload("res://src/ui/GradeBadge.gd")
const DifficultyRecommender = preload("res://src/managers/DifficultyRecommender.gd")

@onready var total_games_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/TotalGamesPanel/VBoxContainer/TotalGamesValue
@onready var high_score_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/HighScoreHeroPanel/VBoxContainer/HighScoreValue
@onready var longest_combo_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/LongestComboPanel/VBoxContainer/LongestComboValue
@onready var average_session_duration_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/AverageSessionDurationPanel/VBoxContainer/AverageSessionDurationValue
@onready var longest_session_duration_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/LongestSessionDurationPanel/VBoxContainer/LongestSessionDurationValue
@onready var average_orders_per_game_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/AverageOrdersPerGamePanel/VBoxContainer/AverageOrdersPerGameValue
@onready var games_ended_by_time_out_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/GamesEndedByTimeOutPanel/VBoxContainer/GamesEndedByTimeOutValue
@onready var games_ended_by_quit_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/GamesEndedByQuitPanel/VBoxContainer/GamesEndedByQuitValue
@onready var average_time_remaining_on_quit_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/AverageTimeRemainingOnQuitPanel/VBoxContainer/AverageTimeRemainingOnQuitValue
@onready var back_button: Button = $ButtonContainer/BackButton

const CARD_STYLE = preload("res://assets/styles/dark_inventory_panel.tres")
const HEADER_FONT = preload("res://assets/fonts/MuseoSansRounded1000.otf")
const BODY_FONT = preload("res://assets/fonts/MuseoSansRounded500.otf")

# Difficulty recommendation dismissal state
var _difficulty_recommendation_dismissed: bool = false

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
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")

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
	longest_combo_value.text = str(stats.longest_orders_combo_overall)
	average_session_duration_value.text = "%ds" % int(stats.average_session_duration_overall)
	longest_session_duration_value.text = "%ds" % int(stats.longest_session_duration_overall)
	average_orders_per_game_value.text = "%.1f" % stats.average_orders_per_game_overall
	games_ended_by_time_out_value.text = str(stats.games_ended_by_time_out)
	games_ended_by_quit_value.text = str(stats.games_ended_by_quit)
	average_time_remaining_on_quit_value.text = "%ds" % int(stats.average_time_remaining_on_quit)

	# Could add more detailed statistics here
	update_detailed_stats()
func update_detailed_stats() -> void:
	var stats = ProgressTracker.statistics
	var stats_container = $MainScrollContainer/StatsContainer

	# Remove existing detailed sections (if any) to rebuild them
	for child in stats_container.get_children():
		if child.name.begins_with("DetailedSection"):
			child.queue_free()

	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	spacer.name = "DetailedSectionSpacer1"
	stats_container.add_child(spacer)

	# Add difficulty recommendation (if not dismissed)
	if not _difficulty_recommendation_dismissed:
		add_difficulty_recommendation_section()

	# Add visual breakdown
	add_visual_breakdown_section(stats)

	# Add score trend graph
	add_score_trend_section()

	# Add achievements section
	if stats.achievements_unlocked.size() > 0:
		add_achievements_section(stats)

	# Add difficulty breakdown
	add_difficulty_breakdown_section(stats)

	# Add operation statistics
	add_operation_statistics_section()

	# Add recent sessions
	add_recent_sessions_section()
	
	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 20)
	bottom_spacer.name = "DetailedSectionSpacerBottom"
	stats_container.add_child(bottom_spacer)

func _create_styled_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CARD_STYLE)
	return panel

func _create_section_title(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", HEADER_FONT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func add_achievements_section(stats: ProgressTrackerTypes.PlayerStatistics) -> void:
	var stats_container = $MainScrollContainer/StatsContainer

	var section = VBoxContainer.new()
	section.name = "DetailedSectionAchievements"
	stats_container.add_child(section)

	section.add_child(_create_section_title("Achievements Unlocked (" + str(stats.achievements_unlocked.size()) + ")"))
	
	var panel = _create_styled_panel()
	section.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	panel.add_child(margin)

	var achievements_grid = GridContainer.new()
	achievements_grid.columns = 2
	achievements_grid.add_theme_constant_override("h_separation", 10)
	achievements_grid.add_theme_constant_override("v_separation", 8)
	margin.add_child(achievements_grid)

	for achievement_id in stats.achievements_unlocked:
		var achievement_label = Label.new()
		achievement_label.text = "🏆 " + ProgressTracker.get_achievement_name(achievement_id)
		achievement_label.add_theme_font_override("font", BODY_FONT)
		achievement_label.add_theme_font_size_override("font_size", 18)
		achievement_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		achievements_grid.add_child(achievement_label)

func add_difficulty_breakdown_section(stats: ProgressTrackerTypes.PlayerStatistics) -> void:
	var stats_container = $MainScrollContainer/StatsContainer
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	spacer.name = "DetailedSectionSpacerDiff"
	stats_container.add_child(spacer)

	var section = VBoxContainer.new()
	section.name = "DetailedSectionDifficulty"
	stats_container.add_child(section)

	section.add_child(_create_section_title("Performance by Difficulty"))

	var panel = _create_styled_panel()
	section.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	panel.add_child(margin)

	var difficulty_grid = GridContainer.new()
	difficulty_grid.columns = 3
	difficulty_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty_grid.add_theme_constant_override("h_separation", 10)
	difficulty_grid.add_theme_constant_override("v_separation", 8)
	margin.add_child(difficulty_grid)

	# Headers
	var headers = ["Level", "High Score", "Average"]
	for h in headers:
		var lbl = Label.new()
		lbl.text = h
		lbl.add_theme_font_override("font", BODY_FONT)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.modulate = Color(0.2, 0.2, 0.2, 1)
		difficulty_grid.add_child(lbl)

	for difficulty in range(1, 6):
		var level_label = Label.new()
		level_label.text = str(difficulty)
		level_label.add_theme_font_override("font", HEADER_FONT)
		level_label.add_theme_font_size_override("font_size", 18)
		level_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		difficulty_grid.add_child(level_label)

		var high_score_label = Label.new()
		high_score_label.text = str(stats.high_scores_by_difficulty.get(difficulty, 0))
		high_score_label.add_theme_font_override("font", BODY_FONT)
		high_score_label.add_theme_font_size_override("font_size", 18)
		high_score_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		difficulty_grid.add_child(high_score_label)

		var avg_score_label = Label.new()
		var avg_score = stats.average_scores_by_difficulty.get(difficulty, 0.0)
		avg_score_label.text = "%.0f" % avg_score if avg_score > 0 else "-"
		avg_score_label.add_theme_font_override("font", BODY_FONT)
		avg_score_label.add_theme_font_size_override("font_size", 18)
		avg_score_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		difficulty_grid.add_child(avg_score_label)

func add_operation_statistics_section() -> void:
	var stats = ProgressTracker.statistics

	# Skip if no operations have been used
	if stats.operation_usage_count.is_empty():
		return

	var stats_container = $MainScrollContainer/StatsContainer

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	spacer.name = "DetailedSectionSpacerOp"
	stats_container.add_child(spacer)

	var section = VBoxContainer.new()
	section.name = "DetailedSectionOperations"
	stats_container.add_child(section)

	section.add_child(_create_section_title("Operation Mastery"))

	var panel = _create_styled_panel()
	section.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	panel.add_child(margin)

	var operations_vbox = VBoxContainer.new()
	operations_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(operations_vbox)

	# Sort operations by mastery (highest first)
	var sorted_operations = stats.operation_usage_count.keys()
	sorted_operations.sort_custom(func(a, b):
		return _calculate_operation_mastery(a, stats) > _calculate_operation_mastery(b, stats)
	)

	# Display each operation with mastery bar
	for operation_name in sorted_operations:
		var count = stats.operation_usage_count[operation_name]
		var mastery = _calculate_operation_mastery(operation_name, stats)
		var mastery_color = _get_mastery_color(mastery)

		# Operation container
		var op_container = VBoxContainer.new()
		op_container.add_theme_constant_override("separation", 4)
		operations_vbox.add_child(op_container)

		# Info row (name, uses, mastery %)
		var info_row = HBoxContainer.new()
		info_row.add_theme_constant_override("separation", 8)
		op_container.add_child(info_row)

		var name_label = Label.new()
		name_label.text = operation_name
		name_label.add_theme_font_override("font", HEADER_FONT)
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_row.add_child(name_label)

		var count_label = Label.new()
		count_label.text = str(count) + " uses"
		count_label.add_theme_font_override("font", BODY_FONT)
		count_label.add_theme_font_size_override("font_size", 16)
		count_label.modulate = Color(0.2, 0.2, 0.2, 1)
		info_row.add_child(count_label)

		var mastery_label = Label.new()
		mastery_label.text = "%.0f%%" % mastery
		mastery_label.add_theme_font_override("font", BODY_FONT)
		mastery_label.add_theme_font_size_override("font_size", 16)
		mastery_label.modulate = mastery_color
		info_row.add_child(mastery_label)

		# Progress bar (custom drawn Control)
		var progress_bar = _create_mastery_progress_bar(mastery, mastery_color)
		op_container.add_child(progress_bar)

func add_recent_sessions_section() -> void:
	var stats_container = $MainScrollContainer/StatsContainer

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	spacer.name = "DetailedSectionSpacerRecent"
	stats_container.add_child(spacer)

	var section = VBoxContainer.new()
	section.name = "DetailedSectionRecentSessions"
	stats_container.add_child(section)

	section.add_child(_create_section_title("Recent Games"))

	var recent_sessions = ProgressTracker.get_recent_sessions(5)
	if recent_sessions.is_empty():
		var no_games_label = Label.new()
		no_games_label.text = "No games played yet"
		no_games_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		no_games_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(no_games_label)
		return

	# Instead of a grid, let's use a VBox of Panels for each session (mobile friendly)
	var list_container = VBoxContainer.new()
	section.add_child(list_container)

	for session in recent_sessions:
		var card = _create_styled_panel()
		list_container.add_child(card)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		card.add_child(margin)
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		margin.add_child(row)

		# Grade badge (left side)
		var stats = ProgressTracker.statistics
		var grade = ProgressTrackerTypes.GradeCalculator.calculate_session_grade(session, stats)
		var badge = GradeBadge.new()
		badge.set_grade(grade)
		badge.custom_minimum_size = Vector2(50, 50)
		row.add_child(badge)

		# Middle: Date & Result
		var left_vbox = VBoxContainer.new()
		left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left_vbox)
		
		var timestamp_parts = session.timestamp.split("T")
		var date_str = timestamp_parts[0] if timestamp_parts.size() > 0 else session.timestamp
		var date_label = Label.new()
		date_label.text = date_str
		date_label.add_theme_font_override("font", BODY_FONT)
		date_label.add_theme_font_size_override("font_size", 16)
		date_label.modulate = Color(0.2, 0.2, 0.2, 1)
		left_vbox.add_child(date_label)

		var result_label = Label.new()
		match session.completion_status:
			"time_out":
				result_label.text = "TIME OUT"
				result_label.modulate = Color.RED
			"quit":
				result_label.text = "QUIT"
				result_label.modulate = Color.ORANGE
			_: # This will catch "incomplete" or any other unexpected status
				result_label.text = "INCOMPLETE"
				result_label.modulate = Color.GRAY
		result_label.add_theme_font_override("font", HEADER_FONT)
		result_label.add_theme_font_size_override("font_size", 24)
		left_vbox.add_child(result_label)
		
		# Right side: Score & Difficulty
		var right_vbox = VBoxContainer.new()
		row.add_child(right_vbox)

		# Score row with delta indicator
		var score_row = HBoxContainer.new()
		score_row.add_theme_constant_override("separation", 6)
		score_row.alignment = BoxContainer.ALIGNMENT_END
		right_vbox.add_child(score_row)

		var score_label = Label.new()
		score_label.text = "Score: " + str(session.final_score)
		score_label.add_theme_font_override("font", HEADER_FONT)
		score_label.add_theme_font_size_override("font_size", 20)
		score_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		score_row.add_child(score_label)

		# Delta indicator
		var delta_data = _calculate_score_delta(session, stats)
		if delta_data.show:
			var delta_label = Label.new()
			delta_label.text = _format_delta_text(delta_data)
			delta_label.add_theme_font_override("font", BODY_FONT)
			delta_label.add_theme_font_size_override("font_size", 14)
			delta_label.modulate = _get_delta_color(delta_data)
			score_row.add_child(delta_label)

		var diff_label = Label.new()
		diff_label.text = "Lvl " + str(session.difficulty_level)
		diff_label.add_theme_font_override("font", BODY_FONT)
		diff_label.add_theme_font_size_override("font_size", 16)
		diff_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right_vbox.add_child(diff_label)

func add_visual_breakdown_section(stats: ProgressTrackerTypes.PlayerStatistics) -> void:
	var stats_container = $MainScrollContainer/StatsContainer
	
	var section = VBoxContainer.new()
	section.name = "DetailedSectionVisuals"
	stats_container.add_child(section)

	section.add_child(_create_section_title("Visual Breakdown"))
	
	var panel = _create_styled_panel()
	section.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)

	# 2. Operations Pie Chart (if data exists) - Bottom
	if not stats.operation_usage_count.is_empty():
		var pie_root_vbox = VBoxContainer.new()
		pie_root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		main_vbox.add_child(pie_root_vbox)

		var pie_label = Label.new()
		pie_label.text = "Operations Used"
		pie_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pie_label.add_theme_font_override("font", BODY_FONT)
		pie_label.add_theme_font_size_override("font_size", 18)
		pie_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		pie_root_vbox.add_child(pie_label)

		# Horizontal box for Pie + Legend
		var pie_h_box = HBoxContainer.new()
		pie_h_box.alignment = BoxContainer.ALIGNMENT_CENTER
		pie_h_box.add_theme_constant_override("separation", 20)
		pie_root_vbox.add_child(pie_h_box)

		var pie = PieChart.new()
		pie.custom_minimum_size = Vector2(180, 180)
		pie.set_data(stats.operation_usage_count)
		pie_h_box.add_child(pie)

		# Legend
		var legend_vbox = VBoxContainer.new()
		legend_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		pie_h_box.add_child(legend_vbox)

		var legend_data = pie.get_legend_data()
		for item in legend_data:
			var item_hbox = HBoxContainer.new()
			legend_vbox.add_child(item_hbox)

			var color_rect = ColorRect.new()
			color_rect.custom_minimum_size = Vector2(15, 15)
			color_rect.color = item["color"]
			item_hbox.add_child(color_rect)

			var name_lbl = Label.new()
			name_lbl.text = item["name"]
			name_lbl.add_theme_font_override("font", BODY_FONT)
			name_lbl.add_theme_font_size_override("font_size", 14)
			name_lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
			item_hbox.add_child(name_lbl)

func add_score_trend_section() -> void:
	var stats_container = $MainScrollContainer/StatsContainer

	# Add spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	spacer.name = "DetailedSectionSpacerTrend"
	stats_container.add_child(spacer)

	var section = VBoxContainer.new()
	section.name = "DetailedSectionScoreTrend"
	stats_container.add_child(section)

	section.add_child(_create_section_title("Score Trend"))

	# Time period selector buttons
	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 8)
	section.add_child(button_row)

	var button_group = ButtonGroup.new()
	for period in ["7D", "14D", "30D"]:
		var btn = Button.new()
		btn.text = period
		btn.custom_minimum_size = Vector2(60, 44)
		btn.button_group = button_group
		btn.toggle_mode = true
		if period == "7D":
			btn.button_pressed = true  # Default selection
		btn.pressed.connect(_on_trend_period_changed.bind(period))
		button_row.add_child(btn)

	var panel = _create_styled_panel()
	section.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	panel.add_child(margin)

	var graph = ScoreTrendGraph.new()
	graph.custom_minimum_size = Vector2(696, 250)
	graph.name = "ScoreTrendGraph"
	graph.set_sessions(ProgressTracker.game_sessions, 7)  # Default 7 days
	margin.add_child(graph)

func _on_trend_period_changed(period: String) -> void:
	var graph_path = "MainScrollContainer/StatsContainer/DetailedSectionScoreTrend/PanelContainer/MarginContainer/ScoreTrendGraph"
	var graph = get_node_or_null(graph_path)
	if graph:
		var days = 7 if period == "7D" else (14 if period == "14D" else 30)
		graph.set_sessions(ProgressTracker.game_sessions, days)

func add_difficulty_recommendation_section() -> void:
	var stats = ProgressTracker.statistics
	var sessions = ProgressTracker.game_sessions

	var recommendation = DifficultyRecommender.get_recommendation(stats, sessions)

	# Only show if recommendation has meaningful confidence
	if recommendation.confidence == "default":
		return  # Not enough data

	var stats_container = $MainScrollContainer/StatsContainer

	var section = VBoxContainer.new()
	section.name = "DetailedSectionRecommendation"
	stats_container.add_child(section)

	var panel = _create_styled_panel()
	section.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	panel.add_child(margin)

	var main_row = HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 12)
	margin.add_child(main_row)

	# Icon container (left side)
	var icon_bg = ColorRect.new()
	icon_bg.custom_minimum_size = Vector2(60, 60)
	icon_bg.color = Color(0.2, 0.5, 0.9, 0.2)  # Light blue tint
	main_row.add_child(icon_bg)

	var icon_label = Label.new()
	icon_label.text = "📊"  # Chart emoji
	icon_label.add_theme_font_size_override("font_size", 36)
	icon_label.position = Vector2(12, 12)
	icon_bg.add_child(icon_label)

	# Content (middle)
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 4)
	main_row.add_child(content_vbox)

	var title = Label.new()
	title.text = "Recommended Difficulty"
	title.add_theme_font_override("font", HEADER_FONT)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	content_vbox.add_child(title)

	var level_row = HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 8)
	content_vbox.add_child(level_row)

	var level_text = Label.new()
	level_text.text = "Level"
	level_text.add_theme_font_override("font", BODY_FONT)
	level_text.add_theme_font_size_override("font_size", 28)
	level_text.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	level_row.add_child(level_text)

	var level_number = Label.new()
	level_number.text = str(recommendation.level)
	level_number.add_theme_font_override("font", HEADER_FONT)
	level_number.add_theme_font_size_override("font_size", 36)
	level_number.modulate = Color(0.9, 0.6, 0.2)  # Orange
	level_row.add_child(level_number)

	# Trend indicator
	var current_fav = stats.favorite_difficulty
	if recommendation.level > current_fav:
		var up_arrow = Label.new()
		up_arrow.text = "↑"
		up_arrow.add_theme_font_size_override("font_size", 24)
		up_arrow.modulate = Color.GREEN
		level_row.add_child(up_arrow)
	elif recommendation.level < current_fav:
		var down_arrow = Label.new()
		down_arrow.text = "↓"
		down_arrow.add_theme_font_size_override("font_size", 24)
		down_arrow.modulate = Color.ORANGE
		level_row.add_child(down_arrow)

	var reasoning = Label.new()
	reasoning.text = recommendation.reasoning
	reasoning.add_theme_font_override("font", BODY_FONT)
	reasoning.add_theme_font_size_override("font_size", 16)
	reasoning.modulate = Color(0.2, 0.2, 0.2, 1)
	reasoning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_vbox.add_child(reasoning)

	# Dismiss button (right side)
	var dismiss_btn = Button.new()
	dismiss_btn.text = "×"
	dismiss_btn.custom_minimum_size = Vector2(44, 44)
	dismiss_btn.add_theme_font_size_override("font_size", 32)
	dismiss_btn.pressed.connect(_on_recommendation_dismissed)
	main_row.add_child(dismiss_btn)

func _on_recommendation_dismissed() -> void:
	_difficulty_recommendation_dismissed = true
	var section = $MainScrollContainer/StatsContainer/DetailedSectionRecommendation
	if section:
		section.queue_free()

## Calculate operation mastery percentage (0-100)
## Mastery = (success_rate × 70%) + (experience_bonus × 30%)
func _calculate_operation_mastery(operation_name: String, stats: ProgressTrackerTypes.PlayerStatistics) -> float:
	if not stats.operation_proficiency.has(operation_name):
		return 0.0

	var proficiency = stats.operation_proficiency[operation_name]
	var success_rate: float = proficiency.get("rate", 0.0)  # 0.0 to 1.0
	var usage_count: int = stats.operation_usage_count.get(operation_name, 0)

	# Mastery formula: weighted combination of success rate and experience
	# - Success rate: 70% weight (skill matters most)
	# - Experience bonus: 30% weight (usage count, capped at 50 uses)

	var skill_component: float = success_rate * 70.0  # Max 70 points from skill

	var experience_ratio: float = min(float(usage_count) / 50.0, 1.0)  # Cap at 50 uses
	var experience_component: float = experience_ratio * 30.0  # Max 30 points from experience

	var mastery_percentage: float = skill_component + experience_component

	return clamp(mastery_percentage, 0.0, 100.0)

## Get color for mastery percentage
func _get_mastery_color(mastery: float) -> Color:
	if mastery >= 80.0:
		return Color(0.2, 0.8, 0.2)  # GREEN - mastered
	elif mastery >= 50.0:
		return Color(0.9, 0.9, 0.2)  # YELLOW - developing
	else:
		return Color(0.9, 0.2, 0.2)  # RED - needs practice

## Create a custom progress bar for mastery display
func _create_mastery_progress_bar(mastery: float, color: Color) -> Control:
	var bar = Control.new()
	bar.custom_minimum_size = Vector2(0, 8)

	# Connect draw signal to draw the progress bar
	bar.draw.connect(func():
		var bg_color = Color(0.85, 0.85, 0.85)
		var border_color = Color(0.2, 0.2, 0.2)

		# Background
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), bg_color)

		# Fill (based on mastery percentage)
		var fill_width = bar.size.x * (mastery / 100.0)
		bar.draw_rect(Rect2(Vector2.ZERO, Vector2(fill_width, bar.size.y)), color)

		# Border
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), border_color, false, 1.0)
	)

	bar.queue_redraw()
	return bar

## Calculate score delta compared to personal average
## Returns: {"delta": int, "is_positive": bool, "percentage": float, "show": bool}
func _calculate_score_delta(session: ProgressTrackerTypes.GameSession, stats: ProgressTrackerTypes.PlayerStatistics) -> Dictionary:
	var difficulty: int = session.difficulty_level
	var session_score: int = session.final_score

	# Get personal average for this difficulty
	var avg_score: float = stats.average_scores_by_difficulty.get(difficulty, 0.0)

	if avg_score == 0.0:
		# First session at this difficulty
		return {
			"delta": 0,
			"is_positive": true,
			"percentage": 0.0,
			"show": false  # Don't show delta on first attempt
		}

	var delta: int = int(session_score - avg_score)
	var percentage: float = (delta / avg_score) * 100.0 if avg_score > 0 else 0.0

	return {
		"delta": delta,
		"is_positive": delta >= 0,
		"percentage": percentage,
		"show": true
	}

## Format delta text for display
## Returns: "+150 (↑)" or "-75 (↓)"
func _format_delta_text(delta_data: Dictionary) -> String:
	if not delta_data.show:
		return ""

	var sign: String = "+" if delta_data.is_positive else ""
	var arrow: String = "↑" if delta_data.is_positive else "↓"

	return "%s%d (%s)" % [sign, delta_data.delta, arrow]

## Get color for delta indicator
func _get_delta_color(delta_data: Dictionary) -> Color:
	if not delta_data.show:
		return Color.GRAY

	if delta_data.is_positive:
		# Above average
		if delta_data.percentage >= 20.0:
			return Color(0.2, 0.8, 0.2)  # GREEN - excellent (20%+ above avg)
		else:
			return Color(0.2, 0.8, 0.8)  # CYAN - good (slightly above avg)
	else:
		# Below average
		if delta_data.percentage <= -20.0:
			return Color(0.9, 0.2, 0.2)  # RED - significantly below (-20% or worse)
		else:
			return Color(0.9, 0.6, 0.2)  # ORANGE - slightly below (between 0% and -20%)
