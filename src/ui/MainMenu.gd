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
