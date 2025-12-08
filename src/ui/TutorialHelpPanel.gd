extends Panel

const TutorialDataTypes = preload("res://src/managers/TutorialDataTypes.gd")

signal help_panel_closed()

# UI References
@onready var rule_title: Label = $MarginContainer/VBoxContainer/RuleTitleContainer/RuleTitle
@onready var rule_description: RichTextLabel = $MarginContainer/VBoxContainer/RuleDescriptionPanel/RuleDescription
@onready var problem_hint: RichTextLabel = $MarginContainer/VBoxContainer/ProblemHintPanel/ProblemHint
@onready var close_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/CloseButton
@onready var problem_number_label: Label = $MarginContainer/VBoxContainer/ProblemNumberLabel

# Tutorial data
var current_tutorial_key: String = ""
var current_problem_index: int = 0

func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
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

	# Format rule description with pattern
	rule_description.bbcode_enabled = true
	rule_description.text = "[b]Description:[/b]\n" + tutorial.description + \
		"\n\n[color=cyan][b]Pattern:[/b] " + tutorial.rule_pattern + "[/color]"

	# Get problem-specific hint
	if problem_index >= 0 and problem_index < tutorial.problems.size():
		var problem: TutorialDataTypes.ProblemData = tutorial.problems[problem_index]
		problem_number_label.text = "Problem " + str(problem.problem_number) + "/10 (" + problem.difficulty + ")"

		problem_hint.bbcode_enabled = true
		problem_hint.text = "[color=yellow][b]Hint for this problem:[/b][/color]\n" + problem.solution
	else:
		problem_number_label.text = "Tutorial Overview"
		problem_hint.bbcode_enabled = true
		problem_hint.text = "[i]No specific hint available.[/i]"

	show()

func _on_close_button_pressed() -> void:
	hide()
	help_panel_closed.emit()

func toggle_visibility() -> void:
	visible = !visible
