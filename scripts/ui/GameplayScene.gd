extends Control

# UI References - Persistent Elements
@onready var lives_display: Label = $UI/MainContainer/TopBar/TopBarContainer/LivesContainer/LivesDisplay
@onready var score_display: Label = $UI/MainContainer/TopBar/TopBarContainer/ScoreContainer/ScoreDisplay
@onready var customer_name: Label = $UI/MainContainer/GameContentArea/CustomerArea/CustomerContainer/CustomerName
@onready var patience_bar: ProgressBar = $UI/MainContainer/PatienceBar
@onready var order_display: RichTextLabel = $UI/MainContainer/GameContentArea/CustomerArea/CustomerContainer/OrderDisplay
@onready var phase_container: Control = $UI/MainContainer/GameContentArea/PhaseContainer

# Phase Scenes
var phase1_scene: PackedScene = preload("res://scenes/Phase1UI.tscn")
var phase2_scene: PackedScene = preload("res://scenes/Phase2UI.tscn")
var current_phase_instance: Control = null

# Game State
var current_customer: GameManager.CustomerData
var validated_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var patience_timer: float = 0.0
var max_patience: float = 60.0
var feedback_label: Label = null
var feedback_timer: Timer = null

func _ready() -> void:
	# Connect to GameManager signals
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.lives_updated.connect(_on_lives_updated)

	# Start background music
	AudioManager.start_background_music()

	# Initialize UI
	update_lives_display()
	update_score_display()

	# Generate first customer
	generate_new_customer()

	# Start in Phase 1
	switch_to_phase1()

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING and current_customer:
		update_patience_timer(delta)

func update_patience_timer(delta: float) -> void:
	if GameManager.infinite_patience or GameManager.current_phase != GameManager.GamePhase.PREPARING_PREMISES:
		return

	patience_timer -= delta
	patience_timer = max(0.0, patience_timer)

	var patience_percentage: float = (patience_timer / max_patience) * 100.0
	patience_bar.value = patience_percentage

	# Change color based on urgency
	if patience_percentage > 60:
		patience_bar.modulate = Color.GREEN
	elif patience_percentage > 30:
		patience_bar.modulate = Color.YELLOW
	else:
		patience_bar.modulate = Color.RED

	# Customer leaves if patience runs out
	if patience_timer <= 0.0:
		customer_leaves()

func switch_to_phase1() -> void:
	GameManager.change_phase(GameManager.GamePhase.PREPARING_PREMISES)

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

func switch_to_phase2() -> void:
	GameManager.change_phase(GameManager.GamePhase.TRANSFORMING_PREMISES)

	# Clear current phase
	if current_phase_instance:
		current_phase_instance.queue_free()
		current_phase_instance = null

	# Load Phase 2
	current_phase_instance = phase2_scene.instantiate()
	phase_container.add_child(current_phase_instance)

	# Connect Phase 2 signals
	current_phase_instance.rule_applied.connect(_on_rule_applied)
	current_phase_instance.target_reached.connect(_on_target_reached)
	current_phase_instance.feedback_message.connect(_on_feedback_message)

	# Pass premises and target to Phase 2
	current_phase_instance.set_premises_and_target(validated_premises, current_customer.target_conclusion)

	# Hide patience bar in Phase 2
	patience_bar.visible = false

func generate_new_customer() -> void:
	var customer_names: Array[String] = ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"]
	var random_name: String = customer_names[randi() % customer_names.size()]

	# Check if we're in tutorial mode
	if GameManager.tutorial_mode:
		var problem: TutorialDataManager.ProblemData = GameManager.get_current_tutorial_problem()
		if problem:
			# Create customer from tutorial problem
			var base_patience: float = 120.0  # More generous patience for tutorials
			current_customer = GameManager.CustomerData.new(random_name, problem.premises, problem.conclusion, base_patience)

			print("Loaded tutorial problem ", problem.problem_number, " (", problem.difficulty, ")")
		else:
			# No more problems in tutorial - return to grid
			print("Tutorial complete! Returning to tutorial selection.")
			SceneManager.change_scene("res://scenes/GridButtonScene.tscn")
			return
	else:
		# Normal game mode - use order templates
		# Get current difficulty level (clamped to available levels)
		var current_level: int = min(GameManager.difficulty_level, 5)

		# Get random order template for this level
		var templates_for_level = GameManager.order_templates[current_level]
		var random_template: GameManager.OrderTemplate = templates_for_level[randi() % templates_for_level.size()]

		# Adjust patience based on difficulty and expected operations
		var base_patience: float = 90.0 - (current_level * 10.0) + (random_template.expected_operations * 15.0)
		base_patience = max(30.0, base_patience)  # Minimum 30 seconds

		current_customer = GameManager.CustomerData.new(random_name, random_template.premises, random_template.conclusion, base_patience)

	# Update UI
	update_customer_display()
	AudioManager.play_customer_arrive()

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

	var order_text: String = "[b]Premises:[/b]\n"
	for premise in current_customer.required_premises:
		order_text += premise + "\n"

	order_text += "\n[b]Conclusion:[/b]\n" + current_customer.target_conclusion

	order_display.text = order_text

func customer_leaves() -> void:
	AudioManager.play_customer_leave()

	# In tutorial mode, don't lose lives - just try again
	if GameManager.tutorial_mode:
		show_feedback_message("Time's up! Try this problem again.", Color.RED)
		# Regenerate same problem
		generate_new_customer()
		switch_to_phase1()
	else:
		GameManager.lose_life()

		if GameManager.current_lives > 0:
			# Generate new customer
			generate_new_customer()
			switch_to_phase1()
		else:
			# Game over
			SceneManager.change_scene("res://scenes/GameOverScene.tscn")

func complete_order_successfully() -> void:
	AudioManager.play_logic_success()

	# Calculate score based on speed and efficiency
	var time_bonus: int = int(patience_timer)
	var base_score: int = 100 + (GameManager.difficulty_level * 50)
	var total_score: int = base_score + time_bonus

	GameManager.add_score(total_score)

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
				SceneManager.change_scene("res://scenes/GridButtonScene.tscn")
			)
	else:
		# Normal game mode progression
		# Increase difficulty level after each completed order (until level 5)
		if GameManager.difficulty_level < 5:
			GameManager.difficulty_level += 1
			show_feedback_message("Level Up! Now at Level " + str(GameManager.difficulty_level), Color.GOLD)
		else:
			show_feedback_message("Master Level - Well done!", Color.GOLD)

		# Generate new customer
		generate_new_customer()
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

func _on_lives_updated(new_lives: int) -> void:
	update_lives_display()

func update_score_display() -> void:
	score_display.text = str(GameManager.current_score)

func update_lives_display() -> void:
	var hearts: String = ""
	for i in range(GameManager.current_lives):
		hearts += "♥"
	lives_display.text = hearts

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
