extends Panel

const TutorialDataTypes = preload("res://src/managers/TutorialDataTypes.gd")

signal help_panel_closed()

# UI References
@onready var rule_title_button: Button = $MarginContainer/VBoxContainer/RuleTitleContainer
@onready var rule_title: Label = $MarginContainer/VBoxContainer/RuleTitleContainer/RuleTitle
@onready var rule_description: RichTextLabel = $MarginContainer/VBoxContainer/RuleDescriptionPanel/RuleDescription
@onready var problem_hint: RichTextLabel = $MarginContainer/VBoxContainer/ProblemHintPanel/ProblemHint
@onready var close_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/CloseButton
@onready var problem_number_label: Label = $MarginContainer/VBoxContainer/ProblemNumberLabel

# Tutorial data
var current_tutorial_key: String = ""
var current_problem_index: int = 0

# Blur overlay
var blur_overlay: ColorRect = null

func _ready() -> void:
	close_button.pressed.connect(toggle_visibility)
	hide()

func show_tutorial_help(tutorial_key: String, problem_index: int) -> void:
	current_tutorial_key = tutorial_key
	current_problem_index = problem_index

	# Get tutorial data
	var tutorial: TutorialDataTypes.TutorialData = TutorialDataManager.get_tutorial_by_name(tutorial_key)

	if not tutorial:
		push_error("Tutorial not found: " + tutorial_key)
		return

	# Update rule information
	rule_title.text = tutorial.rule_name

	# Format rule description with pattern (using black text for contrast on white background)
	rule_description.bbcode_enabled = true
	rule_description.text = "[b]Description:[/b]\n" + tutorial.description + \
		"\n\n[color=blue][b]Pattern:[/b] " + tutorial.rule_pattern + "[/color]"

	# Get problem-specific hint
	if problem_index >= 0 and problem_index < tutorial.problems.size():
		var problem: TutorialDataTypes.ProblemData = tutorial.problems[problem_index]
		problem_number_label.text = "Problem " + str(problem.problem_number) + "/10 (" + problem.difficulty + ")"

		problem_hint.bbcode_enabled = true
		problem_hint.text = "[color=green][b]Hint for this problem:[/b][/color]\n" + problem.solution
	else:
		problem_number_label.text = "Tutorial Overview"
		problem_hint.bbcode_enabled = true
		problem_hint.text = "[i]No specific hint available.[/i]"

	_create_blur_overlay()
	show()



func toggle_visibility() -> void:
	if visible:
		_remove_blur_overlay()
	else:
		_create_blur_overlay()
	visible = !visible

func _create_blur_overlay() -> void:
	# Create semi-transparent overlay behind the popup
	if blur_overlay == null:
		blur_overlay = ColorRect.new()
		blur_overlay.color = Color(0.05, 0.08, 0.15, 0.7)  # Semi-transparent dark blue for better aesthetics
		# Removed z_index assignment to rely on tree order (moved before panel below)

		# Make it fullscreen
		blur_overlay.anchor_left = 0.0
		blur_overlay.anchor_top = 0.0
		blur_overlay.anchor_right = 1.0
		blur_overlay.anchor_bottom = 1.0

		get_parent().add_child(blur_overlay)
		get_parent().move_child(blur_overlay, get_index())  # Place just before this panel

func _remove_blur_overlay() -> void:
	if blur_overlay != null:
		blur_overlay.queue_free()
		blur_overlay = null
