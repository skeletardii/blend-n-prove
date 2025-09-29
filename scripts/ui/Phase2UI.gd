extends Control

# UI References
@onready var phase_label: Label = $WorkContainer/PhaseLabel
@onready var premise_grid: GridContainer = $WorkContainer/InventoryArea/InventoryContainer/InventoryScroll/PremiseGrid
@onready var target_expression: Label = $WorkContainer/TargetArea/TargetContainer/TargetExpression
@onready var operation_mode_label: Label = $WorkContainer/Footer/FooterContainer/OperationModeLabel
@onready var page_toggle_button: Button = $WorkContainer/Footer/FooterContainer/PageToggleButton

# Button Pages
@onready var double_operations_page: Control = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage
@onready var single_operations_page: Control = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage

# Double Operation Buttons
@onready var mp_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/MPButton
@onready var mt_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/MTButton
@onready var hs_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/HSButton
@onready var ds_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/DSButton
@onready var cd_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/CDButton
@onready var dn_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/DNButton
@onready var imp_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/IMPButton
@onready var conv_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/CONVButton
@onready var eq_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/EQButton
@onready var res_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/RESButton

# Single Operation Buttons
@onready var simp_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row1/SIMPButton
@onready var conj_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row1/CONJButton
@onready var add_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row1/ADDButton
@onready var dm_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row1/DMButton
@onready var dist_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row2/DISTButton
@onready var comm_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row2/COMMButton
@onready var assoc_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row2/ASSOCButton
@onready var idemp_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row2/IDEMPButton
@onready var abs_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row3/ABSButton
@onready var neg_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row3/NEGButton
@onready var taut_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row3/TAUTButton
@onready var contr_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row3/CONTRButton
@onready var dneg_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row3/DNEGButton
@onready var paren_remove_button: Button = $WorkContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row2/PAREN_REMOVEButton

# Game State
var available_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var selected_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var target_conclusion: String = ""
var current_page: int = 0  # 0 = single operations, 1 = double operations
var selected_rule: String = ""
var premise_cards: Array[Control] = []

# Signals for parent communication
signal rule_applied(result: BooleanLogicEngine.BooleanExpression)
signal target_reached(result: BooleanLogicEngine.BooleanExpression)
signal feedback_message(message: String, color: Color)

# Rule definitions
enum RuleType {
	SINGLE,
	DOUBLE
}

var rule_definitions = {
	# Double operations (2-input rules)
	"MP": {"type": RuleType.DOUBLE, "name": "Modus Ponens"},
	"MT": {"type": RuleType.DOUBLE, "name": "Modus Tollens"},
	"HS": {"type": RuleType.DOUBLE, "name": "Hypothetical Syllogism"},
	"DS": {"type": RuleType.DOUBLE, "name": "Disjunctive Syllogism"},
	"CD": {"type": RuleType.DOUBLE, "name": "Constructive Dilemma"},
	"DN": {"type": RuleType.DOUBLE, "name": "Destructive Dilemma"},
	"IMP": {"type": RuleType.DOUBLE, "name": "Implication"},
	"CONV": {"type": RuleType.DOUBLE, "name": "Conversion"},
	"EQ": {"type": RuleType.DOUBLE, "name": "Equivalence"},
	"RES": {"type": RuleType.DOUBLE, "name": "Resolution"},

	# Single operations (1-input rules)
	"SIMP": {"type": RuleType.SINGLE, "name": "Simplification"},
	"CONJ": {"type": RuleType.SINGLE, "name": "Conjunction"},
	"ADD": {"type": RuleType.SINGLE, "name": "Addition"},
	"DM": {"type": RuleType.SINGLE, "name": "De Morgan's Laws"},
	"DIST": {"type": RuleType.SINGLE, "name": "Distributivity"},
	"COMM": {"type": RuleType.SINGLE, "name": "Commutativity"},
	"ASSOC": {"type": RuleType.SINGLE, "name": "Associativity"},
	"IDEMP": {"type": RuleType.SINGLE, "name": "Idempotent Laws"},
	"ABS": {"type": RuleType.SINGLE, "name": "Absorption"},
	"NEG": {"type": RuleType.SINGLE, "name": "Negation Laws"},
	"TAUT": {"type": RuleType.SINGLE, "name": "Tautology"},
	"CONTR": {"type": RuleType.SINGLE, "name": "Contradiction"},
	"DNEG": {"type": RuleType.SINGLE, "name": "Double Negation"},
	"PAREN_REMOVE": {"type": RuleType.SINGLE, "name": "Remove Parentheses"}
}

func _ready() -> void:
	connect_rule_buttons()
	connect_page_toggle()
	set_page(1)  # Start with double operations

func connect_rule_buttons() -> void:
	# Double operation buttons
	mp_button.pressed.connect(_on_rule_button_pressed.bind("MP"))
	mt_button.pressed.connect(_on_rule_button_pressed.bind("MT"))
	hs_button.pressed.connect(_on_rule_button_pressed.bind("HS"))
	ds_button.pressed.connect(_on_rule_button_pressed.bind("DS"))
	cd_button.pressed.connect(_on_rule_button_pressed.bind("CD"))
	dn_button.pressed.connect(_on_rule_button_pressed.bind("DN"))
	imp_button.pressed.connect(_on_rule_button_pressed.bind("IMP"))
	conv_button.pressed.connect(_on_rule_button_pressed.bind("CONV"))
	eq_button.pressed.connect(_on_rule_button_pressed.bind("EQ"))
	res_button.pressed.connect(_on_rule_button_pressed.bind("RES"))

	# Single operation buttons
	simp_button.pressed.connect(_on_rule_button_pressed.bind("SIMP"))
	conj_button.pressed.connect(_on_rule_button_pressed.bind("CONJ"))
	add_button.pressed.connect(_on_rule_button_pressed.bind("ADD"))
	dm_button.pressed.connect(_on_rule_button_pressed.bind("DM"))
	dist_button.pressed.connect(_on_rule_button_pressed.bind("DIST"))
	comm_button.pressed.connect(_on_rule_button_pressed.bind("COMM"))
	assoc_button.pressed.connect(_on_rule_button_pressed.bind("ASSOC"))
	idemp_button.pressed.connect(_on_rule_button_pressed.bind("IDEMP"))
	abs_button.pressed.connect(_on_rule_button_pressed.bind("ABS"))
	neg_button.pressed.connect(_on_rule_button_pressed.bind("NEG"))
	taut_button.pressed.connect(_on_rule_button_pressed.bind("TAUT"))
	contr_button.pressed.connect(_on_rule_button_pressed.bind("CONTR"))
	dneg_button.pressed.connect(_on_rule_button_pressed.bind("DNEG"))
	paren_remove_button.pressed.connect(_on_rule_button_pressed.bind("PAREN_REMOVE"))

func connect_page_toggle() -> void:
	page_toggle_button.pressed.connect(_on_page_toggle_pressed)

func set_premises_and_target(premises: Array[BooleanLogicEngine.BooleanExpression], target: String) -> void:
	available_premises = premises.duplicate()
	target_conclusion = target
	target_expression.text = "Prove: " + target
	create_premise_cards()

func create_premise_cards() -> void:
	# Clear existing cards
	for card in premise_cards:
		card.queue_free()
	premise_cards.clear()

	# Create new cards
	for i in range(available_premises.size()):
		var premise = available_premises[i]
		var card = create_premise_card(premise, i)
		premise_grid.add_child(card)
		premise_cards.append(card)

func create_premise_card(premise: BooleanLogicEngine.BooleanExpression, index: int) -> Control:
	var card = Button.new()
	card.text = str(index + 1) + ". " + premise.expression_string
	card.custom_minimum_size = Vector2(200, 60)
	card.toggle_mode = true
	card.pressed.connect(_on_premise_card_pressed.bind(premise, card))
	return card

func _on_premise_card_pressed(premise: BooleanLogicEngine.BooleanExpression, card: Button) -> void:
	# Only allow premise selection if a rule is selected
	if selected_rule.is_empty():
		card.button_pressed = false  # Reset button state
		feedback_message.emit("Please select an operation first", Color.ORANGE)
		return

	if card.button_pressed:
		# Select premise
		if premise not in selected_premises:
			selected_premises.append(premise)
			card.modulate = Color.CYAN
	else:
		# Deselect premise
		if premise in selected_premises:
			selected_premises.erase(premise)
			card.modulate = Color.WHITE

	# Check if we can apply the selected rule
	check_rule_application()

func _on_rule_button_pressed(rule: String) -> void:
	# If clicking the same rule that's already selected, deselect everything
	if selected_rule == rule:
		clear_selections()
		feedback_message.emit("Operation deselected", Color.WHITE)
		return

	# Clear previous rule selection
	clear_rule_selection()

	selected_rule = rule
	var rule_def = rule_definitions[rule]

	feedback_message.emit("Selected " + rule_def.name + ". Select " +
						  ("1 premise" if rule_def.type == RuleType.SINGLE else "2 premises") +
						  " to apply this rule.", Color.YELLOW)

	# Highlight the selected button
	highlight_rule_button(rule)

	# Start jiggle animation
	start_button_jiggle(rule)

func check_rule_application() -> void:
	if selected_rule.is_empty():
		return

	var rule_def = rule_definitions[selected_rule]
	var required_count = 1 if rule_def.type == RuleType.SINGLE else 2

	if selected_premises.size() == required_count:
		apply_rule()

func apply_rule() -> void:
	if selected_rule.is_empty() or selected_premises.is_empty():
		return

	var rule_def = rule_definitions[selected_rule]

	# Apply the rule (simplified - you'll need to implement actual logic)
	var result = apply_logical_rule(selected_rule, selected_premises)

	if result != null and result.is_valid:
		# Add result to inventory
		available_premises.append(result)
		create_premise_cards()

		# Clear selections
		clear_selections()

		feedback_message.emit("✓ Applied " + rule_def.name + ": " + result.expression_string, Color.GREEN)
		rule_applied.emit(result)

		# Check if target is reached
		if result.expression_string.strip_edges() == target_conclusion.strip_edges():
			feedback_message.emit("✓ Target reached! Proof complete!", Color.CYAN)
			target_reached.emit(result)
	else:
		# Clear selections when rule fails
		clear_selections()
		feedback_message.emit(rule_def.name + " cannot be applied to selected premises", Color.RED)

func apply_logical_rule(rule: String, premises: Array[BooleanLogicEngine.BooleanExpression]) -> BooleanLogicEngine.BooleanExpression:
	# Use actual BooleanLogicEngine functions to apply logical rules
	match rule:
		# Double operation rules (require 2 premises)
		"MP":  # Modus Ponens: P→Q, P ⊢ Q
			return BooleanLogicEngine.apply_modus_ponens(premises)
		"MT":  # Modus Tollens: P→Q, ¬Q ⊢ ¬P
			return BooleanLogicEngine.apply_modus_tollens(premises)
		"HS":  # Hypothetical Syllogism: P→Q, Q→R ⊢ P→R
			return BooleanLogicEngine.apply_hypothetical_syllogism(premises)
		"DS":  # Disjunctive Syllogism: P∨Q, ¬P ⊢ Q
			return BooleanLogicEngine.apply_disjunctive_syllogism(premises)
		"CD":  # Constructive Dilemma
			return BooleanLogicEngine.apply_constructive_dilemma(premises)
		"DN":  # Destructive Dilemma
			return BooleanLogicEngine.apply_destructive_dilemma(premises)
		"CONJ":  # Conjunction: P, Q ⊢ P∧Q
			return BooleanLogicEngine.apply_conjunction(premises)

		# Single operation rules (require 1 premise)
		"SIMP":  # Simplification: P∧Q ⊢ P
			return BooleanLogicEngine.apply_simplification(premises)
		"DM":  # De Morgan's Laws
			if premises.size() == 1:
				var premise = premises[0]
				if premise.is_conjunction():
					return BooleanLogicEngine.apply_de_morgan_and(premise)
				elif premise.is_disjunction():
					return BooleanLogicEngine.apply_de_morgan_or(premise)
			return BooleanLogicEngine.BooleanExpression.new("")
		"DOUBLE_NEG":  # Double Negation: ¬¬P ⊢ P
			if premises.size() == 1:
				return BooleanLogicEngine.apply_double_negation(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")

		# Biconditional rules
		"IMP":  # Biconditional to Implications: P↔Q ⊢ (P→Q)∧(Q→P)
			if premises.size() == 1:
				return BooleanLogicEngine.apply_biconditional_to_implications(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")
		"CONV":  # Biconditional to Equivalence: P↔Q ⊢ (P∧Q)∨(¬P∧¬Q)
			if premises.size() == 1:
				return BooleanLogicEngine.apply_biconditional_to_equivalence(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")

		# XOR rules
		"XOR_ELIM":  # XOR Elimination: P⊕Q ⊢ (P∨Q)∧¬(P∧Q)
			if premises.size() == 1:
				return BooleanLogicEngine.apply_xor_elimination(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")

		# New double operation rules
		"EQ":  # Equivalence: P↔Q, P ⊢ Q (or similar equivalence rule)
			if premises.size() == 2:
				return BooleanLogicEngine.apply_equivalence(premises)
			return BooleanLogicEngine.BooleanExpression.new("")
		"RES":  # Resolution: P∨Q, ¬P∨R ⊢ Q∨R
			if premises.size() == 2:
				return BooleanLogicEngine.apply_resolution(premises)
			return BooleanLogicEngine.BooleanExpression.new("")

		# Double negation (moved to single operations section)
		"DNEG":  # Double Negation: ¬¬P ⊢ P
			if premises.size() == 1:
				return BooleanLogicEngine.apply_double_negation(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")

		# Single operation rules - now fully implemented
		"DIST":  # Distributivity Laws: A∧(B∨C) ≡ (A∧B)∨(A∧C)
			if premises.size() == 1:
				return BooleanLogicEngine.apply_distributivity(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")
		"COMM":  # Commutativity Laws: A∧B ≡ B∧A
			if premises.size() == 1:
				return BooleanLogicEngine.apply_commutativity(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")
		"ASSOC":  # Associativity Laws: (A∧B)∧C ≡ A∧(B∧C)
			if premises.size() == 1:
				return BooleanLogicEngine.apply_associativity(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")
		"IDEMP":  # Idempotent Laws: A∧A ≡ A
			if premises.size() == 1:
				return BooleanLogicEngine.apply_idempotent(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")
		"ABS":  # Absorption Laws: A∧(A∨B) ≡ A
			if premises.size() == 1:
				return BooleanLogicEngine.apply_absorption(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")
		"NEG":  # Negation Laws: A∧¬A ≡ FALSE
			if premises.size() == 1:
				return BooleanLogicEngine.apply_negation_laws(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")
		"TAUT":  # Tautology Laws: A∨TRUE ≡ TRUE
			if premises.size() == 1:
				return BooleanLogicEngine.apply_tautology_laws(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")
		"CONTR":  # Contradiction Laws: A∧FALSE ≡ FALSE
			if premises.size() == 1:
				return BooleanLogicEngine.apply_contradiction_laws(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")
		"PAREN_REMOVE":  # Remove Parentheses: (P) ≡ P
			if premises.size() == 1:
				return BooleanLogicEngine.apply_parenthesis_removal(premises[0])
			return BooleanLogicEngine.BooleanExpression.new("")

		# Other single operation rules (special cases)
		"ADD":  # Addition: P ⊢ P∨Q (needs additional expression)
			# For ADD rule, we need to ask user for the additional expression
			# For now, return empty to indicate this rule needs special handling
			return BooleanLogicEngine.BooleanExpression.new("")
		_:
			return BooleanLogicEngine.BooleanExpression.new("")

func clear_selections() -> void:
	selected_premises.clear()
	selected_rule = ""

	# Reset card colors
	for card in premise_cards:
		var button = card as Button
		if button:
			button.button_pressed = false
			button.modulate = Color.WHITE

	# Clear rule button highlights
	clear_rule_selection()

func clear_rule_selection() -> void:
	# Reset all rule button colors
	for button in get_all_rule_buttons():
		button.modulate = Color.WHITE
		stop_button_jiggle(button)

func get_all_rule_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	# Add all rule buttons
	buttons.append_array([mp_button, mt_button, hs_button, ds_button, cd_button, dn_button, imp_button, conv_button, eq_button, res_button])
	buttons.append_array([simp_button, conj_button, add_button, dm_button, dist_button, comm_button, assoc_button, idemp_button])
	buttons.append_array([abs_button, neg_button, taut_button, contr_button, dneg_button, paren_remove_button])
	return buttons

func highlight_rule_button(rule: String) -> void:
	var button = get_rule_button(rule)
	if button:
		button.modulate = Color.YELLOW

func get_rule_button(rule: String) -> Button:
	match rule:
		"MP": return mp_button
		"MT": return mt_button
		"HS": return hs_button
		"DS": return ds_button
		"CD": return cd_button
		"DN": return dn_button
		"IMP": return imp_button
		"CONV": return conv_button
		"EQ": return eq_button
		"RES": return res_button
		"SIMP": return simp_button
		"CONJ": return conj_button
		"ADD": return add_button
		"DM": return dm_button
		"DIST": return dist_button
		"COMM": return comm_button
		"ASSOC": return assoc_button
		"IDEMP": return idemp_button
		"ABS": return abs_button
		"NEG": return neg_button
		"TAUT": return taut_button
		"CONTR": return contr_button
		"DNEG": return dneg_button
		"PAREN_REMOVE": return paren_remove_button
		_: return null

func start_button_jiggle(rule: String) -> void:
	var button = get_rule_button(rule)
	if button:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(button, "rotation", 0.1, 0.1)
		tween.tween_property(button, "rotation", -0.1, 0.1)
		tween.tween_property(button, "rotation", 0.0, 0.1)
		tween.tween_interval(0.3)

func stop_button_jiggle(button: Button) -> void:
	# Stop any running tweens on this button
	var tweens = get_tree().get_processed_tweens()
	for tween in tweens:
		if tween.is_valid():
			tween.kill()
	button.rotation = 0.0

func _on_page_toggle_pressed() -> void:
	current_page = 1 - current_page  # Toggle between 0 and 1
	set_page(current_page)

func set_page(page: int) -> void:
	current_page = page

	if page == 0:  # Single operations
		single_operations_page.visible = true
		double_operations_page.visible = false
		operation_mode_label.text = "Single Operations"
		page_toggle_button.text = "→"
	else:  # Double operations
		single_operations_page.visible = false
		double_operations_page.visible = true
		operation_mode_label.text = "Double Operations"
		page_toggle_button.text = "←"

func add_premise_to_inventory(premise: BooleanLogicEngine.BooleanExpression) -> void:
	available_premises.append(premise)
	create_premise_cards()
