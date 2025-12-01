extends Control

@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingLabel
@onready var tip_label: Label = $CenterContainer/VBoxContainer/TipLabel
@onready var scrolling_bg: TextureRect = $ScrollingBG

var progress: float = 0.0
var target_scene: String = ""

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

	# Start loading animation
	progress_bar.value = 0

	# Start background breathing animation
	start_background_breathing()

	# Begin loading process
	start_loading()

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
	"""Simulate loading with progress animation"""
	var tween = create_tween()

	# Animate progress bar from 0 to 100 over 1.5 seconds
	tween.tween_property(progress_bar, "value", 100, 1.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Wait for animation to complete
	await tween.finished

	# Small delay before scene change
	await get_tree().create_timer(0.3).timeout

	# Change to target scene
	if target_scene != "":
		SceneManager.change_scene(target_scene)

func set_target_scene(scene_path: String) -> void:
	"""Set which scene to load after the loading screen"""
	target_scene = scene_path
