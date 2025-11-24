extends Control
class_name AnalogClock

# Visual settings
@export var clock_radius: float = 40.0
@export var border_width: float = 3.0
@export var hand_width: float = 4.0

# Time tracking
var current_percentage: float = 100.0
var current_color: Color = Color.GREEN

func _ready() -> void:
	custom_minimum_size = Vector2(clock_radius * 2 + 10, clock_radius * 2 + 10)

func _draw() -> void:
	var center: Vector2 = size / 2.0

	# Draw clock face (background circle)
	draw_circle(center, clock_radius, Color(1.0, 1.0, 1.0, 0.9))

	# Draw clock border
	draw_arc(center, clock_radius, 0, TAU, 64, current_color, border_width, true)

	# Draw 12 o'clock marker (top)
	var marker_start: Vector2 = center + Vector2(0, -clock_radius + 5)
	var marker_end: Vector2 = center + Vector2(0, -clock_radius + 12)
	draw_line(marker_start, marker_end, current_color, 2.0)

	# Calculate hand angle (starts at 12 o'clock = -PI/2, rotates clockwise)
	# When percentage is 100%, angle should be at 12 (top)
	# When percentage is 0%, angle should complete full rotation back to 12
	var angle: float = -PI / 2.0 + (TAU * (1.0 - current_percentage / 100.0))

	# Draw clock hand
	var hand_length: float = clock_radius - 8
	var hand_end: Vector2 = center + Vector2(cos(angle), sin(angle)) * hand_length
	draw_line(center, hand_end, current_color, hand_width, true)

	# Draw center dot
	draw_circle(center, 4.0, current_color)

func update_time(percentage: float) -> void:
	"""Update the clock to show the given percentage of time remaining"""
	current_percentage = clamp(percentage, 0.0, 100.0)

	# Update color based on urgency
	if current_percentage > 60:
		current_color = Color.GREEN
	elif current_percentage > 30:
		current_color = Color.YELLOW
	else:
		current_color = Color.RED

	queue_redraw()
