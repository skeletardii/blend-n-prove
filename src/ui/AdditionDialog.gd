extends Panel

# Signals
signal expression_confirmed(expression_text: String)
signal dialog_cancelled()

# UI References
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var rule_label: Label = $MarginContainer/VBoxContainer/RuleLabel
@onready var premise_label: Label = $MarginContainer/VBoxContainer/PremiseLabel
@onready var instruction_label: Label = $MarginContainer/VBoxContainer/InstructionLabel
@onready var expression_input: LineEdit = $MarginContainer/VBoxContainer/ExpressionInput
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/CancelButton
@onready var apply_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/ApplyButton

func _ready() -> void:
	# Connect button signals
	cancel_button.pressed.connect(_on_cancel_pressed)
	apply_button.pressed.connect(_on_apply_pressed)

	# Connect Enter key to apply
	expression_input.text_submitted.connect(_on_text_submitted)

	# Start hidden
	hide()

func show_dialog(premise: BooleanLogicEngine.BooleanExpression) -> void:
	# Update premise label to show what was selected
	if premise and premise.is_valid:
		premise_label.text = "Selected premise: " + premise.expression_string
	else:
		premise_label.text = "Selected premise: (invalid)"

	# Clear previous input
	expression_input.text = ""

	# Show dialog and focus input
	show()
	expression_input.grab_focus()

func _on_apply_pressed() -> void:
	var input_text = expression_input.text.strip_edges()

	# Validate that input is not empty
	if input_text.is_empty():
		# Could add visual feedback here (shake animation, red border, etc.)
		return

	# Emit confirmation signal with the input
	expression_confirmed.emit(input_text)
	hide()

func _on_cancel_pressed() -> void:
	hide()
	dialog_cancelled.emit()

func _on_text_submitted(text: String) -> void:
	# When user presses Enter, treat it like clicking Apply
	_on_apply_pressed()
