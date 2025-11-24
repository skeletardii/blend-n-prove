extends Node2D
class_name HourglassSprite

# Hourglass dimensions
@export var hourglass_size: Vector2 = Vector2(24, 32)
@export var flip_interval: float = 2.0

var flip_timer: float = 0.0
var is_flipped: bool = false
var sand_percentage: float = 100.0

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	# Update flip timer
	flip_timer += delta

	# Flip hourglass periodically
	if flip_timer >= flip_interval:
		flip_timer = 0.0
		is_flipped = !is_flipped
		# Create flip animation using rotation
		var tween = create_tween()
		tween.tween_property(self, "rotation", rotation + PI, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	queue_redraw()

func _draw() -> void:
	var half_width: float = hourglass_size.x / 2.0
	var half_height: float = hourglass_size.y / 2.0

	# Draw hourglass outline
	var top_left: Vector2 = Vector2(-half_width, -half_height)
	var top_right: Vector2 = Vector2(half_width, -half_height)
	var bottom_left: Vector2 = Vector2(-half_width, half_height)
	var bottom_right: Vector2 = Vector2(half_width, half_height)
	var center: Vector2 = Vector2.ZERO

	# Hourglass shape (two triangles meeting at center)
	var outline_color: Color = Color(0.4, 0.3, 0.2, 1.0)
	var sand_color: Color = Color(0.87, 0.72, 0.53, 1.0)  # Sand beige color
	var glass_color: Color = Color(0.9, 0.9, 0.95, 0.2)

	# Draw glass (background)
	draw_colored_polygon(
		PackedVector2Array([top_left, top_right, center]),
		glass_color
	)
	draw_colored_polygon(
		PackedVector2Array([bottom_left, bottom_right, center]),
		glass_color
	)

	# Draw sand in top portion (decreasing over time)
	var sand_height: float = (sand_percentage / 100.0) * half_height
	if sand_height > 0:
		var sand_width: float = (sand_height / half_height) * half_width
		var sand_bottom: Vector2 = Vector2(0, 0)  # Center point
		var sand_left: Vector2 = Vector2(-sand_width, -sand_height)
		var sand_right: Vector2 = Vector2(sand_width, -sand_height)

		draw_colored_polygon(
			PackedVector2Array([sand_bottom, sand_left, sand_right]),
			sand_color
		)

	# Draw sand accumulating in bottom
	var bottom_sand_height: float = ((100.0 - sand_percentage) / 100.0) * half_height
	if bottom_sand_height > 0:
		var sand_width: float = (bottom_sand_height / half_height) * half_width
		var sand_top: Vector2 = Vector2(0, 0)  # Center point
		var sand_left: Vector2 = Vector2(-sand_width, bottom_sand_height)
		var sand_right: Vector2 = Vector2(sand_width, bottom_sand_height)

		draw_colored_polygon(
			PackedVector2Array([sand_top, sand_left, sand_right]),
			sand_color
		)

	# Draw outline
	draw_line(top_left, top_right, outline_color, 2.0)
	draw_line(top_left, center, outline_color, 2.0)
	draw_line(top_right, center, outline_color, 2.0)
	draw_line(bottom_left, bottom_right, outline_color, 2.0)
	draw_line(bottom_left, center, outline_color, 2.0)
	draw_line(bottom_right, center, outline_color, 2.0)

func update_sand(percentage: float) -> void:
	"""Update sand level based on time remaining percentage"""
	sand_percentage = clamp(percentage, 0.0, 100.0)
	queue_redraw()
