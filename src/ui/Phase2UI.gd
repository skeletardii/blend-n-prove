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

# Remote Controls
@onready var double_ops_remote: Panel = $DoubleOpsRemote
@onready var single_ops_remote: Panel = $SingleOpsRemote
@onready var double_toggle_button: Button = $DoubleOpsRemote/Header/ToggleButton
@onready var single_toggle_button: Button = $SingleOpsRemote/Header/ToggleButton

# Double Operation Buttons
@onready var mp_button: Button = $DoubleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/MPButton
@onready var mt_button: Button = $DoubleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/MTButton
@onready var hs_button: Button = $DoubleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/HSButton
@onready var ds_button: Button = $DoubleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/DSButton
@onready var cd_button: Button = $DoubleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/CDButton
@onready var dn_button: Button = $DoubleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/DNButton
@onready var conj_button: Button = $DoubleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/CONJButton
@onready var eq_button: Button = $DoubleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/EQButton
@onready var res_button: Button = $DoubleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/RESButton

# Single Operation Buttons
@onready var simp_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/SIMPButton
@onready var imp_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/IMPButton
@onready var conv_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/CONVButton
@onready var add_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/ADDButton
@onready var dm_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/DMButton
@onready var dneg_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/DNEGButton
@onready var dist_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/DISTButton
@onready var comm_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/COMMButton
@onready var assoc_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/ASSOCButton
@onready var idemp_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/IDEMPButton
@onready var abs_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/ABSButton
@onready var paren_remove_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/PAREN_REMOVEButton
@onready var neg_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/NEGButton
@onready var taut_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/TAUTButton
@onready var contr_button: Button = $SingleOpsRemote/RemoteContainer/ButtonsScroll/ButtonsContainer/CONTRButton

# Game State
var available_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var selected_premises: Array[BooleanLogicEngine.BooleanExpression] = []
var target_conclusion: String = ""
var selected_rule: String = ""
var premise_cards: Array[Control] = []
var target_reached_triggered: bool = false  # Prevent multiple target animations

# Animation State
var double_panel_height: float = 450.0
var single_panel_height: float = 600.0
var button_height: float = 50.0
var is_animating_double: bool = false
var is_animating_single: bool = false

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
	connect_addition_dialog()
	connect_toggle_buttons()
	start_silhouette_breathing()

	# Initialize both remotes (hidden - only buttons visible)
	double_ops_remote.visible = true
	single_ops_remote.visible = true

	# Set initial positions (retracted - only button header visible at bottom)
	# Both remotes start contracted, showing only the header (50px)
	double_ops_remote.offset_top = -button_height
	single_ops_remote.offset_top = -button_height

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


func connect_addition_dialog() -> void:
	addition_dialog.expression_confirmed.connect(_on_addition_dialog_confirmed)
	addition_dialog.dialog_cancelled.connect(_on_addition_dialog_cancelled)

func connect_toggle_buttons() -> void:
	double_toggle_button.pressed.connect(_on_double_toggle_pressed)
	single_toggle_button.pressed.connect(_on_single_toggle_pressed)

func _on_double_toggle_pressed() -> void:
	toggle_double_remote()

func _on_single_toggle_pressed() -> void:
	toggle_single_remote()

func toggle_double_remote() -> void:
	if is_animating_double or is_animating_single:
		return

	# Check if double remote is currently closed (showing only button)
	var is_closed: bool = abs(double_ops_remote.offset_top + button_height) < 10.0

	if is_closed:
		# Close single remote first if it's open
		var single_is_open: bool = abs(single_ops_remote.offset_top + single_panel_height) < 10.0
		if single_is_open:
			close_single_remote()
		open_double_remote()
	else:
		close_double_remote()

func toggle_single_remote() -> void:
	if is_animating_single or is_animating_double:
		return

	# Check if single remote is currently closed (showing only button)
	var is_closed: bool = abs(single_ops_remote.offset_top + button_height) < 10.0

	if is_closed:
		# Close double remote first if it's open
		var double_is_open: bool = abs(double_ops_remote.offset_top + double_panel_height) < 10.0
		if double_is_open:
			close_double_remote()
		open_single_remote()
	else:
		close_single_remote()

func open_double_remote() -> void:
	if is_animating_double:
		return

	is_animating_double = true
	double_toggle_button.text = "▼"

	# Animate from -50 (button only) to -450 (full panel)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(double_ops_remote, "offset_top", -double_panel_height, 0.3)
	tween.finished.connect(func(): is_animating_double = false)

func close_double_remote() -> void:
	if is_animating_double:
		return

	is_animating_double = true
	double_toggle_button.text = "▲"

	# Animate from -450 (full panel) to -50 (button only)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(double_ops_remote, "offset_top", -button_height, 0.3)
	tween.finished.connect(func(): is_animating_double = false)

func open_single_remote() -> void:
	if is_animating_single:
		return

	is_animating_single = true
	single_toggle_button.text = "▼"

	# Animate from -50 (button only) to -600 (full panel)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(single_ops_remote, "offset_top", -single_panel_height, 0.3)
	tween.finished.connect(func(): is_animating_single = false)

func close_single_remote() -> void:
	if is_animating_single:
		return

	is_animating_single = true
	single_toggle_button.text = "▲"

	# Animate from -600 (full panel) to -50 (button only)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(single_ops_remote, "offset_top", -button_height, 0.3)
	tween.finished.connect(func(): is_animating_single = false)

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

	# Start jiggle animation
	start_button_jiggle(rule)

	# Close both remotes after selecting a rule
	close_double_remote()
	close_single_remote()

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
	animated_card.modulate = Color.BLACK
	animated_card.z_index = 100
	# Set pivot to center for rotation
	animated_card.pivot_offset = winning_card.size / 2
	add_child(animated_card)

	# Get start and end positions
	var start_pos: Vector2 = winning_card.global_position
	# End position is the center of the silhouette, moved 40px left
	var end_pos: Vector2 = silhouette.global_position + silhouette.size / 2
	end_pos.x -= 40  # Move 40px to the left

	# Explosion position is 30px to the right of the flying endpoint
	var explosion_pos: Vector2 = end_pos
	explosion_pos.x += 30  # Move 30px to the right

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

	# Add swirling rotation animation (multiple full rotations for dramatic effect)
	tween.parallel().tween_property(animated_card, "rotation", TAU * 3, duration)

	# When animation completes, create flash at the explosion position and clean up
	tween.finished.connect(func():
		# Flash spawns at explosion_pos (30px right of where card lands)
		create_target_flash(explosion_pos)
		animated_card.queue_free()
		# Play success sound
		AudioManager.play_logic_success()
	)

	# Hide the original card
	winning_card.modulate = Color(1, 1, 1, 0)

func create_target_flash(position: Vector2) -> void:
	"""Create a satisfying circular flash effect where the ingredient disappears"""
	# Move explosion up by 100px from silhouette center
	position.y -= 100

	# Create outer golden ring flash (circular)
	var flash = Panel.new()
	var flash_style = StyleBoxFlat.new()
	flash_style.bg_color = Color(1.0, 0.9, 0.3, 0.8)  # Golden yellow
	flash_style.corner_radius_top_left = 20
	flash_style.corner_radius_top_right = 20
	flash_style.corner_radius_bottom_left = 20
	flash_style.corner_radius_bottom_right = 20
	flash.add_theme_stylebox_override("panel", flash_style)
	flash.custom_minimum_size = Vector2(40, 40)
	flash.size = Vector2(40, 40)
	flash.position = position - flash.size / 2
	flash.z_index = 200
	flash.pivot_offset = flash.size / 2
	add_child(flash)

	# Animate the flash expanding and fading (creates circular explosion effect)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(5.0, 5.0), 0.5)
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.tween_property(flash, "rotation", TAU, 0.5)  # Full rotation for effect

	# Create inner white flash (faster and more intense, circular)
	var flash2 = Panel.new()
	var flash2_style = StyleBoxFlat.new()
	flash2_style.bg_color = Color(1.0, 1.0, 1.0, 1.0)  # Bright white
	flash2_style.corner_radius_top_left = 13
	flash2_style.corner_radius_top_right = 13
	flash2_style.corner_radius_bottom_left = 13
	flash2_style.corner_radius_bottom_right = 13
	flash2.add_theme_stylebox_override("panel", flash2_style)
	flash2.custom_minimum_size = Vector2(25, 25)
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

	# Create additional particle-like flashes around the impact point (circular)
	for i in range(6):  # 6 small particles
		var particle = Panel.new()
		var particle_style = StyleBoxFlat.new()
		particle_style.bg_color = Color(1.0, 0.95, 0.5, 1.0)
		particle_style.corner_radius_top_left = 5
		particle_style.corner_radius_top_right = 5
		particle_style.corner_radius_bottom_left = 5
		particle_style.corner_radius_bottom_right = 5
		particle.add_theme_stylebox_override("panel", particle_style)
		particle.custom_minimum_size = Vector2(10, 10)
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
	tween2.finished.connect(func():
		flash2.queue_free()
		# Show score popup after explosion
		show_score_popup_at_position(position)
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

func show_score_popup_at_position(explosion_pos: Vector2) -> void:
	"""Show score popup at the explosion position"""
	if not score_display:
		return

	# Calculate score based on speed and efficiency
	var time_bonus: int = int(patience_timer)
	var base_score: int = 100 + (GameManager.difficulty_level * 50)
	var total_score: int = base_score + time_bonus

	# Show score popup animation at explosion position
	var popup: CanvasLayer = score_popup_scene.instantiate()
	get_tree().root.add_child(popup)
	popup.show_score_popup_phase2(total_score, time_bonus, base_score, explosion_pos, score_display, GameManager.current_score)

	# Add score to GameManager after animation completes
	get_tree().create_timer(0.6 + 0.5).timeout.connect(func():
		GameManager.add_score(total_score)
	)

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
		button.modulate = Color.BLACK
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
		button.modulate = Color.BLACK

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

func _on_addition_dialog_cancelled() -> void:
	# User cancelled the Addition dialog
	clear_selections()
	feedback_message.emit("Addition cancelled", Color.WHITE)
