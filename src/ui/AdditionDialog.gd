extends Control

# Explicit preload to ensure BooleanExpression type is available
const BooleanExpression = preload("res://src/game/expressions/BooleanExpression.gd")

# Signals
signal expression_confirmed(expression_text: String)
signal dialog_cancelled()

# UI References
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var rule_label: Label = $Panel/MarginContainer/VBoxContainer/RuleLabel
@onready var premise_label: Label = $Panel/MarginContainer/VBoxContainer/PremiseLabel
@onready var instruction_label: Label = $Panel/MarginContainer/VBoxContainer/InstructionLabel
@onready var input_display: Label = $Panel/MarginContainer/VBoxContainer/InputDisplay
@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CancelButton
@onready var apply_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/ApplyButton

# Virtual Keyboard Button References - Updated for new layout
@onready var var_p: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row1/VarP
@onready var var_q: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row1/VarQ
@onready var var_r: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row1/VarR
@onready var var_s: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row1/VarS
@onready var var_t: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row1/VarT

@onready var and_button: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row2/AndButton
@onready var or_button: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row2/OrButton
@onready var implies_button: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row2/ImpliesButton
@onready var not_button: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row2/NotButton

@onready var open_paren_button: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row3/OpenParenButton
@onready var close_paren_button: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row3/CloseParenButton
@onready var xor_button: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row3/XorButton
@onready var biconditional_button: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row3/BiconditionalButton

@onready var backspace_button: Button = $Panel/MarginContainer/VBoxContainer/VirtualKeyboard/Row4/BackspaceButton

# Input state
var current_input: String = ""

func _ready() -> void:
	# Connect button signals
	cancel_button.pressed.connect(_on_cancel_pressed)
	apply_button.pressed.connect(_on_apply_pressed)

	# Connect virtual keyboard
	connect_virtual_keyboard()

	# Start hidden
	hide()

func connect_virtual_keyboard() -> void:
	# Variable buttons
	var_p.pressed.connect(_on_symbol_pressed.bind("P"))
	var_q.pressed.connect(_on_symbol_pressed.bind("Q"))
	var_r.pressed.connect(_on_symbol_pressed.bind("R"))
	var_s.pressed.connect(_on_symbol_pressed.bind("S"))
	var_t.pressed.connect(_on_symbol_pressed.bind("T"))

	# Operator buttons
	and_button.pressed.connect(_on_symbol_pressed.bind("∧"))
	or_button.pressed.connect(_on_symbol_pressed.bind("∨"))
	implies_button.pressed.connect(_on_symbol_pressed.bind("→"))
	not_button.pressed.connect(_on_symbol_pressed.bind("¬"))
	
	# Advanced operators and parens
	open_paren_button.pressed.connect(_on_symbol_pressed.bind("("))
	close_paren_button.pressed.connect(_on_symbol_pressed.bind(")"))
	xor_button.pressed.connect(_on_symbol_pressed.bind("⊕"))
	biconditional_button.pressed.connect(_on_symbol_pressed.bind("↔"))

	# Backspace
	backspace_button.pressed.connect(_on_backspace_pressed)

func _on_symbol_pressed(symbol: String) -> void:
	# Auto-add spaces around binary operators
	if symbol in ["∧", "∨", "⊕", "↔", "→"]:
		current_input += " " + symbol + " "
	else:
		current_input += symbol

	update_input_display()

func _on_backspace_pressed() -> void:
	if current_input.length() > 0:
		current_input = current_input.substr(0, current_input.length() - 1)

		# Remove trailing spaces after backspace
		while current_input.ends_with(" "):
			current_input = current_input.substr(0, current_input.length() - 1)

		update_input_display()

func update_input_display() -> void:
	# Update the display label with current input
	if current_input.is_empty():
		input_display.text = ""
	else:
		input_display.text = current_input

func show_dialog(premise: BooleanExpression) -> void:
	# Update premise label to show what was selected
	if premise and premise.is_valid:
		premise_label.text = "Selected premise: " + premise.expression_string
	else:
		premise_label.text = "Selected premise: (invalid)"

	# Clear previous input
	current_input = ""
	update_input_display()

	# Show dialog
	show()

func _on_apply_pressed() -> void:
	var input_text = current_input.strip_edges()

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
