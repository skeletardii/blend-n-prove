extends CanvasLayer

signal rating_completed

@onready var stars_container: HBoxContainer = $RatingControl/Panel/MarginContainer/VBoxContainer/StarsContainer
@onready var feedback_edit: TextEdit = $RatingControl/Panel/MarginContainer/VBoxContainer/FeedbackEdit
@onready var submit_button: Button = $RatingControl/Panel/MarginContainer/VBoxContainer/ButtonContainer/SubmitButton
@onready var skip_button: Button = $RatingControl/Panel/MarginContainer/VBoxContainer/ButtonContainer/SkipButton
@onready var title_label: Label = $RatingControl/Panel/MarginContainer/VBoxContainer/TitleLabel

var current_rating: int = 0
var is_manual: bool = false

func _ready() -> void:
	submit_button.pressed.connect(_on_submit_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	if is_manual:
		skip_button.text = "CANCEL"
	
	# Setup star buttons if they exist in the scene
	for i in range(stars_container.get_child_count()):
		var star = stars_container.get_child(i) as Button
		if star:
			star.pressed.connect(_on_star_pressed.bind(i + 1))

	# Initial state
	submit_button.disabled = true
	
	# Custom styling for a better look
	var panel = $RatingControl/Panel
	var style = panel.get_theme_stylebox("panel", "Panel").duplicate() as StyleBoxFlat
	if style:
		style.bg_color = Color(0.95, 0.95, 0.95, 1.0) # Match Wenrexa style
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.2, 0.5, 1.0, 1.0)
		style.corner_radius_top_left = 20
		style.corner_radius_top_right = 20
		style.corner_radius_bottom_left = 20
		style.corner_radius_bottom_right = 20
		panel.add_theme_stylebox_override("panel", style)

func set_manual_mode(manual: bool) -> void:
	is_manual = manual
	if is_inside_tree() and skip_button:
		skip_button.text = "CANCEL" if is_manual else "NOT NOW"

func _on_star_pressed(rating: int) -> void:
	current_rating = rating
	submit_button.disabled = false
	AudioManager.play_button_click()
	
	# Update star visuals
	for i in range(stars_container.get_child_count()):
		var star = stars_container.get_child(i) as Button
		if i < rating:
			star.modulate = Color(1, 0.9, 0.2) # Gold
		else:
			star.modulate = Color(0.5, 0.5, 0.5) # Gray

func _on_submit_pressed() -> void:
	AudioManager.play_button_click()
	
	# Save that the user has rated
	ProgressTracker.statistics.has_rated = true
	ProgressTracker.save_progress_data()
	
	# Here you would typically send the feedback to a server/Supabase
	# For now we'll just log it
	print("User Rating: ", current_rating)
	print("User Feedback: ", feedback_edit.text)
	
	# Optional: Send to Supabase if implemented
	if SupabaseService.has_method("submit_feedback"):
		SupabaseService.submit_feedback(current_rating, feedback_edit.text)
	
	rating_completed.emit()
	queue_free()

func _on_skip_pressed() -> void:
	AudioManager.play_button_click()
	# Just close, don't mark as rated so it can ask again later (or we could mark it as "declined")
	# If we want it to NOT ask again even if they skip, we'd set has_rated = true here.
	# But usually "Not Now" means ask later.
	rating_completed.emit()
	queue_free()
