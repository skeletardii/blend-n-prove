extends Control

# UI References
@onready var work_container: VBoxContainer = $WorkContainer
@onready var phase_label: Label = $WorkContainer/PhaseLabel
@onready var premise_grid: GridContainer = $WorkContainer/InventoryArea/InventoryContainer/InventoryScroll/PremiseGrid
@onready var target_expression: Label = $WorkContainer/TargetArea/TargetContainer/TargetExpression
@onready var rules_overlay: Panel = $RulesOverlay
@onready var toggle_rules_button: Button = $RulesOverlay/ToggleRulesButton
@onready var operation_mode_label: Label = $RulesOverlay/OverlayContainer/Footer/FooterContainer/OperationModeLabel
@onready var page_toggle_button: Button = $RulesOverlay/OverlayContainer/Footer/FooterContainer/PageToggleButton
@onready var addition_dialog: Panel = $AdditionDialog

# Button Pages
@onready var double_operations_page: Control = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage
@onready var single_operations_page: Control = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage

# Double Operation Buttons
@onready var mp_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/MPButton
@onready var mt_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/MTButton
@onready var hs_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/HSButton
@onready var ds_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/DSButton
@onready var cd_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/CDButton
@onready var dn_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/DNButton
@onready var conj_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/CONJButton
@onready var eq_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/EQButton
@onready var res_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/DoubleOperationsPage/DoubleOpsGrid/RESButton

# Single Operation Buttons
@onready var simp_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row1/SIMPButton
@onready var imp_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row1/IMPButton
@onready var conv_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row1/CONVButton
@onready var add_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row2/ADDButton
@onready var dm_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row2/DMButton
@onready var dneg_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row2/DNEGButton
@onready var dist_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row3/DISTButton
@onready var comm_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row3/COMMButton
@onready var assoc_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row3/ASSOCButton
@onready var idemp_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row4/IDEMPButton
@onready var abs_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row4/ABSButton
@onready var paren_remove_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row4/PAREN_REMOVEButton
@onready var neg_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row5/NEGButton
@onready var taut_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row5/TAUTButton
@onready var contr_button: Button = $RulesOverlay/OverlayContainer/RuleButtonsArea/RuleButtonsContainer/ButtonPages/SingleOperationsPage/SingleOpsContainer/Row5/CONTRButton

# Game State
var available_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var selected_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var target_conclusion: String = ""
var current_page: int = 0  # 0 = single operations, 1 = double operations
var selected_rule: String = ""
var premise_cards: Array[Control] = []

# Animation State
var rules_panel_height: float = 450.0
var rules_button_height: float = 50.0
var is_animating: bool = false

# Signals for parent communication
signal rule_applied(result: BooleanLogicEngine.BooleanExpression)
signal target_reached(result: BooleanLogicEngine.BooleanExpression)
signal feedback_message(message: String, color: Color)
signal premise_selected(premise: String)  # For tutorial detection

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
	"CONJ": {"type": RuleType.DOUBLE, "name": "Conjunction"},
	"EQ": {"type": RuleType.DOUBLE, "name": "Equivalence"},
	"RES": {"type": RuleType.DOUBLE, "name": "Resolution"},

	# Single operations (1-input rules)
	"SIMP": {"type": RuleType.SINGLE, "name": "Simplification"},
	"IMP": {"type": RuleType.SINGLE, "name": "Implication"},
	"CONV": {"type": RuleType.SINGLE, "name": "Conversion"},
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

func setup_dynamic_spacing() -> void:
	"""Set dynamic spacing between UI modules based on viewport height"""
	var viewport_height: float = get_viewport_rect().size.y

	# Calculate spacing as a percentage of viewport height
	# For 1280px height, use 10px spacing (0.78%)
	var dynamic_spacing: int = max(5, int(viewport_height * 0.0078))

	# Apply to work container
	if work_container:
		work_container.add_theme_constant_override("separation", dynamic_spacing)

func _ready() -> void:
	setup_dynamic_spacing()
	connect_rule_buttons()
	connect_page_toggle()
	connect_addition_dialog()
	connect_toggle_rules_button()
	set_page(1)  # Start with double operations

	# Initialize panel position (hidden - only button visible)
	rules_overlay.visible = true
	# Panel is anchored to bottom, so we use negative offset_top
	# Hidden state: only button visible
	rules_overlay.offset_top = -rules_button_height
	rules_overlay.offset_bottom = rules_panel_height - rules_button_height

func connect_rule_buttons() -> void:
	# Double operation buttons
	mp_button.pressed.connect(_on_rule_button_pressed.bind("MP"))
	mt_button.pressed.connect(_on_rule_button_pressed.bind("MT"))
	hs_button.pressed.connect(_on_rule_button_pressed.bind("HS"))
	ds_button.pressed.connect(_on_rule_button_pressed.bind("DS"))
	cd_button.pressed.connect(_on_rule_button_pressed.bind("CD"))
	dn_button.pressed.connect(_on_rule_button_pressed.bind("DN"))
	conj_button.pressed.connect(_on_rule_button_pressed.bind("CONJ"))
	eq_button.pressed.connect(_on_rule_button_pressed.bind("EQ"))
	res_button.pressed.connect(_on_rule_button_pressed.bind("RES"))

	# Single operation buttons
	simp_button.pressed.connect(_on_rule_button_pressed.bind("SIMP"))
	imp_button.pressed.connect(_on_rule_button_pressed.bind("IMP"))
	conv_button.pressed.connect(_on_rule_button_pressed.bind("CONV"))
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

func connect_addition_dialog() -> void:
	addition_dialog.expression_confirmed.connect(_on_addition_dialog_confirmed)
	addition_dialog.dialog_cancelled.connect(_on_addition_dialog_cancelled)

func connect_toggle_rules_button() -> void:
	toggle_rules_button.pressed.connect(_on_toggle_rules_button_pressed)

func _on_toggle_rules_button_pressed() -> void:
	toggle_rules_overlay()

func toggle_rules_overlay() -> void:
	if is_animating:
		return  # Don't allow toggling while animating

	# Check current state based on position (with tolerance)
	var is_hidden: bool = abs(rules_overlay.offset_top + rules_button_height) < 10.0

	if is_hidden:
		open_rules_overlay()
	else:
		close_rules_overlay()

func close_rules_overlay() -> void:
	if is_animating:
		return

	is_animating = true
	toggle_rules_button.text = "▲ Show Rules ▲"

	# Animate panel sliding down (hide - only button visible)
	# offset_top: -50 (50px above bottom of screen)
	# offset_bottom: 400 (extends 400px below screen, so only top 50px visible)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(rules_overlay, "offset_top", -rules_button_height, 0.3)
	tween.tween_property(rules_overlay, "offset_bottom", rules_panel_height - rules_button_height, 0.3)
	tween.finished.connect(_on_close_animation_finished)

func open_rules_overlay() -> void:
	if is_animating:
		return

	is_animating = true
	toggle_rules_button.text = "▼ Hide Rules ▼"

	# Animate panel sliding up (show full panel)
	# offset_top: -450 (450px above bottom of screen)
	# offset_bottom: 0 (bottom edge at screen bottom)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(rules_overlay, "offset_top", -rules_panel_height, 0.3)
	tween.tween_property(rules_overlay, "offset_bottom", 0.0, 0.3)
	tween.finished.connect(_on_open_animation_finished)

func _on_close_animation_finished() -> void:
	is_animating = false

func _on_open_animation_finished() -> void:
	is_animating = false

func set_premises_and_target(premises: Array[BooleanLogicEngine.BooleanExpression], target: String) -> void:
	# Clean all premises before adding to inventory
	available_premises.clear()
	for premise in premises:
		var cleaned = clean_expression(premise)
		available_premises.append(cleaned)

	target_conclusion = target
	target_expression.text = "Prove: " + target
	create_premise_cards()

# Extended version for Level 6 natural language problems
func set_premises_and_target_with_display(
	premises: Array[BooleanLogicEngine.BooleanExpression],
	logical_target: String,
	display_target: String
) -> void:
	# Clean all premises before adding to inventory
	available_premises.clear()
	for premise in premises:
		var cleaned = clean_expression(premise)
		available_premises.append(cleaned)

	target_conclusion = logical_target  # Validate against this
	target_expression.text = "Prove: " + display_target  # Display this to player
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
		open_rules_overlay()  # Open rules if not selected
		return

	if card.button_pressed:
		# Select premise
		if premise not in selected_premises:
			selected_premises.append(premise)
			card.modulate = Color.CYAN
			# Emit signal for tutorial detection
			premise_selected.emit(premise.expression_string)
	else:
		# Deselect premise
		if premise in selected_premises:
			selected_premises.erase(premise)
			card.modulate = Color.WHITE

	# Check if we can apply the selected rule
	check_rule_application()

func _on_rule_button_pressed(rule: String) -> void:
	# Special handling for Addition rule - needs user input
	if rule == "ADD":
		if selected_premises.size() != 1:
			feedback_message.emit("Select exactly 1 premise for Addition", Color.ORANGE)
			return
		# Show dialog for user to input the expression to add
		addition_dialog.show_dialog(selected_premises[0])
		return

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

	# Close the rules overlay after selecting a rule
	close_rules_overlay()

func check_rule_application() -> void:
	if selected_rule.is_empty():
		return

	var rule_def = rule_definitions[selected_rule]
	var required_count = 1 if rule_def.type == RuleType.SINGLE else 2

	if selected_premises.size() == required_count:
		apply_rule()

func clean_expression(expr: BooleanLogicEngine.BooleanExpression) -> BooleanLogicEngine.BooleanExpression:
	# DON'T auto-clean! Preserve structure so users can see what they built
	# Users can explicitly use PAREN_REMOVE button if they want to clean up
	# This preserves expressions like (P ∧ Q) instead of converting to P ∧ Q
	return expr

	# OLD AUTO-CLEAN CODE (disabled to preserve structure):
	# var cleaned = BooleanLogicEngine.apply_parenthesis_removal(expr)
	# if cleaned.is_valid:
	#	return cleaned
	# return expr

func apply_rule() -> void:
	if selected_rule.is_empty() or selected_premises.is_empty():
		return

	var rule_def = rule_definitions[selected_rule]

	# Check if this is a multi-result operation
	var multi_results = apply_logical_rule_multi(selected_rule, selected_premises)

	if multi_results != null and multi_results.size() > 1:
		# Multi-result operation - add valid results to inventory (after cleaning)
		var added_results: Array = []
		for result in multi_results:
			if result.is_valid:
				var cleaned_result = clean_expression(result)
				available_premises.append(cleaned_result)
				added_results.append(cleaned_result)

		# Only proceed if at least one result was added
		if added_results.size() > 0:
			create_premise_cards()
			ProgressTracker.record_operation_used(rule_def.name, true)
			clear_selections()

			feedback_message.emit("✓ Applied " + rule_def.name + ": Added " + str(added_results.size()) + " result" + ("s" if added_results.size() > 1 else ""), Color.GREEN)

			# Emit signal for each valid result
			for cleaned_result in added_results:
				rule_applied.emit(cleaned_result)
				# Check if any result is the target
				if cleaned_result.expression_string.strip_edges() == target_conclusion.strip_edges():
					feedback_message.emit("✓ Target reached! Proof complete!", Color.CYAN)
					# Find the card that matches the result and animate it
					animate_target_reached(cleaned_result)
					# Emit signal after animation delay
					get_tree().create_timer(1.0).timeout.connect(func(): target_reached.emit(cleaned_result))
		else:
			# No valid results - show error
			clear_selections()
			feedback_message.emit(rule_def.name + " produced no valid results", Color.RED)
			open_rules_overlay()  # Reopen rules on failure
		return

	# Single-result operation (original behavior)
	var result = apply_logical_rule(selected_rule, selected_premises)

	if result != null and result.is_valid:
		# Clean the result before adding to inventory
		var cleaned_result = clean_expression(result)

		# Add result to inventory
		available_premises.append(cleaned_result)
		create_premise_cards()

		# Track successful operation usage
		ProgressTracker.record_operation_used(rule_def.name, true)

		# Clear selections
		clear_selections()

		feedback_message.emit("✓ Applied " + rule_def.name + ": " + cleaned_result.expression_string, Color.GREEN)
		rule_applied.emit(cleaned_result)

		# Check if target is reached
		if cleaned_result.expression_string.strip_edges() == target_conclusion.strip_edges():
			feedback_message.emit("✓ Target reached! Proof complete!", Color.CYAN)
			# Find the card that matches the result and animate it
			animate_target_reached(cleaned_result)
			# Emit signal after animation delay
			get_tree().create_timer(1.0).timeout.connect(func(): target_reached.emit(cleaned_result))
	else:
		# Clear selections when rule fails
		clear_selections()
		feedback_message.emit(rule_def.name + " cannot be applied to selected premises", Color.RED)
		open_rules_overlay()  # Reopen rules on failure

func apply_logical_rule_multi(rule: String, premises: Array[BooleanLogicEngine.BooleanExpression]) -> Array:
	# Returns an array of results for operations that can produce multiple statements
	# Returns empty array if this is not a multi-result operation
	match rule:
		"SIMP":  # Simplification: P∧Q ⊢ P and Q (both)
			if premises.size() == 1:
				var results = BooleanLogicEngine.apply_simplification_both(premises)
				if results.size() == 2:
					return results
			return []
		"IMP":  # Biconditional to Implications: P↔Q ⊢ [P→Q, Q→P] (both)
			if premises.size() == 1:
				var results = BooleanLogicEngine.apply_biconditional_to_implications_both(premises[0])
				if results.size() == 2:
					return results
			return []
		"CONV":  # Biconditional to Equivalence: P↔Q ⊢ [P∧Q, ¬P∧¬Q] (both)
			if premises.size() == 1:
				var results = BooleanLogicEngine.apply_biconditional_to_equivalence_both(premises[0])
				if results.size() == 2:
					return results
			return []
		_:
			# Not a multi-result operation
			return []

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

func animate_target_reached(result: BooleanLogicEngine.BooleanExpression) -> void:
	"""Animate the newly created winning card flying into the target box with a flash effect"""
	# Find the LAST (most recently added) card that matches the result
	# This ensures we animate the newly created ingredient, not an old one
	var winning_card: Control = null
	for i in range(premise_cards.size() - 1, -1, -1):  # Search backwards
		var card = premise_cards[i]
		var button = card as Button
		if button and button.text.contains(result.expression_string):
			winning_card = card
			break

	if not winning_card:
		return

	# Create a duplicate card for animation
	var animated_card = Button.new()
	animated_card.text = winning_card.text
	animated_card.custom_minimum_size = winning_card.custom_minimum_size
	animated_card.modulate = Color.GOLD
	animated_card.z_index = 100
	add_child(animated_card)

	# Get start and end positions
	var start_pos: Vector2 = winning_card.global_position
	var end_pos: Vector2 = target_expression.global_position + target_expression.size / 2

	# Set initial position
	animated_card.global_position = start_pos

	# Create randomized curved path for variety
	var mid_pos: Vector2 = (start_pos + end_pos) / 2
	# Randomize arc height between 100-200px
	var arc_height: float = randf_range(100.0, 200.0)
	mid_pos.y -= arc_height
	# Randomize horizontal offset for more natural curves
	var horizontal_offset: float = randf_range(-50.0, 50.0)
	mid_pos.x += horizontal_offset

	# Consistent animation duration for all cards (same speed)
	var duration = 0.8

	# Animate the card along a curved path
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# Animate position using a custom bezier curve
	for i in range(0, 101, 5):  # 0 to 100 in steps of 5
		var t = i / 100.0
		# Quadratic bezier curve
		var pos = start_pos.lerp(mid_pos, t).lerp(mid_pos.lerp(end_pos, t), t)
		tween.tween_property(animated_card, "global_position", pos, duration / 20.0)

	# Scale down as it flies
	tween.parallel().tween_property(animated_card, "scale", Vector2(0.3, 0.3), duration)

	# When animation completes, create flash at the card's final position and clean up
	tween.finished.connect(func():
		# Flash spawns where the card disappears (at end_pos)
		create_target_flash(animated_card.global_position + animated_card.size / 2)
		animated_card.queue_free()
		# Play success sound
		AudioManager.play_logic_success()
	)

	# Hide the original card
	winning_card.modulate = Color(1, 1, 1, 0)

func create_target_flash(position: Vector2) -> void:
	"""Create a satisfying circular flash effect where the ingredient disappears"""
	# Create outer golden ring flash
	var flash = ColorRect.new()
	flash.color = Color(1.0, 0.9, 0.3, 0.8)  # Golden yellow
	flash.size = Vector2(40, 40)
	flash.position = position - flash.size / 2
	flash.z_index = 200
	# Make it circular by setting pivot and rotating slightly for visual effect
	flash.pivot_offset = flash.size / 2
	add_child(flash)

	# Animate the flash expanding and fading (creates circular explosion effect)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(5.0, 5.0), 0.5)
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.tween_property(flash, "rotation", TAU, 0.5)  # Full rotation for effect

	# Create inner white flash (faster and more intense)
	var flash2 = ColorRect.new()
	flash2.color = Color(1.0, 1.0, 1.0, 1.0)  # Bright white
	flash2.size = Vector2(25, 25)
	flash2.position = position - flash2.size / 2
	flash2.z_index = 201
	flash2.pivot_offset = flash2.size / 2
	add_child(flash2)

	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(flash2, "scale", Vector2(4.0, 4.0), 0.3)
	tween2.tween_property(flash2, "modulate:a", 0.0, 0.3)
	tween2.tween_property(flash2, "rotation", -TAU, 0.3)  # Counter-rotation

	# Create additional particle-like flashes around the impact point
	for i in range(6):  # 6 small particles
		var particle = ColorRect.new()
		particle.color = Color(1.0, 0.95, 0.5, 1.0)
		particle.size = Vector2(10, 10)
		var angle = (TAU / 6.0) * i  # Evenly spaced around circle
		var offset = Vector2(cos(angle), sin(angle)) * 20
		particle.position = position + offset - particle.size / 2
		particle.z_index = 199
		add_child(particle)

		# Animate particles flying outward
		var particle_tween = create_tween()
		particle_tween.set_parallel(true)
		var final_offset = offset * 3  # Fly outward
		particle_tween.tween_property(particle, "position", position + final_offset - particle.size / 2, 0.4)
		particle_tween.tween_property(particle, "modulate:a", 0.0, 0.4)
		particle_tween.tween_property(particle, "scale", Vector2(0.5, 0.5), 0.4)
		particle_tween.finished.connect(func(): particle.queue_free())

	# Clean up after animation
	tween.finished.connect(func(): flash.queue_free())
	tween2.finished.connect(func(): flash2.queue_free())

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
	# Clean expression before adding to inventory
	var cleaned_premise = clean_expression(premise)
	available_premises.append(cleaned_premise)
	create_premise_cards()

func _on_addition_dialog_confirmed(expr_text: String) -> void:
	# User confirmed the Addition dialog with an expression
	if selected_premises.size() != 1:
		feedback_message.emit("Error: No premise selected", Color.RED)
		clear_selections()
		return

	# Create expression from user input
	var additional_expr = BooleanLogicEngine.create_expression(expr_text)

	if not additional_expr.is_valid:
		feedback_message.emit("Invalid expression: " + expr_text, Color.RED)
		return

	# Apply addition rule: P ⊢ P ∨ Q
	var result = BooleanLogicEngine.apply_addition([selected_premises[0]], additional_expr)

	if result.is_valid:
		# Clean the result before adding to inventory
		var cleaned_result = clean_expression(result)

		# Add result to inventory
		available_premises.append(cleaned_result)
		create_premise_cards()

		# Track successful operation usage
		ProgressTracker.record_operation_used("Addition", true)

		# Clear selections
		clear_selections()

		feedback_message.emit("✓ Applied Addition: " + cleaned_result.expression_string, Color.GREEN)
		rule_applied.emit(cleaned_result)

		# Check if target is reached
		if cleaned_result.expression_string.strip_edges() == target_conclusion.strip_edges():
			feedback_message.emit("✓ Target reached! Proof complete!", Color.CYAN)
			target_reached.emit(cleaned_result)
	else:
		clear_selections()
		feedback_message.emit("Addition failed to produce valid result", Color.RED)

func _on_addition_dialog_cancelled() -> void:
	# User cancelled the Addition dialog
	clear_selections()
	feedback_message.emit("Addition cancelled", Color.WHITE)
