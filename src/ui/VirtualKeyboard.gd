class_name VirtualKeyboard
extends Control

## Virtual keyboard for boolean logic input
## Provides buttons for logic operators, variables, parentheses, and control keys
## CRITICAL: Does NOT add automatic spacing when symbols are inserted

signal symbol_pressed(symbol: String)
signal delete_pressed()
signal clear_pressed()
signal space_pressed()

var target_field: LineEdit = null

# Button layout definitions
const OPERATOR_ROW_1 = ["∧", "∨", "⊕", "→", "↔","¬","(", ")"]
const VARIABLE_ROW = ["P", "Q", "R", "S", "T","U","V","Del", "Clr"]

# UI containers
var keyboard_panel: Panel
var keyboard_layout: VBoxContainer
var operator_row1: HBoxContainer
var operator_row2: HBoxContainer
var variable_row: HBoxContainer
var paren_row: HBoxContainer
var control_row: HBoxContainer

func _ready():
	create_keyboard()

func create_keyboard():
	# Main panel with styling
	keyboard_panel = Panel.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	panel_style.border_color = Color(0.775, 0.417, 0.946, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	keyboard_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(keyboard_panel)

	# Layout container
	keyboard_layout = VBoxContainer.new()
	keyboard_layout.add_theme_constant_override("separation", 5)
	keyboard_panel.add_child(keyboard_layout)

	# Add margin around keyboard
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	keyboard_panel.add_child(margin)
	margin.add_child(keyboard_layout)

	# Anchor panel to fill parent
	keyboard_panel.anchor_left = 0.0
	keyboard_panel.anchor_top = 0.0
	keyboard_panel.anchor_right = 1.0
	keyboard_panel.anchor_bottom = 1.0

	# Create rows
	operator_row1 = create_centered_row()
	keyboard_layout.add_child(operator_row1)
	create_row_buttons(operator_row1, OPERATOR_ROW_1, 60)

	variable_row = create_centered_row()
	keyboard_layout.add_child(variable_row)
	create_row_buttons(variable_row, VARIABLE_ROW, 60)

	control_row = create_centered_row()
	keyboard_layout.add_child(control_row)

func create_centered_row() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	return row

func create_row_buttons(row: HBoxContainer, symbols: Array, button_size: int):
	for symbol in symbols:
		var button = Button.new()
		button.text = symbol
		button.custom_minimum_size = Vector2(button_size, button_size)
		button.add_theme_font_size_override("font_size", 28)
		# Purple text for symbols
		#button.add_theme_color_override("font_color", Color(0.775, 0.417, 0.946, 1.0))
		#button.add_theme_color_override("font_focus_color", Color(0.775, 0.417, 0.946, 1.0))
		#button.add_theme_color_override("font_hover_color", Color(0.6, 0.2, 0.8, 1.0))
		button.pressed.connect(_on_symbol_pressed.bind(symbol))
		row.add_child(button)
		match symbol:
			"Del":
				button.pressed.connect(_on_delete_pressed)
			"Clr":
				button.pressed.connect(_on_clear_pressed)

## Set the target LineEdit that this keyboard will input to
func set_target_field(field: LineEdit):
	target_field = field

## Called when a symbol button is pressed
## CRITICAL: No automatic spacing - inserts symbol at cursor position
func _on_symbol_pressed(symbol: String):
	if target_field:
		var cursor_pos = target_field.caret_column
		var current_text = target_field.text
		# Insert symbol at cursor position WITHOUT adding spaces
		var new_text = current_text.insert(cursor_pos, symbol)
		target_field.text = new_text
		target_field.caret_column = cursor_pos + symbol.length()
		target_field.grab_focus()
		symbol_pressed.emit(symbol)
		AudioManager.play_button_click()

## Called when Delete button is pressed
func _on_delete_pressed():
	if target_field and target_field.text.length() > 0:
		var cursor_pos = target_field.caret_column
		if cursor_pos > 0:
			var current_text = target_field.text
			var new_text = current_text.erase(cursor_pos - 4, 1)
			target_field.text = new_text
			target_field.caret_column = cursor_pos - 1
			target_field.grab_focus()
			delete_pressed.emit()
			AudioManager.play_button_click()

## Called when Clear button is pressed
func _on_clear_pressed():
	if target_field:
		target_field.text = ""
		target_field.caret_column = 0
		target_field.grab_focus()
		clear_pressed.emit()
		AudioManager.play_button_click()

## Called when Space button is pressed
func _on_space_pressed():
	if target_field:
		var cursor_pos = target_field.caret_column
		var current_text = target_field.text
		var new_text = current_text.insert(cursor_pos, " ")
		target_field.text = new_text
		target_field.caret_column = cursor_pos + 1
		target_field.grab_focus()
		space_pressed.emit()
		AudioManager.play_button_click()
