class_name FeedbackView
extends Control

signal continue_pressed
signal retry_pressed

@onready var main_scroll: ScrollContainer = $MarginContainer/ScrollContainer
@onready var content_vbox: VBoxContainer = $MarginContainer/ScrollContainer/ContentVBox
@onready var steps_container: VBoxContainer = $MarginContainer/ScrollContainer/ContentVBox/StepsContainer
@onready var feedback_label: RichTextLabel = $MarginContainer/ScrollContainer/ContentVBox/FeedbackLabel
@onready var correct_solution_container: VBoxContainer = $MarginContainer/ScrollContainer/ContentVBox/CorrectSolutionContainer
@onready var buttons_container: HBoxContainer = $MarginContainer/ScrollContainer/ContentVBox/ButtonsContainer
@onready var retry_button: Button = $MarginContainer/ScrollContainer/ContentVBox/ButtonsContainer/RetryButton
@onready var continue_button: Button = $MarginContainer/ScrollContainer/ContentVBox/ButtonsContainer/ContinueButton
@onready var correct_label: RichTextLabel = $MarginContainer/ScrollContainer/ContentVBox/CorrectSolutionContainer/CorrectLabel

func _ready():
	retry_button.pressed.connect(func(): retry_pressed.emit())
	continue_button.pressed.connect(func(): continue_pressed.emit())

func display_feedback(user_steps: Array, validation_data: Dictionary):
	# Clear previous
	for child in steps_container.get_children():
		child.queue_free()
	
	var is_correct = validation_data.get("is_correct", false)
	var step_analysis = validation_data.get("step_analysis", [])
	var feedback = validation_data.get("feedback", "")
	var encouragement = validation_data.get("encouragement", "")
	
	# Set header feedback
	var header_text = ""
	if is_correct:
		header_text = "[center][color=green][b]Correct![/b][/color]\n" + encouragement + "[/center]"
	else:
		header_text = "[center][color=#d63031][b]Needs Improvement[/b][/color]\n" + feedback + "[/center]"
	feedback_label.text = header_text
	
	# Create map of analysis for easy lookup: step_number -> analysis_data
	var analysis_map = {}
	for item in step_analysis:
		var step_num = int(item.get("step", -1))
		if step_num != -1:
			analysis_map[step_num] = item
	
	# Populate steps
	for i in range(user_steps.size()):
		var step_data = user_steps[i]
		var step_num = i + 1
		var analysis = analysis_map.get(step_num, {})
		var step_is_correct = analysis.get("is_correct", false)
		
		var step_panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		
		if not step_is_correct:
			style.border_color = Color(0.9, 0.3, 0.3, 1.0) # Red border
			style.bg_color = Color(1.0, 0.95, 0.95, 1.0) # Light red bg
		else:
			style.border_color = Color(0.2, 0.6, 0.2, 1.0) # Green border
			style.bg_color = Color(0.95, 1.0, 0.95, 1.0) # Light green bg
			
		step_panel.add_theme_stylebox_override("panel", style)
		
		var step_margin = MarginContainer.new()
		step_margin.add_theme_constant_override("margin_left", 10)
		step_margin.add_theme_constant_override("margin_top", 10)
		step_margin.add_theme_constant_override("margin_right", 10)
		step_margin.add_theme_constant_override("margin_bottom", 10)
		step_panel.add_child(step_margin)
		
		var step_vbox = VBoxContainer.new()
		step_margin.add_child(step_vbox)
		
		# Step content
		var step_text = "[b]Step " + str(step_num) + ":[/b] " + str(step_data.get("result", "")) + "\n"
		step_text += "[color=gray]Using " + str(step_data.get("rule", "")) + " on " + str(step_data.get("sources", [])) + "[/color]"
		
		var step_label = RichTextLabel.new()
		step_label.bbcode_enabled = true
		step_label.text = step_text
		step_label.fit_content = true
		step_label.add_theme_color_override("default_color", Color(0,0,0,1))
		step_vbox.add_child(step_label)
		
		# Analysis Feedback
		var feedback_msg = Label.new()
		feedback_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if step_is_correct:
			feedback_msg.text = "✅ " + analysis.get("feedback", "Correct step")
			feedback_msg.add_theme_color_override("font_color", Color(0.1, 0.5, 0.1, 1.0))
		else:
			feedback_msg.text = "❌ " + analysis.get("feedback", "Incorrect step")
			feedback_msg.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1.0))
			
			if analysis.has("suggestion"):
				var sugg = Label.new()
				sugg.text = "💡 Try: " + analysis.get("suggestion", "")
				sugg.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2, 1.0))
				sugg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				step_vbox.add_child(feedback_msg) # Add msg first
				step_vbox.add_child(sugg)
				continue # skip adding msg again below
		
		step_vbox.add_child(feedback_msg)
			
		steps_container.add_child(step_panel)
		
	# Correct Solution
	if validation_data.has("correct_solution") and not validation_data.correct_solution.is_empty() and not is_correct:
		correct_solution_container.visible = true
		var sol_text = ""
		var sol_steps = validation_data.correct_solution
		for i in range(sol_steps.size()):
			sol_text += str(i+1) + ". " + str(sol_steps[i]) + "\n"
		correct_label.text = sol_text
	else:
		correct_solution_container.visible = false
