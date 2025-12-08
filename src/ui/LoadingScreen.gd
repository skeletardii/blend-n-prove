extends Control

@onready var loading_circles: HBoxContainer = $CenterContainer/VBoxContainer/LoadingCircles
@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingLabel
@onready var tip_label: Label = $CenterContainer/VBoxContainer/TipLabel
@onready var scrolling_bg: TextureRect = $ScrollingBG

var progress: float = 0.0
var target_scene: String = ""
var circles: Array[Panel] = []

# Loading tips to display
var loading_tips: Array[String] = [
	"Tip: Use logical equivalences to simplify complex expressions!",
	"Tip: Modus Ponens (MP) is one of the most common inference rules.",
	"Tip: De Morgan's Laws can help you work with negations.",
	"Tip: Speed bonuses reward quick thinking - work fast!",
	"Tip: The Distributive law works for both AND and OR operations.",
	"Tip: Double Negation (¬¬P = P) can simplify your formulas.",
	"Tip: Check your target carefully before applying rules!",
	"Tip: Some rules work on entire formulas, others on parts.",
	"Tip: Practice makes perfect - play more to increase your streak!",
	"Tip: Higher difficulty levels unlock more complex rules.",
]

func _ready() -> void:
	# Show random tip
	tip_label.text = loading_tips[randi() % loading_tips.size()]

	# Setup circles
	setup_circles()

	# Start circle animation
	start_circle_animation()

	# Start background breathing animation
	start_background_breathing()

	# Begin loading process
	start_loading()

func setup_circles() -> void:
	"""Setup circular style for loading circles"""
	# Get all circle panels
	for child in loading_circles.get_children():
		if child is Panel:
			circles.append(child)

			# Create circular style
			var style_box = StyleBoxFlat.new()
			style_box.bg_color = Color(1, 1, 1, 1)  # White circles
			style_box.corner_radius_top_left = 10
			style_box.corner_radius_top_right = 10
			style_box.corner_radius_bottom_left = 10
			style_box.corner_radius_bottom_right = 10
			child.add_theme_stylebox_override("panel", style_box)

func start_circle_animation() -> void:
	"""Animate circles in a revolving pattern"""
	# Stagger the animation for each circle
	for i in range(circles.size()):
		animate_circle(circles[i], i * 0.15)  # 0.15 second delay between each

func animate_circle(circle: Panel, delay: float) -> void:
	"""Animate a single circle with scaling effect"""
	await get_tree().create_timer(delay).timeout

	var tween = create_tween()
	tween.set_loops()

	# Pulse animation: scale up and down
	tween.tween_property(circle, "scale", Vector2(1.5, 1.5), 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(circle, "scale", Vector2(1.0, 1.0), 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Brief pause before next cycle
	tween.tween_interval(0.2)

func start_background_breathing() -> void:
	"""Creates a breathing animation for the scrolling background (same as title screen)"""
	if not scrolling_bg:
		return

	# Wait for layout to complete
	await get_tree().process_frame
	await get_tree().process_frame

	# Get the rect size
	var rect_size: Vector2 = scrolling_bg.get_rect().size

	# Set pivot to the center
	scrolling_bg.pivot_offset = rect_size / 2

	# Create infinite looping tween for breathing effect
	var breathe_tween = create_tween()
	breathe_tween.set_loops()  # Infinite loop

	# Breathing parameters (expand and shrink)
	var breathe_duration = 2.5  # 2.5 seconds to expand
	var shrink_duration = 2.5   # 2.5 seconds to shrink
	var expanded_scale = Vector2(1.05, 1.05)  # Expand to 105%
	var normal_scale = Vector2(1.0, 1.0)      # Normal size (100%)

	# Expand (inhale)
	breathe_tween.tween_property(scrolling_bg, "scale", expanded_scale, breathe_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Shrink (exhale)
	breathe_tween.tween_property(scrolling_bg, "scale", normal_scale, shrink_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func start_loading() -> void:
	"""Simulate loading with timer"""
	# Wait for loading animation duration (1.8 seconds total)
	await get_tree().create_timer(1.8).timeout

	# Change to target scene
	if target_scene != "":
		SceneManager.change_scene(target_scene)

func set_target_scene(scene_path: String) -> void:
	"""Set which scene to load after the loading screen"""
	target_scene = scene_path
