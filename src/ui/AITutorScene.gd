extends Control

## AI Tutor Mode Scene
## Combines an AI chatbot with a step-by-step boolean logic solver

# Tutor state machine
enum TutorState {
	GREETING,           # Initial greeting
	AWAITING_TOPIC,     # Waiting for learning topic
	GENERATING_PROBLEM, # AI creating problem
	AWAITING_SOLUTION,  # User solving
	PROVIDING_FEEDBACK  # AI reviewing
}

var current_state: TutorState = TutorState.GREETING

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

# Note: We use stateless JSON requests, no conversation history needed

# UI References
@onready var messages_container: VBoxContainer = $MainMargin/MainVBox/ChatPanel/ChatMargin/ChatVBox/MessagesScroll/MessagesContainer
@onready var messages_scroll: ScrollContainer = $MainMargin/MainVBox/ChatPanel/ChatMargin/ChatVBox/MessagesScroll
@onready var input_field: LineEdit = $MainMargin/MainVBox/ChatPanel/ChatMargin/ChatVBox/InputArea/InputField
@onready var send_button: Button = $MainMargin/MainVBox/ChatPanel/ChatMargin/ChatVBox/InputArea/SendButton
@onready var status_label: Label = $MainMargin/MainVBox/ChatPanel/ChatMargin/ChatVBox/StatusLabel
@onready var http_request: HTTPRequest = $MainMargin/MainVBox/ChatPanel/HTTPRequest
@onready var problem_display: RichTextLabel = $MainMargin/MainVBox/SolverPanel/SolverMargin/SolverVBox/ProblemDisplay
@onready var steps_container: VBoxContainer = $MainMargin/MainVBox/SolverPanel/SolverMargin/SolverVBox/StepsScroll/StepsContainer
@onready var add_step_button: Button = $MainMargin/MainVBox/SolverPanel/SolverMargin/SolverVBox/ButtonsArea/AddStepButton
@onready var finish_button: Button = $MainMargin/MainVBox/SolverPanel/SolverMargin/SolverVBox/ButtonsArea/FinishButton
@onready var new_problem_button: Button = $MainMargin/MainVBox/SolverPanel/SolverMargin/SolverVBox/ButtonsArea/NewProblemButton
@onready var virtual_keyboard: VirtualKeyboard = $MainMargin/MainVBox/VirtualKeyboard
@onready var back_button: Button = $MainMargin/MainVBox/TopBar/BackButton

# System prompts for different request types
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

Use only variables: P, Q, R, S, T
Use operators: ∧ (AND), ∨ (OR), ⊕ (XOR), ¬ (NOT), → (implies), ↔ (biconditional)
"""

const PROBLEM_GENERATION_PROMPT = """Generate a boolean logic practice problem based on the student's learning request.

You MUST respond with ONLY valid JSON in this exact format:
{
  "type": "problem",
  "topic": "description of what this problem teaches",
  "premises": ["premise1", "premise2", ...],
  "target": "conclusion to derive",
  "hint": "optional hint about which rules to use",
  "difficulty": "easy|medium|hard"
}

Requirements:
- Problem should be solvable in 3-7 steps
- Premises should be simple, clear logical statements
- Target should logically follow from premises
- Do not include step numbers or labels in premises
- Respond with ONLY the JSON, no other text
"""

const VALIDATION_PROMPT = """Validate the student's step-by-step solution to a boolean logic problem.

You MUST respond with ONLY valid JSON in this exact format:
{
  "type": "validation",
  "is_correct": true|false,
  "errors": [
    {
      "step": 1,
      "issue": "description of the error",
      "suggestion": "how to fix it"
    }
  ],
  "feedback": "overall feedback message",
  "correct_solution": ["step1", "step2", ...],
  "encouragement": "positive message for the student"
}

If solution is correct, errors array should be empty and is_correct should be true.
Respond with ONLY the JSON, no other text.
"""

const QUESTION_PROMPT = """Answer the student's question about boolean logic, inference rules, or their current problem.

You MUST respond with ONLY valid JSON in this exact format:
{
  "type": "answer",
  "response": "your detailed answer to the question",
  "related_rules": ["rule1", "rule2", ...],
  "example": "optional example if helpful"
}

Be concise but thorough. Respond with ONLY the JSON, no other text.
"""

func _ready():
	# Connect signals
	send_button.pressed.connect(_on_send_button_pressed)
	add_step_button.pressed.connect(_on_add_step_button_pressed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	new_problem_button.pressed.connect(_on_new_problem_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	input_field.text_submitted.connect(func(_text): _on_send_button_pressed())

	# Initialize conversation with base context (no history needed for JSON mode)
	add_ai_message("Hello! I'm your AI tutor for boolean logic. What would you like to learn today?\n\nFor example, you can say:\n• 'I want to learn modus ponens'\n• 'Help me with De Morgan's laws'\n• 'Teach me about disjunctive syllogism'")
	current_state = TutorState.AWAITING_TOPIC

func _on_send_button_pressed():
	var user_input = input_field.text.strip_edges()
	if user_input.is_empty():
		return

	# Add user message to chat
	add_user_message(user_input)
	input_field.text = ""

	# Handle based on current state
	match current_state:
		TutorState.AWAITING_TOPIC:
			await handle_topic_request(user_input)
		TutorState.AWAITING_SOLUTION:
			# User can ask questions during solving
			await handle_question_during_solving(user_input)
		_:
			# Generic conversation
			await handle_generic_conversation(user_input)

func add_ai_message(text: String):
	var msg_box = ChatMessageBox.new(ChatMessageBox.MessageRole.AI, text)
	messages_container.add_child(msg_box)
	await get_tree().process_frame
	messages_scroll.scroll_vertical = messages_scroll.get_v_scroll_bar().max_value

func add_user_message(text: String):
	var msg_box = ChatMessageBox.new(ChatMessageBox.MessageRole.USER, text)
	messages_container.add_child(msg_box)
	await get_tree().process_frame
	messages_scroll.scroll_vertical = messages_scroll.get_v_scroll_bar().max_value

func handle_topic_request(topic: String):
	current_state = TutorState.GENERATING_PROBLEM
	status_label.visible = true
	status_label.text = "Generating problem..."

	# Build JSON request for problem generation
	var request_json = {
		"request_type": "generate_problem",
		"topic": topic
	}

	# Create messages with system context and request
	var messages = [
		{"role": "system", "content": BASE_SYSTEM_CONTEXT + "\n\n" + PROBLEM_GENERATION_PROMPT},
		{"role": "user", "content": JSON.stringify(request_json)}
	]

	# Request problem from AI
	var response = await OpenRouterService.send_chat_request(messages, http_request)

	if response.is_empty():
		add_ai_message("I'm having trouble connecting. Please try again.")
		status_label.visible = false
		current_state = TutorState.AWAITING_TOPIC
		return

	# Parse JSON response
	var problem_data = parse_json_response(response)

	if problem_data == null or problem_data.get("type") != "problem":
		add_ai_message("I had trouble generating a problem. Please try rephrasing your request.")
		status_label.visible = false
		current_state = TutorState.AWAITING_TOPIC
		return

	# Store problem data
	current_problem = {
		"topic": problem_data.get("topic", ""),
		"premises": problem_data.get("premises", []),
		"target": problem_data.get("target", ""),
		"hint": problem_data.get("hint", ""),
		"difficulty": problem_data.get("difficulty", "medium")
	}

	# Display problem in chat
	var chat_msg = "Great! I've prepared a problem for you on [b]" + current_problem.topic + "[/b].\n"
	chat_msg += "Difficulty: " + current_problem.difficulty.capitalize()
	add_ai_message(chat_msg)

	# Display problem in solver area
	if not current_problem.premises.is_empty():
		var problem_text = "[b]Premises:[/b]\n"
		for i in range(current_problem.premises.size()):
			problem_text += "P" + str(i + 1) + ": " + current_problem.premises[i] + "\n"
		problem_text += "\n[b]Target:[/b]\n" + current_problem.target

		#if not current_problem.hint.is_empty():
			#problem_text += "\n\n[b]Hint:[/b]\n" + current_problem.hint

		problem_display.text = problem_text

		# Enable solver UI
		add_step_button.visible = true
		finish_button.visible = true

		current_state = TutorState.AWAITING_SOLUTION
	else:
		add_ai_message("There was an issue with the problem. Please try again.")
		current_state = TutorState.AWAITING_TOPIC

	status_label.visible = false

func parse_json_response(response: String) -> Dictionary:
	# Try to extract JSON from response (handle cases where AI adds extra text)
	var json_start = response.find("{")
	var json_end = response.rfind("}") + 1

	if json_start == -1 or json_end == 0:
		print("Error: No JSON found in response")
		return {}

	var json_str = response.substr(json_start, json_end - json_start)
	var json = JSON.new()
	var parse_result = json.parse(json_str)

	if parse_result != OK:
		print("Error parsing JSON: ", json.get_error_message())
		return {}

	return json.data

func handle_question_during_solving(question: String):
	status_label.visible = true
	status_label.text = "Thinking..."

	# Build JSON request for question
	var request_json = {
		"request_type": "answer_question",
		"question": question,
		"current_problem": current_problem
	}

	var messages = [
		{"role": "system", "content": BASE_SYSTEM_CONTEXT + "\n\n" + QUESTION_PROMPT},
		{"role": "user", "content": JSON.stringify(request_json)}
	]

	var response = await OpenRouterService.send_chat_request(messages, http_request)

	if not response.is_empty():
		var answer_data = parse_json_response(response)

		if answer_data != null and answer_data.get("type") == "answer":
			var answer_text = answer_data.get("response", "")

			# Add related rules if present
			if answer_data.has("related_rules") and answer_data.related_rules.size() > 0:
				answer_text += "\n\n[b]Related Rules:[/b] " + ", ".join(answer_data.related_rules)

			# Add example if present
			if answer_data.has("example") and answer_data.example != "":
				answer_text += "\n\n[b]Example:[/b] " + answer_data.example

			add_ai_message(answer_text)
		else:
			add_ai_message(response)  # Fallback to raw response

	status_label.visible = false

func handle_generic_conversation(message: String):
	# Use question handler for generic conversation too
	await handle_question_during_solving(message)

func _on_add_step_button_pressed():
	var step_number = solver_steps.size() + 1
	var step_row = SolverStepRow.new(step_number)
	step_row.result_focused.connect(_on_step_result_focused)
	step_row.delete_requested.connect(_on_step_delete_requested)
	steps_container.add_child(step_row)
	solver_steps.append(step_row)

	# Auto-focus the new step
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

		# Renumber remaining steps
		for i in range(solver_steps.size()):
			solver_steps[i].update_step_number(i + 1)

	AudioManager.play_button_click()

func _on_finish_button_pressed():
	if solver_steps.is_empty():
		add_ai_message("Please add at least one step before submitting.")
		return

	finish_button.disabled = true
	finish_button.text = "Submitting..."
	status_label.visible = true
	status_label.text = "AI is reviewing your solution..."

	# Build solution data for validation
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

	# Build JSON request for validation
	var request_json = {
		"request_type": "validate_solution",
		"problem": current_problem,
		"solution": solution_steps
	}

	var messages = [
		{"role": "system", "content": BASE_SYSTEM_CONTEXT + "\n\n" + VALIDATION_PROMPT},
		{"role": "user", "content": JSON.stringify(request_json)}
	]

	# Show solution summary to user
	var solution_summary = "My solution:\n"
	for i in range(solution_steps.size()):
		var step = solution_steps[i]
		solution_summary += "Step %d: %s (Rule: %s, From: %s)\n" % [
			step.step_number,
			step.result,
			step.rule,
			step.sources
		]
	add_user_message(solution_summary)

	# Get AI validation
	var response = await OpenRouterService.send_chat_request(messages, http_request)

	status_label.visible = false
	finish_button.disabled = false
	finish_button.text = "Submit for Feedback"

	if not response.is_empty():
		var validation_data = parse_json_response(response)

		if validation_data != null and validation_data.get("type") == "validation":
			var is_correct = validation_data.get("is_correct", false)
			var errors = validation_data.get("errors", [])
			var feedback = validation_data.get("feedback", "")
			var encouragement = validation_data.get("encouragement", "")

			# Build feedback message
			var feedback_msg = ""

			if is_correct:
				feedback_msg = "[color=green][b]✓ Correct![/b][/color]\n\n"
			else:
				feedback_msg = "[color=orange][b]Not quite right...[/b][/color]\n\n"

			feedback_msg += feedback

			# Show specific errors if present
			if errors.size() > 0:
				feedback_msg += "\n\n[b]Issues found:[/b]"
				for error in errors:
					feedback_msg += "\n• [b]Step " + str(error.step) + ":[/b] " + error.issue
					if error.has("suggestion"):
						feedback_msg += "\n  [i]Suggestion:[/i] " + error.suggestion

			# Add correct solution if provided
			if not is_correct and validation_data.has("correct_solution"):
				var correct_sol = validation_data.correct_solution
				if correct_sol.size() > 0:
					feedback_msg += "\n\n[b]Correct approach:[/b]"
					for i in range(correct_sol.size()):
						feedback_msg += "\n" + str(i + 1) + ". " + correct_sol[i]

			feedback_msg += "\n\n" + encouragement

			add_ai_message(feedback_msg)

			# Allow questions after validation - show new problem button
			current_state = TutorState.AWAITING_SOLUTION
			new_problem_button.visible = true
			add_ai_message("Do you have any questions about this solution?\n\nOr click 'Try Another Problem' below when you're ready for a new challenge!")
		else:
			add_ai_message(response)  # Fallback to raw response
	else:
		add_ai_message("I had trouble reviewing your solution. Please try again.")

	AudioManager.play_button_click()

func _on_new_problem_button_pressed():
	# Clear all solver steps
	for step in solver_steps:
		step.queue_free()
	solver_steps.clear()

	# Clear problem display
	problem_display.text = "[i]New problem will appear here[/i]"

	# Hide solver buttons
	add_step_button.visible = false
	finish_button.visible = false
	new_problem_button.visible = false

	# Reset active field
	active_step_field = null

	# Reset state
	current_state = TutorState.AWAITING_TOPIC
	current_problem = {
		"premises": [],
		"target": "",
		"hint": "",
		"difficulty": ""
	}

	# Add prompt for new topic
	add_ai_message("Great! What would you like to learn next?")

	AudioManager.play_button_click()

func _on_back_button_pressed():
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")
	AudioManager.play_button_click()
