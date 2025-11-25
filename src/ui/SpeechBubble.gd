extends Control
class_name SpeechBubble

## A speech bubble that points to a specific position

@export var pointer_direction: Vector2 = Vector2(0, 1)  ## Direction the pointer points (normalized)
@export var pointer_size: float = 20.0  ## Size of the pointer triangle
@export var bubble_color: Color = Color.WHITE
@export var border_color: Color = Color(0.2, 0.2, 0.2)
@export var border_width: float = 2.0
@export var corner_radius: float = 10.0

func _draw() -> void:
	var rect = get_rect()

	# Draw bubble background with rounded corners
	var bubble_rect = Rect2(Vector2.ZERO, rect.size)
	draw_rounded_rect(bubble_rect, corner_radius, bubble_color)

	# Draw pointer triangle pointing downward to center of target
	var center_x = rect.size.x / 2.0
	var bottom_y = rect.size.y

	# Triangle vertices: center bottom of bubble, and two points at the tip
	var triangle_points = PackedVector2Array([
		Vector2(center_x - pointer_size / 2, bottom_y),
		Vector2(center_x + pointer_size / 2, bottom_y),
		Vector2(center_x, bottom_y + pointer_size)
	])

	draw_colored_polygon(triangle_points, bubble_color)

	# Draw border around the bubble
	draw_rounded_rect_border(bubble_rect, corner_radius, border_color, border_width)

	# Draw border around triangle
	draw_polyline(PackedVector2Array([
		triangle_points[0],
		triangle_points[2],
		triangle_points[1]
	]), border_color, border_width)

func draw_rounded_rect(rect: Rect2, radius: float, color: Color) -> void:
	draw_rect(rect, color)

func draw_rounded_rect_border(rect: Rect2, radius: float, color: Color, width: float) -> void:
	# Draw border as a polyline around the rectangle
	var points = PackedVector2Array([
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y),
		Vector2(rect.position.x, rect.position.y + rect.size.y),
		Vector2(rect.position.x, rect.position.y)
	])
	draw_polyline(points, color, width)
