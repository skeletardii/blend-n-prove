class_name ScoreTrendGraph
extends Control

## Score Trend Graph - Displays daily high scores over time with trend analysis
##
## Features:
## - Line graph of daily high scores
## - Rolling 3-day average trend line
## - Personal record markers (gold stars)
## - Grid lines and axis labels
## - Configurable time period (7/14/30 days)

# Data storage
var sessions: Array = []
var days_to_show: int = 7
var daily_scores: Dictionary = {}  # {"YYYY-MM-DD": score}
var rolling_avg: Dictionary = {}   # {"YYYY-MM-DD": avg_score}
var pr_points: Array = []          # [{date: String, score: int, position: Vector2}]

# Drawing configuration
const PADDING_LEFT: float = 40.0
const PADDING_RIGHT: float = 40.0
const PADDING_TOP: float = 30.0
const PADDING_BOTTOM: float = 40.0

# Colors
const COLOR_DAILY_LINE: Color = Color(0.2, 0.5, 0.9)      # Blue
const COLOR_ROLLING_AVG: Color = Color(0.9, 0.6, 0.2)     # Orange
const COLOR_GRID: Color = Color(0.8, 0.8, 0.8, 0.5)       # Semi-transparent gray
const COLOR_PR_MARKER: Color = Color(1.0, 0.8, 0.0)       # Gold
const COLOR_AXIS_TEXT: Color = Color(0.2, 0.2, 0.2, 1.0)  # Dark gray

# Fonts
const BODY_FONT = preload("res://assets/fonts/MuseoSansRounded500.otf")

## Set sessions data and update the graph
func set_sessions(new_sessions: Array, days: int) -> void:
	sessions = new_sessions
	days_to_show = days
	_process_data()
	queue_redraw()

## Process session data into daily aggregates
func _process_data() -> void:
	daily_scores = _aggregate_sessions_by_date(sessions, days_to_show)
	rolling_avg = _calculate_rolling_average(daily_scores, 3)
	pr_points = _identify_personal_records(daily_scores)

## Aggregate sessions by date, keeping highest score per day
func _aggregate_sessions_by_date(session_list: Array, days: int) -> Dictionary:
	var today = Time.get_datetime_dict_from_system()
	var cutoff_timestamp = _get_timestamp_days_ago(today, days)
	var daily_data: Dictionary = {}

	for session in session_list:
		# Check if session has valid data
		if session == null or session.timestamp.is_empty():
			continue

		var timestamp_str: String = session.timestamp
		var date_str: String = timestamp_str.split("T")[0]  # Extract YYYY-MM-DD

		# Convert timestamp to Unix time for comparison
		var session_time = Time.get_unix_time_from_datetime_string(timestamp_str)

		if session_time >= cutoff_timestamp:
			# Store highest score for each day
			if not daily_data.has(date_str):
				daily_data[date_str] = session.final_score
			else:
				daily_data[date_str] = max(daily_data[date_str], session.final_score)

	return daily_data

## Calculate rolling average with given window size
func _calculate_rolling_average(daily_data: Dictionary, window: int) -> Dictionary:
	if daily_data.is_empty():
		return {}

	var sorted_dates = daily_data.keys()
	sorted_dates.sort()

	var rolling_data: Dictionary = {}

	for i in range(sorted_dates.size()):
		var sum_value: float = 0.0
		var count: int = 0

		# Look back window days (including current day)
		for j in range(max(0, i - window + 1), i + 1):
			sum_value += daily_data[sorted_dates[j]]
			count += 1

		rolling_data[sorted_dates[i]] = sum_value / float(count)

	return rolling_data

## Identify personal records in the date range
func _identify_personal_records(daily_data: Dictionary) -> Array:
	if daily_data.is_empty():
		return []

	var sorted_dates = daily_data.keys()
	sorted_dates.sort()

	var pr_list: Array = []
	var max_score_so_far: int = 0

	for date in sorted_dates:
		var score = daily_data[date]
		if score > max_score_so_far:
			pr_list.append({"date": date, "score": score})
			max_score_so_far = score

	return pr_list

## Get Unix timestamp for N days ago
func _get_timestamp_days_ago(today_dict: Dictionary, days: int) -> int:
	var today_unix = Time.get_unix_time_from_datetime_dict(today_dict)
	var seconds_per_day = 86400
	return today_unix - (days * seconds_per_day)

## Draw the graph
func _draw() -> void:
	if daily_scores.is_empty():
		_draw_empty_state()
		return

	var drawable_area = size - Vector2(PADDING_LEFT + PADDING_RIGHT, PADDING_TOP + PADDING_BOTTOM)

	# Draw background grid
	_draw_grid(drawable_area)

	# Draw rolling average line (behind main line)
	if rolling_avg.size() > 1:
		_draw_trend_line(rolling_avg, drawable_area, COLOR_ROLLING_AVG, 2.0, true)

	# Draw main daily scores line
	if daily_scores.size() > 1:
		_draw_trend_line(daily_scores, drawable_area, COLOR_DAILY_LINE, 3.0, false)

	# Draw data point markers
	_draw_data_markers(daily_scores, drawable_area, COLOR_DAILY_LINE)

	# Draw personal record markers
	_draw_pr_markers(daily_scores, drawable_area)

	# Draw axes labels
	_draw_axes_labels(daily_scores, drawable_area)

## Draw empty state message
func _draw_empty_state() -> void:
	var center = size / 2
	var message = "No data available for this period"
	var font_size = 16
	var string_size = BODY_FONT.get_string_size(message, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = center - Vector2(string_size.x / 2, -string_size.y / 4)
	draw_string(BODY_FONT, text_pos, message, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, COLOR_AXIS_TEXT)

## Draw background grid
func _draw_grid(drawable_area: Vector2) -> void:
	var grid_lines = 5
	for i in range(grid_lines):
		var y = PADDING_TOP + (drawable_area.y / float(grid_lines - 1)) * i
		var start_pos = Vector2(PADDING_LEFT, y)
		var end_pos = Vector2(size.x - PADDING_RIGHT, y)
		draw_line(start_pos, end_pos, COLOR_GRID, 1.0)

## Draw a trend line (either daily scores or rolling average)
func _draw_trend_line(data: Dictionary, drawable_area: Vector2, color: Color, width: float, dashed: bool) -> void:
	var points = _calculate_plot_points(data, drawable_area)

	if points.size() < 2:
		return

	if dashed:
		_draw_dashed_polyline(points, color, width)
	else:
		draw_polyline(points, color, width, true)

## Draw data point markers (circles)
func _draw_data_markers(data: Dictionary, drawable_area: Vector2, color: Color) -> void:
	var points = _calculate_plot_points(data, drawable_area)

	for point in points:
		draw_circle(point, 5.0, color)
		draw_circle(point, 3.0, Color.WHITE)

## Draw personal record markers (gold stars)
func _draw_pr_markers(data: Dictionary, drawable_area: Vector2) -> void:
	var points_dict = _calculate_plot_points_dict(data, drawable_area)

	for pr_data in pr_points:
		var date = pr_data.date
		if points_dict.has(date):
			var pos = points_dict[date]
			# Draw gold circle
			draw_circle(pos, 8.0, COLOR_PR_MARKER)
			# Draw star shape
			_draw_star(pos, 6.0, Color(1.0, 1.0, 0.0))

## Draw a star shape at given position
func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points = PackedVector2Array()
	var num_points = 5

	for i in range(num_points * 2):
		var angle = (PI * 2 * i) / (num_points * 2) - PI / 2
		var r = radius if i % 2 == 0 else radius * 0.4
		points.append(center + Vector2(cos(angle), sin(angle)) * r)

	draw_colored_polygon(points, color)

## Draw a dashed polyline
func _draw_dashed_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	var dash_length = 8.0
	var gap_length = 4.0
	var total_pattern = dash_length + gap_length

	for i in range(points.size() - 1):
		var start = points[i]
		var end = points[i + 1]
		var direction = (end - start).normalized()
		var distance = start.distance_to(end)

		var current_dist = 0.0
		while current_dist < distance:
			var dash_start = start + direction * current_dist
			var dash_end = start + direction * min(current_dist + dash_length, distance)
			draw_line(dash_start, dash_end, color, width, true)
			current_dist += total_pattern

## Draw axes labels (X: dates, Y: scores)
func _draw_axes_labels(data: Dictionary, drawable_area: Vector2) -> void:
	if data.is_empty():
		return

	var sorted_dates = data.keys()
	sorted_dates.sort()

	# Y-axis labels (scores)
	_draw_y_axis_labels(data, drawable_area)

	# X-axis labels (dates)
	_draw_x_axis_labels(sorted_dates, drawable_area)

## Draw Y-axis score labels
func _draw_y_axis_labels(data: Dictionary, drawable_area: Vector2) -> void:
	var scores = data.values()
	var max_score = scores.max()
	var min_score = max(0, scores.min() - 100)

	var grid_lines = 5
	for i in range(grid_lines):
		var score = min_score + ((max_score - min_score) / float(grid_lines - 1)) * i
		var y = PADDING_TOP + drawable_area.y - (drawable_area.y / float(grid_lines - 1)) * i
		var label = str(int(score))
		var font_size = 12
		var string_size = BODY_FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos = Vector2(PADDING_LEFT - string_size.x - 5, y + string_size.y / 4)
		draw_string(BODY_FONT, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_AXIS_TEXT)

## Draw X-axis date labels
func _draw_x_axis_labels(sorted_dates: Array, drawable_area: Vector2) -> void:
	var num_labels = min(5, sorted_dates.size())
	var step = max(1, sorted_dates.size() / num_labels)

	for i in range(0, sorted_dates.size(), step):
		var date_str = sorted_dates[i]
		var x = PADDING_LEFT + (drawable_area.x / float(max(sorted_dates.size() - 1, 1))) * i
		var y = size.y - PADDING_BOTTOM + 15

		# Format date (show MM/DD)
		var parts = date_str.split("-")
		var label = ""
		if parts.size() >= 3:
			label = parts[1] + "/" + parts[2]  # MM/DD
		else:
			label = date_str

		var font_size = 12
		var string_size = BODY_FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = Vector2(x - string_size.x / 2, y)
		draw_string(BODY_FONT, text_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, COLOR_AXIS_TEXT)

## Calculate plot points for drawing
func _calculate_plot_points(data: Dictionary, drawable_area: Vector2) -> PackedVector2Array:
	var points = PackedVector2Array()

	if data.is_empty():
		return points

	var sorted_dates = data.keys()
	sorted_dates.sort()

	var scores = data.values()
	var max_score = scores.max()
	var min_score = max(0, scores.min() - 100)
	var score_range = max_score - min_score

	if score_range == 0:
		score_range = 1  # Avoid division by zero

	for i in range(sorted_dates.size()):
		var x = PADDING_LEFT + (drawable_area.x / float(max(sorted_dates.size() - 1, 1))) * i
		var normalized_score = (data[sorted_dates[i]] - min_score) / float(score_range)
		var y = PADDING_TOP + drawable_area.y - (normalized_score * drawable_area.y)
		points.append(Vector2(x, y))

	return points

## Calculate plot points as dictionary (date -> position)
func _calculate_plot_points_dict(data: Dictionary, drawable_area: Vector2) -> Dictionary:
	var points_dict: Dictionary = {}

	if data.is_empty():
		return points_dict

	var sorted_dates = data.keys()
	sorted_dates.sort()

	var scores = data.values()
	var max_score = scores.max()
	var min_score = max(0, scores.min() - 100)
	var score_range = max_score - min_score

	if score_range == 0:
		score_range = 1

	for i in range(sorted_dates.size()):
		var date = sorted_dates[i]
		var x = PADDING_LEFT + (drawable_area.x / float(max(sorted_dates.size() - 1, 1))) * i
		var normalized_score = (data[date] - min_score) / float(score_range)
		var y = PADDING_TOP + drawable_area.y - (normalized_score * drawable_area.y)
		points_dict[date] = Vector2(x, y)

	return points_dict
