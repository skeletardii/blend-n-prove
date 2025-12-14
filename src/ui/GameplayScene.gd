extends Control

# Explicit preload to ensure BooleanExpression type is available
const BooleanExpression = preload("res://src/game/expressions/BooleanExpression.gd")
const TutorialDataTypes = preload("res://src/managers/TutorialDataTypes.gd")
const GameManagerTypes = preload("res://src/managers/GameManagerTypes.gd")

# UI References - Persistent Elements
@onready var main_container: VBoxContainer = $UI/MainContainer
@onready var score_display: Label = $UI/MainContainer/TopBar/TopBarContainer/ScoreContainer/CurrentScoreContainer/ScoreDisplay
@onready var high_score_display: Label = $UI/MainContainer/TopBar/TopBarContainer/ScoreContainer/HighScoreContainer/HighScoreDisplay
@onready var customer_name: Label = $UI/MainContainer/ScrollContainer/GameContentArea/CustomerArea/CustomerContainer/CustomerName
@onready var patience_bar: ProgressBar = $UI/MainContainer/PatienceBar
var fuel_icon: TextureRect = null  # Created dynamically to show fuel icon
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
@onready var toggle_music_button: Button = $PauseOverlay/PauseMenu/MenuContainer/ToggleMusicButton
@onready var toggle_sfx_button: Button = $PauseOverlay/PauseMenu/MenuContainer/ToggleSFXButton
@onready var background_texture: TextureRect = $TextureRect
@onready var intro_flash: ColorRect = $IntroFlash
@onready var black_hole: TextureRect = $BlackHole

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
var current_customer  # GameManager.CustomerData (type annotation removed for proxy compatibility)
var validated_premises: Array[BooleanExpression] = []
var patience_timer: float = 0.0
var max_patience: float = 60.0
var feedback_label: Label = null
var feedback_timer: Timer = null
var is_paused: bool = false
var is_game_over_sequence_started: bool = false

var game_over_comments: Array[String] = [
	"you should've typed faster",
	"more fuel please",
	"you can review in the tutorial, maybe",
	"logic is hard, isn't it?",
	"ran out of time...",
	"maybe try a simpler difficulty?",
	"don't give up!",
	"so close!",
	"need more practice?",
	"keep trying!",
	"fuel empty!",
	"better luck next time"
]

# Fuel System (Rocket Ship)
var fuel: float = 100.0
var max_fuel: float = 100.0
var current_speed: float = 1.0  # Speed multiplier for score gain
var base_speed: float = 1.0
var speed_boost: float = 0.0  # Temporary boost from clean solutions
var gameplay_multiplier: float = 1.0 # Global score multiplier from successful answers
var combo_count: int = 0  # Consecutive correct answers
var fuel_consumption_rate: float = 1.0  # Base consumption per second
var score_accumulator: float = 0.0  # Accumulates score over time
var is_first_customer: bool = true  # Track if this is the first customer to initialize fuel

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

func create_fuel_icon() -> void:
	"""Create a fuel canister icon overlay on the patience bar"""
	if not patience_bar:
		return

	fuel_icon = TextureRect.new()
	var icon_texture = load("res://assets/sprites/fuelcanister.png")
	fuel_icon.texture = icon_texture
	fuel_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fuel_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Make icon cover the entire progress bar
	fuel_icon.anchors_preset = Control.PRESET_FULL_RECT
	fuel_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow clicks to pass through

	patience_bar.add_child(fuel_icon)

func _ready() -> void:
	# Fade out the white flash from intro
	if intro_flash:
		var tween = create_tween()
		tween.tween_property(intro_flash, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): intro_flash.queue_free())

	# Start black hole rotation animation
	if black_hole:
		start_black_hole_rotation()

	# Set dynamic spacing based on viewport size
	setup_dynamic_spacing()

	# Connect to GameManager signals
	GameManager.score_updated.connect(_on_score_updated)

	# Start background music
	AudioManager.start_background_music()

	# Initialize UI
	update_score_display()
	update_high_score_display()

	# Create fuel icon
	create_fuel_icon()

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
		if hint_popup.has_signal("skip_requested"):
			hint_popup.skip_requested.connect(_on_hint_skip_requested)

	# Setup pause button
	pause_button.pressed.connect(_on_pause_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	if toggle_music_button:
		toggle_music_button.pressed.connect(_on_toggle_music_pressed)
	if toggle_sfx_button:
		toggle_sfx_button.pressed.connect(_on_toggle_sfx_pressed)
		
	update_audio_buttons_state()

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

func _on_hint_skip_requested() -> void:
	show_feedback_message("Skipping problem...", Color.YELLOW)
	
	# Skip to next customer immediately
	generate_new_customer()
	
	if should_skip_phase1():
		convert_premises_and_skip_to_phase2()
	else:
		switch_to_phase1()

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING and current_customer:
		update_patience_timer(delta)
		update_fuel_system(delta)

func update_fuel_system(delta: float) -> void:
	"""Update fuel-based rocket ship system"""
	if GameManager.infinite_patience:
		return

	# Calculate fuel consumption based on score (higher score = faster drain)
	var score_multiplier: float = 1.0 + (GameManager.current_score / 5000.0)
	score_multiplier = min(score_multiplier, 2.0)  # Cap at 2x consumption

	# Apply speed boost decay
	if speed_boost > 0.0:
		speed_boost -= delta * 0.5  # Decay speed boost over time
		speed_boost = max(0.0, speed_boost)

	# Calculate current speed (base + boost)
	current_speed = base_speed + speed_boost

	# Update Phase2UI background scroll speed to match rocket speed
	if current_phase_instance and current_phase_instance.has_method("set_rocket_speed"):
		current_phase_instance.set_rocket_speed(current_speed)

	# Consume fuel
	fuel -= delta * fuel_consumption_rate * score_multiplier
	fuel = max(0.0, fuel)

	# Gain score over time based on speed
	score_accumulator += delta * current_speed * 10.0 * gameplay_multiplier  # 10 points per second at 1x speed
	var score_to_add: int = int(score_accumulator)
	if score_to_add > 0:
		GameManager.add_score(score_to_add)
		score_accumulator -= score_to_add

	# Update fuel bar display
	var fuel_percentage: float = (fuel / max_fuel) * 100.0
	patience_bar.value = fuel_percentage

	# Change color based on fuel level
	if fuel_percentage > 60:
		patience_bar.self_modulate = Color(0.2, 1.0, 0.3)  # Green
	elif fuel_percentage > 30:
		patience_bar.self_modulate = Color(1.0, 0.9, 0.0)  # Yellow
	elif fuel_percentage > 15:
		patience_bar.self_modulate = Color(1.0, 0.65, 0.0)  # Orange
	else:
		patience_bar.self_modulate = Color(1.0, 0.0, 0.0)  # Red

	# Game over if fuel runs out
	if fuel <= 0.0:
		customer_leaves()

func update_patience_timer(delta: float) -> void:
	# Legacy timer for backward compatibility (now unused in favor of fuel)
	if GameManager.infinite_patience:
		return

	patience_timer -= delta
	patience_timer = max(0.0, patience_timer)

func add_fuel(amount: float) -> void:
	"""Add fuel to the rocket ship"""
	fuel += amount
	fuel = min(fuel, max_fuel)

func apply_fuel_penalty(percentage: float) -> void:
	"""Remove a percentage of current fuel as penalty"""
	var penalty_amount: float = fuel * percentage
	fuel -= penalty_amount
	fuel = max(0.0, fuel)
	show_feedback_message("Fuel Lost: -" + str(int(percentage * 100)) + "%!", Color.RED)
	reset_combo()

func add_speed_boost(boost_amount: float, show_message: bool = true) -> void:
	"""Add a temporary speed boost"""
	speed_boost += boost_amount
	speed_boost = min(speed_boost, 5.0)  # Cap at 5x boost
	if show_message:
		show_feedback_message("Speed Boost! +" + str(int(boost_amount * 100)) + "%", Color.CYAN)

func increment_combo() -> void:
	"""Increment combo counter and apply increasing speed boosts"""
	combo_count += 1
	
	# Increase global multiplier
	gameplay_multiplier = min(gameplay_multiplier + 0.5, 10.0)
	
	# Combo multiplier: 1st = 0.5x, 2nd = 1.0x, 3rd = 1.5x, etc.
	var combo_boost: float = combo_count * 0.5
	add_speed_boost(combo_boost, false)
	show_feedback_message("MULTIPLIER x" + str(gameplay_multiplier) + "!", Color.GOLD)

func reset_combo() -> void:
	"""Reset combo counter on mistake"""
	if combo_count > 0 or gameplay_multiplier > 1.0:
		show_feedback_message("Multiplier Reset!", Color.ORANGE_RED)
	combo_count = 0
	gameplay_multiplier = 1.0

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

	# Update patience timer for new customer (but keep fuel as-is for subsequent customers)
	patience_timer = current_customer.patience_duration
	max_patience = current_customer.patience_duration
	patience_bar.visible = true

	# Initialize fuel system only for the first customer
	if is_first_customer:
		fuel = 100.0  # Start with full fuel
		max_fuel = 100.0
		combo_count = 0
		speed_boost = 0.0
		current_speed = 1.0
		score_accumulator = 0.0
		is_first_customer = false  # Mark that first customer has been initialized

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

	# Update patience timer for new customer
	patience_timer = current_customer.patience_duration
	max_patience = current_customer.patience_duration
	patience_bar.visible = true

	# Initialize fuel system only for the first customer
	if is_first_customer:
		fuel = 100.0  # Start with full fuel
		max_fuel = 100.0
		combo_count = 0
		speed_boost = 0.0
		current_speed = 1.0
		score_accumulator = 0.0
		is_first_customer = false  # Mark that first customer has been initialized

func switch_to_phase2() -> void:
	GameManager.change_phase(GameManager.GamePhase.TRANSFORMING_PREMISES)

	# Change background to Phase 2
	change_background(GameManager.GamePhase.TRANSFORMING_PREMISES)

	# Check if we're already in Phase 2 - if so, just update premises instead of recreating scene
	var already_in_phase2 = current_phase_instance != null and current_phase_instance.has_method("set_premises_and_target")

	if not already_in_phase2:
		# Clear current phase (Phase 1)
		if current_phase_instance:
			current_phase_instance.queue_free()
			current_phase_instance = null

		# Load Phase 2 for the first time
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

	# Update premises and target (whether new scene or existing scene)
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
		# Word problem: Cat meowing example (Modus Ponens)
		var tutorial_nl_premises: Array[String] = [
			"If the cat is hungry (P), then it meows (Q).",
			"The cat is hungry (P)."
		]
		var tutorial_logical_premises: Array[String] = ["P → Q", "P"]
		var tutorial_nl_conclusion: String = "The cat meows (Q)."
		var tutorial_logical_conclusion: String = "Q"
		var tutorial_patience: float = 999999.0  # Infinite time
		var tutorial_solution: String = "Translate: P = 'The cat is hungry', Q = 'The cat meows'. Apply Modus Ponens."
		var tutorial_var_defs: Dictionary = {
			"P": "the cat is hungry",
			"Q": "the cat meows"
		}

		current_customer = GameManagerTypes.CustomerData.new(
			"Tutorial Guide",
			tutorial_logical_premises,
			tutorial_logical_conclusion,
			tutorial_patience,
			tutorial_solution
		)

		# CRITICAL: Set natural language data to enable Phase 1
		current_customer.set_natural_language_data(tutorial_nl_premises, tutorial_nl_conclusion, tutorial_var_defs)

		print("Loaded first-time tutorial word problem")

	# Check if we're in regular tutorial mode
	elif GameManager.tutorial_mode:
		var problem: TutorialDataTypes.ProblemData = GameManager.get_current_tutorial_problem()
		if problem:
			# Create customer from tutorial problem
			var base_patience: float = 120.0  # More generous patience for tutorials
			
			# Determine if this is a natural language problem
			var is_nl = not problem.variable_definitions.is_empty()
			
			# If NL, use hidden premises for logic, otherwise use standard premises
			var logical_premises = problem.hidden_premises if is_nl and not problem.hidden_premises.is_empty() else problem.premises
			var logical_conclusion = problem.hidden_conclusion if is_nl and not problem.hidden_conclusion.is_empty() else problem.conclusion
			
			current_customer = GameManagerTypes.CustomerData.new(random_name, logical_premises, logical_conclusion, base_patience, problem.solution)

			if is_nl:
				current_customer.set_natural_language_data(
					problem.premises, # Display text
					problem.conclusion, # Display conclusion
					problem.variable_definitions
				)

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
		var random_template = templates_for_level[randi() % templates_for_level.size()]

		# Adjust patience based on difficulty and expected operations
		var base_patience: float = 90.0 - (current_level * 10.0) + (random_template.expected_operations * 15.0)

		# Add extra time for word analysis (natural language) problems
		# +20 seconds per operation to account for translation overhead
		if random_template.is_natural_language:
			base_patience += random_template.expected_operations * 20.0

		base_patience = max(30.0, base_patience)  # Minimum 30 seconds

		# Create customer with logical premises (hidden premises for Level 6)
		current_customer = GameManagerTypes.CustomerData.new(random_name, random_template.premises, random_template.conclusion, base_patience, random_template.solution)

		# If this is a Level 6 natural language problem, set the natural language data
		if random_template.is_natural_language:
			current_customer.set_natural_language_data(
				random_template.natural_language_premises,
				random_template.natural_language_conclusion,
				random_template.variable_definitions
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
		var tutorial: TutorialDataTypes.TutorialData = TutorialDataManager.get_tutorial_by_name(GameManager.current_tutorial_key)
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
	# In tutorial mode, just try again
	if GameManager.tutorial_mode:
		AudioManager.play_error()
		show_feedback_message("Time's up! Try this problem again.", Color.RED)
		# Regenerate same problem
		generate_new_customer()
		switch_to_phase1()
	else:
		if is_game_over_sequence_started:
			return
		is_game_over_sequence_started = true

		# Out of fuel = Game Over - play error sound ONCE
		AudioManager.play_error()
		show_feedback_message("Out of Fuel! Game Over!", Color.RED)

		# Trigger failure effect if in Phase 2
		if current_phase_instance and current_phase_instance.has_method("trigger_failure_effect"):
			current_phase_instance.trigger_failure_effect()

		# Create fade overlay if it doesn't exist
		if not intro_flash:
			intro_flash = ColorRect.new()
			intro_flash.color = Color.BLACK
			intro_flash.modulate.a = 0.0
			intro_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			intro_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(intro_flash)
			
			# Add randomized game over comment
			var comment_label = Label.new()
			comment_label.text = game_over_comments.pick_random()
			comment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			comment_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			comment_label.add_theme_color_override("font_color", Color.WHITE)
			comment_label.add_theme_font_size_override("font_size", 32)
			comment_label.set_anchors_preset(Control.PRESET_CENTER)
			intro_flash.add_child(comment_label)

		# Wait briefly, then fade to black
		await get_tree().create_timer(2.0).timeout

		# Stop music and all sounds before transition
		AudioManager.stop_music()

		# Fade to black
		var tween = create_tween()
		tween.tween_property(intro_flash, "modulate:a", 1.0, 4.0)
		await tween.finished

		# Wait a moment in black, then transition
		await get_tree().create_timer(1.0).timeout
		SceneManager.change_scene("res://src/ui/GameOverScene.tscn")

func complete_order_successfully() -> void:
	AudioManager.play_logic_success()

	# No longer calculating score in chunks - it's continuous!
	# Instead, give a big fuel boost for completing the order
	add_fuel(50.0)  # Big fuel reward for completion

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
			show_feedback_message("Order Complete! Fuel Restored!", Color.GOLD)

		# Generate new customer
		generate_new_customer()
		if should_skip_phase1():
		# For symbol-only problems, convert premises directly and go to Phase 2
			convert_premises_and_skip_to_phase2()
		else:
		# Start in Phase 1 for natural language problems
			switch_to_phase1()


# Phase 1 Signal Handlers
func _on_premise_validated(expression: BooleanExpression) -> void:
	validated_premises.append(expression)
	AudioManager.play_premise_complete()

func _on_premises_completed(premises: Array[BooleanExpression]) -> void:
	validated_premises = premises
	show_feedback_message("✓ All premises ready! Advancing to Phase 2...", Color.CYAN)
	# Auto-advance to Phase 2 after a short delay
	get_tree().create_timer(1.5).timeout.connect(switch_to_phase2)

# Phase 2 Signal Handlers
func _on_rule_applied(result: BooleanExpression) -> void:
	validated_premises.append(result)
	AudioManager.play_logic_success()

func _on_target_reached(result: BooleanExpression) -> void:
	show_feedback_message("✓ Proof complete! Order fulfilled!", Color.CYAN)

	# Massive fuel bonus for completing the proof
	add_fuel(30.0)
	# Big speed boost for clean completion
	add_speed_boost(2.0, true)

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
	update_audio_buttons_state()
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

	# End the game and show game over screen
	show_feedback_message("Game Ended!", Color.ORANGE)
	await get_tree().create_timer(1.0).timeout
	SceneManager.change_scene("res://src/ui/GameOverScene.tscn")

func _on_toggle_music_pressed() -> void:
	AudioManager.toggle_music_mute()
	AudioManager.play_button_click()
	update_audio_buttons_state()

func _on_toggle_sfx_pressed() -> void:
	AudioManager.toggle_sfx_mute()
	AudioManager.play_button_click()
	update_audio_buttons_state()

func update_audio_buttons_state() -> void:
	if toggle_music_button:
		toggle_music_button.text = "Unmute Music" if AudioManager.is_music_muted else "Mute Music"
		toggle_music_button.modulate = Color(1, 0.5, 0.5) if AudioManager.is_music_muted else Color.WHITE
		
	if toggle_sfx_button:
		toggle_sfx_button.text = "Unmute SFX" if AudioManager.is_sfx_muted else "Mute SFX"
		toggle_sfx_button.modulate = Color(1, 0.5, 0.5) if AudioManager.is_sfx_muted else Color.WHITE

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

func start_black_hole_rotation() -> void:
	"""Start continuous rotation of the black hole"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(black_hole, "rotation", TAU, 20.0).from(0.0).set_trans(Tween.TRANS_LINEAR)
