extends Control
class_name CircleGraph

var value: float = 0.0
var max_value: float = 1.0
var line_width: float = 10.0
var color: Color = Color.GREEN
var bg_color: Color = Color(0.2, 0.2, 0.2)
var label_text: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(100, 100)

func set_values(current: float, maximum: float, text: String = "", progress_color: Color = Color.GREEN) -> void:
	value = current
	max_value = maximum
	if text != "":
		label_text = text
	else:
		if max_value > 0:
			label_text = "%.0f%%" % ((value / max_value) * 100)
		else:
			label_text = "0%"
	color = progress_color
	queue_redraw()

func _draw() -> void:
	var center = size / 2
	var radius = (min(size.x, size.y) / 2) - line_width
	
	# Draw background circle
	draw_arc(center, radius, 0, TAU, 32, bg_color, line_width, true)
	
	if max_value > 0:
		var ratio = clamp(value / max_value, 0.0, 1.0)
		var angle_to = -PI / 2 + (ratio * TAU)
		draw_arc(center, radius, -PI / 2, angle_to, 32, color, line_width, true)
	
	# Draw text centered
	if label_text != "":
		var font = get_theme_font("font")
		var font_size = get_theme_font_size("font_size")
		# If not set in theme, fallback (though usually Control has defaults or we need to load one)
		if font == null:
			# Fallback if no font is set in theme
			return 
			
		var string_size = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - Vector2(string_size.x / 2, -string_size.y / 4), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)
