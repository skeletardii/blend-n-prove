extends Control

## AI Tutor Mode Scene
## Combines an AI chatbot with a step-by-step boolean logic solver

# Tutor state machine
enum TutorState {
	AWAITING_INPUT,     # Waiting for user input (topic, question, or chat)
	AWAITING_SOLUTION,  # User is solving a problem
	REVIEWING           # Viewing feedback
}

var current_state: TutorState = TutorState.AWAITING_INPUT

# Problem data
var current_problem: Dictionary = {
	"premises": [],
	"target": "",
	"hint": "",
	"full_text": ""
}

# Solution data
var solver_steps: Array[SolverStepRow] = []
var active_step_field: LineEdit = null

# Chat state
var is_chat_open: bool = false
var chat_tween: Tween = null
var has_unread_messages: bool = false

# UI References - Chat Overlay
@onready var chat_toggle_button: Button = $MainMargin/MainVBox/TopBar/ChatToggleButton
@onready var close_button: Button = $ChatOverlayContainer/ChatPanel/ChatVBox/ChatHeader/ChatHeaderMargin/ChatHeaderHBox/CloseButton
@onready var notification_badge: PanelContainer = $MainMargin/MainVBox/TopBar/ChatToggleButton/NotificationBadge
@onready var dim_overlay: ColorRect = $DimOverlay
@onready var chat_overlay: PanelContainer = $ChatOverlayContainer
@onready var messages_container: VBoxContainer = $ChatOverlayContainer/ChatPanel/ChatVBox/ChatMargin/ChatContentVBox/MessagesScroll/MessagesContainer
@onready var messages_scroll: ScrollContainer = $ChatOverlayContainer/ChatPanel/ChatVBox/ChatMargin/ChatContentVBox/MessagesScroll
@onready var input_field: LineEdit = $ChatOverlayContainer/ChatPanel/ChatVBox/ChatMargin/ChatContentVBox/InputArea/InputField
@onready var send_button: Button = $ChatOverlayContainer/ChatPanel/ChatVBox/ChatMargin/ChatContentVBox/InputArea/SendButton
@onready var status_label: Label = $ChatOverlayContainer/ChatPanel/ChatVBox/ChatMargin/ChatContentVBox/StatusLabel
@onready var http_request: HTTPRequest = $ChatOverlayContainer/HTTPRequest

# UI References - Solver
@onready var problem_display: RichTextLabel = $MainMargin/MainVBox/ContentScroll/SolverPanel/SolverMargin/SolverVBox/ProblemDisplay
@onready var steps_container: VBoxContainer = $MainMargin/MainVBox/ContentScroll/SolverPanel/SolverMargin/SolverVBox/StepsScroll/StepsContainer
@onready var add_step_button: Button = $MainMargin/MainVBox/ContentScroll/SolverPanel/SolverMargin/SolverVBox/ButtonsArea/AddStepButton
@onready var finish_button: Button = $MainMargin/MainVBox/ContentScroll/SolverPanel/SolverMargin/SolverVBox/ButtonsArea/FinishButton
@onready var new_problem_button: Button = $MainMargin/MainVBox/ContentScroll/SolverPanel/SolverMargin/SolverVBox/ButtonsArea/NewProblemButton
@onready var virtual_keyboard: VirtualKeyboard = $MainMargin/MainVBox/VirtualKeyboard
@onready var back_button: Button = $MainMargin/MainVBox/TopBar/BackButton
@onready var erase_button: Button = $MainMargin/MainVBox/InputControls/EraseButton
@onready var clear_button: Button = $MainMargin/MainVBox/InputControls/ClearButton

# New UI Elements
var feedback_view: FeedbackView
var loading_overlay: ColorRect
var loading_label: Label

# System prompts
const BASE_SYSTEM_CONTEXT = """You are an expert tutor for boolean logic and formal reasoning.

Available Inference Rules:
- Modus Ponens (MP): P, P → Q ⊢ Q
- Modus Tollens (MT): P → Q, ¬Q ⊢ ¬P
- Hypothetical Syllogism (HS): P → Q, Q → R ⊢ P → R
- Disjunctive Syllogism (DS): P ∨ Q, ¬P ⊢ Q
- Simplification (SIMP): P ∧ Q ⊢ P (or Q)
- Conjunction (CONJ): P, Q ⊢ P ∧ Q
- Addition (ADD): P ⊢ P ∨ Q
- Constructive Dilemma (CD): (P → Q) ∧ (R → S), P ∨ R ⊢ Q ∨ S
- Destructive Dilemma (DD): (P → Q) ∧ (R → S), ¬Q ∨ ¬S ⊢ ¬P ∨ ¬R
- Resolution (RES): P ∨ Q, ¬P ∨ R ⊢ Q ∨ R

Available Equivalence Laws:
- Commutativity: P ∧ Q ≡ Q ∧ P, P ∨ Q ≡ Q ∨ P
- Associativity: (P ∧ Q) ∧ R ≡ P ∧ (Q ∧ R)
- Distributivity: P ∧ (Q ∨ R) ≡ (P ∧ Q) ∨ (P ∧ R)
- De Morgan's Laws: ¬(P ∧ Q) ≡ ¬P ∨ ¬Q, ¬(P ∨ Q) ≡ ¬P ∧ ¬Q
- Double Negation: ¬¬P ≡ P
- Implication: P → Q ≡ ¬P ∨ Q
- Contrapositive: P → Q ≡ ¬Q → ¬P
- Idempotence: P ∧ P ≡ P, P ∨ P ≡ P
- Absorption: P ∧ (P ∨ Q) ≡ P, P ∨ (P ∧ Q) ≡ P
"""

const ROUTER_PROMPT = """Analyze the student's input and determine the appropriate response type.

You MUST respond with ONLY valid JSON in this exact format with a 'type' field. Prioritize generating a 'problem' if the student asks to learn a concept.

1. If the student explicitly asks for a boolean logic practice problem, mentions a topic to practice, or asks to learn/be taught a specific logic concept or rule (e.g., "teach me Modus Ponens", "I want to learn about conjunction"):
{
  "type": "problem",
  "problem_type": "symbol|worded",
  "topic": "description of topic (e.g., Modus Ponens, Conjunction)",
  "premises": ["premise1", "premise2", ...],
  "variable_mapping": {"P": "It is raining", "Q": "The ground is wet"}, // Required if problem_type is 'worded', else null
  "target": "conclusion",
  "hint": "optional hint",
  "difficulty": "easy|medium|hard"
}
Note: Problem should be solvable in 3-7 steps. Premises must be simple logical statements. Variables used in problems MUST be strictly from P, Q, R, S, T, U, V. Do NOT use A, B, C, W, X, Y, Z or any other letters. No step numbers.
If problem_type is "worded", premises should be in English sentences, and variable_mapping must provide the key. If "symbol", premises use logical symbols directly.

2. If the student asks a general question about logic/rules/concepts without requesting to be taught or practice (e.g., "What is a tautology?", "How does Modus Tollens work in general?"):
{
  "type": "answer",
  "response": "detailed answer",
  "related_rules": ["rule1", "rule2"],
  "example": "optional example"
}

3. If the student is just chatting or saying hello:
{
  "type": "chat",
  "response": "conversational response"
}

4. If the request is unrelated to boolean logic, math, or reasoning:
{
  "type": "refusal",
  "response": "polite refusal message explaining you only teach boolean logic"
}

Respond with ONLY the JSON.
"""

const VALIDATION_PROMPT = """Validate the student's step-by-step solution to the boolean logic problem.

The solution steps use the following reference notation:
- P#: Refers to a premise from the original problem (e.g., P1 is the first premise).
- S#: Refers to a previous step in the user's solution (e.g., S1 is the result of the user's first step).

You MUST respond with ONLY valid JSON in this exact format:
{
  "type": "validation",
  "is_correct": true|false,
  "step_analysis": [
    {
      "step": 1,
      "is_correct": true|false,
      "feedback": "Specific feedback for this step (why it is correct or incorrect)",
      "suggestion": "optional hint if incorrect"
    }
  ],
  "feedback": "overall assessment",
  "correct_solution": ["step1", "step2", ...],
  "encouragement": "positive message"
}

Provide analysis for EVERY step submitted by the student.
Respond with ONLY the JSON.
"""

func _ready():
	# Connect signals
	send_button.pressed.connect(_on_send_button_pressed)
	add_step_button.pressed.connect(_on_add_step_button_pressed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	new_problem_button.pressed.connect(_on_new_problem_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	input_field.text_submitted.connect(func(_text): _on_send_button_pressed())

	# Connect new buttons
	erase_button.pressed.connect(_on_erase_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)

	# Connect chat overlay buttons
	chat_toggle_button.pressed.connect(_on_chat_toggle_pressed)
	close_button.pressed.connect(close_chat)
	dim_overlay.gui_input.connect(_on_dim_overlay_clicked)

	# Initialize notification badge
	notification_badge.visible = false
	dim_overlay.modulate = Color(1, 1, 1, 0)
	
	setup_custom_ui()

	# Initial greeting
	add_ai_message("Hello! I'm your AI tutor for boolean logic. How can I help you today?\n\nYou can ask for a problem on a specific topic, or ask me questions about logic rules.")
	current_state = TutorState.AWAITING_INPUT

	# Open chat initially
	await get_tree().process_frame
	open_chat()

func setup_custom_ui():
	# Create Feedback View
	var feedback_scene = load("res://src/ui/FeedbackView.tscn")
	feedback_view = feedback_scene.instantiate()
	feedback_view.z_index = 250 # Ensure it appears above MainMargin(10) and Chat(200)
	feedback_view.visible = false
	feedback_view.continue_pressed.connect(_on_feedback_continue)
	feedback_view.retry_pressed.connect(_on_feedback_retry)
	add_child(feedback_view)
	
	# Create Loading Overlay
	loading_overlay = ColorRect.new()
	loading_overlay.color = Color(0, 0, 0, 0.7)
	loading_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_overlay.visible = false
	loading_overlay.z_index = 300 # Above everything
	add_child(loading_overlay)
	
	loading_label = Label.new()
	loading_label.text = "Evaluating your solution..."
	loading_label.add_theme_font_size_override("font_size", 24)
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loading_label.set_anchors_preset(Control.PRESET_CENTER)
	loading_overlay.add_child(loading_label)

func _on_erase_button_pressed():
	if active_step_field and active_step_field.has_focus():
		var text = active_step_field.text
		if not text.is_empty():
			var caret = active_step_field.caret_column
			if caret > 0:
				active_step_field.text = text.erase(caret - 1, 1)
				active_step_field.caret_column = caret - 1
	elif active_step_field:
			var text = active_step_field.text
			if not text.is_empty():
				active_step_field.text = text.substr(0, text.length() - 1)
				active_step_field.caret_column = active_step_field.text.length()
	AudioManager.play_button_click()

func _on_clear_button_pressed():
	if active_step_field:
		active_step_field.text = ""
		active_step_field.caret_column = 0
	AudioManager.play_button_click()

func _on_send_button_pressed():
	var user_input = input_field.text.strip_edges()
	if user_input.is_empty():
		return

	add_user_message(user_input)
	input_field.text = ""

	# Handle based on current state, but always use Router logic for input interpretation
	# unless we are strictly in a "answering questions while solving" mode.
	# But even then, the user might ask for a new problem.
	
	handle_user_input(user_input)

func handle_user_input(input: String):
	status_label.visible = true
	status_label.text = "Thinking..."

	var context = BASE_SYSTEM_CONTEXT
	if current_state == TutorState.AWAITING_SOLUTION:
		context += "\nCurrent Problem:\nPremises: " + str(current_problem.premises) + "\nTarget: " + current_problem.target

	# Prepare router request
	var request_json = {
		"user_input": input,
		"current_state": "solving" if current_state == TutorState.AWAITING_SOLUTION else "idle"
	}

	var messages = [
		{"role": "system", "content": context + "\n\n" + ROUTER_PROMPT},
		{"role": "user", "content": JSON.stringify(request_json)}
	]

	var response = await OpenRouterService.send_chat_request(messages, http_request)
	status_label.visible = false

	if response.is_empty():
		add_ai_message("I'm having trouble connecting. Please try again.")
		return

	var data = parse_json_response(response)
	if data == null or not data.has("type"):
		add_ai_message("I didn't quite catch that. Could you rephrase?")
		return

	match data.get("type"):
		"problem":
			handle_generated_problem(data)
		"answer":
			var text = data.get("response", "")
			if data.has("example"): text += "\n\nExample: " + data.example
			add_ai_message(text)
		"chat":
			add_ai_message(data.get("response", "Hello!"))
		"refusal":
			add_ai_message(data.get("response", "I can only help with boolean logic."))
		_:
			add_ai_message("I'm not sure how to handle that response type.")

func handle_generated_problem(problem_data: Dictionary):
	current_problem = {
		"topic": problem_data.get("topic", "Logic Problem"),
		"problem_type": problem_data.get("problem_type", "symbol"),
		"premises": problem_data.get("premises", []),
		"variable_mapping": problem_data.get("variable_mapping", {}),
		"target": problem_data.get("target", ""),
		"hint": problem_data.get("hint", ""),
		"difficulty": problem_data.get("difficulty", "medium")
	}

	var chat_msg = "I've generated a problem on: " + current_problem.topic + "\n"
	chat_msg += "Check the main screen to solve it!"
	add_ai_message(chat_msg)
	
	# Close chat to show problem
	close_chat()

	# Update UI
	var problem_text = ""
	
	# Display variable mapping if worded
	if current_problem.problem_type == "worded" and not current_problem.variable_mapping.is_empty():
		problem_text += "[b]Definitions:[/b]\n"
		for key in current_problem.variable_mapping:
			problem_text += "Let " + key + " be: " + current_problem.variable_mapping[key] + "\n"
		problem_text += "\n"

	problem_text += "[b]Premises:[/b]\n"
	for i in range(current_problem.premises.size()):
		problem_text += "P" + str(i + 1) + ": " + current_problem.premises[i] + "\n"
	problem_text += "\n[b]Target:[/b]\n" + current_problem.target

	problem_display.text = problem_text
	add_step_button.visible = true
	finish_button.visible = true
	
	# Clear previous steps
	_clear_solver_steps()
	
	current_state = TutorState.AWAITING_SOLUTION

func _clear_solver_steps():
	for step in solver_steps:
		step.queue_free()
	solver_steps.clear()
	active_step_field = null

func _on_finish_button_pressed():
	if solver_steps.is_empty():
		add_ai_message("Please add at least one step.")
		open_chat()
		return

	# Show loading overlay
	loading_overlay.visible = true
	finish_button.disabled = true
	
	# Collect solution
	var solution_steps = []
	for i in range(solver_steps.size()):
		var step = solver_steps[i]
		var step_data = step.get_step_data()
		solution_steps.append({
			"step_number": i + 1,
			"result": step_data.result,
			"rule": step_data.rule,
			"sources": step_data.sources
		})

	var request_json = {
		"request_type": "validate_solution",
		"problem": current_problem,
		"solution": solution_steps
	}

	var messages = [
		{"role": "system", "content": BASE_SYSTEM_CONTEXT + "\n\n" + VALIDATION_PROMPT},
		{"role": "user", "content": JSON.stringify(request_json)}
	]

	var response = await OpenRouterService.send_chat_request(messages, http_request)
	
	loading_overlay.visible = false
	finish_button.disabled = false

	if response.is_empty():
		add_ai_message("Connection error during validation.")
		open_chat()
		return

	var validation_data = parse_json_response(response)
	if validation_data and validation_data.get("type") == "validation":
		# Show feedback view
		current_state = TutorState.REVIEWING
		feedback_view.visible = true
		feedback_view.display_feedback(solution_steps, validation_data)
		# Hide Chat if open
		if is_chat_open:
			close_chat()
	else:
		add_ai_message("Error validating solution. Please try again.")
		open_chat()

func _on_feedback_continue():
	# Go back to AWAITING_INPUT (Reset)
	feedback_view.visible = false
	current_state = TutorState.AWAITING_INPUT
	
	_clear_solver_steps()
	problem_display.text = "[i]Ask for a new problem in the chat![/i]"
	add_step_button.visible = false
	finish_button.visible = false
	new_problem_button.visible = false # Legacy button, might hide it always
	
	open_chat()
	add_ai_message("Ready for the next topic? Just ask!")

func _on_feedback_retry():
	# Keep the same problem, hide feedback, allow editing
	feedback_view.visible = false
	current_state = TutorState.AWAITING_SOLUTION
	# Steps are still there, user can edit them
	
	# Maybe open chat with hint?
	open_chat()
	add_ai_message("Check the feedback and try to fix your steps!")

# Legacy button handler (if visible)
func _on_new_problem_button_pressed():
	_on_feedback_continue()

func add_ai_message(text: String):
	var msg_box = ChatMessageBox.new(ChatMessageBox.MessageRole.AI, text)
	messages_container.add_child(msg_box)
	await get_tree().process_frame
	messages_scroll.scroll_vertical = messages_scroll.get_v_scroll_bar().max_value
	show_notification_badge()

func add_user_message(text: String):
	var msg_box = ChatMessageBox.new(ChatMessageBox.MessageRole.USER, text)
	messages_container.add_child(msg_box)
	await get_tree().process_frame
	messages_scroll.scroll_vertical = messages_scroll.get_v_scroll_bar().max_value

func parse_json_response(response: String) -> Dictionary:
	var json_start = response.find("{")
	var json_end = response.rfind("}") + 1

	if json_start == -1 or json_end == 0:
		return {}

	var json_str = response.substr(json_start, json_end - json_start)
	var json = JSON.new()
	if json.parse(json_str) == OK:
		return json.data
	return {}

## Chat Overlay Toggle Functions

func _on_chat_toggle_pressed():
	if is_chat_open:
		close_chat()
	else:
		open_chat()

func _on_dim_overlay_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_chat()

func open_chat():
	if is_chat_open:
		return

	is_chat_open = true
	chat_overlay.visible = true
	dim_overlay.visible = true
	
	# Update toggle button state
	chat_toggle_button.button_pressed = true

	if chat_tween and chat_tween.is_running():
		chat_tween.kill()

	chat_tween = create_tween()
	chat_tween.set_parallel(true)

	var screen_size = get_viewport_rect().size
	var target_pos = Vector2(screen_size.x * 0.05, screen_size.y * 0.075)

	chat_tween.tween_property(dim_overlay, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)
	chat_tween.tween_property(chat_overlay, "position", target_pos, 0.5).from(Vector2(screen_size.x, target_pos.y)).set_trans(Tween.TRANS_CUBIC)
	chat_tween.tween_property(chat_overlay, "scale", Vector2(1.0, 1.0), 0.5).from(Vector2(0.95, 0.95)).set_trans(Tween.TRANS_CUBIC)
	chat_tween.tween_property(chat_overlay, "modulate:a", 1.0, 0.5).from(0.0).set_trans(Tween.TRANS_CUBIC)
	chat_tween.tween_property(virtual_keyboard, "modulate:a", 0.3, 0.3).set_trans(Tween.TRANS_CUBIC)

	has_unread_messages = false
	notification_badge.visible = false
	AudioManager.play_button_click()

func close_chat():
	if not is_chat_open:
		return

	is_chat_open = false
	
	# Update toggle button state
	chat_toggle_button.button_pressed = false

	if chat_tween and chat_tween.is_running():
		chat_tween.kill()

	chat_tween = create_tween()
	chat_tween.set_parallel(true)

	var screen_size = get_viewport_rect().size
	var current_pos = chat_overlay.position

	chat_tween.tween_property(dim_overlay, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC)
	chat_tween.tween_property(chat_overlay, "position", Vector2(screen_size.x, current_pos.y), 0.4).set_trans(Tween.TRANS_CUBIC)
	chat_tween.tween_property(chat_overlay, "scale", Vector2(0.95, 0.95), 0.4).set_trans(Tween.TRANS_CUBIC)
	chat_tween.tween_property(chat_overlay, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	chat_tween.tween_property(virtual_keyboard, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)

	chat_tween.chain().tween_callback(func():
		chat_overlay.visible = false
		dim_overlay.visible = false
	)
	AudioManager.play_button_click()

func show_notification_badge():
	if not is_chat_open:
		has_unread_messages = true
		notification_badge.visible = true

## Solver Functions

func _on_add_step_button_pressed():
	var step_number = solver_steps.size() + 1
	var step_row = SolverStepRow.new(step_number)
	step_row.result_focused.connect(_on_step_result_focused)
	step_row.delete_requested.connect(_on_step_delete_requested)
	steps_container.add_child(step_row)
	solver_steps.append(step_row)
	
	await get_tree().process_frame
	_on_step_result_focused(step_row)
	AudioManager.play_button_click()

func _on_step_result_focused(step: SolverStepRow):
	active_step_field = step.get_result_field()
	virtual_keyboard.set_target_field(active_step_field)

func _on_step_delete_requested(step: SolverStepRow):
	var index = solver_steps.find(step)
	if index >= 0:
		solver_steps.remove_at(index)
		step.queue_free()
		for i in range(solver_steps.size()):
			solver_steps[i].update_step_number(i + 1)
	AudioManager.play_button_click()

func _on_back_button_pressed():
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")
	AudioManager.play_button_click()
