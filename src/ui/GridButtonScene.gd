extends Control

const TutorialDataTypes = preload("res://src/managers/TutorialDataTypes.gd")
const TutorialSelectionDialogScene = preload("res://src/ui/TutorialSelectionDialog.tscn")

@onready var back_button: Button = $MainContainer/HeaderPanel/BackButton
@onready var button_grid: VBoxContainer = $MainContainer/ScrollContainer/MarginContainer/ButtonGrid

var tutorial_explanation_dialog: Control = null

func _ready() -> void:
	AudioManager.start_menu_music()

	# Connect back button
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

	# Wait for tutorials to load, then setup buttons
	if TutorialDataManager.tutorials_loaded:
		setup_tutorial_buttons()
	else:
		TutorialDataManager.all_tutorials_loaded.connect(setup_tutorial_buttons)

	# Connect to progress updates
	ProgressTracker.progress_updated.connect(_on_progress_updated)

func setup_tutorial_buttons() -> void:
	# Setup all grid buttons with tutorial names and completion status
	for i in range(1, 19):
		var button = button_grid.get_node_or_null("Button" + str(i)) as Button
		if button:
			update_button_display(button, i)
			if not button.pressed.is_connected(_on_grid_button_pressed):
				button.pressed.connect(_on_grid_button_pressed.bind(i))

func update_button_display(button: Button, button_index: int) -> void:
	var tutorial: TutorialDataTypes.TutorialData = TutorialDataManager.get_tutorial_by_button_index(button_index)

	if tutorial:
		var display_name: String = tutorial.rule_name
		var progress: int = TutorialDataManager.get_tutorial_progress(tutorial.tutorial_key)
		var total: int = tutorial.problems.size()
		var is_completed: bool = TutorialDataManager.is_tutorial_completed(tutorial.tutorial_key)

		# Format: "Modus Ponens\n7/10" or "Modus Ponens\n✓"
		var button_text: String = display_name
		if is_completed:
			button_text += "\nCompleted"
		elif progress > 0:
			button_text += "\n" + str(progress) + "/" + str(total)
		
		button.text = button_text

		# Color code based on completion
		if is_completed:
			button.modulate = Color(0.8, 1.0, 0.8)  # Light Green tint
		elif progress > 0:
			button.modulate = Color(1.0, 1.0, 0.9)  # Light Yellow tint
		else:
			button.modulate = Color(1.0, 1.0, 1.0)  # Normal
			
		button.disabled = false
	else:
		# Hide unused buttons or style them as "Coming Soon"
		button.text = "Coming Soon"
		button.disabled = true
		button.modulate = Color(1, 1, 1, 0.5)

func _on_progress_updated() -> void:
	# Refresh all button displays when progress changes
	for i in range(1, 19):
		var button = button_grid.get_node_or_null("Button" + str(i)) as Button
		if button:
			update_button_display(button, i)

func _on_back_button_pressed() -> void:
	AudioManager.play_button_click()
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")

func _on_grid_button_pressed(button_number: int) -> void:
	AudioManager.play_button_click()
	var tutorial: TutorialDataTypes.TutorialData = TutorialDataManager.get_tutorial_by_button_index(button_number)

	if tutorial:
		show_tutorial_explanation(tutorial)

func show_tutorial_explanation(tutorial: TutorialDataTypes.TutorialData) -> void:
	# Create explanation dialog from scene
	var dialog = TutorialSelectionDialogScene.instantiate()
	add_child(dialog)
	tutorial_explanation_dialog = dialog
	
	var progress: int = TutorialDataManager.get_tutorial_progress(tutorial.tutorial_key)
	var total: int = tutorial.problems.size()
	
	dialog.setup(tutorial, progress, total)
	dialog.start_requested.connect(_on_start_tutorial)
	dialog.cancel_requested.connect(_on_cancel_tutorial)

func _on_start_tutorial(tutorial: TutorialDataTypes.TutorialData) -> void:
	AudioManager.play_button_click()

	# Close dialog
	if tutorial_explanation_dialog:
		tutorial_explanation_dialog.queue_free()
		tutorial_explanation_dialog = null

	# Set tutorial mode in GameManager
	GameManager.start_tutorial_mode(tutorial.tutorial_key)

	# Navigate to gameplay scene
	SceneManager.change_scene("res://src/scenes/GameplayScene.tscn")

func _on_cancel_tutorial() -> void:
	AudioManager.play_button_click()

	# Close dialog
	if tutorial_explanation_dialog:
		tutorial_explanation_dialog.queue_free()
		tutorial_explanation_dialog = null
