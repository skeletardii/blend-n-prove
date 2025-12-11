class_name GradeBadge
extends Control

## Grade Badge - Displays A-F letter grades in circular colored badges
##
## Features:
## - Circular badge with colored background
## - Letter grade (A-F) in white text
## - Supports different sizes via custom_minimum_size
## - Auto-scales font size for different badge sizes

# Grade data
var grade: String = "F"
var grade_color: Color = Color.GRAY

# Font
const HEADER_FONT = preload("res://assets/fonts/MuseoSansRounded1000.otf")

# Default font size (scales up for larger badges)
var base_font_size: int = 28

## Set the grade and update display
func set_grade(new_grade: String) -> void:
	grade = new_grade.to_upper()
	grade_color = _get_grade_color(grade)
	queue_redraw()

## Get color for grade
func _get_grade_color(grade_letter: String) -> Color:
	match grade_letter:
		"A":
			return Color(0.2, 0.8, 0.2)  # GREEN - excellent
		"B":
			return Color(0.2, 0.8, 0.8)  # CYAN - very good
		"C":
			return Color(0.9, 0.9, 0.2)  # YELLOW - average
		"D":
			return Color(0.9, 0.6, 0.2)  # ORANGE - below average
		"F":
			return Color(0.9, 0.2, 0.2)  # RED - needs work
		_:
			return Color.GRAY

## Draw the badge
func _draw() -> void:
	var center = size / 2
	var radius = min(size.x, size.y) / 2 * 0.9

	# Outer circle (grade color background)
	draw_circle(center, radius, grade_color)

	# Inner border (white stroke)
	draw_arc(center, radius - 2, 0, TAU, 32, Color.WHITE, 3.0, true)

	# Letter text
	var font_size_to_use = base_font_size

	# Scale font size for larger badges (120px+ = hero size)
	if custom_minimum_size.x > 60:
		font_size_to_use = int(base_font_size * 2.0)  # 56px for hero badges

	var string_size = HEADER_FONT.get_string_size(grade, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_to_use)
	var text_pos = center - Vector2(string_size.x / 2, -string_size.y / 4)
	draw_string(HEADER_FONT, text_pos, grade, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_to_use, Color.WHITE)
