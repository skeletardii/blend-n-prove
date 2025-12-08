extends Control

const ProgressTrackerTypes = preload("res://src/managers/ProgressTrackerTypes.gd")
const PieChart = preload("res://src/ui/PieChart.gd")
const CircleGraph = preload("res://src/ui/CircleGraph.gd")

@onready var total_games_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/TotalGamesPanel/VBoxContainer/TotalGamesValue
@onready var high_score_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/HighScorePanel/VBoxContainer/HighScoreValue
@onready var success_rate_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/SuccessRatePanel/VBoxContainer/SuccessRateValue
@onready var current_streak_value: Label = $MainScrollContainer/StatsContainer/OverallStatsSection/OverallStatsGrid/CurrentStreakPanel/VBoxContainer/CurrentStreakValue
@onready var back_button: Button = $ButtonContainer/BackButton

const CARD_STYLE = preload("res://assets/styles/dark_inventory_panel.tres")
const HEADER_FONT = preload("res://assets/fonts/MuseoSansRounded1000.otf")
const BODY_FONT = preload("res://assets/fonts/MuseoSansRounded500.otf")

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

	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	spacer.name = "DetailedSectionSpacer1"
	stats_container.add_child(spacer)
	
	# Add visual breakdown
	add_visual_breakdown_section(stats)

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
	bottom_spacer.custom_minimum_size = Vector2(0, 40)
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
	label.add_theme_font_size_override("font_size", 24)
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
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	panel.add_child(margin)

	var achievements_grid = GridContainer.new()
	achievements_grid.columns = 1
	margin.add_child(achievements_grid)

	for achievement_id in stats.achievements_unlocked:
		var achievement_label = Label.new()
		achievement_label.text = "🏆 " + ProgressTracker.get_achievement_name(achievement_id)
		achievement_label.add_theme_font_override("font", BODY_FONT)
		achievement_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		achievements_grid.add_child(achievement_label)

func add_difficulty_breakdown_section(stats: ProgressTrackerTypes.PlayerStatistics) -> void:
	var stats_container = $MainScrollContainer/StatsContainer
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	spacer.name = "DetailedSectionSpacerDiff"
	stats_container.add_child(spacer)

	var section = VBoxContainer.new()
	section.name = "DetailedSectionDifficulty"
	stats_container.add_child(section)

	section.add_child(_create_section_title("Performance by Difficulty"))
	
	var panel = _create_styled_panel()
	section.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	panel.add_child(margin)

	var difficulty_grid = GridContainer.new()
	difficulty_grid.columns = 3
	difficulty_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	difficulty_grid.add_theme_constant_override("h_separation", 20)
	margin.add_child(difficulty_grid)

	# Headers
	var headers = ["Level", "High Score", "Average"]
	for h in headers:
		var lbl = Label.new()
		lbl.text = h
		lbl.add_theme_font_override("font", BODY_FONT)
		lbl.modulate = Color(0.2, 0.2, 0.2, 1)
		difficulty_grid.add_child(lbl)

	for difficulty in range(1, 6):
		var level_label = Label.new()
		level_label.text = str(difficulty)
		level_label.add_theme_font_override("font", HEADER_FONT)
		level_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		difficulty_grid.add_child(level_label)

		var high_score_label = Label.new()
		high_score_label.text = str(stats.high_scores_by_difficulty.get(difficulty, 0))
		high_score_label.add_theme_font_override("font", BODY_FONT)
		high_score_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		difficulty_grid.add_child(high_score_label)

		var avg_score_label = Label.new()
		var avg_score = stats.average_scores_by_difficulty.get(difficulty, 0.0)
		avg_score_label.text = "%.0f" % avg_score if avg_score > 0 else "-"
		avg_score_label.add_theme_font_override("font", BODY_FONT)
		avg_score_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		difficulty_grid.add_child(avg_score_label)

func add_operation_statistics_section() -> void:
	var stats = ProgressTracker.statistics

	# Skip if no operations have been used
	if stats.operation_usage_count.is_empty():
		return

	var stats_container = $MainScrollContainer/StatsContainer
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	spacer.name = "DetailedSectionSpacerOp"
	stats_container.add_child(spacer)

	var section = VBoxContainer.new()
	section.name = "DetailedSectionOperations"
	stats_container.add_child(section)

	section.add_child(_create_section_title("Operation Statistics"))
	
	var panel = _create_styled_panel()
	section.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	panel.add_child(margin)

	var operations_grid = GridContainer.new()
	operations_grid.columns = 3
	operations_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operations_grid.add_theme_constant_override("h_separation", 20)
	margin.add_child(operations_grid)

	# Headers
	var headers = ["Op", "Used", "Success"]
	for h in headers:
		var lbl = Label.new()
		lbl.text = h
		lbl.add_theme_font_override("font", BODY_FONT)
		lbl.modulate = Color(0.2, 0.2, 0.2, 1)
		operations_grid.add_child(lbl)

	# Sort operations by usage count (most used first)
	var sorted_operations = stats.operation_usage_count.keys()
	sorted_operations.sort_custom(func(a, b): return stats.operation_usage_count[a] > stats.operation_usage_count[b])

	# Display each operation
	for operation_name in sorted_operations:
		var count = stats.operation_usage_count[operation_name]

		var name_label = Label.new()
		name_label.text = operation_name
		name_label.add_theme_font_override("font", HEADER_FONT)
		name_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		operations_grid.add_child(name_label)

		var count_label = Label.new()
		count_label.text = str(count)
		count_label.add_theme_font_override("font", BODY_FONT)
		count_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		operations_grid.add_child(count_label)

		var rate_label = Label.new()
		if stats.operation_proficiency.has(operation_name):
			var proficiency = stats.operation_proficiency[operation_name]
			var rate = proficiency.get("rate", 0.0)
			rate_label.text = "%.1f%%" % (rate * 100.0)
			rate_label.add_theme_font_override("font", BODY_FONT)

			# Color code success rate
			if rate >= 0.8:
				rate_label.modulate = Color.GREEN
			elif rate >= 0.5:
				rate_label.modulate = Color.YELLOW
			else:
				rate_label.modulate = Color.RED
		else:
			rate_label.text = "N/A"
			rate_label.modulate = Color.GRAY
		operations_grid.add_child(rate_label)

func add_recent_sessions_section() -> void:
	var stats_container = $MainScrollContainer/StatsContainer
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
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
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_right", 15)
		card.add_child(margin)
		
		var row = HBoxContainer.new()
		margin.add_child(row)
		
		# Left side: Date & Result
		var left_vbox = VBoxContainer.new()
		left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left_vbox)
		
		var timestamp_parts = session.timestamp.split("T")
		var date_str = timestamp_parts[0] if timestamp_parts.size() > 0 else session.timestamp
		var date_label = Label.new()
		date_label.text = date_str
		date_label.add_theme_font_override("font", BODY_FONT)
		date_label.modulate = Color(0.2, 0.2, 0.2, 1)
		left_vbox.add_child(date_label)
		
		var result_label = Label.new()
		match session.completion_status:
			"win":
				result_label.text = "WIN"
				result_label.modulate = Color.GREEN
			"loss":
				result_label.text = "LOSS"
				result_label.modulate = Color.RED
			"quit":
				result_label.text = "QUIT"
				result_label.modulate = Color.ORANGE
			_:
				result_label.text = "Incomplete"
				result_label.modulate = Color.GRAY
		result_label.add_theme_font_override("font", HEADER_FONT)
		left_vbox.add_child(result_label)
		
		# Right side: Score & Difficulty
		var right_vbox = VBoxContainer.new()
		row.add_child(right_vbox)
		
		var score_label = Label.new()
		score_label.text = "Score: " + str(session.final_score)
		score_label.add_theme_font_override("font", HEADER_FONT)
		score_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right_vbox.add_child(score_label)
		
		var diff_label = Label.new()
		diff_label.text = "Lvl " + str(session.difficulty_level)
		diff_label.add_theme_font_override("font", BODY_FONT)
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
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	panel.add_child(margin)

	var h_box = HBoxContainer.new()
	h_box.alignment = BoxContainer.ALIGNMENT_CENTER
	h_box.add_theme_constant_override("separation", 50)
	margin.add_child(h_box)

	# 1. Success Rate Circle
	var circle_vbox = VBoxContainer.new()
	circle_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	h_box.add_child(circle_vbox)
	
	var circle_label = Label.new()
	circle_label.text = "Success Rate"
	circle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	circle_label.add_theme_font_override("font", BODY_FONT)
	circle_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	circle_vbox.add_child(circle_label)

	var circle = CircleGraph.new()
	circle.custom_minimum_size = Vector2(120, 120)
	circle.line_width = 12.0
	# Theme overrides might not propagate to draw without manual handling or theme resource, 
	# but we passed font in CircleGraph _draw via get_theme_font("font") if set on node.
	# Let's set the font directly on the node so get_theme_font finds it.
	circle.add_theme_font_override("font", HEADER_FONT)
	circle.add_theme_font_size_override("font_size", 24)
	
	# Determine color based on rate
	var rate = stats.success_rate
	var color = Color(0.8, 0.2, 0.2) # Red
	if rate >= 0.8: color = Color(0.2, 0.8, 0.2) # Green
	elif rate >= 0.5: color = Color(0.8, 0.8, 0.2) # Yellow
	
	circle.set_values(rate * 100, 100.0, "%.1f%%" % (rate * 100), color)
	circle_vbox.add_child(circle)

	# 2. Operations Pie Chart (if data exists)
	if not stats.operation_usage_count.is_empty():
		var pie_root_vbox = VBoxContainer.new()
		pie_root_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		h_box.add_child(pie_root_vbox)

		var pie_label = Label.new()
		pie_label.text = "Operations Used"
		pie_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pie_label.add_theme_font_override("font", BODY_FONT)
		pie_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		pie_root_vbox.add_child(pie_label)

		# Horizontal box for Pie + Legend
		var pie_h_box = HBoxContainer.new()
		pie_h_box.alignment = BoxContainer.ALIGNMENT_CENTER
		pie_h_box.add_theme_constant_override("separation", 20)
		pie_root_vbox.add_child(pie_h_box)

		var pie = PieChart.new()
		pie.custom_minimum_size = Vector2(120, 120)
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
			name_lbl.add_theme_font_size_override("font_size", 12)
			name_lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
			item_hbox.add_child(name_lbl)