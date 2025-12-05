extends Control

# UI References - Persistent Elements
@onready var main_container: VBoxContainer = $UI/MainContainer
@onready var score_display: Label = $UI/MainContainer/TopBar/TopBarContainer/ScoreContainer/CurrentScoreContainer/ScoreDisplay
@onready var high_score_display: Label = $UI/MainContainer/TopBar/TopBarContainer/ScoreContainer/HighScoreContainer/HighScoreDisplay
@onready var customer_name: Label = $UI/MainContainer/ScrollContainer/GameContentArea/CustomerArea/CustomerContainer/CustomerName
@onready var patience_bar: ProgressBar = $UI/MainContainer/PatienceBar
@onready var order_display: RichTextLabel = $UI/MainContainer/ScrollContainer/GameContentArea/CustomerArea/CustomerContainer/OrderDisplay
@onready var phase_container: Control = $UI/MainContainer/ScrollContainer/GameContentArea/PhaseContainer
@onready var tutorial_help_panel: Panel = $UI/TutorialHelpPanel
@onready var show_help_button: Button = $UI/MainContainer/TopBar/TopBarContainer/ShowHelpButton
@onready var hint_button: Button = $UI/MainContainer/TopBar/TopBarContainer/HintButton
@onready var hint_popup: Panel = $UI/HintPopup
@onready var pause_button: Button = $UI/MainContainer/TopBar/TopBarContainer/PauseButton
@onready var pause_overlay: CanvasLayer = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/PauseMenu/MenuContainer/ResumeButton
@onready var quit_button: Button = $PauseOverlay/PauseMenu/MenuContainer/QuitButton
@onready var background_texture: TextureRect = $TextureRect

# Phase Scenes
var phase1_scene: PackedScene = preload("res://src/ui/Phase1UI.tscn")
var phase2_scene: PackedScene = preload("res://src/ui/Phase2UI.tscn")
var score_popup_scene: PackedScene = preload("res://src/ui/ScorePopup.tscn")
var tutorial_overlay_scene: PackedScene = preload("res://src/ui/TutorialOverlay.tscn")
var tutorial_completion_scene: PackedScene = preload("res://src/ui/TutorialCompletionScreen.tscn")
var current_phase_instance: Control = null

# Background Textures
var phase1_background: Texture2D = preload("res://assets/sprites/phase1bg.jpg")
var phase2_background: Texture2D = preload("res://assets/sprites/phase2bg.jpg")

# Game State
var current_customer: GameManager.CustomerData
var validated_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var patience_timer: float = 0.0
var max_patience: float = 60.0
var feedback_label: Label = null
var feedback_timer: Timer = null
var is_paused: bool = false

# First-time tutorial
var tutorial_overlay: CanvasLayer = null
var tutorial_manager: Node = null

func setup_dynamic_spacing() -> void:
	"""Set dynamic spacing between UI modules based on viewport height"""
	var viewport_height: float = get_viewport_rect().size.y

	# Calculate spacing as a percentage of viewport height
	# For 1280px height, use 2px spacing (0.16%)
	# This scales proportionally with screen size
	var dynamic_spacing: int = max(2, int(viewport_height * 0.0016))

	# Apply to main container
	if main_container:
		main_container.add_theme_constant_override("separation", dynamic_spacing)

func _ready() -> void:
	# Set dynamic spacing based on viewport size
	setup_dynamic_spacing()

	# Connect to GameManager signals
	GameManager.score_updated.connect(_on_score_updated)

	# Start background music
	AudioManager.start_background_music()

	# Initialize UI
	update_score_display()
	update_high_score_display()

	# Setup first-time tutorial if active
	if GameManager.is_first_time_tutorial:
		setup_first_time_tutorial()
		show_help_button.visible = false
		tutorial_help_panel.visible = false
		hint_button.visible = false  # Hide hint button during first-time tutorial
	# Setup tutorial help panel if in regular tutorial mode
	elif GameManager.tutorial_mode:
		show_help_button.visible = true
		show_help_button.pressed.connect(_on_show_help_button_pressed)
		tutorial_help_panel.help_panel_closed.connect(_on_help_panel_closed)
	else:
		show_help_button.visible = false
		tutorial_help_panel.visible = false

	# Setup hint button (available in all modes except first-time tutorial)
	if not GameManager.is_first_time_tutorial:
		hint_button.pressed.connect(_on_hint_button_pressed)
		hint_popup.popup_closed.connect(_on_hint_popup_closed)

	# Setup pause button
	pause_button.pressed.connect(_on_pause_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	# Generate first customer
	generate_new_customer()

	# Check if we should skip Phase 1 for symbol-only problems
	if should_skip_phase1():
		# For symbol-only problems, convert premises directly and go to Phase 2
		convert_premises_and_skip_to_phase2()
	else:
		# Start in Phase 1 for natural language problems
		switch_to_phase1()

	# Start first-time tutorial after phase loads
	if GameManager.is_first_time_tutorial and tutorial_manager:
		call_deferred("start_first_time_tutorial")

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING and current_customer:
		update_patience_timer(delta)

func update_patience_timer(delta: float) -> void:
	if GameManager.infinite_patience:
		return

	# Calculate timer speed multiplier based on score
	# Higher score = faster countdown (1.0x at score 0, up to 3.0x at score 5000+)
	var speed_multiplier: float = 1.0 + (GameManager.current_score / 2500.0)
	speed_multiplier = min(speed_multiplier, 3.0)  # Cap at 3x speed

	patience_timer -= delta * speed_multiplier
	patience_timer = max(0.0, patience_timer)

	var patience_percentage: float = (patience_timer / max_patience) * 100.0
	patience_bar.value = patience_percentage

	# Change color based on urgency
	if patience_percentage > 60:
		patience_bar.modulate = Color.BLACK
	elif patience_percentage > 30:
		patience_bar.modulate = Color.BLACK
	else:
		patience_bar.modulate = Color.BLACK

	# Customer leaves if patience runs out
	if patience_timer <= 0.0:
		customer_leaves()

func change_background(phase: GameManager.GamePhase) -> void:
	"""Change the background based on the current game phase"""
	if not background_texture:
		return

	match phase:
		GameManager.GamePhase.PREPARING_PREMISES:
			background_texture.texture = phase1_background
			# Darken Phase 1 background by 60% (20% + 40% more)
			background_texture.modulate = Color(0.4, 0.4, 0.4, 1.0)
		GameManager.GamePhase.TRANSFORMING_PREMISES:
			background_texture.texture = phase2_background
			# Phase 2 background at full brightness
			background_texture.modulate = Color(1.0, 1.0, 1.0, 1.0)

func should_skip_phase1() -> bool:
	print("skip")
	"""Check if we should skip Phase 1 for symbol-only problems"""
	if not current_customer:
		return false

	# Skip Phase 1 if this is NOT a natural language problem
	# (i.e., premises are already in symbolic form)
	return not current_customer.is_natural_language

func convert_premises_and_skip_to_phase2() -> void:
	"""Convert symbolic premises directly to Phase 2 for symbol-only problems"""
	if not current_customer:
		return

	# Convert all premises to BooleanExpression objects
	validated_premises.clear()
	for premise_str in current_customer.required_premises:
		var expr = BooleanLogicEngine.create_expression(premise_str)
		if expr.is_valid:
			validated_premises.append(expr)

	# Initialize patience timer (same as Phase 1 would do)
	patience_timer = current_customer.patience_duration
	max_patience = current_customer.patience_duration
	patience_bar.visible = true

	# Go directly to Phase 2
	switch_to_phase2()

func switch_to_phase1() -> void:
	GameManager.change_phase(GameManager.GamePhase.PREPARING_PREMISES)

	# Change background to Phase 1
	change_background(GameManager.GamePhase.PREPARING_PREMISES)

	# Clear current phase
	if current_phase_instance:
		current_phase_instance.queue_free()
		current_phase_instance = null

	# Load Phase 1
	current_phase_instance = phase1_scene.instantiate()
	phase_container.add_child(current_phase_instance)

	# Connect Phase 1 signals
	current_phase_instance.premise_validated.connect(_on_premise_validated)
	current_phase_instance.premises_completed.connect(_on_premises_completed)
	current_phase_instance.feedback_message.connect(_on_feedback_message)

	# Pass customer data to Phase 1
	current_phase_instance.set_customer_data(current_customer)

	# Reset validated premises
	validated_premises.clear()

	# Start patience timer for Phase 1
	patience_timer = current_customer.patience_duration
	max_patience = current_customer.patience_duration
	patience_bar.visible = true

func switch_to_phase2() -> void:
	GameManager.change_phase(GameManager.GamePhase.TRANSFORMING_PREMISES)

	# Change background to Phase 2
	change_background(GameManager.GamePhase.TRANSFORMING_PREMISES)

	# Clear current phase
	if current_phase_instance:
		current_phase_instance.queue_free()
		current_phase_instance = null

	# Load Phase 2
	current_phase_instance = phase2_scene.instantiate()
	phase_container.add_child(current_phase_instance)

	# Pass score display and patience timer references
	current_phase_instance.score_display = score_display
	current_phase_instance.patience_timer = patience_timer

	# Connect Phase 2 signals
	current_phase_instance.rule_applied.connect(_on_rule_applied)
	current_phase_instance.target_reached.connect(_on_target_reached)
	current_phase_instance.feedback_message.connect(_on_feedback_message)

	# Connect tutorial signals if in first-time tutorial
	if GameManager.is_first_time_tutorial and tutorial_manager:
		connect_phase2_tutorial_signals()

	# Pass premises and target to Phase 2
	# For Level 6, also pass natural language conclusion for display
	if current_customer.is_natural_language:
		current_phase_instance.set_premises_and_target_with_display(
			validated_premises,
			current_customer.target_conclusion,
			current_customer.natural_language_conclusion
		)
	else:
		current_phase_instance.set_premises_and_target(validated_premises, current_customer.target_conclusion)

func generate_new_customer() -> void:
	var customer_names: Array[String] = ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"]
	var random_name: String = customer_names[randi() % customer_names.size()]

	# Special handling for first-time tutorial
	if GameManager.is_first_time_tutorial:
		# Create a simple tutorial problem: prove P∧Q from premises P and Q
		var tutorial_premises: Array[String] = ["P", "Q"]
		var tutorial_target: String = "P∧Q"
		var tutorial_patience: float = 999999.0  # Infinite time
		current_customer = GameManager.CustomerData.new("Tutorial Guide", tutorial_premises, tutorial_target, tutorial_patience, "")
		print("Loaded first-time tutorial problem")

	# Check if we're in regular tutorial mode
	elif GameManager.tutorial_mode:
		var problem: TutorialDataManager.ProblemData = GameManager.get_current_tutorial_problem()
		if problem:
			# Create customer from tutorial problem
			var base_patience: float = 120.0  # More generous patience for tutorials
			current_customer = GameManager.CustomerData.new(random_name, problem.premises, problem.conclusion, base_patience, problem.solution)

			print("Loaded tutorial problem ", problem.problem_number, " (", problem.difficulty, ")")
		else:
			# No more problems in tutorial - return to grid
			print("Tutorial complete! Returning to tutorial selection.")
			SceneManager.change_scene("res://src/ui/GridButtonScene.tscn")
			return
	else:
		# Normal game mode - use order templates
		# Get current difficulty level (clamped to available levels)
		var current_level: int = min(GameManager.difficulty_level, 6)  # Now supports up to level 6

		# If debug difficulty mode is active, use that instead
		if GameManager.debug_difficulty_mode != -1:
			current_level = clamp(GameManager.debug_difficulty_mode, 1, 6)

		# Get random order template for this level
		var templates_for_level = GameManager.order_templates[current_level]
		var random_template: GameManager.OrderTemplate = templates_for_level[randi() % templates_for_level.size()]

		# Adjust patience based on difficulty and expected operations
		var base_patience: float = 90.0 - (current_level * 10.0) + (random_template.expected_operations * 15.0)

		# Add extra time for word analysis (natural language) problems
		# +20 seconds per operation to account for translation overhead
		if random_template.is_natural_language:
			base_patience += random_template.expected_operations * 20.0

		base_patience = max(30.0, base_patience)  # Minimum 30 seconds

		# Create customer with logical premises (hidden premises for Level 6)
		current_customer = GameManager.CustomerData.new(random_name, random_template.premises, random_template.conclusion, base_patience, random_template.solution)

		# If this is a Level 6 natural language problem, set the natural language data
		if random_template.is_natural_language:
			current_customer.set_natural_language_data(
				random_template.natural_language_premises,
				random_template.natural_language_conclusion
			)

	# Update UI
	update_customer_display()
	AudioManager.play_customer_arrive()

	# Show tutorial help panel automatically for new problems
	if GameManager.tutorial_mode:
		show_tutorial_help()

func update_customer_display() -> void:
	if not current_customer:
		return

	# Show tutorial info if in tutorial mode
	if GameManager.tutorial_mode:
		var tutorial: TutorialDataManager.TutorialData = TutorialDataManager.get_tutorial_by_name(GameManager.current_tutorial_key)
		if tutorial:
			var problem_num: int = GameManager.current_tutorial_problem_index + 1
			var total_problems: int = tutorial.problems.size()
			customer_name.text = tutorial.rule_name + " - Problem " + str(problem_num) + "/" + str(total_problems)
		else:
			customer_name.text = "Tutorial"
	else:
		customer_name.text = current_customer.customer_name

	var order_text: String = ""

	# Level 6: Show natural language instead of logical symbols
	if current_customer.is_natural_language:
		order_text = "[b]Level 6 - Translation Challenge[/b]\n\n"
		order_text += "[b]Translate these statements:[/b]\n"
		for premise in current_customer.natural_language_premises:
			order_text += "• " + premise + "\n"

		order_text += "\n[b]Goal:[/b]\n" + current_customer.natural_language_conclusion
		order_text += "\n\n[i](Translate sentences to logical form)[/i]"
	else:
		# Levels 1-5: Show logical symbols directly
		order_text = "[b]Premises:[/b]\n"
		for premise in current_customer.required_premises:
			order_text += premise + "\n"

		order_text += "\n[b]Conclusion:[/b]\n" + current_customer.target_conclusion

	order_display.text = order_text

func customer_leaves() -> void:
	AudioManager.play_customer_leave()

	# In tutorial mode, just try again
	if GameManager.tutorial_mode:
		show_feedback_message("Time's up! Try this problem again.", Color.RED)
		# Regenerate same problem
		generate_new_customer()
		switch_to_phase1()
	else:
		# Time's up = Game Over (no lives system)
		show_feedback_message("Time's Up! Game Over!", Color.RED)
		get_tree().create_timer(2.0).timeout.connect(func():
			SceneManager.change_scene("res://src/ui/GameOverScene.tscn")
		)

func complete_order_successfully() -> void:
	AudioManager.play_logic_success()

	# Calculate score based on speed and efficiency
	var time_bonus: int = int(patience_timer)
	var base_score: int = 100 + (GameManager.difficulty_level * 50)
	var total_score: int = base_score + time_bonus

	# Add time to the patience timer on successful completion
	# Time bonus scales with difficulty: 15-30 seconds added
	var time_reward: float = 15.0 + (GameManager.difficulty_level * 2.5)
	patience_timer += time_reward
	patience_timer = min(patience_timer, max_patience * 1.5)  # Cap at 1.5x max patience

	# Score popup is now shown directly in Phase2UI at the card location
	# Score is added by Phase2UI after its animation completes

	# Handle tutorial mode completion
	if GameManager.tutorial_mode:
		var has_next_problem: bool = GameManager.advance_to_next_tutorial_problem()

		if has_next_problem:
			show_feedback_message("Problem Complete! Next problem loading...", Color.CYAN)
			# Generate next tutorial problem
			generate_new_customer()
			switch_to_phase1()
		else:
			show_feedback_message("Tutorial Complete! Well done!", Color.GOLD)
			# Return to tutorial selection after a delay
			get_tree().create_timer(3.0).timeout.connect(func():
				GameManager.exit_tutorial_mode()
				SceneManager.change_scene("res://src/ui/GridButtonScene.tscn")
			)
	else:
		# Normal game mode progression
		# Only increase difficulty if debug mode is not locking it
		if GameManager.debug_difficulty_mode == -1:
			# Auto mode: increase difficulty level after each completed order (until level 6)
			if GameManager.difficulty_level < 6:
				GameManager.difficulty_level += 1
				if GameManager.difficulty_level == 6:
					show_feedback_message("Level 6 Unlocked! Translation Challenge Begins!", Color.GOLD)
				else:
					show_feedback_message("Level Up! Now at Level " + str(GameManager.difficulty_level), Color.GOLD)
			else:
				show_feedback_message("Ultimate Master Level - Incredible!", Color.GOLD)
		else:
			# Debug difficulty mode locked - show completion message without level up
			show_feedback_message("Order Complete! Score: +" + str(total_score), Color.GOLD)

		# Generate new customer
		generate_new_customer()
		if should_skip_phase1():
		# For symbol-only problems, convert premises directly and go to Phase 2
			convert_premises_and_skip_to_phase2()
		else:
		# Start in Phase 1 for natural language problems
			switch_to_phase1()


# Phase 1 Signal Handlers
func _on_premise_validated(expression: BooleanLogicEngine.BooleanExpression) -> void:
	validated_premises.append(expression)
	AudioManager.play_premise_complete()

func _on_premises_completed(premises: Array[BooleanLogicEngine.BooleanExpression]) -> void:
	validated_premises = premises
	show_feedback_message("✓ All premises ready! Advancing to Phase 2...", Color.CYAN)
	# Auto-advance to Phase 2 after a short delay
	get_tree().create_timer(1.5).timeout.connect(switch_to_phase2)

# Phase 2 Signal Handlers
func _on_rule_applied(result: BooleanLogicEngine.BooleanExpression) -> void:
	validated_premises.append(result)
	AudioManager.play_logic_success()

func _on_target_reached(result: BooleanLogicEngine.BooleanExpression) -> void:
	show_feedback_message("✓ Proof complete! Order fulfilled!", Color.CYAN)
	# Complete order after a short delay
	get_tree().create_timer(2.0).timeout.connect(complete_order_successfully)

# Universal Signal Handlers
func _on_feedback_message(message: String, color: Color) -> void:
	show_feedback_message(message, color)

func _on_score_updated(new_score: int) -> void:
	update_score_display()

func update_score_display() -> void:
	score_display.text = str(GameManager.current_score)

func update_high_score_display() -> void:
	var stats = ProgressTracker.statistics
	high_score_display.text = str(stats.high_score_overall)

func show_feedback_message(message: String, color: Color = Color.WHITE) -> void:
	# Create feedback label if it doesn't exist
	if not feedback_label:
		feedback_label = Label.new()
		feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(feedback_label)

		# Position at top of screen
		feedback_label.anchors_preset = Control.PRESET_TOP_WIDE
		feedback_label.offset_top = 120
		feedback_label.offset_bottom = 160

		# Style the feedback label
		feedback_label.add_theme_font_size_override("font_size", 20)

	# Create timer if it doesn't exist
	if not feedback_timer:
		feedback_timer = Timer.new()
		feedback_timer.one_shot = true
		feedback_timer.timeout.connect(_on_feedback_timer_timeout)
		add_child(feedback_timer)

	# Show the message
	feedback_label.text = message
	feedback_label.modulate = color
	feedback_label.visible = true

	# Start timer to hide message
	feedback_timer.start(3.0)

func _on_feedback_timer_timeout() -> void:
	if feedback_label:
		feedback_label.visible = false

# Tutorial Help Panel Functions
func show_tutorial_help() -> void:
	if not GameManager.tutorial_mode or not tutorial_help_panel:
		return

	# Get current tutorial info
	var tutorial_key: String = GameManager.current_tutorial_key
	var problem_index: int = GameManager.current_tutorial_problem_index

	# Show the help panel with current problem data
	tutorial_help_panel.show_tutorial_help(tutorial_key, problem_index)

func _on_show_help_button_pressed() -> void:
	if tutorial_help_panel:
		tutorial_help_panel.toggle_visibility()

func _on_help_panel_closed() -> void:
	# Optional: Add any logic when help panel is closed
	pass

# Hint Popup Functions
func _on_hint_button_pressed() -> void:
	if not current_customer:
		return

	# Show the hint popup with the current problem's solution
	var solution_text: String = current_customer.solution
	if solution_text.is_empty():
		solution_text = "No hint available for this problem."

	hint_popup.show_hint(solution_text)

func _on_hint_popup_closed() -> void:
	# Optional: Add any logic when hint popup is closed
	pass

# Pause Menu Functions
func _on_pause_button_pressed() -> void:
	pause_game()

func pause_game() -> void:
	is_paused = true
	pause_overlay.visible = true
	# Block input to the phase container (game area)
	phase_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Note: Timer continues counting as requested by user

func _on_resume_button_pressed() -> void:
	resume_game()

func resume_game() -> void:
	is_paused = false
	pause_overlay.visible = false
	# Re-enable input to the phase container
	phase_container.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_quit_button_pressed() -> void:
	# Play error/cancel sound when quitting
	AudioManager.play_error()

	# Exit tutorial mode if active
	if GameManager.tutorial_mode:
		GameManager.exit_tutorial_mode()

	# Stop background music
	AudioManager.stop_music()

	# Return to main menu
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")

# ============================================================================
# FIRST-TIME TUTORIAL FUNCTIONS
# ============================================================================

func setup_first_time_tutorial() -> void:
	"""Initialize the first-time tutorial overlay and manager"""
	# Create tutorial overlay
	tutorial_overlay = tutorial_overlay_scene.instantiate()
	add_child(tutorial_overlay)
	tutorial_overlay.visible = false  # Will be shown when tutorial starts

	# Create tutorial manager
	var FirstTimeTutorialManager = load("res://src/game/FirstTimeTutorialManager.gd")
	tutorial_manager = FirstTimeTutorialManager.new()
	add_child(tutorial_manager)

	# Connect tutorial signals
	tutorial_manager.tutorial_completed.connect(_on_first_time_tutorial_completed)
	tutorial_manager.tutorial_skipped.connect(_on_first_time_tutorial_skipped)

	print("First-time tutorial initialized")

func start_first_time_tutorial() -> void:
	"""Start the first-time tutorial sequence"""
	if tutorial_manager and tutorial_overlay:
		# Initialize manager with references
		tutorial_manager.initialize(
			tutorial_overlay,
			self,
			current_phase_instance,
			null  # Phase 2 will be set when we switch phases
		)

		# Connect phase 1 signals for tutorial detection
		if current_phase_instance:
			connect_phase1_tutorial_signals()

		# Start tutorial
		tutorial_manager.start_tutorial()
		print("First-time tutorial started")

func connect_phase1_tutorial_signals() -> void:
	"""Connect Phase 1 UI signals needed for tutorial"""
	if current_phase_instance.has_signal("text_changed"):
		current_phase_instance.text_changed.connect(tutorial_manager._on_text_changed)
	else:
		print("Warning: Phase1UI missing text_changed signal")

func connect_phase2_tutorial_signals() -> void:
	"""Connect Phase 2 UI signals needed for tutorial"""
	tutorial_manager.phase2_ui = current_phase_instance
	tutorial_manager.connect_phase2_signals()

func _on_first_time_tutorial_completed() -> void:
	"""Handle tutorial completion - show completion screen"""
	print("Tutorial completed!")

	# Disable tutorial mode
	GameManager.is_first_time_tutorial = false
	GameManager.tutorial_mode = false
	GameManager.infinite_patience = false

	# Show completion screen
	var completion_screen = tutorial_completion_scene.instantiate()
	add_child(completion_screen)
	completion_screen.return_to_menu_requested.connect(_on_return_to_menu_from_tutorial)

func _on_first_time_tutorial_skipped() -> void:
	"""Handle tutorial skip - return to menu"""
	print("Tutorial skipped")

	# Disable tutorial mode
	GameManager.is_first_time_tutorial = false
	GameManager.tutorial_mode = false
	GameManager.infinite_patience = false

	# Return to main menu
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")

func _on_return_to_menu_from_tutorial() -> void:
	"""Return to main menu after tutorial completion screen"""
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")
