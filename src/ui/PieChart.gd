extends Control
class_name PieChart

var data: Dictionary = {}
var colors: Array[Color] = [
	Color(0.8, 0.2, 0.2), # Red
	Color(0.2, 0.8, 0.2), # Green
	Color(0.2, 0.4, 0.8), # Blue
	Color(0.8, 0.8, 0.2), # Yellow
	Color(0.2, 0.8, 0.8), # Cyan
	Color(0.8, 0.2, 0.8), # Magenta
	Color(0.8, 0.5, 0.2), # Orange
	Color(0.5, 0.2, 0.8), # Purple
	Color(0.5, 0.5, 0.5)  # Grey
]
var _sorted_keys: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(150, 150)

func set_data(new_data: Dictionary) -> void:
	data = new_data
	_sorted_keys = data.keys()
	_sorted_keys.sort() # Ensure deterministic order for colors
	queue_redraw()

func get_legend_data() -> Array[Dictionary]:
	var legend: Array[Dictionary] = []
	var color_index = 0
	for key in _sorted_keys:
		legend.append({
			"name": str(key),
			"color": colors[color_index % colors.size()]
		})
		color_index += 1
	return legend

func _draw() -> void:
	if data.is_empty():
		return

	var total = 0.0
	for value in data.values():
		total += value

	if total == 0:
		return

	var start_angle = -PI / 2
	var center = size / 2
	var radius = min(size.x, size.y) / 2 * 0.9
	var color_index = 0

	for key in _sorted_keys:
		var value = data[key]
		var slice_angle = (value / total) * TAU
		var end_angle = start_angle + slice_angle
		var color = colors[color_index % colors.size()]
		
		# Only draw if slice is visible
		if slice_angle > 0.001:
			draw_circle_arc_poly(center, radius, start_angle, end_angle, color)
		
		start_angle = end_angle
		color_index += 1

func draw_circle_arc_poly(center: Vector2, radius: float, angle_from: float, angle_to: float, color: Color) -> void:
	var nb_points = 32
	var points = PackedVector2Array()
	points.push_back(center)
	var colors_array = PackedColorArray([color])

	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points
		points.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	draw_polygon(points, colors_array)
