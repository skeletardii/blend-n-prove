extends Control

@onready var debug_panel: Panel = $DebugPanel
@onready var debug_blur_overlay: ColorRect = $DebugBlurOverlay
@onready var difficulty_slider: HSlider = $DebugPanel/DebugContainer/DifficultyContainer/DifficultySlider
@onready var difficulty_value_label: Label = $DebugPanel/DebugContainer/DifficultyContainer/DifficultyValue
@onready var infinite_patience_check: CheckBox = $DebugPanel/DebugContainer/InfinitePatienceCheck
@onready var settings_panel: Panel = $SettingsPanel
@onready var music_slider: HSlider = $SettingsPanel/SettingsContainer/MusicVolumeContainer/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/SettingsContainer/SFXVolumeContainer/SFXSlider
@onready var mute_check: CheckBox = $SettingsPanel/SettingsContainer/MuteCheck
@onready var difficulty_mode_option: OptionButton = $SettingsPanel/SettingsContainer/DifficultyModeContainer/DifficultyModeOption
@onready var play_button: Button = $MenuContainer/PlayButton
@onready var how_to_play_button: Button = $MenuContainer/HowToPlayButton
@onready var progress_button: Button = $MenuContainer/ProgressButton
@onready var grid_button: Button = $MenuContainer/GridButton
@onready var leaderboard_button: Button = $MenuContainer/LeaderboardButton
@onready var high_score_quick: Label = $QuickStatsPanel/HighScoreQuick
@onready var games_played_quick: Label = $QuickStatsPanel/GamesPlayedQuick
@onready var streak_quick: Label = $QuickStatsPanel/StreakQuick
@onready var reset_confirmation_dialog: ConfirmationDialog = $ResetConfirmationDialog
@onready var feedback_label: Label = $FeedbackLabel
@onready var title_sprite: TextureRect = $MenuContainer/TextureRect
@onready var high_score_value: Label = $MenuContainer/HighScoreContainer/HighScoreValue

func _ready() -> void:
	AudioManager.start_menu_music()

	# Connect to GameManager signals
	GameManager.game_state_changed.connect(_on_game_state_changed)

	# Web build specific adjustments: Hide Quit and Progress buttons
	if OS.has_feature("web"):
		progress_button.visible = false
		if has_node("MenuContainer/QuitButton"):
			$MenuContainer/QuitButton.visible = false

	# Check for app updates (Android only) - disabled if UpdateChecker not loaded
	if has_node("/root/UpdateCheckerService"):
		_check_for_app_updates()

	# Connect button signals
	print("Connecting play button...")
	if not play_button.pressed.is_connected(_on_play_button_pressed):
		play_button.pressed.connect(_on_play_button_pressed)
		print("Play button connected!")
	else:
		print("Play button already connected")

	if not how_to_play_button.pressed.is_connected(_on_how_to_play_button_pressed):
		how_to_play_button.pressed.connect(_on_how_to_play_button_pressed)
		print("How to Play button connected!")

	if not progress_button.pressed.is_connected(_on_progress_button_pressed):
		progress_button.pressed.connect(_on_progress_button_pressed)
		print("Progress button connected!")

	if not grid_button.pressed.is_connected(_on_grid_button_pressed):
		grid_button.pressed.connect(_on_grid_button_pressed)
		print("Grid button connected!")

	if not leaderboard_button.pressed.is_connected(_on_leaderboard_button_pressed):
		leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
		print("Leaderboard button connected!")

	# Connect to progress updates
	ProgressTracker.progress_updated.connect(_on_progress_updated)

	# Update debug UI
	difficulty_slider.value = GameManager.difficulty_level
	difficulty_value_label.text = str(GameManager.difficulty_level)
	infinite_patience_check.button_pressed = GameManager.infinite_patience

	# Setup settings panel
	setup_difficulty_mode_options()
	setup_audio_settings()

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
				debug_blur_overlay.visible = debug_panel.visible
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
	print("About to change scene to GameplayScene...")

	# Check if the scene file exists first
	if ResourceLoader.exists("res://src/scenes/GameplayScene.tscn"):
		print("✅ GameplayScene.tscn exists")
	else:
		print("❌ GameplayScene.tscn does not exist!")
		return

	# Start new game first
	GameManager.start_new_game()
	print("Started new game")

	# Use loading screen transition to Intro Sequence
	SceneManager.change_scene_with_loading("res://src/ui/IntroSequence.tscn")

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

func _on_how_to_play_button_pressed() -> void:
	AudioManager.play_button_click()

	# Start first-time tutorial mode in GameManager
	GameManager.start_first_time_tutorial()

	# Load gameplay scene with tutorial
	SceneManager.change_scene("res://src/scenes/GameplayScene.tscn")

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

func _on_leaderboard_button_pressed() -> void:
	AudioManager.play_button_click()
	SceneManager.change_scene("res://src/ui/LeaderboardScene.tscn")

func _on_progress_updated() -> void:
	update_quick_stats()

func update_quick_stats() -> void:
	var stats = ProgressTracker.statistics

	high_score_quick.text = "High Score: " + str(stats.high_score_overall)
	games_played_quick.text = "Games Played: " + str(stats.total_games_played)
	streak_quick.text = "Best Combo: " + str(stats.longest_orders_combo_overall)

	# Update the main high score display below the title
	high_score_value.text = str(stats.high_score_overall)

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

func setup_audio_settings() -> void:
	# Initialize UI from AudioManager
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	mute_check.button_pressed = AudioManager.is_muted
	
	# Connect signals
	if not music_slider.value_changed.is_connected(_on_music_volume_changed):
		music_slider.value_changed.connect(_on_music_volume_changed)
	
	if not sfx_slider.value_changed.is_connected(_on_sfx_volume_changed):
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		
	if not mute_check.toggled.is_connected(_on_mute_check_toggled):
		mute_check.toggled.connect(_on_mute_check_toggled)

	# Listen for external changes
	if not AudioManager.audio_settings_changed.is_connected(_on_audio_settings_changed):
		AudioManager.audio_settings_changed.connect(_on_audio_settings_changed)

func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	# Play test sound if not playing already
	if not AudioManager.sfx_player.playing:
		AudioManager.play_button_click()

func _on_mute_check_toggled(toggled_on: bool) -> void:
	if toggled_on != AudioManager.is_muted:
		AudioManager.toggle_mute()

func _on_audio_settings_changed() -> void:
	if abs(music_slider.value - AudioManager.music_volume) > 0.01:
		music_slider.value = AudioManager.music_volume
	
	if abs(sfx_slider.value - AudioManager.sfx_volume) > 0.01:
		sfx_slider.value = AudioManager.sfx_volume
		
	if mute_check.button_pressed != AudioManager.is_muted:
		mute_check.button_pressed = AudioManager.is_muted


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

func _on_populate_test_data_button_pressed() -> void:
	AudioManager.play_button_click()
	ProgressTracker.debug_populate_test_data()
	update_quick_stats()
	show_feedback("Test data populated!", Color(0.2, 0.8, 0.2))

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
	"""Creates a breathing animation for the title sprite"""
	if not title_sprite:
		return

	# Wait for layout to complete
	await get_tree().process_frame
	await get_tree().process_frame

	# Get the rect that the texture is drawn in
	var rect_size: Vector2 = title_sprite.get_rect().size

	# Set pivot to the center of the drawn rect
	title_sprite.pivot_offset = rect_size / 2

	# Create infinite looping tween for breathing effect
	var breathe_tween = create_tween()
	breathe_tween.set_loops()  # Infinite loop

	# Breathing parameters (expand and shrink)
	var breathe_duration = 2.5  # 2.5 seconds to expand
	var shrink_duration = 2.5   # 2.5 seconds to shrink
	var expanded_scale = Vector2(1.05, 1.05)  # Expand to 105%
	var normal_scale = Vector2(1.0, 1.0)      # Normal size (100%)

	# Expand (inhale)
	breathe_tween.tween_property(title_sprite, "scale", expanded_scale, breathe_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Shrink (exhale)
	breathe_tween.tween_property(title_sprite, "scale", normal_scale, shrink_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ===== UPDATE CHECKER =====

func _check_for_app_updates() -> void:
	# Only run if UpdateCheckerService exists (for future PCK update system)
	if not has_node("/root/UpdateCheckerService"):
		return

	# Get reference to UpdateCheckerService
	var update_checker_service = get_node("/root/UpdateCheckerService")

	# Connect to UpdateCheckerService signals
	if not update_checker_service.update_available.is_connected(_on_update_available):
		update_checker_service.update_available.connect(_on_update_available)

	if not update_checker_service.update_check_failed.is_connected(_on_update_check_failed):
		update_checker_service.update_check_failed.connect(_on_update_check_failed)

	# Start update check (async, non-blocking)
	update_checker_service.check_for_updates()

func _on_update_available(update_info: Dictionary) -> void:
	print("MainMenu: Update available, showing popup...")

	# Get or create UpdateChecker popup
	var update_checker = get_node_or_null("UpdateCheckerPopup")

	if not update_checker:
		var update_checker_scene = load("res://src/ui/UpdateChecker.tscn")
		update_checker = update_checker_scene.instantiate()
		update_checker.name = "UpdateCheckerPopup"
		add_child(update_checker)

	update_checker.show_update(update_info)

func _on_update_check_failed(error_message: String) -> void:
	print("MainMenu: Update check failed: ", error_message)
	# Fail silently - don't interrupt user experience
