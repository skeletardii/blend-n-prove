extends Control

@onready var debug_panel: Panel = $DebugPanel
@onready var difficulty_slider: HSlider = $DebugPanel/DebugContainer/DifficultyContainer/DifficultySlider
@onready var difficulty_value_label: Label = $DebugPanel/DebugContainer/DifficultyContainer/DifficultyValue
@onready var infinite_patience_check: CheckBox = $DebugPanel/DebugContainer/InfinitePatienceCheck
@onready var settings_panel: Panel = $SettingsPanel
@onready var difficulty_mode_option: OptionButton = $SettingsPanel/SettingsContainer/DifficultyModeContainer/DifficultyModeOption
@onready var play_button: Button = $MenuContainer/PlayButton
@onready var progress_button: Button = $MenuContainer/ProgressButton
@onready var grid_button: Button = $MenuContainer/GridButton
@onready var high_score_quick: Label = $QuickStatsPanel/HighScoreQuick
@onready var games_played_quick: Label = $QuickStatsPanel/GamesPlayedQuick
@onready var streak_quick: Label = $QuickStatsPanel/StreakQuick
@onready var reset_confirmation_dialog: ConfirmationDialog = $ResetConfirmationDialog
@onready var feedback_label: Label = $FeedbackLabel
@onready var title_sprite: TextureRect = $MenuContainer/TextureRect

func _ready() -> void:
	AudioManager.start_menu_music()

	# Connect to GameManager signals
	GameManager.game_state_changed.connect(_on_game_state_changed)

	# Connect button signals
	print("Connecting play button...")
	if not play_button.pressed.is_connected(_on_play_button_pressed):
		play_button.pressed.connect(_on_play_button_pressed)
		print("Play button connected!")
	else:
		print("Play button already connected")

	if not progress_button.pressed.is_connected(_on_progress_button_pressed):
		progress_button.pressed.connect(_on_progress_button_pressed)
		print("Progress button connected!")

	if not grid_button.pressed.is_connected(_on_grid_button_pressed):
		grid_button.pressed.connect(_on_grid_button_pressed)
		print("Grid button connected!")

	# Connect to progress updates
	ProgressTracker.progress_updated.connect(_on_progress_updated)

	# Update debug UI
	difficulty_slider.value = GameManager.difficulty_level
	difficulty_value_label.text = str(GameManager.difficulty_level)
	infinite_patience_check.button_pressed = GameManager.infinite_patience

	# Setup settings panel
	setup_difficulty_mode_options()

	# Update quick stats display
	update_quick_stats()

	# Start title sprite tilting animation
	start_title_tilt_animation()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_D:
				# Toggle debug panel with 'D' key
				debug_panel.visible = !debug_panel.visible
			KEY_T:
				# Run integration test with 'T' key
				if debug_panel.visible:
					GameManager.run_integration_test()
				else:
					# Run tutorial tests (outside debug mode)
					run_tutorial_tests()
			KEY_L:
				# Test logic engine with 'L' key
				if debug_panel.visible:
					BooleanLogicEngine.test_logic_engine()

func run_tutorial_tests() -> void:
	# Load and instantiate test script
	var test_script = load("res://test_tutorials.gd")
	var test_node = Node.new()
	test_node.set_script(test_script)
	add_child(test_node)

func _on_play_button_pressed() -> void:
	print("Play button pressed!")
	AudioManager.play_button_click()
	print("About to change scene to Phase1UI...")

	# Check if the scene file exists first
	if ResourceLoader.exists("res://src/scenes/GameplayScene.tscn"):
		print("✅ GameplayScene.tscn exists")
	else:
		print("❌ GameplayScene.tscn does not exist!")
		return

	# Try to load the scene directly
	var scene = load("res://src/scenes/GameplayScene.tscn")
	if scene:
		print("✅ Scene loaded successfully")
		SceneManager.change_scene("res://src/scenes/GameplayScene.tscn")
	else:
		print("❌ Failed to load scene!")
		return

	GameManager.start_new_game()
	print("Started new game")

#func _on_phase1_button_pressed() -> void:
	#AudioManager.play_button_click()
	#SceneManager.change_scene("res://src/scenes/GameplayScene.tscn")
	#GameManager.start_new_game()

func _on_debug_button_pressed() -> void:
	AudioManager.play_button_click()
	debug_panel.visible = !debug_panel.visible

func _on_settings_button_pressed() -> void:
	AudioManager.play_button_click()
	settings_panel.visible = !settings_panel.visible

func _on_quit_button_pressed() -> void:
	AudioManager.play_button_click()
	get_tree().quit()

func _on_difficulty_slider_value_changed(value: float) -> void:
	var difficulty_level: int = int(value)
	GameManager.set_difficulty(difficulty_level)
	difficulty_value_label.text = str(difficulty_level)

func _on_infinite_patience_check_toggled(button_pressed: bool) -> void:
	GameManager.infinite_patience = button_pressed

func _on_force_game_over_button_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.force_game_over()
	debug_panel.visible = false

func _on_logic_test_button_pressed() -> void:
	AudioManager.play_button_click()
	BooleanLogicEngine.test_logic_engine()

func _on_integration_test_button_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.run_integration_test()

func _on_launch_tutorial_button_pressed() -> void:
	AudioManager.play_button_click()
	debug_panel.visible = false

	# Start first-time tutorial mode in GameManager
	GameManager.start_first_time_tutorial()

	# Load gameplay scene with tutorial
	SceneManager.change_scene("res://src/scenes/GameplayScene.tscn")

func _on_close_debug_button_pressed() -> void:
	AudioManager.play_button_click()
	debug_panel.visible = false

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.GAME_OVER:
			debug_panel.visible = false

func _on_progress_button_pressed() -> void:
	AudioManager.play_button_click()
	SceneManager.change_scene("res://src/ui/ProgressScene.tscn")

func _on_grid_button_pressed() -> void:
	AudioManager.play_button_click()
	SceneManager.change_scene("res://src/ui/GridButtonScene.tscn")

func _on_progress_updated() -> void:
	update_quick_stats()

func update_quick_stats() -> void:
	var stats = ProgressTracker.statistics

	high_score_quick.text = "High Score: " + str(stats.high_score_overall)
	games_played_quick.text = "Games Played: " + str(stats.total_games_played)
	streak_quick.text = "Current Streak: " + str(stats.current_streak)

func setup_difficulty_mode_options() -> void:
	# Clear existing items
	difficulty_mode_option.clear()

	# Add difficulty options
	difficulty_mode_option.add_item("Auto (Normal Scaling)", 0)
	difficulty_mode_option.add_item("Level 1", 1)
	difficulty_mode_option.add_item("Level 2", 2)
	difficulty_mode_option.add_item("Level 3", 3)
	difficulty_mode_option.add_item("Level 4", 4)
	difficulty_mode_option.add_item("Level 5", 5)
	difficulty_mode_option.add_item("Level 6", 6)

	# Set current selection based on GameManager setting
	if GameManager.debug_difficulty_mode == -1:
		difficulty_mode_option.select(0)  # Auto
	else:
		difficulty_mode_option.select(GameManager.debug_difficulty_mode)  # 1-6

func _on_difficulty_mode_option_item_selected(index: int) -> void:
	AudioManager.play_button_click()

	# Index 0 = Auto (-1), Index 1-6 = Difficulty levels 1-6
	if index == 0:
		GameManager.set_debug_difficulty_mode(-1)
	else:
		GameManager.set_debug_difficulty_mode(index)

func _on_close_settings_button_pressed() -> void:
	AudioManager.play_button_click()
	settings_panel.visible = false

# ===== SAVE SYSTEM HANDLERS =====

func _on_save_progress_button_pressed() -> void:
	AudioManager.play_button_click()
	ProgressTracker.save_progress_data()
	show_feedback("Progress saved successfully!", Color(0.2, 0.8, 0.2))

func _on_load_progress_button_pressed() -> void:
	AudioManager.play_button_click()
	ProgressTracker.load_progress_data()
	show_feedback("Progress loaded successfully!", Color(0.2, 0.8, 0.2))
	update_quick_stats()

func _on_export_progress_button_pressed() -> void:
	AudioManager.play_button_click()

	# Export to encrypted file (ProgressTracker handles the file writing)
	var export_path = ProgressTracker.export_progress_data()

	if export_path != "":
		# Get the actual filesystem path for display
		var actual_path = ProjectSettings.globalize_path(export_path)
		show_feedback("Progress exported (encrypted) to: " + actual_path, Color(0.2, 0.8, 0.2))
		print("Progress exported to: " + actual_path)
	else:
		show_feedback("Failed to export progress!", Color(0.9, 0.3, 0.3))

func _on_import_progress_button_pressed() -> void:
	AudioManager.play_button_click()

	var import_path = "user://game_progress_export.dat"  # Updated to use encrypted .dat extension

	# Check if export file exists
	if not FileAccess.file_exists(import_path):
		show_feedback("No export file found!", Color(0.9, 0.3, 0.3))
		return

	# Use ProgressTracker's encrypted import function
	var success = ProgressTracker.import_progress_data(import_path)

	if success:
		# Update UI to reflect imported data
		update_quick_stats()
		show_feedback("Progress imported successfully (encrypted)!", Color(0.2, 0.8, 0.2))
	else:
		show_feedback("Failed to import progress! Check console for details.", Color(0.9, 0.3, 0.3))

func _on_reset_progress_button_pressed() -> void:
	AudioManager.play_button_click()
	# Show confirmation dialog
	reset_confirmation_dialog.popup_centered()

func _on_reset_progress_confirmed() -> void:
	# Reset all progress
	ProgressTracker.reset_progress_data()

	# Update UI
	update_quick_stats()

	# Close settings panel and show feedback
	settings_panel.visible = false
	show_feedback("All progress has been reset!", Color(0.9, 0.3, 0.3))

# ===== FEEDBACK SYSTEM =====

var feedback_timer: Timer = null

func show_feedback(message: String, color: Color) -> void:
	feedback_label.text = message
	feedback_label.modulate = color

	# Clear existing timer if any
	if feedback_timer:
		feedback_timer.queue_free()

	# Create new timer to hide feedback after 3 seconds
	feedback_timer = Timer.new()
	feedback_timer.wait_time = 3.0
	feedback_timer.one_shot = true
	feedback_timer.timeout.connect(hide_feedback)
	add_child(feedback_timer)
	feedback_timer.start()

func hide_feedback() -> void:
	feedback_label.text = ""
	if feedback_timer:
		feedback_timer.queue_free()
		feedback_timer = null

func start_title_tilt_animation() -> void:
	"""Creates a subtle tilting animation for the title sprite"""
	if not title_sprite:
		return

	# Set pivot point to top center (anchored like a hanging sign)
	title_sprite.pivot_offset = Vector2(title_sprite.size.x / 2, 0)

	# Create infinite looping tween for tilting
	var tilt_tween = create_tween()
	tilt_tween.set_loops()  # Infinite loop

	# Subtle tilt parameters (similar to a hanging sign swaying)
	var tilt_duration_right = 2.0  # 2 seconds to tilt right
	var tilt_duration_left = 2.0   # 2 seconds to tilt left
	var max_tilt_angle = 0.05      # ~3 degrees in radians (very subtle)

	# Tilt to the right
	tilt_tween.tween_property(title_sprite, "rotation", max_tilt_angle, tilt_duration_right) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Tilt to the left
	tilt_tween.tween_property(title_sprite, "rotation", -max_tilt_angle, tilt_duration_left) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Return to center
	tilt_tween.tween_property(title_sprite, "rotation", 0.0, tilt_duration_right) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
