extends Node
class_name FirstTimeTutorialManager

# Explicit preload to ensure BooleanExpression type is available
const BooleanExpression = preload("res://src/game/expressions/BooleanExpression.gd")

## Manages the first-time tutorial flow with action-based progression

signal tutorial_completed
signal tutorial_skipped

enum TutorialStep {
	# Phase 1 Steps
	WELCOME_AND_ORDER,
	PATIENCE_BAR_EXPLAINED,
	KEYBOARD_BASICS,
	OPERATORS_INTRO,
	TYPE_FIRST_PREMISE,
	SUBMIT_PREMISE,
	COMPLETE_ALL_PREMISES,

	# Transition to Phase 2
	PHASE2_INTRO,

	# Phase 2 Steps
	PREMISE_SELECTION,
	RULE_BUTTONS_OVERVIEW,
	PAGE_TOGGLE,
	APPLY_FIRST_RULE,
	TARGET_EXPLANATION,
	REACH_TARGET,
	BONUS_SCORE_EXPLANATION,

	# Completion
	FINISHED
}

var current_step: TutorialStep = TutorialStep.WELCOME_AND_ORDER
var overlay: TutorialOverlay
var gameplay_scene: Node
var phase1_ui: Node
var phase2_ui: Node

# Track tutorial progress
var has_typed_anything := false
var has_submitted_premise := false
var premises_completed := false
var has_selected_premise := false
var has_applied_rule := false
var target_reached := false


func _ready() -> void:
	pass


func initialize(
	_overlay: TutorialOverlay,
	_gameplay_scene: Node,
	_phase1_ui: Node = null,
	_phase2_ui: Node = null
) -> void:
	"""Initialize the tutorial with required references"""
	overlay = _overlay
	gameplay_scene = _gameplay_scene
	phase1_ui = _phase1_ui
	phase2_ui = _phase2_ui

	# Connect to overlay signals
	if overlay:
		overlay.skip_requested.connect(_on_skip_requested)
		overlay.next_button_pressed.connect(_on_next_button_pressed)

	# Connect to Phase 1 signals
	if phase1_ui:
		connect_phase1_signals()


func connect_phase1_signals() -> void:
	"""Connect to Phase1UI signals for action detection"""
	if phase1_ui.has_signal("text_changed"):
		phase1_ui.text_changed.connect(_on_text_changed)
	if phase1_ui.has_signal("premise_validated"):
		phase1_ui.premise_validated.connect(_on_premise_validated)
	if phase1_ui.has_signal("premises_completed"):
		phase1_ui.premises_completed.connect(_on_premises_completed)


func connect_phase2_signals() -> void:
	"""Connect to Phase2UI signals for action detection"""
	if phase2_ui == null:
		return

	if phase2_ui.has_signal("premise_selected"):
		phase2_ui.premise_selected.connect(_on_premise_selected)
	if phase2_ui.has_signal("rule_applied"):
		phase2_ui.rule_applied.connect(_on_rule_applied)
	if phase2_ui.has_signal("target_reached"):
		phase2_ui.target_reached.connect(_on_target_reached)


func start_tutorial() -> void:
	"""Begin the tutorial from the first step"""
	current_step = TutorialStep.WELCOME_AND_ORDER
	overlay.show_overlay()
	show_current_step()


func show_current_step() -> void:
	"""Display the current tutorial step"""
	match current_step:
		TutorialStep.WELCOME_AND_ORDER:
			show_welcome_step()
		TutorialStep.PATIENCE_BAR_EXPLAINED:
			show_patience_bar_step()
		TutorialStep.KEYBOARD_BASICS:
			show_keyboard_basics_step()
		TutorialStep.OPERATORS_INTRO:
			show_operators_step()
		TutorialStep.TYPE_FIRST_PREMISE:
			show_type_premise_step()
		TutorialStep.SUBMIT_PREMISE:
			show_submit_premise_step()
		TutorialStep.COMPLETE_ALL_PREMISES:
			show_complete_premises_step()
		TutorialStep.PHASE2_INTRO:
			show_phase2_intro_step()
		TutorialStep.PREMISE_SELECTION:
			show_premise_selection_step()
		TutorialStep.RULE_BUTTONS_OVERVIEW:
			show_rule_buttons_step()
		TutorialStep.PAGE_TOGGLE:
			show_page_toggle_step()
		TutorialStep.APPLY_FIRST_RULE:
			show_apply_rule_step()
		TutorialStep.TARGET_EXPLANATION:
			show_target_explanation_step()
		TutorialStep.REACH_TARGET:
			show_reach_target_step()
		TutorialStep.BONUS_SCORE_EXPLANATION:
			show_bonus_score_step()
		TutorialStep.FINISHED:
			complete_tutorial()


# ============================================================================
# PHASE 1 TUTORIAL STEPS
# ============================================================================

func show_welcome_step() -> void:
	var customer_area := find_node_by_path("CustomerArea")
	if customer_area:
		overlay.show_step(
			"[b]Welcome to Logic Café![/b]\n\nYour job is to solve logic puzzles for customers. This customer wants you to prove [b]P∧Q[/b].\n\nLet's learn how!",
			customer_area,
			Vector2.ZERO,
			Vector2.DOWN,
			false,
			Vector2.ZERO,
			true  # Show Next button
		)

	# Wait for Next button press (handled by _on_next_button_pressed)


func show_patience_bar_step() -> void:
	var patience_bar := find_node_by_path("PatienceBar")
	if patience_bar:
		var bar_center := patience_bar.get_global_rect().get_center()
		overlay.show_step(
			"[b]Patience Bar[/b]\n\nThis shows how much time you have. Don't worry though - for this tutorial, you have [b]infinite time[/b]!",
			patience_bar,
			bar_center + Vector2(0, -100),
			Vector2.DOWN,
			true,
			bar_center,
			true  # Show Next button
		)

	# Wait for Next button press


func show_keyboard_basics_step() -> void:
	var keyboard := find_node_by_path("VirtualKeyboard")
	if keyboard:
		overlay.show_step(
			"[b]Virtual Keyboard[/b]\n\nUse these buttons to build logical expressions. The letters [b]P, Q, R, S, T[/b] are variables.\n\nFor this puzzle, you need to enter [b]P[/b] and [b]Q[/b] as separate premises.",
			keyboard,
			Vector2.ZERO,
			Vector2.DOWN,
			false,
			Vector2.ZERO,
			true  # Show Next button
		)

	# Wait for Next button press


func show_operators_step() -> void:
	var keyboard := find_node_by_path("VirtualKeyboard")
	if keyboard:
		overlay.show_step(
			"[b]Logical Operators[/b]\n\n[b]∧[/b] = AND\n[b]∨[/b] = OR\n[b]→[/b] = Implies\n[b]¬[/b] = NOT\n\nYou'll use these later. For now, just type [b]P[/b].",
			keyboard,
			Vector2.ZERO,
			Vector2.DOWN,
			false,
			Vector2.ZERO,
			true  # Show Next button
		)

	# Wait for Next button press


func show_type_premise_step() -> void:
	var keyboard := find_node_by_path("VirtualKeyboard")
	if keyboard:
		overlay.show_step(
			"[b]Try it now![/b]\n\nClick the [b]P[/b] button on the keyboard to type your first premise.",
			keyboard,
			Vector2.ZERO,
			Vector2.DOWN,
			false,
			Vector2.ZERO,
			false  # No Next button - wait for action
		)

	# Wait for player to type something (detected via signal)


func show_submit_premise_step() -> void:
	var submit_button := find_node_by_path("SubmitButton")
	if submit_button:
		var button_center := submit_button.get_global_rect().get_center()
		overlay.show_step(
			"[b]Great![/b]\n\nNow click the [b]Submit[/b] button to validate this premise.",
			submit_button,
			button_center + Vector2(-80, 0),
			Vector2.RIGHT,
			false,
			Vector2.ZERO,
			false  # No Next button - wait for action
		)

	# Wait for player to submit (detected via signal)


func show_complete_premises_step() -> void:
	var keyboard := find_node_by_path("VirtualKeyboard")
	if keyboard:
		overlay.show_step(
			"[b]Excellent![/b]\n\nYou entered your first premise. Now enter the second premise: [b]Q[/b].\n\nType [b]Q[/b] and submit it the same way.",
			keyboard,
			Vector2.ZERO,
			Vector2.DOWN,
			false,
			Vector2.ZERO,
			false  # No Next button - wait for action
		)

	# Wait for all premises to be completed (detected via signal)


# ============================================================================
# PHASE 2 TUTORIAL STEPS
# ============================================================================

func show_phase2_intro_step() -> void:
	overlay.show_step(
		"[b]Phase 2: Transformation![/b]\n\nNow you have your premises [b]P[/b] and [b]Q[/b]. Your goal is to combine them to create [b]P∧Q[/b].\n\nLet's learn how to use logic rules!",
		null,
		Vector2.ZERO,
		Vector2.DOWN,
		false,
		Vector2.ZERO,
		true  # Show Next button
	)

	# Wait for Next button press


func show_premise_selection_step() -> void:
	# STEP 1: Show rule buttons overview first
	var rule_panel := find_node_by_path("RuleButtonsContainer")
	if rule_panel:
		overlay.show_step(
			"[b]Logic Rules[/b]\n\nThese buttons apply logical inference rules. Each rule transforms premises in a specific way.\n\nThere are two pages: [b]Double Operations[/b] (need 2 premises) and [b]Single Operations[/b] (need 1 premise).",
			rule_panel,
			Vector2.ZERO,
			Vector2.DOWN,
			false,
			Vector2.ZERO,
			true  # Show Next button
		)

	# Wait for Next button press


func show_rule_buttons_step() -> void:
	# STEP 2: Explain the page toggle
	var page_toggle := find_node_by_path("PageToggleButton")
	if page_toggle:
		var toggle_center := page_toggle.get_global_rect().get_center()
		overlay.show_step(
			"[b]Page Toggle[/b]\n\nThis button switches between Single and Double operations.\n\nThe [b]CONJ[/b] (Conjunction) rule is on the Double Operations page (shown by default).",
			page_toggle,
			toggle_center + Vector2(-100, 0),
			Vector2.RIGHT,
			true,
			toggle_center,
			true  # Show Next button
		)

	# Wait for Next button press


func show_page_toggle_step() -> void:
	# STEP 3: Tell user to SELECT OPERATION FIRST
	var rule_panel := find_node_by_path("RuleButtonsContainer")
	if rule_panel:
		overlay.show_step(
			"[b]Select Operation First[/b]\n\nClick the [b]CONJ[/b] button to select this operation. It combines two premises with AND (∧).\n\n[i]Important: Always select the operation BEFORE selecting premises![/i]",
			rule_panel,
			Vector2.ZERO,
			Vector2.DOWN,
			false,
			Vector2.ZERO,
			true  # Show Next button - just explaining, not requiring action yet
		)

	# Wait for Next button press


func show_apply_rule_step() -> void:
	# STEP 4: Now tell them to select premises AFTER operation
	var premise_inventory := find_node_by_path("PremiseInventory")
	if premise_inventory:
		overlay.show_step(
			"[b]Now Select Premises[/b]\n\nAfter clicking CONJ, select your premises:\n\n1. Click [b]P[/b]\n2. Click [b]Q[/b]\n\nThe rule will apply automatically when you have both premises selected!",
			premise_inventory,
			Vector2.ZERO,
			Vector2.DOWN,
			false,
			Vector2.ZERO,
			false  # No Next button - wait for action
		)

	# Wait for rule application (detected via signal)


func show_target_explanation_step() -> void:
	var target_display := find_node_by_path("TargetDisplay")
	if target_display:
		overlay.show_step(
			"[b]Target Goal[/b]\n\nThis shows what you're trying to prove. When you create an expression that matches this exactly, you win!",
			target_display,
			Vector2.ZERO,
			Vector2.DOWN,
			false,
			Vector2.ZERO,
			true  # Show Next button
		)

	# Wait for Next button press


func show_reach_target_step() -> void:
	# Check if target was already reached in previous step
	if target_reached:
		# Already complete! Skip this step
		advance_to_next_step()
		return

	overlay.show_step(
		"[b]Almost there![/b]\n\nApply the CONJ rule to [b]P[/b] and [b]Q[/b] to create [b]P∧Q[/b] and complete the puzzle!",
		null,
		Vector2.ZERO,
		Vector2.DOWN,
		false,
		Vector2.ZERO,
		false  # No Next button - wait for action
	)

	# Wait for target to be reached (detected via signal)


func show_bonus_score_step() -> void:
	overlay.show_step(
		"[b]🎉 Puzzle Solved![/b]\n\n[b]Bonus Score Tip:[/b] The faster you solve puzzles, the more bonus points you earn based on remaining time!\n\nYou also get bonuses for:\n• Using fewer operations\n• Solving without hints",
		null,
		Vector2.ZERO,
		Vector2.DOWN,
		false,
		Vector2.ZERO,
		true  # Show Next button
	)

	# Wait for Next button press


# ============================================================================
# PROGRESSION LOGIC
# ============================================================================

func advance_to_next_step() -> void:
	"""Move to the next tutorial step"""
	var next_step := current_step + 1
	if next_step >= TutorialStep.FINISHED:
		current_step = TutorialStep.FINISHED
		complete_tutorial()
	else:
		current_step = next_step
		show_current_step()


func complete_tutorial() -> void:
	"""Tutorial is finished"""
	overlay.hide_overlay()
	tutorial_completed.emit()


# ============================================================================
# ACTION DETECTION (Signal Handlers)
# ============================================================================

func _on_text_changed(_text: String) -> void:
	"""Detect when player types anything"""
	if current_step == TutorialStep.TYPE_FIRST_PREMISE and not has_typed_anything:
		has_typed_anything = true
		await get_tree().create_timer(1.0).timeout
		advance_to_next_step()


func _on_premise_validated(_expression: BooleanExpression) -> void:
	"""Detect when player submits a premise"""
	if current_step == TutorialStep.SUBMIT_PREMISE and not has_submitted_premise:
		has_submitted_premise = true
		await get_tree().create_timer(1.0).timeout
		advance_to_next_step()


func _on_premises_completed(_premises: Array) -> void:
	"""Detect when all premises are entered"""
	if current_step == TutorialStep.COMPLETE_ALL_PREMISES and not premises_completed:
		premises_completed = true
		await get_tree().create_timer(1.0).timeout
		advance_to_next_step()


func _on_premise_selected(_premise: String) -> void:
	"""Detect when player selects a premise in Phase 2"""
	# No longer used - tutorial now waits for rule_applied instead
	# User selects operation first, then premises, then rule applies automatically
	pass


func _on_rule_applied(_result: BooleanExpression) -> void:
	"""Detect when player applies a rule"""
	if current_step == TutorialStep.APPLY_FIRST_RULE and not has_applied_rule:
		has_applied_rule = true
		await get_tree().create_timer(1.0).timeout
		advance_to_next_step()


func _on_target_reached(_result: BooleanExpression) -> void:
	"""Detect when player reaches the target"""
	if not target_reached:
		target_reached = true
		# If we're at the REACH_TARGET step, advance immediately
		if current_step == TutorialStep.REACH_TARGET:
			await get_tree().create_timer(1.0).timeout
			advance_to_next_step()


func _on_skip_requested() -> void:
	"""Handle skip button press"""
	overlay.hide_overlay()
	tutorial_skipped.emit()


func _on_next_button_pressed() -> void:
	"""Handle Next button press"""
	advance_to_next_step()


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func find_node_by_path(node_name: String) -> Control:
	"""Find a node in the gameplay scene by partial path"""
	if not gameplay_scene:
		return null

	# Try common paths
	var paths := [
		"UI/MainContainer/GameContentArea/CustomerArea",
		"UI/MainContainer/PatienceBar",
		"UI/MainContainer/GameContentArea/PhaseContainer/Phase1UI/VirtualKeyboard",
		"UI/MainContainer/GameContentArea/PhaseContainer/Phase1UI/SubmitButton",
		"UI/MainContainer/GameContentArea/PhaseContainer/Phase2UI/PremiseInventory",
		"UI/MainContainer/GameContentArea/PhaseContainer/Phase2UI/RuleButtonsContainer",
		"UI/MainContainer/GameContentArea/PhaseContainer/Phase2UI/PageToggleButton",
		"UI/MainContainer/GameContentArea/TargetDisplay",
	]

	for path in paths:
		if node_name in path:
			var node := gameplay_scene.get_node_or_null(path)
			if node:
				return node

	# Fallback: search recursively
	return find_child_recursive(gameplay_scene, node_name)


func find_child_recursive(parent: Node, target_name: String) -> Control:
	"""Recursively search for a child node by name"""
	for child in parent.get_children():
		if target_name in child.name:
			if child is Control:
				return child
		var result := find_child_recursive(child, target_name)
		if result:
			return result
	return null
