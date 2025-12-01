extends Control

# UI References
@onready var main_container: VBoxContainer = $MainContainer
@onready var lives_display: Label = $MainContainer/TopStatusBar/StatusContainer/LivesDisplay
@onready var score_display: Label = $MainContainer/TopStatusBar/StatusContainer/ScoreDisplay
@onready var level_display: Label = $MainContainer/TopStatusBar/StatusContainer/LevelDisplay
@onready var patience_bar: ProgressBar = $MainContainer/TopStatusBar/PatienceBar
@onready var premise_list: VBoxContainer = $MainContainer/CustomerArea/SpeechBubble/PremiseChecklist/PremiseListScroll/PremiseList
@onready var input_display: Label = $MainContainer/InputSystem/InputContainer/InputField/InputDisplay

# Virtual keyboard buttons
@onready var var_p: Button = $MainContainer/VirtualKeyboard/VariableRow/VarP
@onready var var_q: Button = $MainContainer/VirtualKeyboard/VariableRow/VarQ
@onready var var_r: Button = $MainContainer/VirtualKeyboard/VariableRow/VarR
@onready var var_s: Button = $MainContainer/VirtualKeyboard/VariableRow/VarS
@onready var var_t: Button = $MainContainer/VirtualKeyboard/VariableRow/VarT
@onready var and_button: Button = $MainContainer/VirtualKeyboard/OperatorRow/AndButton
@onready var xor_button: Button = $MainContainer/VirtualKeyboard/OperatorRow/XorButton
@onready var biconditional_button: Button = $MainContainer/VirtualKeyboard/OperatorRow/BiconditionalButton
@onready var or_button: Button = $MainContainer/VirtualKeyboard/OperatorRow/OrButton
@onready var implies_button: Button = $MainContainer/VirtualKeyboard/MixedRow/ImpliesButton
@onready var open_paren_button: Button = $MainContainer/VirtualKeyboard/MixedRow/OpenParenButton
@onready var close_paren_button: Button = $MainContainer/VirtualKeyboard/MixedRow/CloseParenButton
@onready var not_button: Button = $MainContainer/VirtualKeyboard/MixedRow/NotButton
@onready var backspace_button: Button = $MainContainer/VirtualKeyboard/MixedRow/BackspaceButton

# Action buttons
@onready var clear_button: Button = $MainContainer/ActionButtons/ButtonContainer/ClearButton
@onready var submit_button: Button = $MainContainer/ActionButtons/ButtonContainer/SubmitButton

# Game State
var current_customer: GameManager.CustomerData
var validated_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var current_input: String = ""
var premise_items: Array[Control] = []
var patience_timer: float = 120.0
var current_time: float = 0.0
var lives: int = 3
var score: int = 0
var level: int = 1

# Signals for parent communication
signal premise_validated(expression: BooleanLogicEngine.BooleanExpression)
signal premises_completed(premises: Array[BooleanLogicEngine.BooleanExpression])
signal feedback_message(message: String, color: Color)
signal patience_expired
signal life_lost
signal text_changed(text: String)  # For tutorial detection

func setup_dynamic_spacing() -> void:
	"""Set dynamic spacing between UI modules based on viewport height"""
	var viewport_height: float = get_viewport_rect().size.y

	# Calculate spacing as a percentage of viewport height
	# For 1280px height, use 10px spacing (0.78%)
	var dynamic_spacing: int = max(5, int(viewport_height * 0.0078))

	# Apply to main container
	if main_container:
		main_container.add_theme_constant_override("separation", dynamic_spacing)

func _ready() -> void:
	setup_dynamic_spacing()
	connect_virtual_keyboard()
	update_input_display()
	update_status_display()

func connect_virtual_keyboard() -> void:
	# Variable buttons
	var_p.pressed.connect(_on_symbol_pressed.bind("P"))
	var_q.pressed.connect(_on_symbol_pressed.bind("Q"))
	var_r.pressed.connect(_on_symbol_pressed.bind("R"))
	var_s.pressed.connect(_on_symbol_pressed.bind("S"))
	var_t.pressed.connect(_on_symbol_pressed.bind("T"))

	# Operator buttons
	and_button.pressed.connect(_on_symbol_pressed.bind("∧"))
	xor_button.pressed.connect(_on_symbol_pressed.bind("⊕"))
	biconditional_button.pressed.connect(_on_symbol_pressed.bind("↔"))
	or_button.pressed.connect(_on_symbol_pressed.bind("∨"))
	implies_button.pressed.connect(_on_symbol_pressed.bind("→"))
	not_button.pressed.connect(_on_symbol_pressed.bind("¬"))

	# Parentheses buttons
	open_paren_button.pressed.connect(_on_symbol_pressed.bind("("))
	close_paren_button.pressed.connect(_on_symbol_pressed.bind(")"))

	# Special buttons
	backspace_button.pressed.connect(_on_backspace_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	submit_button.pressed.connect(_on_submit_pressed)

func set_customer_data(customer: GameManager.CustomerData) -> void:
	current_customer = customer
	validated_premises.clear()
	update_premise_checklist()

	clear_input()

func _on_symbol_pressed(symbol: String) -> void:
	AudioManager.play_button_click()
	# Handle special symbols with spacing
	if symbol in ["∧", "∨", "⊕", "↔", "→"]:
		current_input += " " + symbol + " "
	else:
		current_input += symbol
	update_input_display()

func _on_backspace_pressed() -> void:
	AudioManager.play_button_click()
	if current_input.length() > 0:
		current_input = current_input.substr(0, current_input.length() - 1)
		# If we just deleted a character and the input now ends with a space, remove that space too
		if current_input.length() > 0 and current_input[current_input.length() - 1] == " ":
			current_input = current_input.substr(0, current_input.length() - 1)
		update_input_display()

func _on_clear_pressed() -> void:
	AudioManager.play_button_click()
	clear_input()

func _on_submit_pressed() -> void:
	AudioManager.play_button_click()
	validate_current_input()

func validate_current_input() -> void:
	var expression_text: String = current_input.strip_edges()
	if expression_text.is_empty():
		feedback_message.emit("Please enter a premise first", Color.ORANGE)
		return

	# Validate the expression
	var expression := BooleanLogicEngine.create_expression(expression_text)

	if expression.is_valid:
		# Check if this expression matches one of the required premises
		var is_required: bool = false
		var matched_index: int = -1
		for i in range(current_customer.required_premises.size()):
			var required_premise = current_customer.required_premises[i]
			if expression.expression_string.strip_edges() == required_premise.strip_edges():
				is_required = true
				matched_index = i
				break

		if is_required:
			# Check if already completed
			var already_exists: bool = false
			for existing in validated_premises:
				if existing.expression_string == expression.expression_string:
					already_exists = true
					break

			if not already_exists:
				validated_premises.append(expression)
				update_premise_checklist()
				clear_input()
				premise_validated.emit(expression)

				# Different feedback for Level 6 vs Levels 1-5
				if current_customer.is_natural_language:
					feedback_message.emit("✓ Correct translation!", Color.GREEN)
				else:
					feedback_message.emit("✓ Premise validated!", Color.GREEN)

				score += 100
				update_status_display()

				# Check if we can proceed to next phase
				if check_premises_completion():
					feedback_message.emit("✓ All premises ready! Advancing to Phase 2...", Color.CYAN)
					premises_completed.emit(validated_premises)
			else:
				feedback_message.emit("This premise is already validated", Color.YELLOW)
		else:
			# Different error feedback for Level 6 vs Levels 1-5
			if current_customer.is_natural_language:
				feedback_message.emit("✗ That doesn't match the sentence meaning. Try again!", Color.RED)
			else:
				feedback_message.emit("This expression doesn't match required premises", Color.RED)

			clear_input()
			lives -= 1
			update_status_display()
			if lives <= 0:
				life_lost.emit()
	else:
		feedback_message.emit("Invalid premise syntax", Color.RED)
		clear_input()
		lives -= 1
		update_status_display()
		if lives <= 0:
			life_lost.emit()

func clear_input() -> void:
	current_input = ""
	update_input_display()

func update_input_display() -> void:
	if current_input.is_empty():
		input_display.text = "Type your premise here..."
		input_display.modulate = Color(0.5, 0.5, 0.5, 1)  # Gray placeholder with better contrast
	else:
		input_display.text = current_input
		input_display.modulate = Color(0.1, 0.1, 0.1, 1)  # Dark text for better contrast

	# Emit signal for tutorial detection
	text_changed.emit(current_input)

func update_status_display() -> void:
	# Update lives display
	var hearts = ""
	for i in range(lives):
		hearts += "❤️ "
	lives_display.text = hearts.strip_edges()

	# Update score
	score_display.text = "Score: " + str(score)

	# Update level
	level_display.text = "LV." + str(level)

func update_premise_checklist() -> void:
	# Clear existing items
	for item in premise_items:
		item.queue_free()
	premise_items.clear()

	# Determine which text to display based on problem type
	var display_premises: Array[String] = []
	if current_customer.is_natural_language:
		# Level 6: Show natural language sentences
		display_premises = current_customer.natural_language_premises.duplicate()
	else:
		# Levels 1-5: Show logical symbols
		display_premises = current_customer.required_premises.duplicate()

	# Create new items
	for i in range(display_premises.size()):
		var premise_text = display_premises[i]
		var is_completed = is_premise_completed_by_index(i)

		var premise_panel = create_premise_panel(premise_text, is_completed)
		premise_list.add_child(premise_panel)
		premise_items.append(premise_panel)

func create_premise_panel(premise_text: String, is_completed: bool) -> PanelContainer:
	var panel = PanelContainer.new()

	# Create StyleBox for the panel
	var style_box = StyleBoxFlat.new()
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8

	if is_completed:
		# Completed: White background with subtle gray border
		style_box.bg_color = Color(1.0, 1.0, 1.0, 1.0)  # White
		style_box.border_color = Color(0.7, 0.7, 0.7, 1.0)  # Light gray border
		style_box.shadow_color = Color(0.0, 0.0, 0.0, 0.3)  # Subtle shadow
	else:
		# Unchecked: Dark grey with drop shadow to emphasize hole
		style_box.bg_color = Color(0.25, 0.25, 0.25, 1.0)  # Dark grey
		style_box.border_color = Color(0.15, 0.15, 0.15, 1.0)  # Darker grey border
		style_box.shadow_color = Color(0.0, 0.0, 0.0, 0.8)  # Deep shadow for hole effect

	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.shadow_size = 4
	style_box.shadow_offset = Vector2(2, 2)

	style_box.content_margin_left = 12
	style_box.content_margin_right = 12
	style_box.content_margin_top = 8
	style_box.content_margin_bottom = 8

	panel.add_theme_stylebox_override("panel", style_box)

	# Create label
	var label = Label.new()
	label.text = premise_text
	var font_size = 24 if current_customer.is_natural_language else 48
	label.add_theme_font_size_override("font_size", font_size)

	# For natural language text, enable word wrapping
	if current_customer.is_natural_language:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 350

	if is_completed:
		# Black text for contrast on white background
		label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))  # Black for contrast
	else:
		# Dirty white for unchecked
		label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8, 1.0))  # Dirty white

	panel.add_child(label)
	return panel

func is_premise_completed(premise_text: String) -> bool:
	for validated in validated_premises:
		if validated.expression_string.strip_edges() == premise_text.strip_edges():
			return true
	return false

func is_premise_completed_by_index(index: int) -> bool:
	# For Level 6, we validate against hidden logical premises by checking if the index has been validated
	if index < 0 or index >= current_customer.required_premises.size():
		return false

	var required_premise = current_customer.required_premises[index]
	for validated in validated_premises:
		if validated.expression_string.strip_edges() == required_premise.strip_edges():
			return true
	return false

func check_premises_completion() -> bool:
	if not current_customer:
		return false

	# Check if we have all required premises in the tray
	var required_count: int = current_customer.required_premises.size()
	var validated_count: int = 0

	for required_premise in current_customer.required_premises:
		for validated_premise in validated_premises:
			if validated_premise.expression_string.strip_edges() == required_premise.strip_edges():
				validated_count += 1
				break

	return validated_count >= required_count

func _process(delta: float) -> void:
	if current_customer:
		current_time += delta
		var remaining_ratio = max(0.0, (patience_timer - current_time) / patience_timer)
		patience_bar.value = remaining_ratio * 100.0

		if current_time >= patience_timer:
			patience_expired.emit()

func get_validated_premises() -> Array[BooleanLogicEngine.BooleanExpression]:
	return validated_premises
