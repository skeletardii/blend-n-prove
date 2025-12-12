class_name ChatMessageBox
extends PanelContainer

## Chat message component for AI Tutor Mode
## Displays a message with role-based styling (AI, User, or System)

enum MessageRole {
	USER,
	AI,
	SYSTEM
}

var role: MessageRole
var message_text: String
var label: RichTextLabel

func _init(p_role: MessageRole, p_text: String):
	role = p_role
	message_text = p_text
	call_deferred("setup_ui")

func setup_ui():
	# Create and apply StyleBoxFlat based on role
	var style = StyleBoxFlat.new()

	if role == MessageRole.AI:
		# Light blue background for AI messages
		style.bg_color = Color(0.91, 0.96, 1.0, 1.0)  # #E8F4FF
		style.border_color = Color(0.24, 0.60, 1.0, 1.0)  # #3D9BFF
	elif role == MessageRole.USER:
		# Light gray background for user messages
		style.bg_color = Color(0.96, 0.96, 0.96, 1.0)  # #F5F5F5
		style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	else:  # SYSTEM
		# Light yellow background for system messages
		style.bg_color = Color(1.0, 0.98, 0.9, 1.0)
		style.border_color = Color(0.8, 0.7, 0.4, 1.0)

	# Rounded corners
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12

	# Borders
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	# Padding (done via MarginContainer below)
	add_theme_stylebox_override("panel", style)

	# Add margin container for padding
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	# Add rich text label for message content
	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.selection_enabled = true
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_font_size_override("bold_font_size", 20)
	label.add_theme_color_override("default_color", Color(0.1, 0.1, 0.1, 1.0))
	label.text = message_text
	margin.add_child(label)

	# Set minimum size for proper layout
	custom_minimum_size = Vector2(0, 60)

func set_message_text(text: String):
	message_text = text
	if label:
		label.text = text
