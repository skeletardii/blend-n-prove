extends Control

# Preload score popup scene
const score_popup_scene = preload("res://src/ui/ScorePopup.tscn")

# UI References
@onready var work_container: VBoxContainer = $WorkContainer
@onready var phase_label: Label = $WorkContainer/PhaseLabel
@onready var premise_grid: GridContainer = $WorkContainer/InventoryArea/InventoryContainer/InventoryScroll/MarginContainer/PremiseGrid
@onready var target_expression: Label = $WorkContainer/TargetArea/ChatBubble/TargetContainer/TargetExpression
@onready var addition_dialog: Panel = $AdditionDialog
@onready var silhouette: TextureRect = $Silhouette
@onready var feedback_label: Label = $WorkContainer/InventoryArea/InventoryContainer/FeedbackLabel

# References passed from GameplayScene
var score_display: Label = null
var patience_timer: float = 0.0

# Operations Panel
@onready var operations_panel: Panel = $OperationsPanel
@onready var operations_close_button: Button = $OperationsPanel/MainContainer/Header/CloseButton
@onready var double_ops_tab: Button = $OperationsPanel/MainContainer/TabContainer/DoubleOpsTab
@onready var single_ops_tab: Button = $OperationsPanel/MainContainer/TabContainer/SingleOpsTab
@onready var double_ops_container: VBoxContainer = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer
@onready var single_ops_container: VBoxContainer = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer

# Double Operation Buttons
@onready var mp_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/MPButton
@onready var mt_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/MTButton
@onready var hs_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/HSButton
@onready var ds_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/DSButton
@onready var cd_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/CDButton
@onready var dn_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/DNButton
@onready var conj_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/CONJButton
@onready var eq_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/EQButton
@onready var res_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/RESButton

# Single Operation Buttons
@onready var simp_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/SIMPButton
@onready var imp_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/IMPButton
@onready var conv_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/CONVButton
@onready var add_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/ADDButton
@onready var dm_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/DMButton
@onready var dneg_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/DNEGButton
@onready var dist_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/DISTButton
@onready var comm_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/COMMButton
@onready var assoc_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/ASSOCButton
@onready var idemp_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/IDEMPButton
@onready var abs_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/ABSButton

# Game State
var available_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var selected_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var target_conclusion: String = ""
var selected_rule: String = ""
var premise_cards: Array[Control] = []
var target_reached_triggered: bool = false  # Prevent multiple target animations

# Animation State
var panel_height: float = 800.0
var panel_closed_height: float = 70.0
var is_animating_panel: bool = false
var current_tab: String = "double"  # "double" or "single"

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
	"DNEG": {"type": RuleType.SINGLE, "name": "Double Negation"}
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
	connect_addition_dialog()
	connect_toggle_buttons()
	start_silhouette_breathing()

	# Initialize operations panel (starts collapsed)
	operations_panel.visible = true

	# Show double ops by default
	double_ops_container.visible = true
	single_ops_container.visible = false
	double_ops_tab.button_pressed = true
	single_ops_tab.button_pressed = false

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
	dneg_button.pressed.connect(_on_rule_button_pressed.bind("DNEG"))


func connect_addition_dialog() -> void:
	addition_dialog.expression_confirmed.connect(_on_addition_dialog_confirmed)
	addition_dialog.dialog_cancelled.connect(_on_addition_dialog_cancelled)

func connect_toggle_buttons() -> void:
	operations_close_button.pressed.connect(_on_operations_panel_toggle)
	double_ops_tab.pressed.connect(_on_double_tab_pressed)
	single_ops_tab.pressed.connect(_on_single_tab_pressed)

func _on_operations_panel_toggle() -> void:
	toggle_operations_panel()

func _on_double_tab_pressed() -> void:
	switch_to_tab("double")

func _on_single_tab_pressed() -> void:
	switch_to_tab("single")

func toggle_operations_panel() -> void:
	if is_animating_panel:
		return

	# Check if panel is currently closed
	var is_closed: bool = abs(operations_panel.offset_top + panel_closed_height) < 10.0

	if is_closed:
		open_operations_panel()
	else:
		close_operations_panel()

func open_operations_panel() -> void:
	if is_animating_panel:
		return

	is_animating_panel = true
	operations_close_button.text = "▼"

	# Animate from closed to open
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(operations_panel, "offset_top", -panel_height, 0.3)
	tween.finished.connect(func(): is_animating_panel = false)

func close_operations_panel() -> void:
	if is_animating_panel:
		return

	is_animating_panel = true
	operations_close_button.text = "▲"

	# Animate from open to closed
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(operations_panel, "offset_top", -panel_closed_height, 0.3)
	tween.finished.connect(func(): is_animating_panel = false)

func switch_to_tab(tab: String) -> void:
	current_tab = tab

	if tab == "double":
		double_ops_container.visible = true
		single_ops_container.visible = false
		double_ops_tab.button_pressed = true
		single_ops_tab.button_pressed = false
	else:
		double_ops_container.visible = false
		single_ops_container.visible = true
		double_ops_tab.button_pressed = false
		single_ops_tab.button_pressed = true

func start_silhouette_breathing() -> void:
	"""Creates a subtle breathing animation for the silhouette sprite"""
	if not silhouette:
		return

	# Set the pivot point to center bottom (feet stay grounded while body breathes)
	silhouette.pivot_offset = Vector2(silhouette.size.x / 2, silhouette.size.y)

	# Create infinite looping tween for breathing
	var breathe_tween = create_tween()
	breathe_tween.set_loops()  # Infinite loop

	# Breathing cycle parameters (based on natural breathing: ~4-5 seconds per cycle)
	var inhale_duration = 2.0  # 2 seconds to inhale
	var exhale_duration = 2.5  # 2.5 seconds to exhale
	var inhale_scale = Vector2(1.02, 1.03)  # Slight vertical expansion (chest rises)
	var exhale_scale = Vector2(1.0, 1.0)  # Return to normal

	# Inhale: Expand slightly (chest/torso rises)
	breathe_tween.tween_property(silhouette, "scale", inhale_scale, inhale_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Exhale: Return to normal size
	breathe_tween.tween_property(silhouette, "scale", exhale_scale, exhale_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func set_premises_and_target(premises: Array[BooleanLogicEngine.BooleanExpression], target: String) -> void:
	# Clean all premises before adding to inventory
	available_premises.clear()
	for premise in premises:
		var cleaned = clean_expression(premise)
		available_premises.append(cleaned)

	target_conclusion = target
	target_expression.text = "Prove: " + target
	adjust_target_font_size()
	create_premise_cards()

	# Reset target reached flag for new problem
	target_reached_triggered = false

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
	adjust_target_font_size()
	create_premise_cards()

	# Reset target reached flag for new problem
	target_reached_triggered = false

func adjust_target_font_size() -> void:
	"""Dynamically adjust font size to fit text within the chat bubble"""
	# Start with maximum font size
	var max_font_size = 30
	var min_font_size = 12
	var current_font_size = max_font_size

	# Get the available width/height from the parent container
	await get_tree().process_frame  # Wait for layout to update

	var available_size = target_expression.get_parent().size

	# Try decreasing font sizes until text fits
	while current_font_size >= min_font_size:
		target_expression.add_theme_font_size_override("font_size", current_font_size)
		await get_tree().process_frame  # Let label recalculate size

		# Check if text fits within bounds
		var text_size = target_expression.get_minimum_size()
		if text_size.x <= available_size.x and text_size.y <= available_size.y:
			break

		current_font_size -= 2  # Decrease by 2px each iteration

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
	card.custom_minimum_size = Vector2(280, 80)
	card.toggle_mode = true
	# Center the text horizontally (vertical centering is automatic for buttons)
	card.alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Increase font size
	card.add_theme_font_size_override("font_size", 24)

	# Ensure white background color
	card.modulate = Color.WHITE

	# Use default theme styling (white buttons with gray border and drop shadow from Wenrexa theme)
	# No custom StyleBox overrides - let the theme handle it

	card.pressed.connect(_on_premise_card_pressed.bind(premise, card))
	return card

func _on_premise_card_pressed(premise: BooleanLogicEngine.BooleanExpression, card: Button) -> void:
	# Only allow premise selection if a rule is selected
	if selected_rule.is_empty():
		card.button_pressed = false  # Reset button state
		show_feedback("Select operation first", Color.ORANGE, false)
		# Don't auto-open remotes - let user choose which one
		return

	if card.button_pressed:
		# Select premise
		if premise not in selected_premises:
			selected_premises.append(premise)
			# Emit signal for tutorial detection
			premise_selected.emit(premise.expression_string)
	else:
		# Deselect premise
		if premise in selected_premises:
			selected_premises.erase(premise)

	# Check if we can apply the selected rule
	check_rule_application()

func _on_rule_button_pressed(rule: String) -> void:
	# If clicking the same rule that's already selected, deselect everything
	if selected_rule == rule:
		clear_selections()
		show_feedback("Deselected", Color.WHITE, false)
		return

	# Clear previous rule selection
	clear_rule_selection()

	selected_rule = rule
	var rule_def = rule_definitions[rule]

	var premise_count = "1 premise" if rule_def.type == RuleType.SINGLE else "2 premises"
	show_feedback(rule_def.name + " - Select " + premise_count, Color.YELLOW, false)

	# Highlight the selected button
	highlight_rule_button(rule)

	# Close operations panel after selecting a rule
	close_operations_panel()

func check_rule_application() -> void:
	if selected_rule.is_empty():
		return

	var rule_def = rule_definitions[selected_rule]
	var required_count = 1 if rule_def.type == RuleType.SINGLE else 2

	if selected_premises.size() == required_count:
		# Special handling for Addition rule - needs user input via dialog
		if selected_rule == "ADD":
			addition_dialog.show_dialog(selected_premises[0])
			return

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

			var result_text = str(added_results.size()) + " result" + ("s" if added_results.size() > 1 else "")
			show_feedback("✓ " + rule_def.name + ": " + result_text, Color.GREEN, false)

			# Emit signal for each valid result
			for cleaned_result in added_results:
				rule_applied.emit(cleaned_result)
				# Check if any result is the target (only trigger once)
				if not target_reached_triggered and cleaned_result.expression_string.strip_edges() == target_conclusion.strip_edges():
					target_reached_triggered = true
					show_feedback("✓ Proof complete!", Color.CYAN)
					# Find the card that matches the result and animate it
					animate_target_reached(cleaned_result)
					# Emit signal after animation delay
					get_tree().create_timer(1.0).timeout.connect(func(): target_reached.emit(cleaned_result))
		else:
			# No valid results - show error
			clear_selections()
			show_feedback("✗ No valid results", Color.RED, false)
			# Penalty: lose fuel and reset combo
			apply_fuel_penalty()
			# Don't auto-open remotes on failure
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

		show_feedback("✓ " + rule_def.name, Color.GREEN, false)
		rule_applied.emit(cleaned_result)

		# Check if target is reached (only trigger once)
		if not target_reached_triggered and cleaned_result.expression_string.strip_edges() == target_conclusion.strip_edges():
			target_reached_triggered = true
			show_feedback("✓ Proof complete!", Color.CYAN)
			# Find the card that matches the result and animate it
			animate_target_reached(cleaned_result)
			# Emit signal after animation delay
			get_tree().create_timer(1.0).timeout.connect(func(): target_reached.emit(cleaned_result))
	else:
		# Clear selections when rule fails
		clear_selections()
		show_feedback("✗ Cannot apply " + rule_def.name, Color.RED, false)
		# Penalty: lose fuel and reset combo
		apply_fuel_penalty()
		# Don't auto-open remotes on failure

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

		# Other single operation rules (special cases)
		"ADD":  # Addition: P ⊢ P∨Q (needs additional expression)
			# For ADD rule, we need to ask user for the additional expression
			# For now, return empty to indicate this rule needs special handling
			return BooleanLogicEngine.BooleanExpression.new("")
		_:
			return BooleanLogicEngine.BooleanExpression.new("")

func animate_target_reached(result: BooleanLogicEngine.BooleanExpression) -> void:
	"""Show green glow effect on the winning card and display score popup"""
	# Find the LAST (most recently added) card that matches the result
	var winning_card: Control = null
	for i in range(premise_cards.size() - 1, -1, -1):  # Search backwards
		var card = premise_cards[i]
		var button = card as Button
		if button and button.text.contains(result.expression_string):
			winning_card = card
			break

	if not winning_card:
		return

	# Play success sound
	AudioManager.play_logic_success()

	# Create green glow effect
	var tween = create_tween()
	tween.set_loops(3)  # Pulse 3 times
	tween.tween_property(winning_card, "modulate", Color.GREEN, 0.3)
	tween.tween_property(winning_card, "modulate", Color.WHITE, 0.3)

	# Show score popup at the card's position after glow animation
	tween.finished.connect(func():
		winning_card.modulate = Color.GREEN  # Keep final green color
		show_score_popup_at_card(winning_card)
	)


func show_feedback(message: String, color: Color, emit_to_parent: bool = true) -> void:
	"""Show shortened feedback at the bottom of the premise box"""
	feedback_label.text = message
	feedback_label.modulate = color

	# Emit to parent for any global handling if needed
	if emit_to_parent:
		feedback_message.emit(message, color)

	# Auto-clear feedback after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(func():
		if feedback_label.text == message:  # Only clear if message hasn't changed
			feedback_label.text = ""
	)

func apply_fuel_penalty() -> void:
	"""Apply fuel penalty and reset combo in GameplayScene"""
	# Get reference to GameplayScene (parent of parent)
	var gameplay_scene = get_parent().get_parent()
	if gameplay_scene and gameplay_scene.has_method("apply_fuel_penalty"):
		gameplay_scene.apply_fuel_penalty(0.20)  # Lose 20% of current fuel
	if gameplay_scene and gameplay_scene.has_method("reset_combo"):
		gameplay_scene.reset_combo()

func show_score_popup_at_card(card: Control) -> void:
	"""Show speed boost notification at the card's position"""
	if not score_display:
		return

	# Get card center position
	var card_pos: Vector2 = card.global_position + card.size / 2

	# Show speed boost popup animation at card position
	# (Score is now gained continuously over time, not in chunks)
	# This popup now just shows the speed boost being applied
	var gameplay_scene = get_parent().get_parent()
	if gameplay_scene and gameplay_scene.has_method("add_speed_boost"):
		# Clean solution gives speed boost
		gameplay_scene.add_speed_boost(2.0, false)

		# Show visual feedback
		show_feedback("🚀 Speed Boost Activated!", Color.CYAN, true)

func clear_selections() -> void:
	selected_premises.clear()
	selected_rule = ""

	# Reset card states
	for card in premise_cards:
		var button = card as Button
		if button:
			button.button_pressed = false

	# Clear rule button highlights
	clear_rule_selection()

func clear_rule_selection() -> void:
	# Reset all rule button colors
	for button in get_all_rule_buttons():
		button.modulate = Color.WHITE

func get_all_rule_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	# Add all rule buttons
	buttons.append_array([mp_button, mt_button, hs_button, ds_button, cd_button, dn_button, conj_button, eq_button, res_button])
	buttons.append_array([simp_button, imp_button, conv_button, add_button, dm_button, dneg_button, dist_button, comm_button, assoc_button, idemp_button, abs_button])
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
		"DNEG": return dneg_button
		_: return null


func add_premise_to_inventory(premise: BooleanLogicEngine.BooleanExpression) -> void:
	# Clean expression before adding to inventory
	var cleaned_premise = clean_expression(premise)
	available_premises.append(cleaned_premise)
	create_premise_cards()

func _on_addition_dialog_confirmed(expr_text: String) -> void:
	# User confirmed the Addition dialog with an expression
	if selected_premises.size() != 1:
		show_feedback("✗ No premise selected", Color.RED, false)
		clear_selections()
		return

	# Create expression from user input
	var additional_expr = BooleanLogicEngine.create_expression(expr_text)

	if not additional_expr.is_valid:
		show_feedback("✗ Invalid expression", Color.RED, false)
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

		show_feedback("✓ Addition", Color.GREEN, false)
		rule_applied.emit(cleaned_result)

		# Check if target is reached (only trigger once)
		if not target_reached_triggered and cleaned_result.expression_string.strip_edges() == target_conclusion.strip_edges():
			target_reached_triggered = true
			show_feedback("✓ Proof complete!", Color.CYAN)
			# Find the card that matches the result and animate it
			animate_target_reached(cleaned_result)
			# Emit signal after animation delay
			get_tree().create_timer(1.0).timeout.connect(func(): target_reached.emit(cleaned_result))
	else:
		clear_selections()
		show_feedback("✗ Addition failed", Color.RED, false)
		# Penalty: lose fuel and reset combo
		apply_fuel_penalty()

func _on_addition_dialog_cancelled() -> void:
	# User cancelled the Addition dialog
	clear_selections()
	feedback_message.emit("Addition cancelled", Color.WHITE)
