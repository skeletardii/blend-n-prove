extends CanvasLayer
class_name TutorialOverlay

## Tutorial overlay that provides visual guidance with arrows, circles, and text

signal skip_requested
signal next_button_pressed

@onready var darkening_layer: ColorRect = $DarkeningLayer
@onready var spotlight_container: Control = $SpotlightContainer
@onready var arrow: Polygon2D = $Arrow
@onready var circle: Line2D = $Circle
@onready var explanation_panel: Panel = $ExplanationPanel
@onready var explanation_label: RichTextLabel = $ExplanationPanel/MarginContainer/ScrollContainer/ExplanationLabel
@onready var next_button: Button = $ExplanationPanel/NextButton
@onready var skip_button: Button = $SkipButton

# Visual constants
const ARROW_SIZE := 40.0
const CIRCLE_RADIUS := 80.0


func _ready() -> void:
	# Hide darkening layer (disabled - was covering highlighted elements)
	darkening_layer.visible = false
	darkening_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Add semi-transparent background to explanation panel for contrast
	var panel_bg := ColorRect.new()
	#panel_bg.color = Color(0.1, 0.1, 0.15, 0.85)  # Dark semi-transparent background
	explanation_panel.add_child(panel_bg)
	explanation_panel.move_child(panel_bg, 0)  # Move to back
	panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Setup buttons
	skip_button.pressed.connect(_on_skip_pressed)
	next_button.pressed.connect(_on_next_pressed)

	# Initially hide all visual elements
	hide_all()


func show_step(
	explanation_text: String,
	highlight_node: Control = null,
	arrow_position: Vector2 = Vector2.ZERO,
	arrow_direction: Vector2 = Vector2.DOWN,
	show_circle: bool = false,
	circle_position: Vector2 = Vector2.ZERO,
	show_next: bool = false
) -> void:
	"""Display a tutorial step with specified visual elements"""

	# Show explanation text
	explanation_label.text = explanation_text
	explanation_panel.visible = true

	# Smart positioning based on highlighted element
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_pos := calculate_panel_position(viewport_size, highlight_node)
	explanation_panel.position = panel_pos

	# Control Next button visibility
	next_button.visible = show_next

	# Handle arrow
	if arrow_position != Vector2.ZERO:
		show_arrow(arrow_position, arrow_direction)
	else:
		arrow.visible = false

	# Handle circle highlight
	if show_circle:
		show_circle_highlight(circle_position)
	else:
		circle.visible = false


func calculate_panel_position(viewport_size: Vector2, highlight: Control) -> Vector2:
	"""Calculate smart panel position that avoids covering highlighted elements"""
	var panel_x := (viewport_size.x - explanation_panel.size.x) / 2.0
	var panel_y: float

	if highlight != null:
		var highlight_rect := highlight.get_global_rect()
		var highlight_center_y := highlight_rect.get_center().y
		var highlight_bottom := highlight_rect.position.y + highlight_rect.size.y
		var highlight_top := highlight_rect.position.y

		# Determine if element is in upper or lower half of screen
		if highlight_center_y < viewport_size.y / 2.0:
			# Element in upper half - position panel at bottom
			panel_y = viewport_size.y - explanation_panel.size.y - 100.0
		else:
			# Element in lower half - position panel at top
			panel_y = 50.0

		# Additional check: make sure panel doesn't overlap with highlighted element
		var panel_rect := Rect2(Vector2(panel_x, panel_y), explanation_panel.size)
		if panel_rect.intersects(highlight_rect):
			# If still overlapping, try positioning below or above the element
			if highlight_bottom + explanation_panel.size.y + 20.0 < viewport_size.y:
				panel_y = highlight_bottom + 20.0
			elif highlight_top - explanation_panel.size.y - 20.0 > 0:
				panel_y = highlight_top - explanation_panel.size.y - 20.0
	else:
		# No highlight - position at top to avoid blocking lower buttons
		panel_y = 50.0

	return Vector2(panel_x, panel_y)


func show_arrow(position: Vector2, direction: Vector2) -> void:
	"""Display an arrow pointing in the specified direction"""
	arrow.visible = true
	arrow.position = position

	# Create arrow shape pointing in direction
	var normalized := direction.normalized()
	var perpendicular := Vector2(-normalized.y, normalized.x)

	var tip := normalized * ARROW_SIZE
	var base := Vector2.ZERO
	var left_wing := base + perpendicular * (ARROW_SIZE * 0.4) - normalized * (ARROW_SIZE * 0.3)
	var right_wing := base - perpendicular * (ARROW_SIZE * 0.4) - normalized * (ARROW_SIZE * 0.3)

	arrow.polygon = PackedVector2Array([tip, left_wing, base, right_wing])
	arrow.color = Color(1.0, 0.8, 0.2, 0.95)  # Bright yellow


func show_circle_highlight(position: Vector2) -> void:
	"""Display a circle highlight at the specified position"""
	circle.visible = true
	circle.position = position

	# Create circle points
	var points := PackedVector2Array()
	var num_points := 64
	for i in range(num_points + 1):
		var angle := (float(i) / num_points) * TAU
		var point := Vector2(cos(angle), sin(angle)) * CIRCLE_RADIUS
		points.append(point)

	circle.points = points
	circle.default_color = Color(1.0, 0.8, 0.2, 0.95)  # Bright yellow
	circle.width = 4.0


func hide_all() -> void:
	"""Hide all tutorial visual elements"""
	explanation_panel.visible = false
	arrow.visible = false
	circle.visible = false


func show_overlay() -> void:
	"""Show the overlay"""
	visible = true


func hide_overlay() -> void:
	"""Hide the entire overlay"""
	visible = false
	hide_all()


func _on_skip_pressed() -> void:
	skip_requested.emit()


func _on_next_pressed() -> void:
	next_button_pressed.emit()
