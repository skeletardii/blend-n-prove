class_name SolverStepRow
extends PanelContainer

## Step-by-step solver row component
## Contains 3 parts: Result (LineEdit), Rule (OptionButton), Source statements (LineEdit)

signal result_focused(row: SolverStepRow)
signal step_changed()
signal delete_requested(row: SolverStepRow)

var step_number: int = 1
var result_text: String = ""
var selected_rule: String = ""
var selected_sources: Array = []

# UI References
var number_label: Label
var result_field: LineEdit
var rule_dropdown: OptionButton
var source_field: LineEdit
var delete_button: Button

func _init(p_step_number: int):
	step_number = p_step_number
	call_deferred("setup_ui")

func setup_ui():
	# Panel styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	style.border_color = Color(0.775, 0.417, 0.946, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", style)

	# Main layout with margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	# Grid container for layout
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 5)
	margin.add_child(grid)

	# Row 1: Step number and Delete button
	var header_container = HBoxContainer.new()
	number_label = Label.new()
	number_label.text = "Step " + str(step_number)
	number_label.add_theme_font_size_override("font_size", 20)
	header_container.add_child(number_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(spacer)

	delete_button = Button.new()
	delete_button.text = "×"
	delete_button.custom_minimum_size = Vector2(30, 30)
	delete_button.add_theme_font_size_override("font_size", 24)
	delete_button.pressed.connect(func(): delete_requested.emit(self))
	header_container.add_child(delete_button)

	grid.add_child(header_container)
	grid.add_child(Control.new())  # Spacer for grid

	# Row 2: Result label and field
	var result_label = Label.new()
	result_label.text = "Result:"
	result_label.add_theme_font_size_override("font_size", 16)
	grid.add_child(result_label)

	result_field = LineEdit.new()
	result_field.custom_minimum_size = Vector2(400, 40)
	result_field.editable = false  # Read-only, use virtual keyboard
	result_field.add_theme_font_size_override("font_size", 18)
	result_field.focus_entered.connect(func(): result_focused.emit(self))
	result_field.text_changed.connect(func(new_text):
		result_text = new_text
		step_changed.emit()
	)
	grid.add_child(result_field)

	# Row 3: Rule label and dropdown
	var rule_label = Label.new()
	rule_label.text = "Rule:"
	rule_label.add_theme_font_size_override("font_size", 16)
	grid.add_child(rule_label)

	rule_dropdown = OptionButton.new()
	rule_dropdown.custom_minimum_size = Vector2(400, 40)
	rule_dropdown.add_theme_font_size_override("font_size", 16)
	populate_rule_dropdown()
	rule_dropdown.item_selected.connect(_on_rule_selected)
	grid.add_child(rule_dropdown)

	# Row 4: Source label and field
	var source_label = Label.new()
	source_label.text = "From:"
	source_label.add_theme_font_size_override("font_size", 16)
	grid.add_child(source_label)

	source_field = LineEdit.new()
	source_field.custom_minimum_size = Vector2(400, 40)
	source_field.placeholder_text = "e.g., P1, P2 or S1, S2"
	source_field.add_theme_font_size_override("font_size", 18)
	source_field.text_changed.connect(func(new_text):
		parse_sources(new_text)
		step_changed.emit()
	)
	grid.add_child(source_field)

	# Set minimum size
	custom_minimum_size = Vector2(0, 180)

func populate_rule_dropdown():
	# Add "---" as first item
	rule_dropdown.add_item("---")
	rule_dropdown.selected = 0

	# Inference Rules section
	var inference_header_idx = rule_dropdown.get_item_count()
	rule_dropdown.add_item("-- Inference Rules --")
	rule_dropdown.set_item_disabled(inference_header_idx, true)

	# Inference rules
	var inference_rules = [
		"Modus Ponens (MP)",
		"Modus Tollens (MT)",
		"Hypothetical Syllogism (HS)",
		"Disjunctive Syllogism (DS)",
		"Simplification (SIMP)",
		"Conjunction (CONJ)",
		"Addition (ADD)",
		"Constructive Dilemma (CD)",
		"Destructive Dilemma (DD)",
		"Resolution (RES)"
	]

	for rule in inference_rules:
		rule_dropdown.add_item(rule)

	# Equivalence Laws section
	var equivalence_header_idx = rule_dropdown.get_item_count()
	rule_dropdown.add_item("-- Equivalence Laws --")
	rule_dropdown.set_item_disabled(equivalence_header_idx, true)

	# Equivalence laws
	var equivalence_laws = [
		"Commutativity (COMM)",
		"Associativity (ASSOC)",
		"Distributivity (DIST)",
		"De Morgan's Laws (DM)",
		"Double Negation (DNEG)",
		"Implication (IMP)",
		"Contrapositive (CONV)",
		"Idempotence (IDEMP)",
		"Absorption (ABS)",
		"Identity (ID)",
		"Domination (DOM)",
		"Negation (NEG)"
	]

	for law in equivalence_laws:
		rule_dropdown.add_item(law)

func _on_rule_selected(index: int):
	selected_rule = rule_dropdown.get_item_text(index)
	step_changed.emit()

func parse_sources(text: String):
	selected_sources.clear()
	var parts = text.split(",")
	for part in parts:
		var trimmed = part.strip_edges().to_upper()
		
		# Check for Prefix
		var type = ""
		var number_str = ""
		
		if trimmed.begins_with("P"):
			type = "P"
			number_str = trimmed.substr(1)
		elif trimmed.begins_with("S"):
			type = "S"
			number_str = trimmed.substr(1)
		elif trimmed.is_valid_int():
			# Fallback for plain numbers, assume P if it's typical input style or just handle as is
			# But user asked for P/S distinction. 
			# Let's assume input "1" means "P1" for backward compat or "S1"? 
			# The prompt implies explicit differentiation.
			# Let's default to just storing the raw number if no prefix, 
			# but the prompt asks for S1/P1 interpretation.
			# Let's STRICTLY parse P and S, or raw numbers.
			number_str = trimmed
		
		if number_str.is_valid_int():
			var val = number_str.to_int()
			if type == "P":
				selected_sources.append("P" + str(val))
			elif type == "S":
				selected_sources.append("S" + str(val))
			else:
				# No prefix provided, maybe default to P? Or just pass formatted string?
				# Let's try to infer or just keep raw for now, but the system needs P/S.
				# If user types "1", and we want them to type P1/S1, maybe we just store "1" and let validation handle it?
				# OR, we force them to type P/S.
				# Let's store "P" + val if they just type a number to be safe/lazy?
				# No, let's respect the user's input.
				selected_sources.append(str(val))


func update_result_text(text: String):
	result_text = text
	result_field.text = text

func get_step_data() -> Dictionary:
	return {
		"number": step_number,
		"result": result_text,
		"rule": selected_rule,
		"sources": selected_sources
	}

func get_result_field() -> LineEdit:
	return result_field

func update_step_number(new_number: int):
	step_number = new_number
	if number_label:
		number_label.text = "Step " + str(step_number)
