extends Control

@onready var back_button: Button = $MainContainer/BackButton
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
		var button = $MainContainer/ScrollContainer/ButtonGrid.get_node("Button" + str(i)) as Button
		if button:
			update_button_display(button, i)
			if not button.pressed.is_connected(_on_grid_button_pressed):
				button.pressed.connect(_on_grid_button_pressed.bind(i))

func update_button_display(button: Button, button_index: int) -> void:
	var tutorial: TutorialDataManager.TutorialData = TutorialDataManager.get_tutorial_by_button_index(button_index)

	if tutorial:
		var display_name: String = tutorial.rule_name
		var progress: int = TutorialDataManager.get_tutorial_progress(tutorial.tutorial_key)
		var total: int = tutorial.problems.size()
		var is_completed: bool = TutorialDataManager.is_tutorial_completed(tutorial.tutorial_key)

		# Format: "Modus Ponens\n7/10" or "Modus Ponens\n✓"
		var button_text: String = display_name
		if is_completed:
			button_text += "\n✓ Completed"
		elif progress > 0:
			button_text += "\n" + str(progress) + "/" + str(total)
		else:
			button_text += "\n0/" + str(total)

		button.text = button_text

		# Color code based on completion
		if is_completed:
			button.modulate = Color(0.5, 1.0, 0.5)  # Green tint
		elif progress > 0:
			button.modulate = Color(1.0, 1.0, 0.7)  # Yellow tint
		else:
			button.modulate = Color(1.0, 1.0, 1.0)  # Normal
	else:
		button.text = "Button " + str(button_index)

func _on_progress_updated() -> void:
	# Refresh all button displays when progress changes
	for i in range(1, 19):
		var button = $MainContainer/ScrollContainer/ButtonGrid.get_node("Button" + str(i)) as Button
		if button:
			update_button_display(button, i)

func _on_back_button_pressed() -> void:
	AudioManager.play_button_click()
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")

func _on_grid_button_pressed(button_number: int) -> void:
	AudioManager.play_button_click()
	var tutorial: TutorialDataManager.TutorialData = TutorialDataManager.get_tutorial_by_button_index(button_number)

	if tutorial:
		show_tutorial_explanation(tutorial)
	else:
		print("No tutorial found for button: ", button_number)

func show_tutorial_explanation(tutorial: TutorialDataManager.TutorialData) -> void:
	# Create explanation dialog
	tutorial_explanation_dialog = create_explanation_dialog(tutorial)
	add_child(tutorial_explanation_dialog)

func create_explanation_dialog(tutorial: TutorialDataManager.TutorialData) -> Control:
	# Create a modal dialog
	var dialog: Control = Control.new()
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP

	# Semi-transparent background
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	dialog.add_child(bg)

	# Content panel
	var panel: Panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(600, 500)
	panel.position = Vector2(-300, -250)
	dialog.add_child(panel)

	# VBoxContainer for content
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Title
	var title: Label = Label.new()
	title.text = tutorial.rule_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	# Description
	var desc: RichTextLabel = RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.text = "[b]Description:[/b]\n" + tutorial.description + "\n\n[b]Rule Pattern:[/b]\n" + tutorial.rule_pattern
	desc.custom_minimum_size = Vector2(0, 250)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.scroll_active = true
	vbox.add_child(desc)

	# Progress info
	var progress_label: Label = Label.new()
	var progress: int = TutorialDataManager.get_tutorial_progress(tutorial.tutorial_key)
	var total: int = tutorial.problems.size()
	progress_label.text = "Progress: " + str(progress) + "/" + str(total) + " problems completed"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(progress_label)

	# Buttons container
	var button_box: HBoxContainer = HBoxContainer.new()
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.add_theme_constant_override("separation", 20)
	vbox.add_child(button_box)

	# Start Tutorial button
	var start_btn: Button = Button.new()
	start_btn.text = "Start Tutorial"
	start_btn.custom_minimum_size = Vector2(200, 50)
	start_btn.pressed.connect(_on_start_tutorial.bind(tutorial))
	button_box.add_child(start_btn)

	# Cancel button
	var cancel_btn: Button = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(200, 50)
	cancel_btn.pressed.connect(_on_cancel_tutorial)
	button_box.add_child(cancel_btn)

	return dialog

func _on_start_tutorial(tutorial: TutorialDataManager.TutorialData) -> void:
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
